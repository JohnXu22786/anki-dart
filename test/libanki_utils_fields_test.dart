/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Utils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart' as anki;
import 'package:test/test.dart';

void main() {
  group('Utils.ids2str', () {
    test('formats null, empty, integer, and generic iterable values', () {
      expect(anki.Utils.ids2str(null), '()');
      expect(anki.Utils.ids2str(<int>[]), '()');
      expect(anki.Utils.ids2str([1, -2, 3]), '(1, -2, 3)');
      expect(anki.Utils.ids2str(<Object?>[1, null, 'x']), '(1, null, x)');
    });
  });

  group('Utils.joinFields', () {
    test('joins values with only the pinned U+001F separator', () {
      expect(anki.Utils.joinFields([]), '');
      expect(anki.Utils.joinFields(['']), '');
      expect(anki.Utils.joinFields(['alpha']), 'alpha');
      expect(
        anki.Utils.joinFields(['', 'alpha', '', 'omega', '']),
        '\u001falpha\u001f\u001fomega\u001f',
      );
      expect(anki.Utils.joinFields(['a', 'b']), 'a\u001fb');
      expect(anki.LibAnkiConsts.fieldSeparator, '\u001f');
    });
  });

  group('Utils.splitFields', () {
    test('preserves empty fields before, between, and after separators', () {
      expect(anki.Utils.splitFields('foo\u001fbar'), ['foo', 'bar']);
      expect(anki.Utils.splitFields('\u001ffoo\u001f\u001f\u001f'), [
        '',
        'foo',
        '',
        '',
        '',
      ]);
      expect(anki.Utils.splitFields(''), ['']);
      expect(anki.Utils.splitFields('\u001f'), ['', '']);
    });
  });

  group('Utils.checksum', () {
    test('returns an empty string for null input', () {
      expect(anki.Utils.checksum(null), '');
    });

    test('returns the SHA-1 checksum for ASCII UTF-8 input', () {
      expect(
        anki.Utils.checksum('abc'),
        'a9993e364706816aba3e25717850c26c9cd0d89d',
      );
    });

    test('hashes multibyte input as UTF-8', () {
      expect(
        anki.Utils.checksum('café'),
        'f424452a9673918c6f09b0cdd35b20be8e6ae7d7',
      );
    });

    test('replaces unpaired surrogates like JVM UTF-8 encoding', () {
      expect(
        anki.Utils.checksum('\ud800'),
        '5bab61eb53176449e25c2c82f172b82cb13ffb9d',
      );
      expect(
        anki.Utils.checksum('\udc00'),
        '5bab61eb53176449e25c2c82f172b82cb13ffb9d',
      );
      expect(
        anki.Utils.checksum('😀'),
        '9c533688a979a858cbd6a43c9f91aba624651f18',
      );
    });

    test('pads leading zeroes to a 40-character lowercase digest', () {
      final checksum = anki.Utils.checksum('checksum-padding-4');

      expect(checksum, '01f31198d5da7f431a38654abad7d8d6edb1d9fa');
      expect(checksum, hasLength(40));
      expect(checksum, matches(RegExp(r'^[0-9a-f]{40}$')));
    });
  });
}
