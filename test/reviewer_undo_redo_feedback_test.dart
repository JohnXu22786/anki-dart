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
 * Source-derived Reviewer undo/redo feedback choice cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer undo/redo feedback message', () {
    test(
      'exposes status and actions from the shared Reviewer journal',
      () async {
        var status = const UndoStatus(
          undo: 'Suspend Cards',
          redo: null,
          lastStep: 3,
        );
        final actions = <String>[];
        final reviewer = ReviewerUndoRedoActions(
          readStatus: () => status,
          undo: () async {
            actions.add('undo');
            status = const UndoStatus(
              undo: null,
              redo: 'Suspend Cards',
              lastStep: 4,
            );
            return 'Suspend Cards';
          },
          redo: () async {
            actions.add('redo');
            return 'Suspend Cards';
          },
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (operation) => 'undid $operation',
          redoMessage: (operation) => 'redid $operation',
        );

        expect(reviewer.canUndo, isTrue);
        expect(reviewer.undoLabel, 'Suspend Cards');
        expect(await reviewer.undoWithFeedback(), 'undid Suspend Cards');
        expect(reviewer.canUndo, isFalse);
        expect(reviewer.canRedo, isTrue);
        expect(reviewer.redoLabel, 'Suspend Cards');
        expect(actions, ['undo']);
      },
    );

    test(
      'runs the selected Reviewer action and localizes its operation',
      () async {
        final calls = <String>[];
        final message = await performReviewerUndoRedoAction(
          isUndo: false,
          undo: () async {
            calls.add('undo');
            return 'wrong action';
          },
          redo: () async {
            calls.add('redo');
            return 'Suspend Cards';
          },
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (operation) => 'undid $operation',
          redoMessage: (operation) => 'redid $operation',
        );

        expect(message, 'redid Suspend Cards');
        expect(calls, ['redo']);
      },
    );

    test('uses host nothing-to-undo message for an empty undo operation', () {
      final calls = <String>[];
      expect(
        reviewerUndoRedoFeedbackMessage(
          isUndo: true,
          operation: '',
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (operation) {
            calls.add('undo:$operation');
            return 'undo operation';
          },
          redoMessage: (operation) {
            calls.add('redo:$operation');
            return 'redo operation';
          },
        ),
        'nothing to undo',
      );
      expect(calls, isEmpty);
    });

    test('uses host nothing-to-redo message for an empty redo operation', () {
      final calls = <String>[];
      expect(
        reviewerUndoRedoFeedbackMessage(
          isUndo: false,
          operation: '',
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (operation) {
            calls.add('undo:$operation');
            return 'undo operation';
          },
          redoMessage: (operation) {
            calls.add('redo:$operation');
            return 'redo operation';
          },
        ),
        'nothing to redo',
      );
      expect(calls, isEmpty);
    });

    test('uses undo message callback for a nonempty undo operation', () {
      final calls = <String>[];
      expect(
        reviewerUndoRedoFeedbackMessage(
          isUndo: true,
          operation: 'undo operation',
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (operation) {
            calls.add('undo:$operation');
            return 'undid $operation';
          },
          redoMessage: (operation) {
            calls.add('redo:$operation');
            return 'redid $operation';
          },
        ),
        'undid undo operation',
      );
      expect(calls, ['undo:undo operation']);
    });

    test('uses redo message callback for a nonempty redo operation', () {
      final calls = <String>[];
      expect(
        reviewerUndoRedoFeedbackMessage(
          isUndo: false,
          operation: 'redo operation',
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (operation) {
            calls.add('undo:$operation');
            return 'undid $operation';
          },
          redoMessage: (operation) {
            calls.add('redo:$operation');
            return 'redid $operation';
          },
        ),
        'redid redo operation',
      );
      expect(calls, ['redo:redo operation']);
    });

    test('passes whitespace-only operation unchanged as nonempty', () {
      const operation = ' \t ';
      final calls = <String>[];
      expect(
        reviewerUndoRedoFeedbackMessage(
          isUndo: true,
          operation: operation,
          nothingToUndoMessage: 'nothing to undo',
          nothingToRedoMessage: 'nothing to redo',
          undoMessage: (value) {
            calls.add(value);
            return 'undid [$value]';
          },
          redoMessage: (_) => 'redo operation',
        ),
        'undid [ \t ]',
      );
      expect(calls, [operation]);
    });
  });
}
