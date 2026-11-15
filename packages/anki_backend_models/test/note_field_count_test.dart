// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('pads missing fields with empty strings', () {
    expect(fixNoteFieldCount(['front'], 3), ['front', '', '']);
  });

  test('merges trailing fields into the final retained field', () {
    expect(fixNoteFieldCount(['front', 'back', 'extra'], 2),
        ['front', 'back; extra']);
    expect(fixNoteFieldCount(['a', 'b', 'c'], 1), ['a; b; c']);
  });

  test('preserves one field when the note type has no fields', () {
    expect(fixNoteFieldCount(['a', 'b'], 0), ['a; b']);
    expect(fixNoteFieldCount([], 0), isEmpty);
  });

  test('does not mutate its input when the count already matches', () {
    final fields = ['front', 'back'];
    expect(fixNoteFieldCount(fields, 2), fields);
    expect(fields, ['front', 'back']);
  });
}
