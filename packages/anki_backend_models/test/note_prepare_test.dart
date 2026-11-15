// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

Notetype _notetype({int sortFieldIdx = 0, int fieldCount = 2}) => Notetype(
      id: NotetypeId(Int64(7)),
      fields: List<NoteField>.generate(
        fieldCount,
        (index) => NoteField(
          name: 'Field $index',
          config: proto.Notetype_Field_Config(),
        ),
      ),
      config: proto.Notetype_Config(sortFieldIdx: sortFieldIdx),
    );

void main() {
  group('stripHtmlPreservingMediaFilenames', () {
    test('removes markup while preserving src and data filenames', () {
      expect(
        stripHtmlPreservingMediaFilenames(
          '<b>front</b><img src="image.png"><object data=clip.mp4>',
        ),
        'front image.png  clip.mp4 ',
      );
    });

    test('decodes entities and removes comments, scripts and styles', () {
      expect(
        stripHtmlPreservingMediaFilenames(
          'a&amp;b<!-- hidden --><script>secret</script>'
          '<style>.hidden{}</style><i>&#x1f600;</i>',
        ),
        'a&b😀',
      );
      expect(stripHtmlPreservingMediaFilenames('a&nbsp;b'), 'a b');
      expect(stripHtmlPreservingMediaFilenames('A &amp B'), 'A &amp B');
      expect(
        stripHtmlPreservingMediaFilenames('&amp; &unknown;'),
        '&amp; &unknown;',
      );
      expect(stripHtmlPreservingMediaFilenames('&#x41; &#65;'), 'A A');
      expect(stripHtmlPreservingMediaFilenames('&#X41;'), '&#X41;');
    });

    test('matches source behavior for media tags with quoted attributes', () {
      expect(
        stripHtmlPreservingMediaFilenames(
          "<img alt='preview > label' src='a&amp;b.jpg'>",
        ),
        ' a&b.jpg ',
      );
    });
  });

  group('Note.prepareForUpdate', () {
    test('cleans fields and computes first-field checksum and configured sort',
        () {
      final note = Note(
        notetypeId: Int64(7),
        fields: ['<b>te\u0000st</b>', '<img src="picture.png"> &amp;'],
        sortField: 'stale sort',
        checksum: 123,
      );

      note.prepareForUpdate(_notetype(sortFieldIdx: 1), normalizeText: false);

      expect(note.fields, ['<b>test</b>', '<img src="picture.png"> &amp;']);
      expect(note.checksum, 2840236005);
      expect(note.sortField, ' picture.png  &');
    });

    test('uses first field when the configured sort ordinal is zero', () {
      final note = Note(notetypeId: Int64(7), fields: ['<i>今日</i>', 'other']);

      note.prepareForUpdate(_notetype(), normalizeText: false);

      expect(note.sortField, '今日');
      expect(note.checksum, 1464653051);
    });

    test('uses an empty sort field when the configured ordinal is missing', () {
      final note = Note(notetypeId: Int64(7), fields: ['front', 'back']);

      note.prepareForUpdate(_notetype(sortFieldIdx: 9), normalizeText: false);

      expect(note.sortField, '');
    });

    test('applies optional NFC normalization and requires at least one field',
        () {
      final note = Note(notetypeId: Int64(7), fields: ['e\u0301', 'back']);

      note.prepareForUpdate(_notetype(), normalizeText: true);

      expect(note.fields.first, 'é');
    });

    test('rejects a different notetype and the wrong number of fields', () {
      final differentNotetype = Note(notetypeId: Int64(8), fields: ['a', 'b']);
      expect(
        () => differentNotetype.prepareForUpdate(
          _notetype(),
          normalizeText: false,
        ),
        throwsStateError,
      );
      final wrongCount = Note(notetypeId: Int64(7), fields: ['only one']);
      expect(
        () => wrongCount.prepareForUpdate(
          _notetype(),
          normalizeText: false,
        ),
        throwsStateError,
      );
    });
  });
}
