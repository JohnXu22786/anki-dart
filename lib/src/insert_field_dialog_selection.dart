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

/// A note type field name; equality matches the source value class.
final class FieldName {
  const FieldName(this.name);

  final String name;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is FieldName && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// A special card-template field; equality matches the source value class.
final class SpecialField {
  const SpecialField(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is SpecialField && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Source-ordered special template fields available to the dialog.
abstract final class SpecialFields {
  static const frontSide = SpecialField('FrontSide');
  static const deck = SpecialField('Deck');
  static const subdeck = SpecialField('Subdeck');
  static const tags = SpecialField('Tags');
  static const flag = SpecialField('CardFlag');
  static const noteType = SpecialField('Type');
  static const cardTemplate = SpecialField('Card');
  static const cardId = SpecialField('CardID');

  static const _all = [
    frontSide,
    deck,
    subdeck,
    tags,
    flag,
    noteType,
    cardTemplate,
    cardId,
  ];

  /// Returns the source's ordered availability for [side].
  static List<SpecialField> all(SingleCardSide side) => List.unmodifiable(
    _all.where((field) => field != frontSide || side != SingleCardSide.front),
  );
}

/// The card side used to determine special field availability.
enum SingleCardSide { front, back }

/// The Insert Field Dialog tab and its source position.
enum InsertFieldDialogTab {
  fields(0),
  special(1);

  const InsertFieldDialogTab(this.position);

  final int position;
}

/// A selected value rendered as an Anki template insertion tag.
sealed class SelectedInsertField {
  const SelectedInsertField();

  String renderToTemplateTag();
}

/// A selected note type field. Instances retain regular-class identity.
final class SelectedNamedField extends SelectedInsertField {
  SelectedNamedField(this.name);

  final FieldName name;

  @override
  String renderToTemplateTag() => '{{$name}}';
}

/// A selected special field. Instances retain regular-class identity.
final class SelectedSpecialField extends SelectedInsertField {
  SelectedSpecialField(this.model);

  final SpecialField model;

  @override
  String renderToTemplateTag() => '{{${model.name}}}';
}

/// Portable selection state from AnkiDroid's Insert Field Dialog.
///
/// Field choice validation and the selected value are modeled here. Saved
/// state, flows, metadata queries, localized descriptions, and dialog UI remain
/// with the host application.
final class InsertFieldDialogSelection {
  InsertFieldDialogSelection({
    required List<FieldName> fieldNames,
    required this.side,
  }) : fieldNames = List.unmodifiable(fieldNames),
       specialFields = SpecialFields.all(side);

  final List<FieldName> fieldNames;
  final SingleCardSide side;
  final List<SpecialField> specialFields;

  InsertFieldDialogTab currentTab = InsertFieldDialogTab.fields;
  SelectedInsertField? selectedField;

  /// Selects [fieldName] only when it exactly matches a note type field.
  void selectNamedField(FieldName fieldName) {
    if (!fieldNames.contains(fieldName)) return;
    selectedField = SelectedNamedField(fieldName);
  }

  /// Selects [field] only when it is available on this card side.
  void selectSpecialField(SpecialField field) {
    if (!specialFields.contains(field)) return;
    selectedField = SelectedSpecialField(field);
  }
}
