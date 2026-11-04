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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SortOrder.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiSortOrder', () {
    test('formats its singleton data objects as in the source', () {
      final noOrdering = LibAnkiSortOrder.noOrdering;
      final collectionOrdering = LibAnkiSortOrder.useCollectionOrdering;

      expect(noOrdering.toString(), 'NoOrdering');
      expect(collectionOrdering.toString(), 'UseCollectionOrdering');
      expect(identical(noOrdering, LibAnkiSortOrder.noOrdering), isTrue);
      expect(
        identical(collectionOrdering, LibAnkiSortOrder.useCollectionOrdering),
        isTrue,
      );
      expect(noOrdering, LibAnkiSortOrder.noOrdering);
      expect(collectionOrdering, LibAnkiSortOrder.useCollectionOrdering);
    });

    test('AfterSqlOrderBy retains source data-class behavior and raw SQL', () {
      const ordering = LibAnkiAfterSqlOrderBy('c.ivl asc, c.due desc');
      const sameOrdering = LibAnkiAfterSqlOrderBy('c.ivl asc, c.due desc');
      const differentOrdering = LibAnkiAfterSqlOrderBy('c.ivl DESC, c.due asc');

      expect(
        ordering.toString(),
        'AfterSqlOrderBy(customOrdering=c.ivl asc, c.due desc)',
      );
      expect(ordering.component1(), 'c.ivl asc, c.due desc');
      expect(ordering.copy(), sameOrdering);
      expect(
        ordering.copy(customOrdering: 'c.ivl DESC, c.due asc'),
        differentOrdering,
      );
      expect(ordering, sameOrdering);
      expect(ordering.hashCode, sameOrdering.hashCode);
      expect(ordering, isNot(differentOrdering));
    });

    test(
      'BuiltinColumnSortKind retains an opaque column and identity equality',
      () {
        final column = Object();
        final anotherColumn = Object();
        String keyOf(Object value) =>
            identical(value, column) ? 'cardDue' : 'other';
        final ascending = LibAnkiBuiltinColumnSortKind(
          column: column,
          reverse: false,
          columnKey: keyOf,
        );
        final sameValues = LibAnkiBuiltinColumnSortKind(
          column: column,
          reverse: false,
          columnKey: keyOf,
        );
        final otherColumnSort = LibAnkiBuiltinColumnSortKind(
          column: anotherColumn,
          reverse: false,
          columnKey: keyOf,
        );

        expect(ascending.column, same(column));
        expect(ascending.reverse, isFalse);
        expect(ascending, isNot(sameValues));
        expect(ascending, isNot(otherColumnSort));
        expect(
          LibAnkiBuiltinColumnSortKind(
            column: column,
            reverse: true,
            columnKey: keyOf,
          ).toString(),
          'BuiltinColumnSortKind(column=cardDue, reverse=true)',
        );
      },
    );

    test(
      'BuiltinColumnSortKind reads the host key once and propagates failures',
      () {
        final column = Object();
        final calls = <Object>[];
        final sort = LibAnkiBuiltinColumnSortKind(
          column: column,
          reverse: false,
          columnKey: (value) {
            calls.add(value);
            return 'cardDue';
          },
        );

        expect(
          sort.toString(),
          'BuiltinColumnSortKind(column=cardDue, reverse=false)',
        );
        expect(calls, hasLength(1));
        expect(identical(calls.single, column), isTrue);

        final failure = StateError('column key unavailable');
        final failingSort = LibAnkiBuiltinColumnSortKind(
          column: column,
          reverse: true,
          columnKey: (_) => throw failure,
        );
        expect(() => failingSort.toString(), throwsA(same(failure)));
      },
    );
  });
}
