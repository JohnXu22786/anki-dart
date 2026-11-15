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
 * Source-derived cases for Collection.kt helpers; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Collection helpers', () {
    test(
      'empty card IDs flatten in report and card order, retaining duplicates',
      () {
        final report1 = [2, 4, 4];
        final report2 = <int>[];
        final report3 = [7, 1];

        final actual = flattenEmptyCardIds([report1, report2, report3]);

        expect(actual, [2, 4, 4, 7, 1]);
        expect(report1, [2, 4, 4]);
      },
    );

    test('cloze ordinals sort ascending into a copy', () {
      final backendOrdinals = [3, 1, 2, 1];

      final actual = sortClozeOrdinals(backendOrdinals);

      expect(actual, [1, 1, 2, 3]);
      expect(actual, isNot(same(backendOrdinals)));
      expect(backendOrdinals, [3, 1, 2, 1]);
      expect(sortClozeOrdinals([]), isEmpty);
    });

    test(
      'schema change reads source fields in order with a strict boundary',
      () {
        final calls = <String>[];

        bool isChanged(int schemaModified, int lastSync) =>
            collectionSchemaChanged(
              readSchemaModified: () {
                calls.add('schema');
                return schemaModified;
              },
              readLastSync: () {
                calls.add('lastSync');
                return lastSync;
              },
            );

        expect(isChanged(10, 9), isTrue);
        expect(isChanged(9, 9), isFalse);
        expect(isChanged(8, 9), isFalse);
        expect(calls, [
          'schema',
          'lastSync',
          'schema',
          'lastSync',
          'schema',
          'lastSync',
        ]);
      },
    );

    test(
      'schema change propagates the first callback failure and skips later read',
      () {
        final failure = StateError('schema read failed');
        var lastSyncRead = false;

        expect(
          () => collectionSchemaChanged(
            readSchemaModified: () => throw failure,
            readLastSync: () {
              lastSyncRead = true;
              return 0;
            },
          ),
          throwsA(same(failure)),
        );
        expect(lastSyncRead, isFalse);
      },
    );
  });
}
