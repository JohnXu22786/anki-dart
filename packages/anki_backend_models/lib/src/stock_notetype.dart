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
    required this.commentsField,
    required this.cardOne,
    required this.cardTwo,
    required this.imageOcclusion,
    required this.occlusionsField,
    required this.imageField,
    required this.headerField,
    required this.toggleMasks,
    required this.errorLoadingImageOcclusion,
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
  final String commentsField;
  final String cardOne;
  final String cardTwo;
  final String imageOcclusion;
  final String occlusionsField;
  final String imageField;
  final String headerField;
  final String toggleMasks;
  final String errorLoadingImageOcclusion;
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

  /// Build the official Image Occlusion note type value.
  ///
  /// This creates the stock fields, HTML templates and CSS only. Collection
  /// operations that add or validate the notetype remain backend behavior.
  static Notetype imageOcclusion({
    required StockNotetypeNames names,
    required BigInt Function() randomU64,
  }) {
    final fields = [
      _imageOcclusionField(
        names.occlusionsField,
        proto.ImageOcclusionField.IMAGE_OCCLUSION_FIELD_OCCLUSIONS,
        randomU64,
        preventDeletion: true,
      ),
      _imageOcclusionField(
        names.imageField,
        proto.ImageOcclusionField.IMAGE_OCCLUSION_FIELD_IMAGE,
        randomU64,
        preventDeletion: true,
      ),
      _imageOcclusionField(
        names.headerField,
        proto.ImageOcclusionField.IMAGE_OCCLUSION_FIELD_HEADER,
        randomU64,
        preventDeletion: true,
      ),
      _imageOcclusionField(
        names.backExtraField,
        proto.ImageOcclusionField.IMAGE_OCCLUSION_FIELD_BACK_EXTRA,
        randomU64,
        preventDeletion: true,
      ),
      _imageOcclusionField(
        names.commentsField,
        proto.ImageOcclusionField.IMAGE_OCCLUSION_FIELD_COMMENTS,
        randomU64,
      ),
    ];
    final qfmt = _imageOcclusionQuestion(names);
    final afmt = '$qfmt'
        '\n'
        '<div><button id="toggle">${names.toggleMasks}</button></div>\n'
        '{{#${names.backExtraField}}}<div>{{${names.backExtraField}}}</div>{{/${names.backExtraField}}}\n';
    final config = Notetype.clozeConfig()
      ..css = imageOcclusionCss
      ..originalStockKind = proto
          .StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_IMAGE_OCCLUSION;
    return Notetype(
      name: names.imageOcclusion,
      fields: fields,
      templates: [
        CardTemplate.newTemplate(
          names.imageOcclusion,
          qfmt,
          afmt,
          randomU64: randomU64,
        ),
      ],
      config: config,
    );
  }

  static NoteField _imageOcclusionField(
    String name,
    proto.ImageOcclusionField tag,
    BigInt Function() randomU64, {
    bool preventDeletion = false,
  }) {
    final field = NoteField.newField(name, randomU64: randomU64);
    field.config
      ..tag = tag.value
      ..preventDeletion = preventDeletion;
    return field;
  }

  static String _imageOcclusionQuestion(StockNotetypeNames names) =>
      '{{#${names.headerField}}}<div>{{${names.headerField}}}</div>{{/${names.headerField}}}\n'
      '<div style="display: none">{{cloze:${names.occlusionsField}}}</div>\n'
      '<div id="err"></div>\n'
      '<div id="image-occlusion-container">\n'
      '    {{${names.imageField}}}\n'
      '    <canvas id="image-occlusion-canvas"></canvas>\n'
      '</div>\n'
      '<script>\n'
      'try {\n'
      '    anki.imageOcclusion.setup();\n'
      '} catch (exc) {\n'
      '    document.getElementById("err").innerHTML = `${names.errorLoadingImageOcclusion}<br><br>\${exc}`;\n'
      '}\n'
      '</script>\n';

  static const imageOcclusionCss = '#image-occlusion-canvas {\n'
      '    --inactive-shape-color: #ffeba2;\n'
      '    --active-shape-color: #ff8e8e;\n'
      '    --inactive-shape-border: 1px #212121;\n'
      '    --active-shape-border: 1px #212121;\n'
      '    --highlight-shape-color: #ff8e8e00;\n'
      '    --highlight-shape-border: 1px #ff8e8e;\n'
      '}\n'
      '\n'
      '.card {\n'
      '    font-family: arial;\n'
      '    font-size: 20px;\n'
      '    text-align: center;\n'
      '    color: black;\n'
      '    background-color: white;\n'
      '}\n';

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
