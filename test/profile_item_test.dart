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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ProfileItemTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileItem.initial', () {
    const id = ProfileId.defaultId;

    test('uppercases the exact host-supplied first grapheme', () {
      const item = ProfileItem(id: id, name: 'work');
      final calls = <String>[];

      final initial = item.initial(
        firstGraphemeOrNull: (value) {
          calls.add(value);
          return 'w';
        },
      );

      expect(initial, 'W');
      expect(calls, ['work']);
    });

    test('uses the source placeholder when the host finds no grapheme', () {
      const item = ProfileItem(id: id, name: '');
      expect(item.initial(firstGraphemeOrNull: (_) => null), '?');
    });

    test('keeps a supplementary emoji grapheme whole', () {
      const emoji = '😀';
      const item = ProfileItem(id: id, name: '😀 Study');
      expect(item.initial(firstGraphemeOrNull: (_) => emoji), emoji);
    });

    test('keeps a paired flag grapheme whole', () {
      const flag = '🇮🇳';
      const item = ProfileItem(id: id, name: '🇮🇳 India');
      expect(item.initial(firstGraphemeOrNull: (_) => flag), flag);
    });

    test('keeps a combining accent attached before uppercase', () {
      const accented = 'e\u0301';
      const item = ProfileItem(id: id, name: 'e\u0301cole');
      expect(item.initial(firstGraphemeOrNull: (_) => accented), 'E\u0301');
    });

    test('uses value equality for its source data-class fields', () {
      const first = ProfileItem(id: id, name: 'work');
      const equal = ProfileItem(id: id, name: 'work');
      const different = ProfileItem(id: id, name: 'home');

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(different));
    });

    test('propagates grapheme callback failures unchanged', () {
      const item = ProfileItem(id: id, name: 'work');
      final failure = StateError('BreakIterator failed');

      expect(
        () => item.initial(firstGraphemeOrNull: (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });
}
