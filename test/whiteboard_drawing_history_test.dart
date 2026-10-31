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
 * Source-derived drawing history cases for AnkiDroid's WhiteboardViewModel.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Whiteboard drawing history', () {
    test('completed action publishes paths, undo, then redo reset', () {
      final existing = _action('existing');
      final first = _action('first');
      final previousRedo = WhiteboardAddAction<_PathToken>(_action('redo'));
      final history = WhiteboardDrawingHistory<_PathToken>(
        paths: [existing],
        undoStack: [WhiteboardClearAction<_PathToken>(const [])],
        redoStack: [previousRedo],
      );

      final effects = history.addCompletedAction(first);

      expect(effects.map((effect) => effect.runtimeType), [
        PublishWhiteboardPathsEffect<_PathToken>,
        PublishWhiteboardUndoStackEffect<_PathToken>,
        PublishWhiteboardRedoStackEffect<_PathToken>,
      ]);
      expect(history.paths, [existing, first]);
      expect(
        history.undoStack.last,
        isA<WhiteboardAddAction<_PathToken>>().having(
          (action) => action.added,
          'added',
          same(first),
        ),
      );
      expect(history.redoStack, isEmpty);
      expect(
        (effects[0] as PublishWhiteboardPathsEffect<_PathToken>).paths.last,
        same(first),
      );
    });

    test('empty clear and empty undo or redo are no-ops', () {
      final action = _action('kept');
      final emptyCanvas = WhiteboardDrawingHistory<_PathToken>(
        redoStack: [WhiteboardAddAction(_action('redo'))],
      );

      expect(emptyCanvas.clearCanvas(), isEmpty);
      expect(emptyCanvas.paths, isEmpty);
      expect(emptyCanvas.undoStack, isEmpty);
      expect(emptyCanvas.redoStack, hasLength(1));

      final history = WhiteboardDrawingHistory<_PathToken>(paths: [action]);
      expect(history.undo(), isEmpty);
      expect(history.redo(), isEmpty);
      expect(history.paths, [action]);
      expect(history.undoStack, isEmpty);
      expect(history.redoStack, isEmpty);
    });

    test('undo add removes only the identical action instance', () {
      final target = _action('same');
      final equalLooking = _action('same');
      final addAction = WhiteboardAddAction(target);
      final history = WhiteboardDrawingHistory<_PathToken>(
        paths: [target, equalLooking],
        undoStack: [addAction],
      );

      final effects = history.undo();

      expect(effects.map((effect) => effect.runtimeType), [
        PublishWhiteboardUndoStackEffect<_PathToken>,
        PublishWhiteboardRedoStackEffect<_PathToken>,
        PublishWhiteboardPathsEffect<_PathToken>,
      ]);
      expect(history.paths, [equalLooking]);
      expect(
        history.redoStack.single,
        isA<WhiteboardAddAction<_PathToken>>().having(
          (action) => action.added,
          'added',
          same(target),
        ),
      );
      expect(identical(history.redoStack.single, addAction), isTrue);

      final redoEffects = history.redo();
      expect(redoEffects.map((effect) => effect.runtimeType), [
        PublishWhiteboardRedoStackEffect<_PathToken>,
        PublishWhiteboardUndoStackEffect<_PathToken>,
        PublishWhiteboardPathsEffect<_PathToken>,
      ]);
      expect(history.paths, hasLength(2));
      expect(identical(history.paths[0], equalLooking), isTrue);
      expect(identical(history.paths[1], target), isTrue);
    });

    test('undo remove sorts indexes and clamps each insertion', () {
      final atZero = _action('zero');
      final atTwo = _action('two');
      final history = WhiteboardDrawingHistory<_PathToken>(
        paths: [_action('remaining')],
        undoStack: [
          WhiteboardRemoveAction<_PathToken>([
            WhiteboardIndexedDrawingAction(8, atTwo),
            WhiteboardIndexedDrawingAction(0, atZero),
          ]),
        ],
      );

      history.undo();

      expect(history.paths.map((action) => action.path.label), [
        'zero',
        'remaining',
        'two',
      ]);
    });

    test(
      'clear history preserves order and redo uses source equality rules',
      () {
        final path = _PathToken('opaque');
        final first = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: 2.0,
        );
        final valueEqual = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: 2.0,
        );
        final different = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: 3.0,
        );
        final history = WhiteboardDrawingHistory<_PathToken>(
          paths: [first, valueEqual],
        );

        final clearEffects = history.clearCanvas();
        expect(history.paths, isEmpty);
        final clearAction =
            history.undoStack.single as WhiteboardClearAction<_PathToken>;
        expect(clearAction.cleared, hasLength(2));
        expect(identical(clearAction.cleared[0], first), isTrue);
        expect(identical(clearAction.cleared[1], valueEqual), isTrue);
        expect(clearEffects.map((effect) => effect.runtimeType), [
          PublishWhiteboardUndoStackEffect<_PathToken>,
          PublishWhiteboardRedoStackEffect<_PathToken>,
          PublishWhiteboardPathsEffect<_PathToken>,
        ]);

        history.undo();
        expect(history.paths, [first, valueEqual]);
        history.redo();
        expect(history.paths, isEmpty);

        final redoClear = WhiteboardDrawingHistory<_PathToken>(
          paths: [first, different],
          redoStack: [
            WhiteboardClearAction([first]),
          ],
        );
        redoClear.redo();
        expect(redoClear.paths, isEmpty);

        final redoRemove = WhiteboardDrawingHistory<_PathToken>(
          paths: [first, valueEqual, different],
          redoStack: [
            WhiteboardRemoveAction<_PathToken>([
              WhiteboardIndexedDrawingAction(0, first),
            ]),
          ],
        );
        redoRemove.redo();
        expect(redoRemove.paths, [different]);

        final samePathValue = WhiteboardDrawingAction(
          path: _PathToken('opaque'),
          color: 0xff000000,
          strokeWidth: 2.0,
        );
        final hostEquality = WhiteboardDrawingHistory<_PathToken>(
          paths: [first, samePathValue],
          redoStack: [
            WhiteboardRemoveAction<_PathToken>([
              WhiteboardIndexedDrawingAction(0, first),
            ]),
          ],
          drawingActionEquals: (left, right) =>
              left.path.label == right.path.label &&
              left.color == right.color &&
              left.strokeWidth == right.strokeWidth &&
              left.isEraser == right.isEraser,
        );
        hostEquality.redo();
        expect(hostEquality.paths, isEmpty);

        final nanAction = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: double.nan,
        );
        final equalNanAction = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: double.nan,
        );
        final nanEquality = WhiteboardDrawingHistory<_PathToken>(
          paths: [nanAction, equalNanAction],
          redoStack: [
            WhiteboardRemoveAction<_PathToken>([
              WhiteboardIndexedDrawingAction(0, nanAction),
            ]),
          ],
        );
        nanEquality.redo();
        expect(nanEquality.paths, isEmpty);

        final positiveZero = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: 0.0,
        );
        final negativeZero = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: -0.0,
        );
        final signedZeroEquality = WhiteboardDrawingHistory<_PathToken>(
          paths: [positiveZero, negativeZero],
          redoStack: [
            WhiteboardRemoveAction<_PathToken>([
              WhiteboardIndexedDrawingAction(0, positiveZero),
            ]),
          ],
        );
        signedZeroEquality.redo();
        expect(signedZeroEquality.paths, [negativeZero]);

        final exactFloatWidth = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: 1.0,
        );
        final sameFloatWidth = WhiteboardDrawingAction(
          path: path,
          color: 0xff000000,
          strokeWidth: 1.00000001,
        );
        final float32Equality = WhiteboardDrawingHistory<_PathToken>(
          paths: [exactFloatWidth, sameFloatWidth],
          redoStack: [
            WhiteboardRemoveAction<_PathToken>([
              WhiteboardIndexedDrawingAction(0, exactFloatWidth),
            ]),
          ],
        );
        float32Equality.redo();
        expect(float32Equality.paths, isEmpty);
      },
    );

    test(
      'reset clears canvas history and both stacks even on empty canvas',
      () {
        final path = _action('canvas');
        final history = WhiteboardDrawingHistory<_PathToken>(
          paths: [path],
          redoStack: [WhiteboardAddAction(_action('redo'))],
        );

        final effects = history.reset();

        expect(effects.map((effect) => effect.runtimeType), [
          PublishWhiteboardUndoStackEffect<_PathToken>,
          PublishWhiteboardRedoStackEffect<_PathToken>,
          PublishWhiteboardPathsEffect<_PathToken>,
          PublishWhiteboardUndoStackEffect<_PathToken>,
          PublishWhiteboardRedoStackEffect<_PathToken>,
        ]);
        expect(history.paths, isEmpty);
        expect(history.undoStack, isEmpty);
        expect(history.redoStack, isEmpty);

        final withStacks = WhiteboardDrawingHistory<_PathToken>(
          undoStack: [WhiteboardAddAction(_action('undo'))],
          redoStack: [WhiteboardAddAction(_action('redo'))],
        );
        withStacks.reset();
        expect(withStacks.paths, isEmpty);
        expect(withStacks.undoStack, isEmpty);
        expect(withStacks.redoStack, isEmpty);
      },
    );
  });
}

WhiteboardDrawingAction<_PathToken> _action(String label) =>
    WhiteboardDrawingAction(
      path: _PathToken(label),
      color: 0xff000000,
      strokeWidth: 2.0,
    );

final class _PathToken {
  const _PathToken(this.label);

  final String label;
}
