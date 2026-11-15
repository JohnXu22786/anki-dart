// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;

import 'card_template.dart';
import 'note_field.dart';
import 'notetype.dart';

/// Localized names used by Anki Core's stock note types.
///
/// The caller supplies names from the active platform locale; the factory
/// builds the remaining field and card template content from Anki Core.
class StockNotetypeNames {
  const StockNotetypeNames({
    required this.basic,
    required this.basicTyping,
    required this.basicReversed,
    required this.basicOptionalReversed,
    required this.cloze,
    required this.frontField,
    required this.backField,
    required this.addReverseField,
    required this.textField,
    required this.backExtraField,
    required this.cardOne,
    required this.cardTwo,
  });

  final String basic;
  final String basicTyping;
  final String basicReversed;
  final String basicOptionalReversed;
  final String cloze;
  final String frontField;
  final String backField;
  final String addReverseField;
  final String textField;
  final String backExtraField;
  final String cardOne;
  final String cardTwo;
}

/// Builds the stock notetypes defined in Anki Core's `notetype/stock.rs`.
///
/// Random identifiers are supplied by the platform caller so this code stays
/// portable across Flutter targets and can be tested deterministically.
class StockNotetypeFactory {
  StockNotetypeFactory._();

  static Notetype basic({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
  }) =>
      _normal(
        name: names.basic,
        originalKind:
            proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_BASIC,
        fields: [
          NoteField.newField(names.frontField, randomU64: randomU64),
          NoteField.newField(names.backField, randomU64: randomU64),
        ],
        templates: [
          CardTemplate.newTemplate(
            names.cardOne,
            _fieldRef(names.frontField),
            '${_fieldRef('FrontSide')}\n\n<hr id=answer>\n\n${_fieldRef(names.backField)}',
            randomU64: randomU64,
          ),
        ],
      );

  static Notetype basicTyping({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
  }) {
    final basic = StockNotetypeFactory.basic(
      names: names,
      randomU64: randomU64,
    );
    final front = _fieldRef(names.frontField);
    final back = names.backField;
    final typed = _withName(basic, names.basicTyping);
    typed.config.originalStockKind =
        proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_BASIC_TYPING;
    typed.templates[0].config
      ..qFormat = '$front\n\n{{type:$back}}'
      ..aFormat = '$front\n\n<hr id=answer>\n\n{{type:$back}}';
    return typed;
  }

  static Notetype basicAndReversed({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
  }) {
    final basic = StockNotetypeFactory.basic(
      names: names,
      randomU64: randomU64,
    );
    final reversed = _withName(basic, names.basicReversed);
    reversed.config.originalStockKind = proto
        .StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_BASIC_AND_REVERSED;
    reversed.templates.add(
      CardTemplate.newTemplate(
        names.cardTwo,
        _fieldRef(names.backField),
        '${_fieldRef('FrontSide')}\n\n<hr id=answer>\n\n${_fieldRef(names.frontField)}',
        randomU64: randomU64,
      ),
    );
    return reversed;
  }

  static Notetype basicOptionalReversed({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
  }) {
    final reversed = StockNotetypeFactory.basicAndReversed(
      names: names,
      randomU64: randomU64,
    );
    final optional = _withName(reversed, names.basicOptionalReversed);
    optional.config.originalStockKind = proto.StockNotetype_OriginalStockKind
        .ORIGINAL_STOCK_KIND_BASIC_OPTIONAL_REVERSED;
    optional.fields.add(
      NoteField.newField(names.addReverseField, randomU64: randomU64),
    );
    final template = optional.templates[1].config;
    template.qFormat =
        '{{#${names.addReverseField}}}${template.qFormat}{{/${names.addReverseField}}}';
    return optional;
  }

  static Notetype cloze({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
  }) {
    final text = NoteField.newField(names.textField, randomU64: randomU64)
      ..config.tag = proto.ClozeField.CLOZE_FIELD_TEXT.value
      ..config.preventDeletion = true;
    final backExtra = NoteField.newField(
      names.backExtraField,
      randomU64: randomU64,
    )..config.tag = proto.ClozeField.CLOZE_FIELD_BACK_EXTRA.value;
    final qfmt = '{{cloze:${names.textField}}}';
    return Notetype(
      name: names.cloze,
      fields: [text, backExtra],
      templates: [
        CardTemplate.newTemplate(
          names.cloze,
          qfmt,
          '$qfmt<br>\n{{${names.backExtraField}}}',
          randomU64: randomU64,
        ),
      ],
      config: Notetype.clozeConfig()
        ..originalStockKind =
            proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_CLOZE,
    );
  }

  static Notetype _normal({
    required String name,
    required proto.StockNotetype_OriginalStockKind originalKind,
    required List<NoteField> fields,
    required List<CardTemplate> templates,
  }) =>
      Notetype(
        name: name,
        fields: fields,
        templates: templates,
        config: Notetype.defaultConfig()..originalStockKind = originalKind,
      );

  static Notetype _withName(Notetype notetype, String name) => Notetype(
        id: notetype.id,
        name: name,
        mtimeSecs: notetype.mtimeSecs,
        usn: notetype.usn,
        fields: notetype.fields,
        templates: notetype.templates,
        config: notetype.config,
      );

  static String _fieldRef(String name) => '{{$name}}';
}
