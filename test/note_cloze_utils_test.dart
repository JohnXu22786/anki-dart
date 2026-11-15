/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Cases adapted from NoteTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('getNextClozeIndex', () {
    test('matches the five pinned NoteTest cases', () {
      expect(getNextClozeIndex([]), 1);
      expect(getNextClozeIndex(['{{c-1::foo}}']), 1);
      expect(getNextClozeIndex(['{{c2::bar}}{{c1::foo}}']), 3);
      expect(getNextClozeIndex(['{{c1::foo}}', '{{c2::bar}}']), 3);
      expect(getNextClozeIndex(['{{c1::foo}}', '{{c3::bar}}{{c4::baz}}']), 5);
    });

    test('matches only the source marker and decimal digit pattern', () {
      expect(
        getNextClozeIndex([
          '{{C8::uppercase}} {{ c9::space}} {{c10 : :colon}} '
              '{{c11::valid}} {{c١٢::non-ascii}}',
        ]),
        12,
      );
    });

    test(
      'parses the largest signed 32-bit cloze id and wraps its increment',
      () {
        expect(getNextClozeIndex(['{{c2147483647::max}}']), -2147483648);
      },
    );

    test(
      'throws FormatException when a captured id exceeds Kotlin Int range',
      () {
        expect(
          () => getNextClozeIndex(['{{c2147483648::too-large}}']),
          throwsFormatException,
        );
      },
    );
  });
}
