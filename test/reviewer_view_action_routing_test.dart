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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewerViewAction routing', () {
    test('enumerates every ViewerAction in source declaration order', () {
      expect(ReviewerViewAction.values.map((action) => action.name), [
        'UNDO',
        'REDO',
        'FLAG_MENU',
        'MARK',
        'EDIT',
        'BURY_MENU',
        'SUSPEND_MENU',
        'DELETE',
        'TOGGLE_WHITEBOARD',
        'BROWSE',
        'STATISTICS',
        'DECK_OPTIONS',
        'CARD_INFO',
        'PREVIOUS_CARD_INFO',
        'ADD_NOTE',
        'TAG',
        'RESCHEDULE_NOTE',
        'RESET_PROGRESS',
        'TOGGLE_AUTO_ADVANCE',
        'RECORD_VOICE',
        'PLAY_MEDIA',
        'USER_ACTION_1',
        'USER_ACTION_2',
        'USER_ACTION_3',
        'USER_ACTION_4',
        'USER_ACTION_5',
        'USER_ACTION_6',
        'USER_ACTION_7',
        'USER_ACTION_8',
        'USER_ACTION_9',
        'BURY_NOTE',
        'BURY_CARD',
        'SUSPEND_NOTE',
        'SUSPEND_CARD',
        'UNSET_FLAG',
        'FLAG_RED',
        'FLAG_ORANGE',
        'FLAG_GREEN',
        'FLAG_BLUE',
        'FLAG_PINK',
        'FLAG_TURQUOISE',
        'FLAG_PURPLE',
        'SHOW_ANSWER',
        'ANSWER_AGAIN',
        'ANSWER_HARD',
        'ANSWER_GOOD',
        'ANSWER_EASY',
        'TOGGLE_FLAG_RED',
        'TOGGLE_FLAG_ORANGE',
        'TOGGLE_FLAG_GREEN',
        'TOGGLE_FLAG_BLUE',
        'TOGGLE_FLAG_PINK',
        'TOGGLE_FLAG_TURQUOISE',
        'TOGGLE_FLAG_PURPLE',
        'SHOW_HINT',
        'SHOW_ALL_HINTS',
        'REPLAY_VOICE',
        'PAGE_UP',
        'PAGE_DOWN',
        'EXIT',
      ]);
    });

    test('projects every action to its exact typed operation and argument', () {
      const expected =
          <ReviewerViewAction, (ReviewerViewActionOperation, Object?)>{
            ReviewerViewAction.UNDO: (ReviewerViewActionOperation.undo, null),
            ReviewerViewAction.REDO: (ReviewerViewActionOperation.redo, null),
            ReviewerViewAction.FLAG_MENU: (
              ReviewerViewActionOperation.noOp,
              null,
            ),
            ReviewerViewAction.MARK: (
              ReviewerViewActionOperation.toggleMark,
              null,
            ),
            ReviewerViewAction.EDIT: (
              ReviewerViewActionOperation.editNote,
              null,
            ),
            ReviewerViewAction.BURY_MENU: (
              ReviewerViewActionOperation.buryCard,
              null,
            ),
            ReviewerViewAction.SUSPEND_MENU: (
              ReviewerViewActionOperation.suspendCard,
              null,
            ),
            ReviewerViewAction.DELETE: (
              ReviewerViewActionOperation.deleteNote,
              null,
            ),
            ReviewerViewAction.TOGGLE_WHITEBOARD: (
              ReviewerViewActionOperation.toggleWhiteboard,
              null,
            ),
            ReviewerViewAction.BROWSE: (
              ReviewerViewActionOperation.browseCards,
              null,
            ),
            ReviewerViewAction.STATISTICS: (
              ReviewerViewActionOperation.openStatistics,
              null,
            ),
            ReviewerViewAction.DECK_OPTIONS: (
              ReviewerViewActionOperation.openDeckOptions,
              null,
            ),
            ReviewerViewAction.CARD_INFO: (
              ReviewerViewActionOperation.openCardInfo,
              null,
            ),
            ReviewerViewAction.PREVIOUS_CARD_INFO: (
              ReviewerViewActionOperation.openPreviousCardInfo,
              null,
            ),
            ReviewerViewAction.ADD_NOTE: (
              ReviewerViewActionOperation.openAddNote,
              null,
            ),
            ReviewerViewAction.TAG: (
              ReviewerViewActionOperation.editNoteTags,
              null,
            ),
            ReviewerViewAction.RESCHEDULE_NOTE: (
              ReviewerViewActionOperation.setDueDate,
              null,
            ),
            ReviewerViewAction.RESET_PROGRESS: (
              ReviewerViewActionOperation.resetProgress,
              null,
            ),
            ReviewerViewAction.TOGGLE_AUTO_ADVANCE: (
              ReviewerViewActionOperation.toggleAutoAdvance,
              null,
            ),
            ReviewerViewAction.RECORD_VOICE: (
              ReviewerViewActionOperation.toggleRecordVoice,
              null,
            ),
            ReviewerViewAction.PLAY_MEDIA: (
              ReviewerViewActionOperation.replayMedia,
              null,
            ),
            ReviewerViewAction.USER_ACTION_1: (
              ReviewerViewActionOperation.runUserAction,
              1,
            ),
            ReviewerViewAction.USER_ACTION_2: (
              ReviewerViewActionOperation.runUserAction,
              2,
            ),
            ReviewerViewAction.USER_ACTION_3: (
              ReviewerViewActionOperation.runUserAction,
              3,
            ),
            ReviewerViewAction.USER_ACTION_4: (
              ReviewerViewActionOperation.runUserAction,
              4,
            ),
            ReviewerViewAction.USER_ACTION_5: (
              ReviewerViewActionOperation.runUserAction,
              5,
            ),
            ReviewerViewAction.USER_ACTION_6: (
              ReviewerViewActionOperation.runUserAction,
              6,
            ),
            ReviewerViewAction.USER_ACTION_7: (
              ReviewerViewActionOperation.runUserAction,
              7,
            ),
            ReviewerViewAction.USER_ACTION_8: (
              ReviewerViewActionOperation.runUserAction,
              8,
            ),
            ReviewerViewAction.USER_ACTION_9: (
              ReviewerViewActionOperation.runUserAction,
              9,
            ),
            ReviewerViewAction.BURY_NOTE: (
              ReviewerViewActionOperation.buryNote,
              null,
            ),
            ReviewerViewAction.BURY_CARD: (
              ReviewerViewActionOperation.buryCard,
              null,
            ),
            ReviewerViewAction.SUSPEND_NOTE: (
              ReviewerViewActionOperation.suspendNote,
              null,
            ),
            ReviewerViewAction.SUSPEND_CARD: (
              ReviewerViewActionOperation.suspendCard,
              null,
            ),
            ReviewerViewAction.UNSET_FLAG: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.none,
            ),
            ReviewerViewAction.FLAG_RED: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.red,
            ),
            ReviewerViewAction.FLAG_ORANGE: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.orange,
            ),
            ReviewerViewAction.FLAG_GREEN: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.green,
            ),
            ReviewerViewAction.FLAG_BLUE: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.blue,
            ),
            ReviewerViewAction.FLAG_PINK: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.pink,
            ),
            ReviewerViewAction.FLAG_TURQUOISE: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.turquoise,
            ),
            ReviewerViewAction.FLAG_PURPLE: (
              ReviewerViewActionOperation.setFlag,
              PreviewerFlag.purple,
            ),
            ReviewerViewAction.SHOW_ANSWER: (
              ReviewerViewActionOperation.showAnswer,
              null,
            ),
            ReviewerViewAction.ANSWER_AGAIN: (
              ReviewerViewActionOperation.answerCard,
              AnswerButtons.again,
            ),
            ReviewerViewAction.ANSWER_HARD: (
              ReviewerViewActionOperation.answerCard,
              AnswerButtons.hard,
            ),
            ReviewerViewAction.ANSWER_GOOD: (
              ReviewerViewActionOperation.answerCard,
              AnswerButtons.good,
            ),
            ReviewerViewAction.ANSWER_EASY: (
              ReviewerViewActionOperation.answerCard,
              AnswerButtons.easy,
            ),
            ReviewerViewAction.TOGGLE_FLAG_RED: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.red,
            ),
            ReviewerViewAction.TOGGLE_FLAG_ORANGE: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.orange,
            ),
            ReviewerViewAction.TOGGLE_FLAG_GREEN: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.green,
            ),
            ReviewerViewAction.TOGGLE_FLAG_BLUE: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.blue,
            ),
            ReviewerViewAction.TOGGLE_FLAG_PINK: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.pink,
            ),
            ReviewerViewAction.TOGGLE_FLAG_TURQUOISE: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.turquoise,
            ),
            ReviewerViewAction.TOGGLE_FLAG_PURPLE: (
              ReviewerViewActionOperation.toggleFlag,
              PreviewerFlag.purple,
            ),
            ReviewerViewAction.SHOW_HINT: (
              ReviewerViewActionOperation.evaluateJavaScript,
              'ankidroid.showHint()',
            ),
            ReviewerViewAction.SHOW_ALL_HINTS: (
              ReviewerViewActionOperation.evaluateJavaScript,
              'ankidroid.showAllHints()',
            ),
            ReviewerViewAction.REPLAY_VOICE: (
              ReviewerViewActionOperation.replayVoice,
              null,
            ),
            ReviewerViewAction.PAGE_UP: (
              ReviewerViewActionOperation.pageUp,
              null,
            ),
            ReviewerViewAction.PAGE_DOWN: (
              ReviewerViewActionOperation.pageDown,
              null,
            ),
            ReviewerViewAction.EXIT: (
              ReviewerViewActionOperation.finishReviewer,
              50,
            ),
          };

      expect(expected.keys.toSet(), ReviewerViewAction.values.toSet());
      for (final entry in expected.entries) {
        final route = reviewerViewActionRoute(entry.key, showingAnswer: false);
        expect(route.operation, entry.value.$1, reason: entry.key.name);
        expect(
          _argumentValue(route.argument),
          entry.value.$2,
          reason: entry.key.name,
        );
      }
    });

    test('SHOW_ANSWER is a no-op once the answer is already showing', () {
      final route = reviewerViewActionRoute(
        ReviewerViewAction.SHOW_ANSWER,
        showingAnswer: true,
      );
      expect(route.operation, ReviewerViewActionOperation.noOp);
      expect(route.argument, isNull);
    });
  });
}

Object? _argumentValue(ReviewerViewActionArgument? argument) =>
    switch (argument) {
      null => null,
      ReviewerViewActionFlagArgument(:final flag) => flag,
      ReviewerViewActionAnswerArgument(:final answer) => answer,
      ReviewerViewActionUserActionArgument(:final ordinal) => ordinal,
      ReviewerViewActionScriptArgument(:final expression) => expression,
      ReviewerViewActionResultArgument(:final result) => result,
    };
