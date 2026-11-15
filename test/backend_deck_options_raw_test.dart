/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from BackendDeckOptions.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BackendDeckOptionsRaw', () {
    test('getDeckConfigsForUpdateRaw forwards and returns callback values', () {
      final calls = <String>[];
      final input = Uint8List.fromList([0, 1, 255]);
      final result = Uint8List.fromList([9, 0, 8]);
      final failure = StateError('backend failure');
      var shouldThrow = false;
      final backend = BackendDeckOptionsRaw(
        BackendDeckOptionsRawCallbacks(
          getDeckConfigsForUpdateRaw: (bytes) {
            calls.add('getDeckConfigsForUpdateRaw');
            expect(bytes, same(input));
            if (shouldThrow) throw failure;
            return result;
          },
          updateDeckConfigsRaw: (_) => throw StateError('unexpected callback'),
        ),
      );

      expect(backend.getDeckConfigsForUpdateRaw(input), same(result));
      expect(calls, ['getDeckConfigsForUpdateRaw']);

      shouldThrow = true;
      expect(
        () => backend.getDeckConfigsForUpdateRaw(input),
        throwsA(same(failure)),
      );
      expect(calls, [
        'getDeckConfigsForUpdateRaw',
        'getDeckConfigsForUpdateRaw',
      ]);
    });

    test('updateDeckConfigsRaw forwards and returns callback values', () {
      final calls = <String>[];
      final input = Uint8List.fromList([2, 0, 254]);
      final result = Uint8List.fromList([7, 6, 0]);
      final failure = StateError('backend failure');
      var shouldThrow = false;
      final backend = BackendDeckOptionsRaw(
        BackendDeckOptionsRawCallbacks(
          getDeckConfigsForUpdateRaw: (_) =>
              throw StateError('unexpected callback'),
          updateDeckConfigsRaw: (bytes) {
            calls.add('updateDeckConfigsRaw');
            expect(bytes, same(input));
            if (shouldThrow) throw failure;
            return result;
          },
        ),
      );

      expect(backend.updateDeckConfigsRaw(input), same(result));
      expect(calls, ['updateDeckConfigsRaw']);

      shouldThrow = true;
      expect(() => backend.updateDeckConfigsRaw(input), throwsA(same(failure)));
      expect(calls, ['updateDeckConfigsRaw', 'updateDeckConfigsRaw']);
    });
  });
}
