/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test(
    'preview search scopes new cards to added days and the selected deck',
    () {
      expect(
        buildPreviewNewCardsSearch(deckName: 'Biology', days: 7),
        'is:new added:7 deck:Biology',
      );
      expect(
        buildPreviewNewCardsSearch(deckName: 'A_B', days: 1),
        r'is:new added:1 deck:A\_B',
      );
    },
  );

  test('preview days accepts the positive signed 32-bit range', () {
    expect(() => validatePreviewNewCardsDays(0), throwsArgumentError);
    expect(() => validatePreviewNewCardsDays(0x80000000), throwsRangeError);
    expect(() => validatePreviewNewCardsDays(1), returnsNormally);
    expect(() => validatePreviewNewCardsDays(0x7fffffff), returnsNormally);
  });
}
