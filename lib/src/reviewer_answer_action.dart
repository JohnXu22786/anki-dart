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
 * Behavioral reference: AnswerButtons.kt and AutomaticAnswer.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_command_router.dart';

/// Maps a reviewer answer-button rating to its command.
///
/// Declaration order follows AnkiDroid's AGAIN/HARD/GOOD/EASY enum.
enum AnswerButtons {
  again,
  hard,
  good,
  easy;

  /// Returns the command dispatched for this rating in AnkiDroid.
  ViewerCommand toViewerCommand() => switch (this) {
        AnswerButtons.again => ViewerCommand.ANSWER_AGAIN,
        AnswerButtons.hard => ViewerCommand.ANSWER_HARD,
        AnswerButtons.good => ViewerCommand.ANSWER_GOOD,
        AnswerButtons.easy => ViewerCommand.ANSWER_EASY,
      };
}

/// AnkiDroid's answer action stored in deck configuration.
///
/// Config values and declaration order match `AutomaticAnswerAction`. This
/// model only resolves a value to a command; config access and command effects
/// remain with the host.
enum AutomaticAnswerAction {
  buryCard(0),
  answerAgain(1),
  answerGood(2),
  answerHard(3),
  showReminder(4);

  const AutomaticAnswerAction(this.configValue);

  /// The integer stored in the source deck configuration.
  final int configValue;

  /// Decodes a source config integer, defaulting unknown values to burying.
  static AutomaticAnswerAction fromConfigValue(int value) => values.firstWhere(
        (action) => action.configValue == value,
        orElse: () => AutomaticAnswerAction.buryCard,
      );

  /// The command for this action, or null for the reminder outcome.
  ViewerCommand? get viewerCommand => switch (this) {
        AutomaticAnswerAction.buryCard => ViewerCommand.BURY_CARD,
        AutomaticAnswerAction.answerAgain => ViewerCommand.ANSWER_AGAIN,
        AutomaticAnswerAction.answerGood => ViewerCommand.ANSWER_GOOD,
        AutomaticAnswerAction.answerHard => ViewerCommand.ANSWER_HARD,
        AutomaticAnswerAction.showReminder => null,
      };
}
