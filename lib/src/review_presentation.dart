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
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: StudyCounts.kt, StudyCountsView.kt,
 * AnswerButtonsNextTime.kt, and Scheduler.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'review_session.dart';

/// The count strings and active queue displayed by AnkiDroid's reviewer.
class StudyCounts {
  StudyCounts({
    int newCount = 0,
    int learnCount = 0,
    int reviewCount = 0,
    this.activeQueue = ReviewQueueKind.newCards,
  })  : newCount = newCount.toString(),
        learnCount = learnCount.toString(),
        reviewCount = reviewCount.toString();

  static StudyCounts fromQueueState<T>(ReviewQueueState<T> state) =>
      StudyCounts(
        newCount: state.counts.newCount,
        learnCount: state.counts.learnCount,
        reviewCount: state.counts.reviewCount,
        activeQueue: state.activeQueue,
      );

  final String newCount;
  final String learnCount;
  final String reviewCount;
  final ReviewQueueKind activeQueue;

  /// Whether [queue] receives the active-count styling in the reviewer view.
  bool isActive(ReviewQueueKind queue) => activeQueue == queue;
}

/// Backend boundary for AnkiDroid's scheduler-provided answer-button labels.
///
/// Implementations pass [schedulingStates] to the compatible backend's
/// `describeNextStates()` API and return its four strings in Again, Hard, Good,
/// Easy order. The strings contain backend formatting and are not recalculated
/// or localized by this presentation model.
abstract interface class ReviewNextStateDescriber<TSchedulingSnapshot> {
  Future<List<String>> describeNextStates(TSchedulingSnapshot schedulingStates);
}

/// The four next-time labels displayed below the reviewer answer buttons.
class AnswerButtonsNextTime {
  const AnswerButtonsNextTime({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  final String again;
  final String hard;
  final String good;
  final String easy;

  /// Gets backend labels for the current state in Again/Hard/Good/Easy order.
  ///
  /// This intentionally indexes the four required values directly, matching
  /// the source's four-element destructuring contract.
  static Future<AnswerButtonsNextTime> from<TSchedulingSnapshot>({
    required ReviewQueueState<TSchedulingSnapshot> state,
    required ReviewNextStateDescriber<TSchedulingSnapshot> scheduler,
  }) async {
    final labels = await scheduler.describeNextStates(state.schedulingSnapshot);
    return AnswerButtonsNextTime(
      again: labels[0],
      hard: labels[1],
      good: labels[2],
      easy: labels[3],
    );
  }
}
