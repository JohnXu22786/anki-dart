// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('removes ASCII controls except line feed and horizontal tab', () {
    final controls =
        String.fromCharCodes(List<int>.generate(33, (i) => i) + [127]);
    expect(
      normalizeNoteField(controls, normalizeText: false),
      String.fromCharCodes([9, 10, 32]),
    );
  });

  test('optionally normalizes text to NFC', () {
    expect(normalizeNoteField('e\u0301', normalizeText: true), 'é');
    expect(normalizeNoteField('e\u0301', normalizeText: false), 'e\u0301');
  });
}
