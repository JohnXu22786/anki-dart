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
 * Source mapping: `JSON.toString()` from AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md and NOTICE.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('jsonToString', () {
    test('returns String and null without invoking host conversion', () {
      var callbackCount = 0;
      String hostToString(Object value) {
        callbackCount++;
        throw StateError('must not be called');
      }

      const value = 'already converted';
      expect(jsonToString(value, hostToString: hostToString), same(value));
      expect(jsonToString(null, hostToString: hostToString), isNull);
      expect(callbackCount, 0);
    });

    test(
      'uses the host conversion once and propagates its result and error',
      () {
        final value = Object();
        const converted = 'host-specific rendering';
        var callbackCount = 0;
        String hostToString(Object actual) {
          callbackCount++;
          expect(actual, same(value));
          return converted;
        }

        expect(
          jsonToString(value, hostToString: hostToString),
          same(converted),
        );
        expect(callbackCount, 1);

        final failure = StateError('host conversion failed');
        expect(
          () => jsonToString(value, hostToString: (actual) => throw failure),
          throwsA(same(failure)),
        );
      },
    );
  });
}
