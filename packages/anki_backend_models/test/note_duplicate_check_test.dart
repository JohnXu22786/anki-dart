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

    test('loads the full checksum query before comparing in source order', () {
      var consumed = 0;
      List<NoteChecksumMatch> loadMatches() {
        final rows = <NoteChecksumMatch>[];
        for (final match in [
          NoteChecksumMatch(noteId: Int64(2), firstField: 'test'),
          NoteChecksumMatch(noteId: Int64(3), firstField: 'test'),
        ]) {
          consumed++;
          rows.add(match);
        }
        return rows;
      }

      expect(
        isDuplicateNoteField(
          note: note,
          firstFieldWithoutHtml: 'test',
          loadFieldsByChecksum: (_, __) => loadMatches(),
        ),
        isTrue,
      );
      expect(consumed, 2);
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
