/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerViewModel.kt and ViewerAction.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'previewer_flag_effects.dart' show PreviewerFlag;
import 'reviewer_answer_action.dart' show AnswerButtons;

/// Reviewer menu and command actions in `ViewerAction` declaration order.
enum ReviewerViewAction {
  UNDO,
  REDO,
  FLAG_MENU,
  MARK,
  EDIT,
  BURY_MENU,
  SUSPEND_MENU,
  DELETE,
  TOGGLE_WHITEBOARD,
  BROWSE,
  STATISTICS,
  DECK_OPTIONS,
  CARD_INFO,
  PREVIOUS_CARD_INFO,
  ADD_NOTE,
  TAG,
  RESCHEDULE_NOTE,
  RESET_PROGRESS,
  TOGGLE_AUTO_ADVANCE,
  RECORD_VOICE,
  PLAY_MEDIA,
  USER_ACTION_1,
  USER_ACTION_2,
  USER_ACTION_3,
  USER_ACTION_4,
  USER_ACTION_5,
  USER_ACTION_6,
  USER_ACTION_7,
  USER_ACTION_8,
  USER_ACTION_9,
  BURY_NOTE,
  BURY_CARD,
  SUSPEND_NOTE,
  SUSPEND_CARD,
  UNSET_FLAG,
  FLAG_RED,
  FLAG_ORANGE,
  FLAG_GREEN,
  FLAG_BLUE,
  FLAG_PINK,
  FLAG_TURQUOISE,
  FLAG_PURPLE,
  SHOW_ANSWER,
  ANSWER_AGAIN,
  ANSWER_HARD,
  ANSWER_GOOD,
  ANSWER_EASY,
  TOGGLE_FLAG_RED,
  TOGGLE_FLAG_ORANGE,
  TOGGLE_FLAG_GREEN,
  TOGGLE_FLAG_BLUE,
  TOGGLE_FLAG_PINK,
  TOGGLE_FLAG_TURQUOISE,
  TOGGLE_FLAG_PURPLE,
  SHOW_HINT,
  SHOW_ALL_HINTS,
  REPLAY_VOICE,
  PAGE_UP,
  PAGE_DOWN,
  EXIT,
}

/// A host operation selected by [reviewerViewActionRoute].
enum ReviewerViewActionOperation {
  noOp,
  openAddNote,
  openCardInfo,
  openPreviousCardInfo,
  openDeckOptions,
  editNote,
  editNoteTags,
  deleteNote,
  toggleMark,
  redo,
  undo,
  setDueDate,
  resetProgress,
  toggleAutoAdvance,
  buryNote,
  buryCard,
  suspendNote,
  suspendCard,
  setFlag,
  toggleFlag,
  showAnswer,
  answerCard,
  evaluateJavaScript,
  toggleWhiteboard,
  toggleRecordVoice,
  replayVoice,
  pageUp,
  pageDown,
  finishReviewer,
  runUserAction,
  openStatistics,
  browseCards,
  replayMedia,
}

/// Typed data attached to an action route when the host operation needs it.
sealed class ReviewerViewActionArgument {
  const ReviewerViewActionArgument();
}

final class ReviewerViewActionFlagArgument extends ReviewerViewActionArgument {
  const ReviewerViewActionFlagArgument(this.flag);

  final PreviewerFlag flag;
}

final class ReviewerViewActionAnswerArgument
    extends ReviewerViewActionArgument {
  const ReviewerViewActionAnswerArgument(this.answer);

  final AnswerButtons answer;
}

final class ReviewerViewActionUserActionArgument
    extends ReviewerViewActionArgument {
  const ReviewerViewActionUserActionArgument(this.ordinal);

  final int ordinal;
}

final class ReviewerViewActionScriptArgument
    extends ReviewerViewActionArgument {
  const ReviewerViewActionScriptArgument(this.expression);

  final String expression;
}

final class ReviewerViewActionResultArgument
    extends ReviewerViewActionArgument {
  const ReviewerViewActionResultArgument(this.result);

  final int result;
}

/// One typed operation and its optional typed payload for the host to execute.
final class ReviewerViewActionRoute {
  const ReviewerViewActionRoute(this.operation, [this.argument]);

  final ReviewerViewActionOperation operation;
  final ReviewerViewActionArgument? argument;
}

/// The source's `AbstractFlashcardViewer.RESULT_DEFAULT` value.
const int reviewerViewActionDefaultResult = 50;

/// Projects the source `ReviewerViewModel.executeAction()` dispatch branch.
///
/// The caller supplies the current answer visibility for the source
/// `SHOW_ANSWER` guard. The host remains responsible for executing the chosen
/// operation, including coroutine/error handling, mutex serialization, IO,
/// collection changes, Flows, JavaScript, UI effects, and lifecycle.
ReviewerViewActionRoute reviewerViewActionRoute(
  ReviewerViewAction action, {
  required bool showingAnswer,
}) => switch (action) {
  ReviewerViewAction.UNDO => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.undo,
  ),
  ReviewerViewAction.REDO => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.redo,
  ),
  ReviewerViewAction.FLAG_MENU => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.noOp,
  ),
  ReviewerViewAction.MARK => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleMark,
  ),
  ReviewerViewAction.EDIT => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.editNote,
  ),
  ReviewerViewAction.BURY_MENU || ReviewerViewAction.BURY_CARD =>
    const ReviewerViewActionRoute(ReviewerViewActionOperation.buryCard),
  ReviewerViewAction.SUSPEND_MENU || ReviewerViewAction.SUSPEND_CARD =>
    const ReviewerViewActionRoute(ReviewerViewActionOperation.suspendCard),
  ReviewerViewAction.DELETE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.deleteNote,
  ),
  ReviewerViewAction.TOGGLE_WHITEBOARD => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleWhiteboard,
  ),
  ReviewerViewAction.BROWSE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.browseCards,
  ),
  ReviewerViewAction.STATISTICS => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.openStatistics,
  ),
  ReviewerViewAction.DECK_OPTIONS => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.openDeckOptions,
  ),
  ReviewerViewAction.CARD_INFO => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.openCardInfo,
  ),
  ReviewerViewAction.PREVIOUS_CARD_INFO => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.openPreviousCardInfo,
  ),
  ReviewerViewAction.ADD_NOTE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.openAddNote,
  ),
  ReviewerViewAction.TAG => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.editNoteTags,
  ),
  ReviewerViewAction.RESCHEDULE_NOTE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setDueDate,
  ),
  ReviewerViewAction.RESET_PROGRESS => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.resetProgress,
  ),
  ReviewerViewAction.TOGGLE_AUTO_ADVANCE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleAutoAdvance,
  ),
  ReviewerViewAction.RECORD_VOICE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleRecordVoice,
  ),
  ReviewerViewAction.PLAY_MEDIA => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.replayMedia,
  ),
  ReviewerViewAction.USER_ACTION_1 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(1),
  ),
  ReviewerViewAction.USER_ACTION_2 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(2),
  ),
  ReviewerViewAction.USER_ACTION_3 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(3),
  ),
  ReviewerViewAction.USER_ACTION_4 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(4),
  ),
  ReviewerViewAction.USER_ACTION_5 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(5),
  ),
  ReviewerViewAction.USER_ACTION_6 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(6),
  ),
  ReviewerViewAction.USER_ACTION_7 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(7),
  ),
  ReviewerViewAction.USER_ACTION_8 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(8),
  ),
  ReviewerViewAction.USER_ACTION_9 => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.runUserAction,
    ReviewerViewActionUserActionArgument(9),
  ),
  ReviewerViewAction.BURY_NOTE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.buryNote,
  ),
  ReviewerViewAction.SUSPEND_NOTE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.suspendNote,
  ),
  ReviewerViewAction.UNSET_FLAG => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.none),
  ),
  ReviewerViewAction.FLAG_RED => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.red),
  ),
  ReviewerViewAction.FLAG_ORANGE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.orange),
  ),
  ReviewerViewAction.FLAG_GREEN => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.green),
  ),
  ReviewerViewAction.FLAG_BLUE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.blue),
  ),
  ReviewerViewAction.FLAG_PINK => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.pink),
  ),
  ReviewerViewAction.FLAG_TURQUOISE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.turquoise),
  ),
  ReviewerViewAction.FLAG_PURPLE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.setFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.purple),
  ),
  ReviewerViewAction.SHOW_ANSWER => ReviewerViewActionRoute(
    showingAnswer
        ? ReviewerViewActionOperation.noOp
        : ReviewerViewActionOperation.showAnswer,
  ),
  ReviewerViewAction.ANSWER_AGAIN => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.answerCard,
    ReviewerViewActionAnswerArgument(AnswerButtons.again),
  ),
  ReviewerViewAction.ANSWER_HARD => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.answerCard,
    ReviewerViewActionAnswerArgument(AnswerButtons.hard),
  ),
  ReviewerViewAction.ANSWER_GOOD => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.answerCard,
    ReviewerViewActionAnswerArgument(AnswerButtons.good),
  ),
  ReviewerViewAction.ANSWER_EASY => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.answerCard,
    ReviewerViewActionAnswerArgument(AnswerButtons.easy),
  ),
  ReviewerViewAction.TOGGLE_FLAG_RED => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.red),
  ),
  ReviewerViewAction.TOGGLE_FLAG_ORANGE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.orange),
  ),
  ReviewerViewAction.TOGGLE_FLAG_GREEN => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.green),
  ),
  ReviewerViewAction.TOGGLE_FLAG_BLUE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.blue),
  ),
  ReviewerViewAction.TOGGLE_FLAG_PINK => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.pink),
  ),
  ReviewerViewAction.TOGGLE_FLAG_TURQUOISE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.turquoise),
  ),
  ReviewerViewAction.TOGGLE_FLAG_PURPLE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.toggleFlag,
    ReviewerViewActionFlagArgument(PreviewerFlag.purple),
  ),
  ReviewerViewAction.SHOW_HINT => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.evaluateJavaScript,
    ReviewerViewActionScriptArgument('ankidroid.showHint()'),
  ),
  ReviewerViewAction.SHOW_ALL_HINTS => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.evaluateJavaScript,
    ReviewerViewActionScriptArgument('ankidroid.showAllHints()'),
  ),
  ReviewerViewAction.REPLAY_VOICE => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.replayVoice,
  ),
  ReviewerViewAction.PAGE_UP => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.pageUp,
  ),
  ReviewerViewAction.PAGE_DOWN => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.pageDown,
  ),
  ReviewerViewAction.EXIT => const ReviewerViewActionRoute(
    ReviewerViewActionOperation.finishReviewer,
    ReviewerViewActionResultArgument(reviewerViewActionDefaultResult),
  ),
};
