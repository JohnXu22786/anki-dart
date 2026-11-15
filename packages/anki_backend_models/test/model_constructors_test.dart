// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('Anki base91 GUID conversion', () {
    test('matches upstream vectors', () {
      expect(base91U64(BigInt.zero), '');
      expect(base91U64(BigInt.one), 'b');
      expect(base91U64(BigInt.parse('18446744073709551615')), 'Rj&Z5m[>Zp');
      expect(base91U64(BigInt.from(1234567890)), 'saAKk');
    });

    test('validates unsigned 64-bit range and signed protobuf conversion', () {
      expect(() => base91U64(BigInt.from(-1)), throwsArgumentError);
      expect(() => base91U64(BigInt.one << 64), throwsArgumentError);
      expect(
        int64FromRandomU64(BigInt.one << 63),
        Int64.parseInt('-9223372036854775808'),
      );
      expect(int64FromRandomU64((BigInt.one << 64) - BigInt.one), Int64(-1));
    });
  });

  test(
    'new Note matches upstream empty values and accepts deterministic GUIDs',
    () {
      final notetype = Notetype(
        id: NotetypeId(Int64(44)),
        fields: [
          NoteField(name: 'Front', config: proto.Notetype_Field_Config()),
        ],
        config: proto.Notetype_Config(),
      );
      final note = Note.newNote(notetype, randomU64: () => BigInt.one);
      expect(note.id, Int64.ZERO);
      expect(note.guid, 'b');
      expect(note.notetypeId, Int64(44));
      expect(note.mtimeSecs, Int64.ZERO);
      expect(note.usn, 0);
      expect(note.tags, isEmpty);
      expect(note.fields, ['']);
      expect(note.sortField, isNull);
      expect(note.checksum, isNull);
    },
  );

  test('new field and template match upstream defaults', () {
    final field = NoteField.newField('Back', randomU64: () => BigInt.one << 63);
    expect(field.ord, isNull);
    expect(field.name, 'Back');
    expect(field.config.id, Int64.parseInt('-9223372036854775808'));
    expect(field.config.sticky, isFalse);
    expect(field.config.rtl, isFalse);
    expect(field.config.plainText, isFalse);
    expect(field.config.fontName, 'Arial');
    expect(field.config.fontSize, 20);
    expect(field.config.description, '');
    expect(field.config.collapsed, isFalse);
    expect(field.config.excludeFromSearch, isFalse);
    expect(field.config.hasTag(), isFalse);
    expect(field.config.preventDeletion, isFalse);
    expect(field.config.other, isEmpty);

    final template = CardTemplate.newTemplate(
      'Card 1',
      '{{Front}}',
      '{{FrontSide}}<hr>{{Back}}',
      randomU64: () => BigInt.from(9),
    );
    expect(template.ord, isNull);
    expect(template.mtimeSecs, Int64.ZERO);
    expect(template.usn, 0);
    expect(template.name, 'Card 1');
    expect(template.config.id, Int64(9));
    expect(template.config.qFormat, '{{Front}}');
    expect(template.config.aFormat, '{{FrontSide}}<hr>{{Back}}');
    expect(template.config.qFormatBrowser, '');
    expect(template.config.aFormatBrowser, '');
    expect(template.config.targetDeckId, Int64.ZERO);
    expect(template.config.browserFontName, '');
    expect(template.config.browserFontSize, 0);
    expect(template.config.other, isEmpty);
  });
}
