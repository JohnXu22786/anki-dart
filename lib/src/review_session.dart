/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd
 * SPDX-FileCopyrightText: 2026 Mike Hardy <github@mikehardy.net>
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Dart adaptation of the reviewer and scheduler wrapper behavior in the pinned
 * AnkiDroid source documented in ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// The four answer ratings passed to AnkiDroid's scheduler.
enum ReviewRating { again, hard, good, easy }

/// The visible side and lifecycle of a study session.
enum ReviewSessionPhase {
  idle,
  loading,
  question,
  answer,
  timeboxReached,
  finished,
}

/// Rendered card content supplied by the review backend.
///
/// Card template rendering and collection access remain responsibilities of the
/// backend adapter.
class ReviewCard {
  const ReviewCard({
    required this.id,
    required this.questionHtml,
    required this.answerHtml,
  });

  final int id;
  final String questionHtml;
  final String answerHtml;
}

/// The active AnkiDroid scheduler queue for the current review state.
enum ReviewQueueKind { newCards, learning, review }

/// The three due counts supplied by AnkiDroid's scheduler.
class ReviewQueueCounts {
  const ReviewQueueCounts({
    required this.newCount,
    required this.learnCount,
    required this.reviewCount,
  });

  final int newCount;
  final int learnCount;
  final int reviewCount;
}

/// A card selected by the scheduler, paired with its opaque scheduling snapshot.
///
/// The snapshot is produced by the compatible Anki backend and is passed back
/// unchanged when the card is answered. A timebox event pauses the reviewer
/// before this card is displayed; the previously visible card side remains
/// visible until queue loading resumes, matching AnkiDroid's reviewer flow.
/// Counts and the active queue correspond to `CurrentQueueState.counts` and
/// `CurrentQueueState.countsIndex` in AnkiDroid 2.25.3.
class ReviewQueueState<TSchedulingSnapshot> {
  const ReviewQueueState({
    required this.card,
    required this.schedulingSnapshot,
    required this.counts,
    required this.activeQueue,
    this.timeboxReached,
  });

  final ReviewCard card;
  final TSchedulingSnapshot schedulingSnapshot;
  final ReviewQueueCounts counts;
  final ReviewQueueKind activeQueue;
  final ReviewTimeboxReached? timeboxReached;
}

/// Time and answer count supplied when AnkiDroid's study timebox expires.
class ReviewTimeboxReached {
  const ReviewTimeboxReached({required this.secs, required this.reps});

  final int secs;
  final int reps;
}

/// The queue and answer operations required by the reviewer flow.
///
/// An adapter for the AnkiDroid 2.25.3 backend should implement queue selection
/// and answer application through the pinned backend API. This package does not
/// reproduce the Rust scheduler or collection storage.
abstract interface class ReviewScheduler<TSchedulingSnapshot> {
  /// Returns the current top card, or `null` when the review queue is empty.
  /// A non-null state's [ReviewQueueState.timeboxReached] pauses presentation.
  Future<ReviewQueueState<TSchedulingSnapshot>?> currentQueueState();

  /// Waits for the current card's state-mutation hook, if one is pending.
  ///
  /// AnkiDroid waits for this callback before revealing the answer or grading a
  /// card; an adapter without a pending hook can complete immediately.
  Future<void> waitForCurrentCardStateMutation();

  /// Applies [rating] to [state] using the backend's scheduling rules.
  Future<void> answerCard(
    ReviewQueueState<TSchedulingSnapshot> state,
    ReviewRating rating,
  );
}

/// The AnkiDroid reviewer lifecycle from queue selection through the next card.
///
/// Actions are serialized like `ReviewerViewModel.executeAction()`. Answer
/// ratings are forwarded to [scheduler] without calculating intervals in Dart.
class ReviewSession<TSchedulingSnapshot> {
  ReviewSession(this.scheduler);

  final ReviewScheduler<TSchedulingSnapshot> scheduler;
  Future<void> _actionTail = Future<void>.value();
  ReviewSessionPhase _phase = ReviewSessionPhase.idle;
  ReviewQueueState<TSchedulingSnapshot>? _current;
  ReviewTimeboxReached? _timeboxReached;
  ReviewCard? _lastDisplayedCard;
  ReviewSessionPhase? _lastDisplayedSide;

  ReviewSessionPhase get phase => _phase;

  ReviewQueueState<TSchedulingSnapshot>? get current => _current;

  ReviewTimeboxReached? get timeboxReached => _timeboxReached;

  /// The visible card side while a new queue state loads or a timebox pauses,
  /// or `null` if there is no displayed card.
  String? get visibleContent {
    final showingLastDisplayed = _current == null &&
        (_phase == ReviewSessionPhase.loading ||
            _phase == ReviewSessionPhase.timeboxReached);
    final card = showingLastDisplayed ? _lastDisplayedCard : _current?.card;
    final side = showingLastDisplayed ? _lastDisplayedSide : _phase;
    if (card == null ||
        (side != ReviewSessionPhase.question &&
            side != ReviewSessionPhase.answer)) {
      return null;
    }
    return side == ReviewSessionPhase.answer
        ? card.answerHtml
        : card.questionHtml;
  }

  /// Loads the first scheduler-selected card. Repeated starts are ignored.
  Future<void> start() => _serialize(() async {
        if (_phase != ReviewSessionPhase.idle) return;
        _phase = ReviewSessionPhase.loading;
        await _loadCurrentQueueState();
      });

  /// Shows the answer once the question is active; repeated calls are ignored.
  Future<void> showAnswer() => _serialize(() async {
        if (_phase != ReviewSessionPhase.question) return;
        await scheduler.waitForCurrentCardStateMutation();
        _phase = ReviewSessionPhase.answer;
        _lastDisplayedSide = ReviewSessionPhase.answer;
      });

  /// Retries a queue read that failed while the session was loading.
  Future<void> retryCurrentQueueState() => _serialize(() async {
        if (_phase != ReviewSessionPhase.loading) return;
        await _loadCurrentQueueState();
      });

  /// Reloads the queue after the caller continues from a timebox event.
  Future<void> continueAfterTimebox() => _serialize(() async {
        if (_phase != ReviewSessionPhase.timeboxReached) return;
        _phase = ReviewSessionPhase.loading;
        _timeboxReached = null;
        await _loadCurrentQueueState();
      });

  /// Sends a rating to the scheduler, then loads the next queue item.
  ///
  /// As in the source action dispatcher, this forwards a rating even if the
  /// answer side has not been shown. If the backend rejects the answer, the
  /// current card and side remain available.
  Future<void> answerCard(ReviewRating rating) => _serialize(() async {
        final state = _current;
        if (state == null ||
            _phase == ReviewSessionPhase.idle ||
            _phase == ReviewSessionPhase.loading ||
            _phase == ReviewSessionPhase.finished) {
          return;
        }

        await scheduler.waitForCurrentCardStateMutation();
        await scheduler.answerCard(state, rating);
        _current = null;
        _timeboxReached = null;
        _phase = ReviewSessionPhase.loading;
        await _loadCurrentQueueState();
      });

  Future<void> _loadCurrentQueueState() async {
    final next = await scheduler.currentQueueState();
    if (next == null) {
      _current = null;
      _timeboxReached = null;
      _phase = ReviewSessionPhase.finished;
    } else if (next.timeboxReached case final timebox?) {
      _current = null;
      _timeboxReached = timebox;
      _phase = ReviewSessionPhase.timeboxReached;
    } else {
      _current = next;
      _lastDisplayedCard = next.card;
      _lastDisplayedSide = ReviewSessionPhase.question;
      _timeboxReached = null;
      _phase = ReviewSessionPhase.question;
    }
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final previous = _actionTail;
    final release = Completer<void>();
    _actionTail = release.future;

    return previous.then((_) => action()).whenComplete(() {
      if (!release.isCompleted) release.complete();
    });
  }
}
