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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: AutoAdvanceTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AutoAdvance actions', () {
    test('settings use structural value equality and hashing', () {
      final first = _settings(
        questionAction: QuestionAction.showReminder,
        answerAction: AnswerAction.answerGood,
        questionDelay: const Duration(seconds: 2),
        answerDelay: const Duration(seconds: 3),
        waitForAudio: true,
      );
      final equal = _settings(
        questionAction: QuestionAction.showReminder,
        answerAction: AnswerAction.answerGood,
        questionDelay: const Duration(seconds: 2),
        answerDelay: const Duration(seconds: 3),
        waitForAudio: true,
      );
      final different = _settings(
        questionAction: QuestionAction.showReminder,
        answerAction: AnswerAction.answerGood,
        questionDelay: const Duration(seconds: 2),
        answerDelay: const Duration(seconds: 3),
        waitForAudio: false,
      );

      expect(equal, first);
      expect(equal.hashCode, first.hashCode);
      expect(different, isNot(first));
    });

    test('decodes the pinned integer codes and fallback actions', () {
      expect(
        QuestionAction.values.map((action) => action.code),
        [0, 1],
      );
      expect(QuestionAction.fromCode(0), QuestionAction.showAnswer);
      expect(QuestionAction.fromCode(1), QuestionAction.showReminder);
      expect(QuestionAction.fromCode(-1), QuestionAction.showAnswer);
      expect(QuestionAction.fromCode(99), QuestionAction.showAnswer);

      expect(
        AnswerAction.values.map((action) => action.code),
        [0, 1, 2, 3, 4],
      );
      expect(AnswerAction.fromCode(0), AnswerAction.buryCard);
      expect(AnswerAction.fromCode(1), AnswerAction.answerAgain);
      expect(AnswerAction.fromCode(2), AnswerAction.answerGood);
      expect(AnswerAction.fromCode(3), AnswerAction.answerHard);
      expect(AnswerAction.fromCode(4), AnswerAction.showReminder);
      expect(AnswerAction.fromCode(-1), AnswerAction.buryCard);
      expect(AnswerAction.fromCode(99), AnswerAction.buryCard);
    });

    test('waits the configured question and answer delays before dispatch',
        () async {
      final delay = _FakeDelay();
      final actions = <AutoAdvanceAction>[];
      final settings = _settings(
        questionAction: QuestionAction.showReminder,
        answerAction: AnswerAction.answerHard,
        questionDelay: const Duration(seconds: 2),
        answerDelay: const Duration(seconds: 3),
      );
      final autoAdvance = _autoAdvance(
        settingsByDeck: {1: settings},
        scheduler: delay,
        actions: actions,
      )..isEnabled = true;

      await autoAdvance.onShowQuestion();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 1));
      expect(actions, isEmpty);
      await delay.advanceBy(const Duration(seconds: 1));
      expect(actions, [QuestionAction.showReminder]);

      await autoAdvance.onShowAnswer();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 2));
      expect(actions, [QuestionAction.showReminder]);
      await delay.advanceBy(const Duration(seconds: 1));
      expect(actions, [QuestionAction.showReminder, AnswerAction.answerHard]);
    });

    test('disabled events and nonpositive durations do not schedule actions',
        () async {
      final delay = _FakeDelay();
      final actions = <AutoAdvanceAction>[];
      final autoAdvance = _autoAdvance(
        settingsByDeck: {
          1: _settings(
            questionDelay: const Duration(seconds: 2),
            answerDelay: Duration.zero,
          ),
          2: _settings(
            questionDelay: const Duration(seconds: -1),
            answerDelay: const Duration(seconds: 1),
          ),
        },
        scheduler: delay,
        actions: actions,
      );

      await autoAdvance.onShowQuestion();
      autoAdvance.isEnabled = true;
      await autoAdvance.onShowAnswer();
      await delay.advanceBy(const Duration(seconds: 5));
      expect(actions, isEmpty);

      autoAdvance.onCardChange(const _Card(2));
      await autoAdvance.onShowQuestion();
      await delay.advanceBy(const Duration(seconds: 5));
      expect(actions, isEmpty);
    });

    test('disabling cancels the pending question timer', () async {
      final delay = _FakeDelay();
      final actions = <AutoAdvanceAction>[];
      final autoAdvance = _autoAdvance(
        settingsByDeck: {
          1: _settings(questionDelay: const Duration(seconds: 5)),
        },
        scheduler: delay,
        actions: actions,
      )..isEnabled = true;

      await autoAdvance.onShowQuestion();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 2));
      autoAdvance.isEnabled = false;
      await delay.advanceBy(const Duration(seconds: 4));

      expect(actions, isEmpty);
    });

    test('showing the opposite side cancels the current side timer', () async {
      final delay = _FakeDelay();
      final actions = <AutoAdvanceAction>[];
      final autoAdvance = _autoAdvance(
        settingsByDeck: {
          1: _settings(
            questionAction: QuestionAction.showAnswer,
            answerAction: AnswerAction.answerGood,
            questionDelay: const Duration(seconds: 3),
            answerDelay: const Duration(seconds: 1),
          ),
        },
        scheduler: delay,
        actions: actions,
      )..isEnabled = true;

      await autoAdvance.onShowQuestion();
      await delay.flush();
      await delay.advanceBy(const Duration(milliseconds: 500));
      await autoAdvance.onShowAnswer();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 1));
      expect(actions, [AnswerAction.answerGood]);
      await delay.advanceBy(const Duration(seconds: 2));
      expect(actions, [AnswerAction.answerGood]);
    });

    test('card changes cancel the current timer and reload deck settings',
        () async {
      final delay = _FakeDelay();
      final actions = <AutoAdvanceAction>[];
      final adapter = _FakeSettingsAdapter({
        1: _settings(
          questionAction: QuestionAction.showAnswer,
          questionDelay: const Duration(seconds: 1),
          waitForAudio: false,
        ),
        2: _settings(
          questionAction: QuestionAction.showReminder,
          questionDelay: const Duration(seconds: 2),
          waitForAudio: true,
        ),
      });
      final autoAdvance = AutoAdvance<_Card>(
        initialCard: const _Card(1),
        settingsAdapter: adapter,
        listener: (action, _) => actions.add(action),
        scheduler: delay,
      )..isEnabled = true;

      expect(await autoAdvance.shouldWaitForAudio(), isFalse);
      await autoAdvance.onShowQuestion();
      await delay.flush();
      autoAdvance.onCardChange(const _Card(2));
      expect(await autoAdvance.shouldWaitForAudio(), isTrue);
      await delay.advanceBy(const Duration(seconds: 1));
      expect(actions, isEmpty);

      await autoAdvance.onShowQuestion();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 2));

      expect(adapter.loadedDecks, [1, 2]);
      expect(actions, [QuestionAction.showReminder]);
    });

    test('disabling signals cancellation to a suspended question listener',
        () async {
      final delay = _FakeDelay();
      final listenerStarted = Completer<void>();
      final listenerCancelled = Completer<void>();
      final autoAdvance = AutoAdvance<_Card>(
        initialCard: const _Card(1),
        settingsAdapter: _FakeSettingsAdapter({
          1: _settings(questionDelay: const Duration(seconds: 1)),
        }),
        listener: (action, cancellation) async {
          listenerStarted.complete();
          await cancellation.whenCancelled;
          listenerCancelled.complete();
        },
        scheduler: delay,
      )..isEnabled = true;

      await autoAdvance.onShowQuestion();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 1));
      await listenerStarted.future;

      autoAdvance.isEnabled = false;
      await listenerCancelled.future;
    });

    test('card changes signal cancellation to a suspended answer listener',
        () async {
      final delay = _FakeDelay();
      final listenerStarted = Completer<void>();
      final listenerCancelled = Completer<void>();
      final autoAdvance = AutoAdvance<_Card>(
        initialCard: const _Card(1),
        settingsAdapter: _FakeSettingsAdapter({
          1: _settings(answerDelay: const Duration(seconds: 1)),
          2: _settings(),
        }),
        listener: (action, cancellation) async {
          listenerStarted.complete();
          await cancellation.whenCancelled;
          listenerCancelled.complete();
        },
        scheduler: delay,
      )..isEnabled = true;

      await autoAdvance.onShowAnswer();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 1));
      await listenerStarted.future;

      autoAdvance.onCardChange(const _Card(2));
      await listenerCancelled.future;
    });

    test('a repeated same-side event leaves the older timer untracked',
        () async {
      final delay = _FakeDelay();
      final actions = <AutoAdvanceAction>[];
      final autoAdvance = _autoAdvance(
        settingsByDeck: {
          1: _settings(
            questionAction: QuestionAction.showReminder,
            questionDelay: const Duration(seconds: 3),
          ),
        },
        scheduler: delay,
        actions: actions,
      )..isEnabled = true;

      await autoAdvance.onShowQuestion();
      await delay.flush();
      await delay.advanceBy(const Duration(seconds: 1));
      await autoAdvance.onShowQuestion();
      await delay.flush();
      autoAdvance.isEnabled = false;

      await delay.advanceBy(const Duration(seconds: 2));
      expect(actions, [QuestionAction.showReminder]);
      await delay.advanceBy(const Duration(seconds: 1));
      expect(actions, [QuestionAction.showReminder]);
    });
  });
}

AutoAdvanceSettings _settings({
  QuestionAction questionAction = QuestionAction.showAnswer,
  AnswerAction answerAction = AnswerAction.buryCard,
  Duration questionDelay = Duration.zero,
  Duration answerDelay = Duration.zero,
  bool waitForAudio = false,
}) =>
    AutoAdvanceSettings(
      questionAction: questionAction,
      answerAction: answerAction,
      durationToShowQuestionFor: questionDelay,
      durationToShowAnswerFor: answerDelay,
      waitForAudio: waitForAudio,
    );

AutoAdvance<_Card> _autoAdvance({
  required Map<int, AutoAdvanceSettings> settingsByDeck,
  required _FakeDelay scheduler,
  required List<AutoAdvanceAction> actions,
}) =>
    AutoAdvance<_Card>(
      initialCard: const _Card(1),
      settingsAdapter: _FakeSettingsAdapter(settingsByDeck),
      listener: (action, _) => actions.add(action),
      scheduler: scheduler,
    );

class _Card {
  const _Card(this.deckId);

  final int deckId;
}

class _FakeSettingsAdapter implements AutoAdvanceSettingsAdapter<_Card> {
  _FakeSettingsAdapter(this.settingsByDeck);

  final Map<int, AutoAdvanceSettings> settingsByDeck;
  final List<int> loadedDecks = [];

  @override
  Future<AutoAdvanceSettings> loadForCard(_Card card) async {
    loadedDecks.add(card.deckId);
    return settingsByDeck[card.deckId]!;
  }
}

class _FakeDelay implements AutoAdvanceScheduler {
  Duration now = Duration.zero;
  int _sequence = 0;
  final List<_PendingDelay> _pending = [];

  @override
  AutoAdvanceDelayHandle schedule(Duration duration) {
    final pending = _PendingDelay._(
      owner: this,
      dueAt: now + duration,
      sequence: _sequence++,
      completer: Completer<void>(),
    );
    _pending.add(pending);
    return pending;
  }

  Future<void> advanceBy(Duration duration) async {
    now += duration;
    while (true) {
      _pending.sort((a, b) {
        final byDueTime = a.dueAt.compareTo(b.dueAt);
        return byDueTime != 0 ? byDueTime : a.sequence.compareTo(b.sequence);
      });
      if (_pending.isEmpty) break;
      final next = _pending[0];
      if (next.dueAt > now) break;
      next.complete();
      await flush();
    }
    await flush();
  }

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }
}

class _PendingDelay implements AutoAdvanceDelayHandle {
  _PendingDelay._({
    required this.owner,
    required this.dueAt,
    required this.sequence,
    required this.completer,
  });

  final _FakeDelay owner;
  final Duration dueAt;
  final int sequence;
  final Completer<void> completer;
  bool _isCompleted = false;

  @override
  Future<void> get completion => completer.future;

  @override
  void cancel() {
    if (_isCompleted) return;
    owner._pending.remove(this);
    _complete();
  }

  void complete() {
    owner._pending.remove(this);
    _complete();
  }

  void _complete() {
    if (_isCompleted) return;
    _isCompleted = true;
    completer.complete();
  }
}
