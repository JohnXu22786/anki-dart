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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserRowActivation', () {
    const selection = BrowserRowSelection(
      rowId: BrowserRowId(20),
      topOffset: 4,
    );

    test('normal phone and fragmented taps request the matching editor route',
        () {
      final phonePlan = planBrowserRowActivation(
        selectedRows: const [BrowserRowId(10)],
        selection: selection,
        isInMultiSelectMode: false,
        isFragmented: false,
      );

      expect(
        phonePlan.effects.map((effect) => effect.kind),
        [
          BrowserRowActivationEffectKind.endMultiSelectModeForEditor,
          BrowserRowActivationEffectKind.launchEditorActivityIfAvailable,
        ],
      );
      expect(phonePlan.effects.first.selectionTransition, isNull);
      expect(phonePlan.effects.last.rowId, selection.rowId);

      final tabletPlan = planBrowserRowActivation(
        selectedRows: const [],
        selection: selection,
        isInMultiSelectMode: false,
        isFragmented: true,
      );

      expect(
        tabletPlan.effects.map((effect) => effect.kind),
        [
          BrowserRowActivationEffectKind.setPaneRow,
          BrowserRowActivationEffectKind.loadEditorInPaneIfAvailable,
        ],
      );
      expect(tabletPlan.effects.first.rowId, selection.rowId);
      expect(tabletPlan.effects.last.rowId, selection.rowId);
    });

    test('multi-select add and phone deselect only toggle selection', () {
      final beforeAdd = [const BrowserRowId(10)];
      final addPlan = planBrowserRowActivation(
        selectedRows: beforeAdd,
        selection: selection,
        isInMultiSelectMode: true,
        isFragmented: true,
      );

      expect(addPlan.effects, hasLength(1));
      expect(
        addPlan.effects.single.kind,
        BrowserRowActivationEffectKind.toggleSelection,
      );
      expect(
        addPlan.effects.single.selectionTransition!.selectedRows,
        [const BrowserRowId(10), selection.rowId],
      );
      expect(beforeAdd, [const BrowserRowId(10)]);

      final deselectPlan = planBrowserRowActivation(
        selectedRows: [const BrowserRowId(10), selection.rowId],
        selection: selection,
        isInMultiSelectMode: true,
        isFragmented: false,
      );

      expect(deselectPlan.effects, hasLength(1));
      expect(
        deselectPlan.effects.single.kind,
        BrowserRowActivationEffectKind.toggleSelection,
      );
      expect(
        deselectPlan.effects.single.selectionTransition!.selectedRows,
        [const BrowserRowId(10)],
      );
    });

    test('fragmented multi-select deselection reloads pane after toggle', () {
      final before = [const BrowserRowId(10), selection.rowId];
      final plan = planBrowserRowActivation(
        selectedRows: before,
        selection: selection,
        isInMultiSelectMode: true,
        isFragmented: true,
      );

      expect(
        plan.effects.map((effect) => effect.kind),
        [
          BrowserRowActivationEffectKind.toggleSelection,
          BrowserRowActivationEffectKind.setPaneRow,
          BrowserRowActivationEffectKind.loadEditorInPaneIfAvailable,
        ],
      );
      expect(
        plan.effects.first.selectionTransition!.selectedRows,
        [const BrowserRowId(10)],
      );
      expect(plan.effects[1].rowId, selection.rowId);
      expect(plan.effects[2].rowId, selection.rowId);
      expect(before, [const BrowserRowId(10), selection.rowId]);
    });
  });
}
