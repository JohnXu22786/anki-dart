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
 * Source-derived whiteboard tool state cases for AnkiDroid's WhiteboardViewModel.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Whiteboard tool state', () {
    test('default brush color matches Android Color.BLACK signed Int', () {
      final state = WhiteboardToolState(brushes: const []);

      expect(state.brushColor, -16777216);
    });

    test(
      'selecting a brush orders state and save effects; invalid index is a no-op',
      () {
        final state = WhiteboardToolState(
          brushes: const [
            BrushInfo(color: 10, width: 2),
            BrushInfo(color: 20, width: 4),
          ],
          activeBrushIndex: 0,
          brushColor: 10,
          activeStrokeWidth: 2,
          isEraserActive: true,
          isDarkMode: true,
        );

        final effects = state.setActiveBrush(1);

        expect(effects.map((effect) => effect.runtimeType), [
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveBrushIndexEffect,
          SaveWhiteboardLastActiveBrushIndexEffect,
          PublishWhiteboardBrushColorEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.isEraserActive, isFalse);
        expect(state.activeBrushIndex, 1);
        expect(state.brushColor, 20);
        expect(state.activeStrokeWidth, 4);
        expect(
          (effects[2] as SaveWhiteboardLastActiveBrushIndexEffect).isDarkMode,
          isTrue,
        );

        expect(state.setActiveBrush(-1), isEmpty);
        expect(state.isEraserActive, isFalse);
        expect(state.activeBrushIndex, 1);
        expect(state.brushColor, 20);
        expect(state.activeStrokeWidth, 4);

        final invalidEraser = WhiteboardToolState(
          brushes: const [BrushInfo(color: 10, width: 2)],
          activeBrushIndex: 5,
          isEraserActive: true,
        );
        expect(invalidEraser.toggleEraser(displayWidth: 40), isEmpty);
        expect(invalidEraser.isEraserActive, isTrue);
      },
    );

    test(
      'eraser changes persist the selected mode width and follow source order',
      () {
        final state = WhiteboardToolState(
          brushes: const [BrushInfo(color: 10, width: 2)],
          inkEraserStrokeWidth: 12,
          strokeEraserStrokeWidth: 30,
        );

        expect(state.enableEraser(displayWidth: 12).map((e) => e.runtimeType), [
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.activeStrokeWidth, 12);

        expect(state.toggleEraser(displayWidth: 99).map((e) => e.runtimeType), [
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveBrushIndexEffect,
          SaveWhiteboardLastActiveBrushIndexEffect,
          PublishWhiteboardBrushColorEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.isEraserActive, isFalse);
        expect(state.toggleEraser(displayWidth: 12).map((e) => e.runtimeType), [
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.activeStrokeWidth, 12);

        final inkWidthEffects = state.setActiveStrokeWidth(17);
        expect(inkWidthEffects.map((e) => e.runtimeType), [
          PublishWhiteboardInkEraserStrokeWidthEffect,
          SaveWhiteboardInkEraserWidthEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.inkEraserStrokeWidth, 17);

        final modeEffects = state.setEraserMode(WhiteboardEraserMode.stroke);
        expect(modeEffects.map((e) => e.runtimeType), [
          PublishWhiteboardEraserModeEffect,
          SaveWhiteboardEraserModeEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.activeStrokeWidth, 30);

        final widthEffects = state.setActiveStrokeWidth(45.123456789);
        expect(widthEffects.map((e) => e.runtimeType), [
          PublishWhiteboardStrokeEraserStrokeWidthEffect,
          SaveWhiteboardStrokeEraserWidthEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.strokeEraserStrokeWidth, _float32(45.123456789));
        expect(state.inkEraserStrokeWidth, 17);
        expect(state.activeStrokeWidth, _float32(45.123456789));

        state.setEraserMode(WhiteboardEraserMode.ink);
        expect(
          state
              .setEraserMode(WhiteboardEraserMode.ink)
              .map((e) => e.runtimeType),
          [
            PublishWhiteboardEraserModeEffect,
            SaveWhiteboardEraserModeEffect,
            PublishWhiteboardActiveStrokeWidthEffect,
          ],
        );
        state.setActiveBrush(0);
        final brushWidth = state.activeStrokeWidth;
        final inactiveModeEffects = state.setEraserMode(
          WhiteboardEraserMode.stroke,
        );
        expect(inactiveModeEffects.map((e) => e.runtimeType), [
          PublishWhiteboardEraserModeEffect,
          SaveWhiteboardEraserModeEffect,
        ]);
        expect(state.activeStrokeWidth, brushWidth);
      },
    );

    test('brush width and color preserve invalid replaceAt save behavior', () {
      final state = WhiteboardToolState(
        brushes: const [BrushInfo(color: 10, width: 2)],
        activeBrushIndex: 0,
        brushColor: 10,
        isDarkMode: true,
      );

      final width = _float32(1.00000001);
      final validWidthEffects = state.setActiveStrokeWidth(1.00000001);
      expect(validWidthEffects.map((e) => e.runtimeType), [
        PublishWhiteboardBrushesEffect,
        SaveWhiteboardBrushesEffect,
        PublishWhiteboardActiveStrokeWidthEffect,
      ]);
      expect(state.brushes.single.width, width);
      expect(state.activeStrokeWidth, width);
      final validColorEffects = state.updateBrushColor(30);
      expect(validColorEffects.map((e) => e.runtimeType), [
        PublishWhiteboardBrushesEffect,
        SaveWhiteboardBrushesEffect,
        PublishWhiteboardBrushColorEffect,
      ]);
      expect(state.brushes.single.color, 30);

      final invalidIndexState = WhiteboardToolState(
        brushes: const [BrushInfo(color: 10, width: 2)],
        activeBrushIndex: 5,
        brushColor: 10,
        isDarkMode: true,
      );
      final beforeInvalidWidth = invalidIndexState.brushes;
      final invalidWidthEffects = invalidIndexState.setActiveStrokeWidth(7);
      expect(invalidWidthEffects.map((e) => e.runtimeType), [
        PublishWhiteboardBrushesEffect,
        SaveWhiteboardBrushesEffect,
        PublishWhiteboardActiveStrokeWidthEffect,
      ]);
      expect(invalidIndexState.brushes, beforeInvalidWidth);
      expect(invalidIndexState.brushes, isNot(same(beforeInvalidWidth)));
      expect(invalidIndexState.activeStrokeWidth, 7);

      final beforeInvalidColor = invalidIndexState.brushes;
      final colorEffects = invalidIndexState.updateBrushColor(99);
      expect(colorEffects.map((e) => e.runtimeType), [
        PublishWhiteboardBrushesEffect,
        SaveWhiteboardBrushesEffect,
        PublishWhiteboardBrushColorEffect,
      ]);
      expect(invalidIndexState.brushes, beforeInvalidColor);
      expect(invalidIndexState.brushes, isNot(same(beforeInvalidColor)));
      expect(invalidIndexState.brushColor, 99);
      expect(
        (colorEffects[1] as SaveWhiteboardBrushesEffect).isDarkMode,
        isTrue,
      );
    });

    test(
      'adding and removing brushes retain source save and selection decisions',
      () {
        final state = WhiteboardToolState(
          brushes: const [
            BrushInfo(color: 10, width: 2),
            BrushInfo(color: 20, width: 4),
          ],
          activeBrushIndex: 1,
          brushColor: 20,
          activeStrokeWidth: 4,
        );

        final addEffects = state.addBrush(30);
        expect(addEffects.map((e) => e.runtimeType), [
          PublishWhiteboardBrushesEffect,
          SaveWhiteboardBrushesEffect,
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveBrushIndexEffect,
          SaveWhiteboardLastActiveBrushIndexEffect,
          PublishWhiteboardBrushColorEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.brushes.last, const BrushInfo(color: 30, width: 10));
        expect(state.activeBrushIndex, 2);
        expect(state.activeStrokeWidth, 10);

        final removeEffects = state.removeBrush(2);
        expect(removeEffects.map((e) => e.runtimeType), [
          PublishWhiteboardBrushesEffect,
          SaveWhiteboardBrushesEffect,
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveBrushIndexEffect,
          SaveWhiteboardLastActiveBrushIndexEffect,
          PublishWhiteboardBrushColorEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.brushes, const [
          BrushInfo(color: 10, width: 2),
          BrushInfo(color: 20, width: 4),
        ]);
        expect(state.activeBrushIndex, 1);

        final beforeInvalid = state.brushes;
        final invalidRemoveEffects = state.removeBrush(99);
        expect(invalidRemoveEffects.map((e) => e.runtimeType), [
          PublishWhiteboardBrushesEffect,
          SaveWhiteboardBrushesEffect,
        ]);
        expect(state.brushes, beforeInvalid);
        expect(state.brushes, isNot(same(beforeInvalid)));

        final shiftEffects = state.removeBrush(0);
        expect(shiftEffects.map((e) => e.runtimeType), [
          PublishWhiteboardBrushesEffect,
          SaveWhiteboardBrushesEffect,
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveBrushIndexEffect,
          SaveWhiteboardLastActiveBrushIndexEffect,
          PublishWhiteboardBrushColorEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(state.activeBrushIndex, 0);
        expect(state.brushColor, 20);

        final negativeRemove = WhiteboardToolState(
          brushes: const [
            BrushInfo(color: 10, width: 2),
            BrushInfo(color: 20, width: 4),
          ],
          activeBrushIndex: 1,
          brushColor: 20,
          activeStrokeWidth: 4,
        );
        expect(negativeRemove.removeBrush(-1).map((e) => e.runtimeType), [
          PublishWhiteboardBrushesEffect,
          SaveWhiteboardBrushesEffect,
          PublishWhiteboardEraserActiveEffect,
          PublishWhiteboardActiveBrushIndexEffect,
          SaveWhiteboardLastActiveBrushIndexEffect,
          PublishWhiteboardBrushColorEffect,
          PublishWhiteboardActiveStrokeWidthEffect,
        ]);
        expect(negativeRemove.brushes, const [
          BrushInfo(color: 10, width: 2),
          BrushInfo(color: 20, width: 4),
        ]);
        expect(negativeRemove.activeBrushIndex, 0);
        expect(negativeRemove.brushColor, 10);

        final oneBrush = WhiteboardToolState(
          brushes: const [BrushInfo(color: 1, width: 10)],
        );
        expect(oneBrush.removeBrush(0), isEmpty);
      },
    );

    test(
      'preference toggles and setters preserve publication and persistence order',
      () {
        final state = WhiteboardToolState(
          brushes: const [BrushInfo(color: 10, width: 2)],
          isStylusOnlyMode: true,
          toolbarAlignment: WhiteboardToolbarAlignment.right,
          isToolbarShown: false,
        );

        expect(state.toggleStylusOnlyMode().map((e) => e.runtimeType), [
          PublishWhiteboardStylusOnlyModeEffect,
          SaveWhiteboardStylusOnlyModeEffect,
        ]);
        expect(state.isStylusOnlyMode, isFalse);
        expect(
          state
              .setToolbarAlignment(WhiteboardToolbarAlignment.left)
              .map((e) => e.runtimeType),
          [
            PublishWhiteboardToolbarAlignmentEffect,
            SaveWhiteboardToolbarAlignmentEffect,
          ],
        );
        expect(
          state.setToolbarAlignment(WhiteboardToolbarAlignment.left),
          isEmpty,
        );
        expect(state.setIsToolbarShown(true).map((e) => e.runtimeType), [
          PublishWhiteboardToolbarShownEffect,
          SaveWhiteboardToolbarShownEffect,
        ]);
        expect(state.setIsToolbarShown(true), isEmpty);
      },
    );
  });
}

double _float32(double value) => Float32List.fromList([value])[0];
