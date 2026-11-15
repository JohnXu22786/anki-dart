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
  group('collectionReplaceInSearchNode', () {
    test(
      'forwards the exact nodes once in role order and returns the result',
      () {
        final existing = Object();
        final replacement = Object();
        const result = 'backend replacement result';
        final events = <String>[];
        Object? actualExisting;
        Object? actualReplacement;

        final actual = collectionReplaceInSearchNode<Object>(
          existingNode: existing,
          replacementNode: replacement,
          replaceSearchNode:
              ({required existingNode, required replacementNode}) {
                events.add('backend');
                actualExisting = existingNode;
                actualReplacement = replacementNode;
                return result;
              },
        );

        expect(events, ['backend']);
        expect(identical(actualExisting, existing), isTrue);
        expect(identical(actualReplacement, replacement), isTrue);
        expect(actual, same(result));
      },
    );

    test('propagates backend failure unchanged', () {
      final failure = StateError('backend replace failed');
      var backendCalls = 0;

      expect(
        () => collectionReplaceInSearchNode<Object>(
          existingNode: Object(),
          replacementNode: Object(),
          replaceSearchNode:
              ({required existingNode, required replacementNode}) {
                backendCalls++;
                throw failure;
              },
        ),
        throwsA(same(failure)),
      );
      expect(backendCalls, 1);
    });
  });
}
