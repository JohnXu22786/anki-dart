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
 * Source-derived from CombinedException.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CombinedExceptionProjection', () {
    test('override wins unchanged and suppresses formatting callbacks', () {
      final exception = Object();
      var formatterCalls = 0;
      final projection = CombinedExceptionProjection.create<Object>(
        exceptions: [exception],
        messageOverride: '',
        messageFormatter: (_, _) {
          formatterCalls++;
          return 'formatted';
        },
        messageOf: (_) => fail('override must suppress message lookup'),
        simpleNameOf: (_) => fail('override must suppress name lookup'),
      );

      expect(projection.message, isEmpty);
      expect(projection.exceptions, [same(exception)]);
      expect(formatterCalls, 0);
    });

    test(
      'formatter receives source-order indexes exactly once and joins lines',
      () {
        final first = Object();
        final second = Object();
        final calls = <(int, Object)>[];
        final projection = CombinedExceptionProjection.create<Object>(
          exceptions: [first, second],
          messageFormatter: (index, exception) {
            calls.add((index, exception));
            return 'item$index';
          },
          messageOf: (_) => fail('formatter takes precedence'),
          simpleNameOf: (_) => fail('formatter takes precedence'),
        );

        expect(projection.message, 'item0\nitem1');
        expect(calls, [(0, first), (1, second)]);
        expect(projection.exceptions, [same(first), same(second)]);
      },
    );

    test(
      'default message falls back only for null and preserves empty strings',
      () {
        final first = Object();
        final second = Object();
        final third = Object();
        final nameCalls = <Object>[];
        final projection = CombinedExceptionProjection.create<Object>(
          exceptions: [first, second, third],
          messageOf: (exception) => switch (exception) {
            final e when identical(e, first) => null,
            final e when identical(e, second) => '',
            _ => 'body',
          },
          simpleNameOf: (exception) {
            nameCalls.add(exception);
            return 'FirstType';
          },
        );

        expect(projection.message, 'FirstType\n\nbody');
        expect(nameCalls, [same(first)]);
      },
    );

    test('empty exception collections produce an empty message', () {
      expect(
        CombinedExceptionProjection.create<Object>(
          exceptions: const [],
          messageFormatter: (_, _) => fail('no elements to format'),
          messageOf: (_) => fail('no elements to inspect'),
          simpleNameOf: (_) => fail('no elements to inspect'),
        ).message,
        isEmpty,
      );
      expect(
        CombinedExceptionProjection.create<Object>(
          exceptions: const [],
          messageOf: (_) => fail('no elements to inspect'),
          simpleNameOf: (_) => fail('no elements to inspect'),
        ).message,
        isEmpty,
      );
    });

    test('from returns null for empty values', () {
      expect(CombinedExceptionProjection.from<Object>([]), isNull);
    });

    test(
      'from preserves exception order and labels including empty labels',
      () {
        final first = Object();
        final second = Object();
        final third = Object();
        final projection = CombinedExceptionProjection.from<Object>([
          ('first', first),
          ('', second),
          ('third', third),
        ])!;

        expect(projection.message, 'first\n\nthird');
        expect(projection.exceptions, [same(first), same(second), same(third)]);
      },
    );

    test('formatter failures propagate and prevent later callbacks', () {
      final first = Object();
      final second = Object();
      final failure = StateError('formatter failed');
      final calls = <int>[];

      expect(
        () => CombinedExceptionProjection.create<Object>(
          exceptions: [first, second],
          messageFormatter: (index, _) {
            calls.add(index);
            if (index == 0) throw failure;
            return 'unreachable';
          },
          messageOf: (_) => fail('formatter takes precedence'),
          simpleNameOf: (_) => fail('formatter takes precedence'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, [0]);
    });
  });
}
