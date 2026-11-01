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
 * Source-derived from CharSequence.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ifNullOrEmpty', () {
    test('uses the fallback for null and empty receivers exactly once', () {
      var callbackCount = 0;
      String fallback() {
        callbackCount++;
        return 'fallback';
      }

      expect(ifNullOrEmpty(null, fallback), 'fallback');
      expect(callbackCount, 1);
      expect(ifNullOrEmpty('', fallback), 'fallback');
      expect(callbackCount, 2);
    });

    test('returns a nonempty receiver without evaluating the fallback', () {
      var callbackCount = 0;

      final result = ifNullOrEmpty('kept', () {
        callbackCount++;
        return 'fallback';
      });

      expect(result, 'kept');
      expect(callbackCount, 0);
    });

    test('propagates exceptions from the fallback', () {
      final exception = StateError('fallback failed');

      expect(
        () => ifNullOrEmpty(null, () => throw exception),
        throwsA(same(exception)),
      );
    });
  });
}
