/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionAddCustomUndoEntry', () {
    test('forwards the exact name once and returns the host step counter', () {
      final name = 'custom undo entry';
      String? forwardedName;
      var calls = 0;

      final result = collectionAddCustomUndoEntry(name, (value) {
        calls++;
        forwardedName = value;
        return 2147483648;
      });

      expect(calls, 1);
      expect(identical(forwardedName, name), isTrue);
      expect(result, 2147483648);
    });

    test('propagates the exact host failure', () {
      final failure = StateError('custom undo entry failed');

      expect(
        () => collectionAddCustomUndoEntry('custom', (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });

  group('collectionMergeUndoEntries', () {
    test(
      'forwards the exact target once and returns the generic host value',
      () {
        const target = 4294967296;
        var forwardedTarget = -1;
        var calls = 0;
        final hostChanges = <Object>[Object()];

        final result = collectionMergeUndoEntries<List<Object>>(target, (
          value,
        ) {
          calls++;
          forwardedTarget = value;
          return hostChanges;
        });

        expect(calls, 1);
        expect(forwardedTarget, target);
        expect(identical(result, hostChanges), isTrue);
      },
    );

    test('propagates the exact host failure', () {
      final failure = StateError('undo entries could not be merged');

      expect(
        () => collectionMergeUndoEntries<Object>(31, (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });
}
