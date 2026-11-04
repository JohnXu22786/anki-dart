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
}
