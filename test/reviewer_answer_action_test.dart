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
 * Behavioral reference: AnswerButtons.kt, AutomaticAnswer.kt,
 * AnswerButtonsTest.kt, and AutomaticAnswerActionTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnswerButtons', () {
    test('maps each rating to the matching reviewer answer command', () {
      expect(
        AnswerButtons.values,
        [
          AnswerButtons.again,
          AnswerButtons.hard,
          AnswerButtons.good,
          AnswerButtons.easy,
        ],
      );
      expect(
        {
          for (final rating in AnswerButtons.values)
            rating: rating.toViewerCommand(),
        },
        {
          AnswerButtons.again: ViewerCommand.ANSWER_AGAIN,
          AnswerButtons.hard: ViewerCommand.ANSWER_HARD,
          AnswerButtons.good: ViewerCommand.ANSWER_GOOD,
          AnswerButtons.easy: ViewerCommand.ANSWER_EASY,
        },
      );
    });
  });

  group('AutomaticAnswerAction', () {
    test('decodes every persisted config code in source order', () {
      expect(
        AutomaticAnswerAction.values.map((action) => action.configValue),
        [0, 1, 2, 3, 4],
      );
      expect(
        [
          for (var value = 0; value <= 4; value++)
            AutomaticAnswerAction.fromConfigValue(value)
        ],
        AutomaticAnswerAction.values,
      );
    });

    test('uses BURY_CARD for unknown config integers', () {
      expect(
        [
          AutomaticAnswerAction.fromConfigValue(-1),
          AutomaticAnswerAction.fromConfigValue(5),
        ],
        [
          AutomaticAnswerAction.buryCard,
          AutomaticAnswerAction.buryCard,
        ],
      );
    });

    test('maps actions to source commands and keeps reminder commandless', () {
      expect(
        {
          for (final action in AutomaticAnswerAction.values)
            action: action.viewerCommand,
        },
        {
          AutomaticAnswerAction.buryCard: ViewerCommand.BURY_CARD,
          AutomaticAnswerAction.answerAgain: ViewerCommand.ANSWER_AGAIN,
          AutomaticAnswerAction.answerGood: ViewerCommand.ANSWER_GOOD,
          AutomaticAnswerAction.answerHard: ViewerCommand.ANSWER_HARD,
          AutomaticAnswerAction.showReminder: null,
        },
      );
    });
  });
}
