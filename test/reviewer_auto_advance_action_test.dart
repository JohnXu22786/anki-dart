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
 * Source-derived Reviewer Auto Advance routing cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer Auto Advance action routing', () {
    test('maps each command action to its matching ViewerCommand', () {
      expect(
        {
          for (final action in <AutoAdvanceAction>[
            QuestionAction.showAnswer,
            AnswerAction.buryCard,
            AnswerAction.answerAgain,
            AnswerAction.answerGood,
            AnswerAction.answerHard,
          ])
            action: reviewerAutoAdvanceDirective(
              action,
              questionReminderText: 'question reminder',
              answerReminderText: 'answer reminder',
            ),
        },
        {
          QuestionAction.showAnswer: const ReviewerAutoAdvanceCommand(
            ViewerCommand.SHOW_ANSWER,
          ),
          AnswerAction.buryCard: const ReviewerAutoAdvanceCommand(
            ViewerCommand.BURY_CARD,
          ),
          AnswerAction.answerAgain: const ReviewerAutoAdvanceCommand(
            ViewerCommand.ANSWER_AGAIN,
          ),
          AnswerAction.answerGood: const ReviewerAutoAdvanceCommand(
            ViewerCommand.ANSWER_GOOD,
          ),
          AnswerAction.answerHard: const ReviewerAutoAdvanceCommand(
            ViewerCommand.ANSWER_HARD,
          ),
        },
      );
    });

    test('passes each host-localized reminder string through unchanged', () {
      const questionReminder = 'Localized question reminder —  3 min';
      const answerReminder = 'Localized answer reminder: 2 minutes';

      final questionOutcome = reviewerAutoAdvanceDirective(
        QuestionAction.showReminder,
        questionReminderText: questionReminder,
        answerReminderText: answerReminder,
      );
      expect(questionOutcome, isA<ReviewerAutoAdvanceFeedback>());
      expect(
        (questionOutcome as ReviewerAutoAdvanceFeedback).message,
        questionReminder,
      );

      final answerOutcome = reviewerAutoAdvanceDirective(
        AnswerAction.showReminder,
        questionReminderText: questionReminder,
        answerReminderText: answerReminder,
      );
      expect(answerOutcome, isA<ReviewerAutoAdvanceFeedback>());
      expect(
        (answerOutcome as ReviewerAutoAdvanceFeedback).message,
        answerReminder,
      );
    });
  });
}
