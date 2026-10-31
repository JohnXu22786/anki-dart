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
 * Behavioral reference: CardTemplateNotetype.kt and
 * CardTemplateNotetypeTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardTemplateNotetype change tracking', () {
    test('preserves the pinned add/delete order and database ordinals', () {
      final noteType = CardTemplateNotetype();

      noteType.addTemplateChange(ChangeType.add, 3);
      expect(_changes(noteType.templateChanges), [(3, ChangeType.add)]);
      expect(_changes(noteType.adjustedTemplateChanges), [(3, ChangeType.add)]);
      expect(noteType.getDeleteDbOrds(3), [3]);

      noteType.addTemplateChange(ChangeType.delete, 2);
      expect(_changes(noteType.adjustedTemplateChanges), [
        (2, ChangeType.add),
        (2, ChangeType.delete),
      ]);
      expect(noteType.getDeleteDbOrds(3), [2, 4]);

      noteType.addTemplateChange(ChangeType.delete, 1);
      expect(noteType.getDeleteDbOrds(3), [2, 1, 5]);
      expect(_changes(noteType.adjustedTemplateChanges), [
        (1, ChangeType.add),
        (2, ChangeType.delete),
        (1, ChangeType.delete),
      ]);

      noteType.addTemplateChange(ChangeType.add, 2);
      expect(noteType.getDeleteDbOrds(3), [2, 1, 5]);
      expect(_changes(noteType.templateChanges), [
        (3, ChangeType.add),
        (2, ChangeType.delete),
        (1, ChangeType.delete),
        (2, ChangeType.add),
      ]);
    });

    test('compacts a deleted pending add and shifts later entries', () {
      final noteType = CardTemplateNotetype()
        ..addTemplateChange(ChangeType.add, 3)
        ..addTemplateChange(ChangeType.delete, 2)
        ..addTemplateChange(ChangeType.delete, 1)
        ..addTemplateChange(ChangeType.add, 2)
        ..addTemplateChange(ChangeType.delete, 1);

      expect(_changes(noteType.templateChanges), [
        (2, ChangeType.delete),
        (1, ChangeType.delete),
        (1, ChangeType.add),
      ]);
      expect(_changes(noteType.adjustedTemplateChanges), [
        (2, ChangeType.delete),
        (1, ChangeType.delete),
        (1, ChangeType.add),
      ]);

      noteType
        ..addTemplateChange(ChangeType.add, 2)
        ..addTemplateChange(ChangeType.add, 3)
        ..addTemplateChange(ChangeType.delete, 3);

      expect(_changes(noteType.templateChanges), [
        (2, ChangeType.delete),
        (1, ChangeType.delete),
        (1, ChangeType.add),
        (2, ChangeType.add),
      ]);
      expect(noteType.getDeleteDbOrds(3), [2, 1, 5]);
    });

    test(
      'adjusted adds are copies while adjusted deletes alias their entries',
      () {
        final noteType = CardTemplateNotetype()
          ..addTemplateChange(ChangeType.add, 4)
          ..addTemplateChange(ChangeType.delete, 2);

        final adjusted = noteType.adjustedTemplateChanges;

        expect(adjusted[0].ordinal, 3);
        expect(adjusted[0], isNot(same(noteType.templateChanges[0])));
        expect(adjusted[1], same(noteType.templateChanges[1]));

        adjusted[0].ordinal = 99;
        adjusted[1].ordinal = 7;
        expect(noteType.templateChanges[0].ordinal, 4);
        expect(noteType.templateChanges[1].ordinal, 7);
      },
    );

    test('add lookup and pending-add predicate keep source return values', () {
      final noteType = CardTemplateNotetype()
        ..addTemplateChange(ChangeType.add, 3)
        ..addTemplateChange(ChangeType.delete, 2)
        ..addTemplateChange(ChangeType.delete, 1);

      expect(getAdjustedAddOrdinalAtChangeIndex(noteType, 0), 1);
      expect(getAdjustedAddOrdinalAtChangeIndex(noteType, 1), -1);
      expect(getAdjustedAddOrdinalAtChangeIndex(noteType, 3), -1);
      expect(isOrdinalPendingAdd(noteType, 1), isTrue);
      expect(isOrdinalPendingAdd(noteType, 2), isFalse);

      final deletesOnly = CardTemplateNotetype()
        ..addTemplateChange(ChangeType.delete, 0);
      // The Kotlin helper does not inspect the entry type before comparing its
      // -1 result, so asking about -1 reports a pending add.
      expect(isOrdinalPendingAdd(deletesOnly, -1), isTrue);
    });
  });
}

List<(int, ChangeType)> _changes(Iterable<TemplateChange> changes) => [
  for (final change in changes) (change.ordinal, change.type),
];
