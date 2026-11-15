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
 * Source-derived from Tags.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionCompleteTagRaw', () {
    test('forwards exact bytes once and returns the callback result', () {
      final input = Uint8List.fromList([0, 1, 255]);
      final result = Uint8List.fromList([255, 0, 42]);
      var calls = 0;

      final actual = collectionCompleteTagRaw(
        input,
        completeTagRaw: (bytes) {
          calls++;
          expect(bytes, same(input));
          expect(bytes, [0, 1, 255]);
          return result;
        },
      );

      expect(calls, 1);
      expect(actual, [255, 0, 42]);
      expect(actual, same(result));
    });

    test('propagates callback failures unchanged', () {
      final input = Uint8List.fromList([0, 255]);
      final failure = StateError('backend failure');
      var calls = 0;

      expect(
        () => collectionCompleteTagRaw(
          input,
          completeTagRaw: (bytes) {
            calls++;
            expect(bytes, same(input));
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });
  });
}
