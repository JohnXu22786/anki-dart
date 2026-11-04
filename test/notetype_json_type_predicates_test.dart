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
  group('NotetypeJsonTypePredicates', () {
    test('matches the source standard and cloze kind codes', () {
      final json = Object();
      final standard = NotetypeJsonTypePredicates(
        jsonObject: json,
        getInt: (_, key) {
          expect(key, 'type');
          return 0;
        },
      );
      final cloze = NotetypeJsonTypePredicates(
        jsonObject: json,
        getInt: (_, key) {
          expect(key, 'type');
          return 1;
        },
      );

      expect(standard.isStd, isTrue);
      expect(standard.isCloze, isFalse);
      expect(cloze.isStd, isFalse);
      expect(cloze.isCloze, isTrue);
    });

    test('unknown integer type codes match neither known kind', () {
      for (final code in <int>[-1, 2, 1 << 60]) {
        final predicates = NotetypeJsonTypePredicates(
          jsonObject: Object(),
          getInt: (_, _) => code,
        );

        expect(predicates.isStd, isFalse, reason: 'type code $code');
        expect(predicates.isCloze, isFalse, reason: 'type code $code');
      }
    });

    test(
      'each property reads type once and each access reads independently',
      () {
        final json = Object();
        final reads = <String>[];
        final predicates = NotetypeJsonTypePredicates(
          jsonObject: json,
          getInt: (actualJson, key) {
            expect(actualJson, same(json));
            reads.add(key);
            return reads.length == 1 ? 0 : 1;
          },
        );

        expect(predicates.isStd, isTrue);
        expect(reads, ['type']);
        expect(predicates.isCloze, isTrue);
        expect(reads, ['type', 'type']);
        expect(predicates.isStd, isFalse);
        expect(reads, ['type', 'type', 'type']);
      },
    );

    test('getInt failure propagates unchanged', () {
      final failure = StateError('getInt failed');
      final predicates = NotetypeJsonTypePredicates(
        jsonObject: Object(),
        getInt: (_, _) => throw failure,
      );

      expect(() => predicates.isStd, throwsA(same(failure)));
      expect(() => predicates.isCloze, throwsA(same(failure)));
    });
  });
}
