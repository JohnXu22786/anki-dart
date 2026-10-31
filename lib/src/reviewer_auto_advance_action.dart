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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'auto_advance.dart';
import 'gesture_command_router.dart' show ViewerCommand;

/// The host operation or feedback selected for a scheduled Reviewer action.
sealed class ReviewerAutoAdvanceDirective {
  const ReviewerAutoAdvanceDirective();
}

/// A Viewer command the host should execute for a scheduled action.
final class ReviewerAutoAdvanceCommand extends ReviewerAutoAdvanceDirective {
  const ReviewerAutoAdvanceCommand(this.command);

  final ViewerCommand command;
}

/// Localized reminder feedback supplied unchanged by the host.
final class ReviewerAutoAdvanceFeedback extends ReviewerAutoAdvanceDirective {
  const ReviewerAutoAdvanceFeedback(this.message);

  final String message;
}

/// Projects an Auto Advance callback into a host command or feedback directive.
///
/// The host resolves both localized reminder strings and remains responsible for
/// command execution and feedback delivery.
ReviewerAutoAdvanceDirective reviewerAutoAdvanceDirective(
  AutoAdvanceAction action, {
  required String questionReminderText,
  required String answerReminderText,
}) => switch (action) {
  QuestionAction.showAnswer => const ReviewerAutoAdvanceCommand(
    ViewerCommand.SHOW_ANSWER,
  ),
  QuestionAction.showReminder => ReviewerAutoAdvanceFeedback(
    questionReminderText,
  ),
  AnswerAction.buryCard => const ReviewerAutoAdvanceCommand(
    ViewerCommand.BURY_CARD,
  ),
  AnswerAction.answerAgain => const ReviewerAutoAdvanceCommand(
    ViewerCommand.ANSWER_AGAIN,
  ),
  AnswerAction.answerGood => const ReviewerAutoAdvanceCommand(
    ViewerCommand.ANSWER_GOOD,
  ),
  AnswerAction.answerHard => const ReviewerAutoAdvanceCommand(
    ViewerCommand.ANSWER_HARD,
  ),
  AnswerAction.showReminder => ReviewerAutoAdvanceFeedback(answerReminderText),
};
