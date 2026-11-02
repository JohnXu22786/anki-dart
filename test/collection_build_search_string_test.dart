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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionBuildSearchString', () {
    test('passes one identical node in source order', () {
      final node = Object();
      List<Object>? forwardedNodes;

      collectionBuildSearchString<Object>(node, (nodes) {
        forwardedNodes = nodes;
        return 'query';
      });

      expect(forwardedNodes, hasLength(1));
      expect(identical(forwardedNodes!.single, node), isTrue);
    });

    test('passes an unmodifiable singleton list', () {
      final node = Object();

      expect(
        () => collectionBuildSearchString<Object>(node, (nodes) {
          nodes.add(Object());
          return 'unreachable';
        }),
        throwsUnsupportedError,
      );
    });

    test('invokes the collection callback exactly once', () {
      var calls = 0;

      collectionBuildSearchString<Object>(Object(), (nodes) {
        calls++;
        return 'query';
      });

      expect(calls, 1);
    });

    test('returns the exact collection result', () {
      const result = 'backend search string';

      final actual = collectionBuildSearchString<Object>(
        Object(),
        (_) => result,
      );

      expect(actual, same(result));
    });

    test('propagates the exact collection failure', () {
      final failure = StateError('collection search failed');

      expect(
        () =>
            collectionBuildSearchString<Object>(Object(), (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });
}
