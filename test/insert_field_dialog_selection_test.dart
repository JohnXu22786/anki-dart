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
 * Behavioral reference: InsertFieldDialogViewModel.kt, FieldName.kt,
 * SpecialField.kt, and SingleCardSide.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('InsertFieldDialogSelection', () {
    test('accepts exact note field names and renders their template tags', () {
      final selection = InsertFieldDialogSelection(
        fieldNames: [FieldName('Front'), FieldName('Back')],
        side: SingleCardSide.front,
      );

      selection.selectNamedField(FieldName('Back'));

      expect(selection.selectedField, isA<SelectedNamedField>());
      expect(selection.selectedField!.renderToTemplateTag(), '{{Back}}');
      selection.selectNamedField(FieldName('back'));
      expect(selection.selectedField!.renderToTemplateTag(), '{{Back}}');
      selection.selectNamedField(FieldName(' Back'));
      expect(selection.selectedField!.renderToTemplateTag(), '{{Back}}');
    });

    test('exposes special fields in source order for each card side', () {
      expect(SpecialFields.all(SingleCardSide.front), [
        SpecialFields.deck,
        SpecialFields.subdeck,
        SpecialFields.tags,
        SpecialFields.flag,
        SpecialFields.noteType,
        SpecialFields.cardTemplate,
        SpecialFields.cardId,
      ]);
      expect(SpecialFields.all(SingleCardSide.back), [
        SpecialFields.frontSide,
        SpecialFields.deck,
        SpecialFields.subdeck,
        SpecialFields.tags,
        SpecialFields.flag,
        SpecialFields.noteType,
        SpecialFields.cardTemplate,
        SpecialFields.cardId,
      ]);
    });

    test(
      'selects available special fields and renders source insertion tags',
      () {
        final selection = InsertFieldDialogSelection(
          fieldNames: const [],
          side: SingleCardSide.back,
        );

        selection.selectSpecialField(SpecialFields.cardTemplate);
        expect(selection.selectedField!.renderToTemplateTag(), '{{Card}}');
        selection.selectSpecialField(SpecialField('Card'));
        expect(selection.selectedField!.renderToTemplateTag(), '{{Card}}');
      },
    );

    test('invalid selections retain null and the last valid selection', () {
      final selection = InsertFieldDialogSelection(
        fieldNames: [FieldName('Front')],
        side: SingleCardSide.front,
      );

      selection.selectNamedField(FieldName('Missing'));
      expect(selection.selectedField, isNull);
      selection.selectSpecialField(SpecialFields.frontSide);
      expect(selection.selectedField, isNull);

      selection.selectNamedField(FieldName('Front'));
      final selected = selection.selectedField;
      selection.selectNamedField(FieldName('Missing'));
      expect(selection.selectedField, same(selected));
      selection.selectSpecialField(SpecialFields.frontSide);
      expect(selection.selectedField, same(selected));
    });

    test(
      'field wrappers use value equality while selected variants keep identity',
      () {
        expect(FieldName('Front'), FieldName('Front'));
        expect(FieldName('Front').toString(), 'Front');
        expect(SpecialField('Deck'), SpecialField('Deck'));

        final first = SelectedNamedField(FieldName('Front'));
        final second = SelectedNamedField(FieldName('Front'));
        expect(first, isNot(same(second)));
        expect(first, isNot(second));
      },
    );
  });
}
