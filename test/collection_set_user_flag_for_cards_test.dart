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
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionSetUserFlagForCards', () {
    test('forwards every PreviewerFlag code unchanged', () {
      for (final flag in PreviewerFlag.values) {
        int? forwardedCode;

        collectionSetUserFlagForCards<int, void>(
          const [7, 11],
          flag,
          (_, code) => forwardedCode = code,
        );

        expect(forwardedCode, flag.code);
      }
    });

    test('passes the identical iterable without accessing its iterator', () {
      final cardIds = _TrackingIterable([3, 5]);
      Iterable<int>? forwardedIds;

      collectionSetUserFlagForCards<int, void>(cardIds, PreviewerFlag.green, (
        ids,
        _,
      ) {
        forwardedIds = ids;
      });

      expect(identical(forwardedIds, cardIds), isTrue);
      expect(cardIds.iteratorReads, 0);
    });

    test('invokes the collection callback exactly once', () {
      var calls = 0;

      collectionSetUserFlagForCards<int, void>(
        const [13],
        PreviewerFlag.blue,
        (_, _) => calls++,
      );

      expect(calls, 1);
    });

    test('returns the exact opaque callback result', () {
      final result = Object();

      final actual = collectionSetUserFlagForCards<int, Object>(
        const [17],
        PreviewerFlag.pink,
        (_, _) => result,
      );

      expect(identical(actual, result), isTrue);
    });

    test('propagates the exact callback failure', () {
      final failure = StateError('collection write failed');

      expect(
        () => collectionSetUserFlagForCards<int, Never>(
          const [19],
          PreviewerFlag.turquoise,
          (_, _) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}

final class _TrackingIterable extends Iterable<int> {
  _TrackingIterable(this.values);

  final List<int> values;
  var iteratorReads = 0;

  @override
  Iterator<int> get iterator {
    iteratorReads++;
    return values.iterator;
  }
}
