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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Dart adaptation of AnkiDroid 2.25.3 AutoAdvance.kt and its action/settings
 * types; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Common type for a typed action emitted by Auto Advance.
sealed class AutoAdvanceAction {
  const AutoAdvanceAction();
}

/// An action that can run after the question side is shown.
enum QuestionAction implements AutoAdvanceAction {
  showAnswer(0),
  showReminder(1);

  const QuestionAction(this.code);

  final int code;

  /// Decodes the pinned integer code, falling back to `SHOW_ANSWER`.
  static QuestionAction fromCode(int code) => values.firstWhere(
        (action) => action.code == code,
        orElse: () => QuestionAction.showAnswer,
      );
}

/// An action that can run after the answer side is shown.
enum AnswerAction implements AutoAdvanceAction {
  buryCard(0),
  answerAgain(1),
  answerGood(2),
  answerHard(3),
  showReminder(4);

  const AnswerAction(this.code);

  final int code;

  /// Decodes the pinned integer code, falling back to `BURY_CARD`.
  static AnswerAction fromCode(int code) => values.firstWhere(
        (action) => action.code == code,
        orElse: () => AnswerAction.buryCard,
      );
}

/// The already-resolved Auto Advance values for the current card's deck.
///
/// The adapter supplies every field. This class does not supply deck-config
/// defaults or read collection storage.
class AutoAdvanceSettings {
  const AutoAdvanceSettings({
    required this.questionAction,
    required this.answerAction,
    required this.durationToShowQuestionFor,
    required this.durationToShowAnswerFor,
    required this.waitForAudio,
  });

  final QuestionAction questionAction;
  final AnswerAction answerAction;
  final Duration durationToShowQuestionFor;
  final Duration durationToShowAnswerFor;
  final bool waitForAudio;
}

/// Loads settings for the deck containing [card].
///
/// An Android/backend adapter should resolve the card's current deck and read
/// its `DeckConfig`. It is responsible for preserving that backend's values and
/// defaults; Auto Advance does not access Anki storage itself.
abstract interface class AutoAdvanceSettingsAdapter<TCard> {
  Future<AutoAdvanceSettings> loadForCard(TCard card);
}

/// Creates cancellable delays used for Auto Advance actions.
///
/// The scheduler is injectable so the timer state can be exercised without
/// waiting for wall-clock time.
abstract interface class AutoAdvanceScheduler {
  AutoAdvanceDelayHandle schedule(Duration duration);
}

/// A scheduled delay that can be cancelled before it completes.
abstract interface class AutoAdvanceDelayHandle {
  Future<void> get completion;

  void cancel();
}

/// A suspended listener receives either a question-side or answer-side action.
typedef AutoAdvanceActionListener = FutureOr<void> Function(
  AutoAdvanceAction action,
);

/// The reviewer Auto Advance timer and deck-settings lifecycle.
///
/// Visibility events start the matching configured timer while enabled. A
/// card change cancels the currently tracked question and answer jobs, then
/// reloads settings through [settingsAdapter]. Repeated events for the same
/// side overwrite that side's tracked job without cancelling the earlier job,
/// matching AnkiDroid's `AutoAdvance` implementation.
class AutoAdvance<TCard> {
  AutoAdvance({
    required TCard initialCard,
    required AutoAdvanceSettingsAdapter<TCard> settingsAdapter,
    required AutoAdvanceActionListener listener,
    AutoAdvanceScheduler? scheduler,
  })  : _settingsAdapter = settingsAdapter,
        _listener = listener,
        _scheduler = scheduler ?? const _TimerAutoAdvanceScheduler(),
        _settings = Future<AutoAdvanceSettings>.sync(
          () => settingsAdapter.loadForCard(initialCard),
        );

  final AutoAdvanceSettingsAdapter<TCard> _settingsAdapter;
  final AutoAdvanceActionListener _listener;
  final AutoAdvanceScheduler _scheduler;
  Future<AutoAdvanceSettings> _settings;
  _AutoAdvanceActionJob? _questionActionJob;
  _AutoAdvanceActionJob? _answerActionJob;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  set isEnabled(bool value) {
    _isEnabled = value;
    if (!value) cancelQuestionAndAnswerActionJobs();
  }

  /// Cancels the most recently tracked job for each visible side.
  void cancelQuestionAndAnswerActionJobs() {
    _questionActionJob?.cancel();
    _answerActionJob?.cancel();
  }

  /// Cancels the tracked jobs and loads settings for [card]'s current deck.
  void onCardChange(TCard card) {
    cancelQuestionAndAnswerActionJobs();
    _settings = Future<AutoAdvanceSettings>.sync(
      () => _settingsAdapter.loadForCard(card),
    );
  }

  /// Returns the current deck setting used by the reviewer audio flow.
  Future<bool> shouldWaitForAudio() async => (await _settings).waitForAudio;

  /// Handles the event that the reviewer has shown the question side.
  Future<void> onShowQuestion() async {
    _answerActionJob?.cancel();
    final duration = (await _settings).durationToShowQuestionFor;
    if (duration <= Duration.zero || !_isEnabled) return;

    final job = _AutoAdvanceActionJob();
    // Same-side jobs are not cancelled here in the pinned source. This also
    // means that only the newest same-side job remains tracked for cancellation.
    _questionActionJob = job;
    unawaited(
      _runAction(
        job,
        (settings) => settings.durationToShowQuestionFor,
        (settings) => settings.questionAction,
      ),
    );
  }

  /// Handles the event that the reviewer has shown the answer side.
  Future<void> onShowAnswer() async {
    _questionActionJob?.cancel();
    final duration = (await _settings).durationToShowAnswerFor;
    if (duration <= Duration.zero || !_isEnabled) return;

    final job = _AutoAdvanceActionJob();
    _answerActionJob = job;
    unawaited(
      _runAction(
        job,
        (settings) => settings.durationToShowAnswerFor,
        (settings) => settings.answerAction,
      ),
    );
  }

  Future<void> _runAction(
    _AutoAdvanceActionJob job,
    Duration Function(AutoAdvanceSettings) durationFor,
    AutoAdvanceAction Function(AutoAdvanceSettings) actionFor,
  ) async {
    if (job.isCancelled) return;
    final duration = durationFor(await _settings);
    if (job.isCancelled) return;

    final delay = _scheduler.schedule(duration);
    job.delay = delay;
    await delay.completion;
    if (job.isCancelled) return;

    final action = actionFor(await _settings);
    if (job.isCancelled) return;
    await _listener(action);
  }
}

class _AutoAdvanceActionJob {
  bool isCancelled = false;
  AutoAdvanceDelayHandle? delay;

  void cancel() {
    isCancelled = true;
    delay?.cancel();
  }
}

class _TimerAutoAdvanceScheduler implements AutoAdvanceScheduler {
  const _TimerAutoAdvanceScheduler();

  @override
  AutoAdvanceDelayHandle schedule(Duration duration) =>
      _TimerAutoAdvanceDelay(duration);
}

class _TimerAutoAdvanceDelay implements AutoAdvanceDelayHandle {
  _TimerAutoAdvanceDelay(Duration duration) {
    _timer = Timer(duration, _complete);
  }

  final Completer<void> _completer = Completer<void>();
  late final Timer _timer;

  @override
  Future<void> get completion => _completer.future;

  @override
  void cancel() {
    _timer.cancel();
    _complete();
  }

  void _complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
