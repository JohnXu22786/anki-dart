// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('matches Anki Core field checksum vectors', () {
    expect(fieldChecksum('test'), 2840236005);
    expect(fieldChecksum('今日'), 1464653051);
  });
}
