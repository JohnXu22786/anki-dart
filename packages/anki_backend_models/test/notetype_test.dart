// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/generic.pb.dart' as generic;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('Notetype', () {
    test('normalizes, fixes, and uniquifies names like Anki Core', () {
      final field = NoteField.newField(
        '  # /^ t:e{s"t} field name #/^  ',
        randomU64: () => BigInt.one,
      );
      field.fixName();
      expect(field.name, 'test field name #/^');

      final quotedTemplate = CardTemplate.newTemplate(
        'Card "1"',
        'q',
        'a',
        randomU64: () => BigInt.one,
      )..fixName();
      expect(quotedTemplate.name, 'Card 1');
      expect(
        () => CardTemplate.newTemplate('""', 'q', 'a',
            randomU64: () => BigInt.one)
          ..fixName(),
        throwsA(isA<InvalidModelValue>().having((error) => error.message,
            'message', 'Template name contains only quotes')),
      );

      final value = Notetype(
        name: 'Cafe\u0301',
        fields: [
          NoteField(name: 'e\u0301', config: proto.Notetype_Field_Config()),
          NoteField(name: 'É', config: proto.Notetype_Field_Config()),
        ],
        templates: [
          CardTemplate(name: 'Card', config: proto.Notetype_Template_Config()),
          CardTemplate(name: 'Card', config: proto.Notetype_Template_Config()),
          CardTemplate(name: 'card', config: proto.Notetype_Template_Config()),
        ],
        config: proto.Notetype_Config(),
      );
      value.normalizeNames();
      expect(value.name, 'Café');
      expect(value.fields.first.name, 'é');
      value.ensureNamesUnique();
      expect(value.templates.map((template) => template.name),
          ['Card', 'Card+', 'card++']);
      expect(value.fields.map((field) => field.name), ['é', 'É+']);

      final unicodeCaseNames = Notetype(
        templates: [
          CardTemplate(
              name: 'Straße', config: proto.Notetype_Template_Config()),
          CardTemplate(
              name: 'STRASSE', config: proto.Notetype_Template_Config()),
          CardTemplate(name: 'ς', config: proto.Notetype_Template_Config()),
          CardTemplate(name: 'Σ', config: proto.Notetype_Template_Config()),
          CardTemplate(
              name: '\uA7C0', config: proto.Notetype_Template_Config()),
          CardTemplate(
              name: '\uA7C1', config: proto.Notetype_Template_Config()),
          CardTemplate(
              name: '\u{10570}', config: proto.Notetype_Template_Config()),
          CardTemplate(
              name: '\u{10597}', config: proto.Notetype_Template_Config()),
        ],
        config: proto.Notetype_Config(),
      )..ensureNamesUnique();
      expect(unicodeCaseNames.templates.map((template) => template.name), [
        'Straße',
        'STRASSE+',
        'ς',
        'Σ+',
        '\uA7C0',
        '\uA7C1',
        '\u{10570}',
        '\u{10597}'
      ]);
      value.fixFieldNames();
      value.fixTemplateNames();

      final emptyField =
          NoteField(name: '', config: proto.Notetype_Field_Config());
      expect(
        () => emptyField.fixName(),
        throwsA(isA<InvalidModelValue>()
            .having((error) => error.message, 'message', 'Empty field name')),
      );

      final invalidAfterCleanup = NoteField(
        name: '::',
        config: proto.Notetype_Field_Config(),
      );
      expect(
        () => invalidAfterCleanup.fixName(),
        throwsA(isA<InvalidModelValue>()
            .having((error) => error.message, 'message', 'Field name: ')),
      );
      expect(invalidAfterCleanup.name, '');

      final nonWhitespaceControls = NoteField(
        name: '\u001cName\u001c',
        config: proto.Notetype_Field_Config(),
      )..fixName();
      expect(nonWhitespaceControls.name, '\u001cName\u001c');
    });

    test('default and cloze configurations match pinned upstream assets', () {
      final defaults = Notetype.ankiDefault();
      expect(defaults.id.value, Int64.ZERO);
      expect(defaults.name, '');
      expect(defaults.mtimeSecs, Int64.ZERO);
      expect(defaults.usn, 0);
      expect(defaults.fields, isEmpty);
      expect(defaults.templates, isEmpty);
      expect(defaults.config.kind, proto.Notetype_Config_Kind.KIND_NORMAL);
      expect(defaults.config.css, Notetype.defaultCss);
      expect(defaults.config.css, contains('font-family: arial;'));
      expect(defaults.config.latexPre, Notetype.defaultLatexHeader);
      expect(defaults.config.latexPre, endsWith('\\begin{document}\n'));
      expect(defaults.config.latexPost, r'\end{document}');

      final cloze = Notetype.clozeConfig();
      expect(cloze.kind, proto.Notetype_Config_Kind.KIND_CLOZE);
      expect(cloze.css, '${Notetype.defaultCss}${Notetype.defaultClozeCss}');
      expect(cloze.css, contains('.nightMode .cloze {'));
      expect(cloze.latexPre, defaults.config.latexPre);
      expect(cloze.latexPost, defaults.config.latexPost);
    });

    test(
      'preserves every scalar, config, signed ID, list order, and round trip',
      () {
        final input = proto.Notetype(
          id: Int64.parseInt('-9223372036854775000'),
          name: 'Cloze',
          mtimeSecs: Int64.parseInt('9223372036854775000'),
          usn: -17,
          config: proto.Notetype_Config(
            kind: proto.Notetype_Config_Kind.KIND_CLOZE,
            sortFieldIdx: 7,
            css: '.card { color: red; }',
            targetDeckIdUnused: Int64(123),
            latexPre: 'pre',
            latexPost: 'post',
            latexSvg: true,
            reqs: [
              proto.Notetype_Config_CardRequirement(
                cardOrd: 4,
                kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ALL,
                fieldOrds: [3, 1],
              ),
            ],
            originalStockKind:
                proto.StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_CLOZE,
            originalId: Int64.parseInt('-9223372036854774999'),
            other: [8, 9],
          ),
          fields: [
            proto.Notetype_Field(
              ord: generic.UInt32(val: 5),
              name: 'Back',
              config: proto.Notetype_Field_Config(),
            ),
            proto.Notetype_Field(
              ord: generic.UInt32(val: 2),
              name: 'Text',
              config: proto.Notetype_Field_Config(fontName: 'Serif'),
            ),
          ],
          templates: [
            proto.Notetype_Template(
              ord: generic.UInt32(val: 9),
              name: 'Second',
              mtimeSecs: Int64(88),
              usn: -19,
              config: proto.Notetype_Template_Config(qFormat: '{{Back}}'),
            ),
            proto.Notetype_Template(
              ord: generic.UInt32(val: 1),
              name: 'First',
              mtimeSecs: Int64(33),
              usn: 21,
              config: proto.Notetype_Template_Config(qFormat: '{{Text}}'),
            ),
          ],
        );

        final value = Notetype.fromProto(input);
        expect(value.id.value, input.id);
        expect(value.name, input.name);
        expect(value.mtimeSecs, input.mtimeSecs);
        expect(value.usn, -17);
        expect(value.fields.map((field) => field.name), ['Back', 'Text']);
        expect(value.fields.map((field) => field.ord), [5, 2]);
        expect(value.templates.map((template) => template.name), [
          'Second',
          'First',
        ]);
        expect(value.templates.map((template) => template.ord), [9, 1]);
        expect(value.config.writeToBuffer(), input.config.writeToBuffer());
        expect(value.toProto().writeToBuffer(), input.writeToBuffer());

        final id = NotetypeId.fromProto(proto.NotetypeId(ntid: input.id));
        expect(id.value, input.id);
        expect(id.toProto().ntid, input.id);
      },
    );

    test('defaults omitted configs and retains absent ordinal presence', () {
      final input = proto.Notetype(
        fields: [proto.Notetype_Field(name: 'Front')],
        templates: [proto.Notetype_Template(name: 'Card 1')],
      );
      final value = Notetype.fromProto(input);

      expect(
        value.config.writeToBuffer(),
        proto.Notetype_Config().writeToBuffer(),
      );
      expect(
        value.fields.single.config.writeToBuffer(),
        proto.Notetype_Field_Config().writeToBuffer(),
      );
      expect(
        value.templates.single.config.writeToBuffer(),
        proto.Notetype_Template_Config().writeToBuffer(),
      );
      expect(value.fields.single.ord, isNull);
      expect(value.templates.single.ord, isNull);
      final output = value.toProto();
      expect(output.hasConfig(), isTrue);
      expect(output.fields.single.hasOrd(), isFalse);
      expect(output.templates.single.hasOrd(), isFalse);
      expect(output.id, input.id);
      expect(output.name, input.name);
      expect(output.mtimeSecs, input.mtimeSecs);
      expect(output.usn, input.usn);
      expect(
        output.config.writeToBuffer(),
        proto.Notetype_Config().writeToBuffer(),
      );
      expect(output.fields.single.name, 'Front');
      expect(
        output.fields.single.config.writeToBuffer(),
        proto.Notetype_Field_Config().writeToBuffer(),
      );
      expect(output.templates.single.name, 'Card 1');
      expect(
        output.templates.single.config.writeToBuffer(),
        proto.Notetype_Template_Config().writeToBuffer(),
      );
    });
  });

  group('NoteField', () {
    test('preserves optional ord and all field config values', () {
      final input = proto.Notetype_Field(
        ord: generic.UInt32(val: 4294967295),
        name: 'Definition',
        config: proto.Notetype_Field_Config(
          sticky: true,
          rtl: true,
          fontName: 'Mono',
          fontSize: 31,
          description: 'description',
          plainText: true,
          collapsed: true,
          excludeFromSearch: true,
          id: Int64.parseInt('-9223372036854775000'),
          tag: 4294967294,
          preventDeletion: true,
          other: [1, 4],
        ),
      );

      final value = NoteField.fromProto(input);
      expect(value.ord, 4294967295);
      expect(value.name, 'Definition');
      expect(value.config.writeToBuffer(), input.config.writeToBuffer());
      final output = value.toProto();
      expect(output.hasOrd(), isTrue);
      expect(output.ord.val, 4294967295);
      expect(output.writeToBuffer(), input.writeToBuffer());

      final noOrd = NoteField.fromProto(proto.Notetype_Field(name: 'No ord'));
      expect(noOrd.ord, isNull);
      expect(noOrd.toProto().hasOrd(), isFalse);
    });
  });

  group('CardTemplate', () {
    test('preserves ord, timestamp, USN, and all template config values', () {
      final input = proto.Notetype_Template(
        ord: generic.UInt32(val: 4000000000),
        name: 'Reverse',
        mtimeSecs: Int64.parseInt('-9223372036854775000'),
        usn: -2147483648,
        config: proto.Notetype_Template_Config(
          qFormat: '{{Front}}',
          aFormat: '{{Back}}',
          qFormatBrowser: 'browser question',
          aFormatBrowser: 'browser answer',
          targetDeckId: Int64.parseInt('9223372036854775000'),
          browserFontName: 'Sans',
          browserFontSize: 19,
          id: Int64.parseInt('-9223372036854774999'),
          other: [2, 7],
        ),
      );

      final value = CardTemplate.fromProto(input);
      expect(value.ord, 4000000000);
      expect(value.name, 'Reverse');
      expect(value.mtimeSecs, input.mtimeSecs);
      expect(value.usn, -2147483648);
      expect(value.config.writeToBuffer(), input.config.writeToBuffer());
      expect(value.toProto().writeToBuffer(), input.writeToBuffer());

      final noOrd = CardTemplate.fromProto(proto.Notetype_Template());
      expect(noOrd.ord, isNull);
      expect(noOrd.toProto().hasOrd(), isFalse);
    });
  });
}
