/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from AnkiDroid 2.25.3 and Anki Core; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test('forgotten search uses rated-again within days and escapes deck', () {
    expect(
      buildForgottenCardsSearch(deckName: 'A_B', days: 7),
      r'deck:A\_B rated:7:1',
    );
  });

  test(
    'forgotten availability omits suspended, buried, and filtered cards',
    () {
      expect(
        buildForgottenCardsAvailabilitySearch(deckName: 'Biology', days: 1),
        'deck:Biology rated:1:1 -is:suspended -is:buried -deck:filtered',
      );
    },
  );

  test('forgotten days accepts the positive signed 32-bit range', () {
    expect(() => validateForgottenCardsDays(0), throwsArgumentError);
    expect(() => validateForgottenCardsDays(0x80000000), throwsRangeError);
    expect(() => validateForgottenCardsDays(1), returnsNormally);
    expect(() => validateForgottenCardsDays(0x7fffffff), returnsNormally);
  });
}
