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
 * Source-derived from AnkiDroid 2.25.3 BrowserColumnSelectionFragment.kt and
 * CardBrowserViewModel.kt; the pinned test tree has no save-handler assertion.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser column selection save plan', () {
    test('unchanged selection dismisses but still supplies an update request',
        () {
      final initial = [BrowserColumn.question, BrowserColumn.tags];
      final selected = [BrowserColumn.question, BrowserColumn.tags];
      final plan = planBrowserColumnSelectionSave(
        initialSelectedColumns: initial,
        selectedColumns: selected,
        mode: BrowserColumnMode.cards,
      );

      expect(plan.hasUnsavedChanges, isFalse);
      expect(plan.effectsBeforeUpdate,
          [BrowserColumnSelectionSaveEffect.dismissDialog]);
      expect(plan.updateRequest.columns, selected);
      expect(plan.updateRequest.mode, BrowserColumnMode.cards);

      final outcome = plan.complete(false);
      expect(outcome.effects,
          [BrowserColumnSelectionSaveEffect.showNoColumnsMessage]);
      expect(outcome.returnedValue, isFalse);
    });

    test('unchanged selection still completes after a successful update', () {
      final plan = planBrowserColumnSelectionSave(
        initialSelectedColumns: const [BrowserColumn.question],
        selectedColumns: const [BrowserColumn.question],
        mode: BrowserColumnMode.notes,
      );

      expect(plan.effectsBeforeUpdate,
          [BrowserColumnSelectionSaveEffect.dismissDialog]);
      final outcome = plan.complete(true);

      expect(outcome.effects, [BrowserColumnSelectionSaveEffect.dismissDialog]);
      expect(outcome.returnedValue, isTrue);
    });

    test('changed columns update first and dismiss after a successful update',
        () {
      final plan = planBrowserColumnSelectionSave(
        initialSelectedColumns: const [BrowserColumn.question],
        selectedColumns: [BrowserColumn.tags, BrowserColumn.deck],
        mode: BrowserColumnMode.notes,
      );

      expect(plan.hasUnsavedChanges, isTrue);
      expect(plan.effectsBeforeUpdate, isEmpty);
      expect(
          plan.updateRequest.columns, [BrowserColumn.tags, BrowserColumn.deck]);
      expect(plan.updateRequest.mode, BrowserColumnMode.notes);

      final outcome = plan.complete(true);
      expect(outcome.effects, [BrowserColumnSelectionSaveEffect.dismissDialog]);
      expect(outcome.returnedValue, isTrue);
    });

    test('an empty selection failure maps to the no-columns message', () {
      final plan = planBrowserColumnSelectionSave(
        initialSelectedColumns: const [BrowserColumn.question],
        selectedColumns: const [],
        mode: BrowserColumnMode.cards,
      );

      expect(plan.hasUnsavedChanges, isTrue);
      expect(plan.effectsBeforeUpdate, isEmpty);
      expect(plan.updateRequest.columns, isEmpty);
      final outcome = plan.complete(false);

      expect(outcome.effects,
          [BrowserColumnSelectionSaveEffect.showNoColumnsMessage]);
      expect(outcome.returnedValue, isFalse);
    });

    test('column comparison is structural but preserves order and duplicates',
        () {
      final sameValues = planBrowserColumnSelectionSave(
        initialSelectedColumns: [BrowserColumn.question, BrowserColumn.tags],
        selectedColumns: [BrowserColumn.question, BrowserColumn.tags],
        mode: BrowserColumnMode.cards,
      );
      final reorderedValues = planBrowserColumnSelectionSave(
        initialSelectedColumns: const [
          BrowserColumn.question,
          BrowserColumn.tags
        ],
        selectedColumns: const [BrowserColumn.tags, BrowserColumn.question],
        mode: BrowserColumnMode.cards,
      );
      final duplicateValues = planBrowserColumnSelectionSave(
        initialSelectedColumns: const [BrowserColumn.question],
        selectedColumns: const [BrowserColumn.question, BrowserColumn.question],
        mode: BrowserColumnMode.cards,
      );

      expect(sameValues.hasUnsavedChanges, isFalse);
      expect(reorderedValues.hasUnsavedChanges, isTrue);
      expect(duplicateValues.hasUnsavedChanges, isTrue);
    });
  });
}
