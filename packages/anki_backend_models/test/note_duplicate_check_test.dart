// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('isDuplicateNoteField', () {
    final note = Note(
      id: Int64(4),
      notetypeId: Int64(7),
      fields: ['test'],
    );

    test('checks the checksum bucket then compares stripped field text', () {
      Int64? requestedNotetypeId;
      int? requestedChecksum;
      final duplicate = isDuplicateNoteField(
        note: note,
        firstFieldWithoutHtml: 'test',
        loadFieldsByChecksum: (notetypeId, checksum) {
          requestedNotetypeId = notetypeId;
          requestedChecksum = checksum;
          return [
            NoteChecksumMatch(
              noteId: Int64(8),
              firstField: '<b>test</b>',
            ),
          ];
        },
      );

      expect(duplicate, isTrue);
      expect(requestedNotetypeId, Int64(7));
      expect(requestedChecksum, fieldChecksum('test'));
    });

    test('ignores the current note and checksum-collision candidates', () {
      final duplicate = isDuplicateNoteField(
        note: note,
        firstFieldWithoutHtml: 'test',
        loadFieldsByChecksum: (_, __) => [
          NoteChecksumMatch(noteId: Int64(4), firstField: 'test'),
          NoteChecksumMatch(noteId: Int64(9), firstField: '<i>other</i>'),
        ],
      );

      expect(duplicate, isFalse);
    });

    test('stops at the first match and preserves iterable order', () {
      var consumed = 0;
      Iterable<NoteChecksumMatch> matches() sync* {
        consumed++;
        yield NoteChecksumMatch(noteId: Int64(2), firstField: 'test');
        consumed++;
        yield NoteChecksumMatch(noteId: Int64(3), firstField: 'test');
      }

      expect(
        isDuplicateNoteField(
          note: note,
          firstFieldWithoutHtml: 'test',
          loadFieldsByChecksum: (_, __) => matches(),
        ),
        isTrue,
      );
      expect(consumed, 1);
    });

    test('propagates storage callback failures unchanged', () {
      final error = StateError('storage read failed');
      expect(
        () => isDuplicateNoteField(
          note: note,
          firstFieldWithoutHtml: 'test',
          loadFieldsByChecksum: (_, __) => throw error,
        ),
        throwsA(same(error)),
      );
    });
  });
}
