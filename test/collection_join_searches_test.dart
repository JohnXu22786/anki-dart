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
  group('collectionJoinSearches', () {
    test(
      'converts first, forwards both nodes once, and returns backend result',
      () {
        final existing = Object();
        final additional = Object();
        const result = 'backend joined search';
        final events = <String>[];
        Object? actualExisting;
        Object? actualAdditional;
        String? actualSeparator;

        final actual = collectionJoinSearches<Object, String, String>(
          existingNode: existing,
          additionalNode: additional,
          operator: 'OR',
          toBackendSeparator: (operator) {
            events.add('convert:$operator');
            return '|';
          },
          joinSearchNodes:
              ({
                required joiner,
                required existingNode,
                required additionalNode,
              }) {
                events.add('backend');
                actualSeparator = joiner;
                actualExisting = existingNode;
                actualAdditional = additionalNode;
                return result;
              },
        );

        expect(events, ['convert:OR', 'backend']);
        expect(actualSeparator, '|');
        expect(identical(actualExisting, existing), isTrue);
        expect(identical(actualAdditional, additional), isTrue);
        expect(actual, same(result));
      },
    );

    test('propagates separator conversion failure before backend callback', () {
      final failure = StateError('separator conversion failed');
      var backendCalls = 0;

      expect(
        () => collectionJoinSearches<Object, String, String>(
          existingNode: Object(),
          additionalNode: Object(),
          operator: 'OR',
          toBackendSeparator: (_) => throw failure,
          joinSearchNodes:
              ({
                required joiner,
                required existingNode,
                required additionalNode,
              }) {
                backendCalls++;
                return 'unreachable';
              },
        ),
        throwsA(same(failure)),
      );
      expect(backendCalls, 0);
    });

    test('propagates backend failure unchanged after conversion', () {
      final failure = StateError('backend join failed');
      final events = <String>[];

      expect(
        () => collectionJoinSearches<Object, String, String>(
          existingNode: Object(),
          additionalNode: Object(),
          operator: 'OR',
          toBackendSeparator: (_) {
            events.add('convert');
            return '|';
          },
          joinSearchNodes:
              ({
                required joiner,
                required existingNode,
                required additionalNode,
              }) {
                events.add('backend');
                throw failure;
              },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['convert', 'backend']);
    });
  });
}
