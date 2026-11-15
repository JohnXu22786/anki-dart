// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:test/test.dart';

void main() {
  const names = StockNotetypeNames(
    basic: 'Basic',
    basicTyping: 'Basic (type answer)',
    basicReversed: 'Basic (and reversed card)',
    basicOptionalReversed: 'Basic (optional reversed card)',
    cloze: 'Cloze',
    frontField: 'Front',
    backField: 'Back',
    addReverseField: 'Add Reverse',
    textField: 'Text',
    backExtraField: 'Back Extra',
    commentsField: 'Comments',
    cardOne: 'Card 1',
    cardTwo: 'Card 2',
    imageOcclusion: 'Image Occlusion',
    occlusionsField: 'Occlusions',
    imageField: 'Image',
    headerField: 'Header',
    toggleMasks: 'Toggle Masks',
    errorLoadingImageOcclusion: 'Error loading Image Occlusion',
  );

  BigInt Function() ids() {
    var next = BigInt.zero;
    return () {
      final current = next;
      next += BigInt.one;
      return current;
    };
  }

  test('Basic factory matches official names, templates, and configs', () {
    final value = StockNotetypeFactory.basic(names: names, randomU64: ids());
    expect(value.name, 'Basic');
    expect(value.config.kind, proto.Notetype_Config_Kind.KIND_NORMAL);
    expect(
      value.config.originalStockKind,
      proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_BASIC,
    );
    expect(value.fields.map((field) => field.name), ['Front', 'Back']);
    expect(value.templates, hasLength(1));
    expect(value.templates.single.name, 'Card 1');
    expect(value.templates.single.config.qFormat, '{{Front}}');
    expect(value.templates.single.config.aFormat,
        '{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}');
    expect(value.fields.map((field) => field.config.id.toInt()), [0, 1]);
    expect(value.templates.single.config.id.toInt(), 2);
  });

  test('typing, reversed, and optional reversed variants match source', () {
    final typing =
        StockNotetypeFactory.basicTyping(names: names, randomU64: ids());
    expect(typing.name, 'Basic (type answer)');
    expect(
      typing.config.originalStockKind,
      proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_BASIC_TYPING,
    );
    expect(
        typing.templates.single.config.qFormat, '{{Front}}\n\n{{type:Back}}');
    expect(typing.templates.single.config.aFormat,
        '{{Front}}\n\n<hr id=answer>\n\n{{type:Back}}');

    final reversed = StockNotetypeFactory.basicAndReversed(
      names: names,
      randomU64: ids(),
    );
    expect(reversed.name, 'Basic (and reversed card)');
    expect(reversed.fields.map((field) => field.name), ['Front', 'Back']);
    expect(reversed.templates.map((template) => template.name),
        ['Card 1', 'Card 2']);
    expect(reversed.templates[1].config.qFormat, '{{Back}}');
    expect(reversed.templates[1].config.aFormat,
        '{{FrontSide}}\n\n<hr id=answer>\n\n{{Front}}');

    final optional = StockNotetypeFactory.basicOptionalReversed(
      names: names,
      randomU64: ids(),
    );
    expect(optional.name, 'Basic (optional reversed card)');
    expect(optional.fields.map((field) => field.name),
        ['Front', 'Back', 'Add Reverse']);
    expect(optional.templates[1].config.qFormat,
        '{{#Add Reverse}}{{Back}}{{/Add Reverse}}');
    expect(
      optional.config.originalStockKind,
      proto.StockNotetype_OriginalStockKind
          .ORIGINAL_STOCK_KIND_BASIC_OPTIONAL_REVERSED,
    );
  });

  test('Cloze factory sets protected fields, tags, and template formats', () {
    final value = StockNotetypeFactory.cloze(names: names, randomU64: ids());
    expect(value.name, 'Cloze');
    expect(value.config.kind, proto.Notetype_Config_Kind.KIND_CLOZE);
    expect(
      value.config.originalStockKind,
      proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_CLOZE,
    );
    expect(value.fields.map((field) => field.name), ['Text', 'Back Extra']);
    expect(value.fields[0].config.tag, proto.ClozeField.CLOZE_FIELD_TEXT.value);
    expect(value.fields[0].config.preventDeletion, isTrue);
    expect(value.fields[1].config.tag,
        proto.ClozeField.CLOZE_FIELD_BACK_EXTRA.value);
    expect(value.templates.single.name, 'Cloze');
    expect(value.templates.single.config.qFormat, '{{cloze:Text}}');
    expect(value.templates.single.config.aFormat,
        '{{cloze:Text}}<br>\n{{Back Extra}}');
  });

  test('Image Occlusion factory matches pinned fields, HTML and CSS', () {
    final value =
        StockNotetypeFactory.imageOcclusion(names: names, randomU64: ids());
    expect(value.name, 'Image Occlusion');
    expect(value.config.kind, proto.Notetype_Config_Kind.KIND_CLOZE);
    expect(
      value.config.originalStockKind,
      proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_IMAGE_OCCLUSION,
    );
    expect(value.config.css, StockNotetypeFactory.imageOcclusionCss);
    expect(value.fields.map((field) => field.name), [
      'Occlusions',
      'Image',
      'Header',
      'Back Extra',
      'Comments',
    ]);
    expect(value.fields.map((field) => field.config.tag), [0, 1, 2, 3, 4]);
    expect(
      value.fields.map((field) => field.config.preventDeletion),
      [true, true, true, true, false],
    );
    expect(value.templates.single.name, 'Image Occlusion');
    expect(
        value.templates.single.config.qFormat,
        '{{#Header}}<div>{{Header}}</div>{{/Header}}\n'
        '<div style="display: none">{{cloze:Occlusions}}</div>\n'
        '<div id="err"></div>\n'
        '<div id="image-occlusion-container">\n'
        '    {{Image}}\n'
        '    <canvas id="image-occlusion-canvas"></canvas>\n'
        '</div>\n'
        '<script>\n'
        'try {\n'
        '    anki.imageOcclusion.setup();\n'
        '} catch (exc) {\n'
        '    document.getElementById("err").innerHTML = `Error loading Image Occlusion<br><br>\${exc}`;\n'
        '}\n'
        '</script>\n');
    expect(
        value.templates.single.config.aFormat,
        '${value.templates.single.config.qFormat}\n'
        '<div><button id="toggle">Toggle Masks</button></div>\n'
        '{{#Back Extra}}<div>{{Back Extra}}</div>{{/Back Extra}}\n');
  });
}
