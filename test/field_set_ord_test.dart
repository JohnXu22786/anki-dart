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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Field.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('setLibAnkiFieldOrd', () {
    test('writes the unchanged integer once to ord', () {
      final writes = <(String, Object?)>[];
      setLibAnkiFieldOrd(
        value: 17,
        nullSentinel: Object(),
        put: (key, value) => writes.add((key, value)),
      );

      expect(writes, [('ord', 17)]);
    });

    test('writes the exact host null sentinel once to ord', () {
      final nullSentinel = Object();
      final writes = <(String, Object?)>[];
      setLibAnkiFieldOrd(
        value: null,
        nullSentinel: nullSentinel,
        put: (key, value) => writes.add((key, value)),
      );

      expect(writes, hasLength(1));
      expect(writes.single.$1, 'ord');
      expect(writes.single.$2, same(nullSentinel));
    });

    test('propagates the exact put failure unchanged', () {
      final failure = StateError('put failed');

      expect(
        () => setLibAnkiFieldOrd(
          value: null,
          nullSentinel: Object(),
          put: (_, _) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
