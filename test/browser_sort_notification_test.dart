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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardBrowserViewModel.kt; pinned tests cover sort
 * persistence/query behavior but do not assert SortChangeNotification values.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser sort change notification', () {
    test('maps NoOrdering without using collection values', () {
      expect(
        projectBrowserSortChangeNotification(
          sortType: const BrowserSortNoOrdering(),
          resolvedColumnLabel: 'resolved label',
          resolvedColumnType: BrowserColumnType.date,
        ),
        isA<BrowserSortNoOrderingNotification>(),
      );
    });

    test('preserves resolved label, type, and reverse', () {
      final notification =
          projectBrowserSortChangeNotification(
                sortType: const BrowserSortCollectionOrdering(
                  key: 'noteFld',
                  reverse: true,
                ),
                resolvedColumnLabel: 'Sort field',
                resolvedColumnType: BrowserColumnType.text,
              )
              as BrowserSortCollectionOrderingNotification;

      expect(notification.columnLabel, 'Sort field');
      expect(notification.type, BrowserColumnType.text);
      expect(notification.reverse, isTrue);
    });

    test('falls back to raw key and unspecified type', () {
      final notification =
          projectBrowserSortChangeNotification(
                sortType: const BrowserSortCollectionOrdering(
                  key: 'unknown-key',
                  reverse: false,
                ),
              )
              as BrowserSortCollectionOrderingNotification;

      expect(notification.columnLabel, 'unknown-key');
      expect(notification.type, BrowserColumnType.unspecified);
      expect(notification.reverse, isFalse);
    });

    test('retains the resolved label when the type is unavailable', () {
      final notification =
          projectBrowserSortChangeNotification(
                sortType: const BrowserSortCollectionOrdering(
                  key: 'cardDue',
                  reverse: true,
                ),
                resolvedColumnLabel: 'Due',
              )
              as BrowserSortCollectionOrderingNotification;

      expect(notification.columnLabel, 'Due');
      expect(notification.type, BrowserColumnType.unspecified);
      expect(notification.reverse, isTrue);
    });

    test('retains the resolved type when the label is unavailable', () {
      final notification =
          projectBrowserSortChangeNotification(
                sortType: const BrowserSortCollectionOrdering(
                  key: 'noteCrt',
                  reverse: false,
                ),
                resolvedColumnType: BrowserColumnType.date,
              )
              as BrowserSortCollectionOrderingNotification;

      expect(notification.columnLabel, 'noteCrt');
      expect(notification.type, BrowserColumnType.date);
      expect(notification.reverse, isFalse);
    });
  });
}
