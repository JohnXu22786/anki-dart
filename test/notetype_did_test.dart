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
 * Source-derived from NotetypeJson.kt and NoteTypeTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeDid', () {
    test(
      'setter writes once and non-null getter reads once in source order',
      () {
        final json = Object();
        final calls = <String>[];
        final did = NotetypeDid(
          jsonObject: json,
          isNull: (object, key) {
            calls.add('isNull:$key');
            expect(object, same(json));
            return false;
          },
          optLong: (object, key, fallback) {
            calls.add('optLong:$key:$fallback');
            expect(object, same(json));
            return 999;
          },
          put: (object, key, value) {
            calls.add('put:$key:$value');
            expect(object, same(json));
          },
        );

        did.did = 999;
        expect(calls, ['put:did:999']);
        calls.clear();
        expect(did.did, 999);
        expect(calls, ['isNull:did', 'optLong:did:1']);
      },
    );

    test('isNull returns the default without calling optLong', () {
      final calls = <String>[];
      final did = NotetypeDid(
        jsonObject: Object(),
        isNull: (_, key) {
          calls.add('isNull:$key');
          return true; // The host JSONObject reports missing and null as null.
        },
        optLong: (_, _, _) => throw StateError('optLong must not run'),
        put: (_, _, _) {},
      );

      expect(did.did, 1);
      expect(calls, ['isNull:did']);
    });

    test('non-null invalid value delegates fallback to host optLong', () {
      final calls = <String>[];
      final did = NotetypeDid(
        jsonObject: Object(),
        isNull: (_, key) {
          calls.add('isNull:$key');
          return false;
        },
        optLong: (_, key, fallback) {
          calls.add('optLong:$key:$fallback');
          return fallback;
        },
        put: (_, _, _) {},
      );

      expect(did.did, 1);
      expect(calls, ['isNull:did', 'optLong:did:1']);
    });

    test('host failures preserve identity and stop later callbacks', () {
      final isNullFailure = StateError('isNull failed');
      final isNullCalls = <String>[];
      final nullFailureDid = NotetypeDid(
        jsonObject: Object(),
        isNull: (_, _) => throw isNullFailure,
        optLong: (_, _, _) {
          isNullCalls.add('optLong');
          return 1;
        },
        put: (_, _, _) {},
      );
      expect(() => nullFailureDid.did, throwsA(same(isNullFailure)));
      expect(isNullCalls, isEmpty);

      final optLongFailure = StateError('optLong failed');
      final optLongDid = NotetypeDid(
        jsonObject: Object(),
        isNull: (_, _) => false,
        optLong: (_, _, _) => throw optLongFailure,
        put: (_, _, _) {},
      );
      expect(() => optLongDid.did, throwsA(same(optLongFailure)));

      final putFailure = StateError('put failed');
      final putDid = NotetypeDid(
        jsonObject: Object(),
        isNull: (_, _) => true,
        optLong: (_, _, _) => 1,
        put: (_, _, _) => throw putFailure,
      );
      expect(() => putDid.did = 4, throwsA(same(putFailure)));
    });
  });
}
