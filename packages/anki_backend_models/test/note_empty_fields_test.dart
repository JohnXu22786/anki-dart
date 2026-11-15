// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

NoteField _field(String name) =>
    NoteField(name: name, config: proto.Notetype_Field_Config());

void main() {
  group('fieldIsEmpty', () {
    test('matches pinned Anki Core examples', () {
      expect(fieldIsEmpty(''), isTrue);
      expect(fieldIsEmpty(' '), isTrue);
      expect(fieldIsEmpty('x'), isFalse);
      expect(fieldIsEmpty('<BR>'), isTrue);
      expect(fieldIsEmpty('<div />'), isTrue);
      expect(fieldIsEmpty(' <div> <br> </div>\n'), isTrue);
      expect(fieldIsEmpty(' <div>x</div>\n'), isFalse);
    });

    test('uses Unicode whitespace and only accepts the source tag forms', () {
      expect(fieldIsEmpty('\u0085\u00a0\u3000'), isTrue);
      expect(fieldIsEmpty('<span></span>'), isFalse);
      expect(fieldIsEmpty('<br  />'), isFalse);
      expect(fieldIsEmpty('<div\n>'), isFalse);
    });
  });

  group('Note.nonEmptyFields', () {
    test(
      'maps nonempty note values to their matching notetype field names',
      () {
        final note = Note(
          notetypeId: Int64(7),
          fields: ['', ' <div><br></div> ', 'answer', 'also here'],
        );

        expect(
          note.nonEmptyFields([
            _field('Front'),
            _field('Back'),
            _field('Extra'),
          ]),
          {'Extra'},
        );
      },
    );

    test('ignores note values without a corresponding notetype field', () {
      final note = Note(notetypeId: Int64(7), fields: ['content', 'more']);

      expect(note.nonEmptyFields([_field('Front')]), {'Front'});
    });

    test('returns a set when field names are repeated', () {
      final note = Note(notetypeId: Int64(7), fields: ['one', 'two']);

      expect(note.nonEmptyFields([_field('Same'), _field('Same')]), {'Same'});
    });
  });
}
