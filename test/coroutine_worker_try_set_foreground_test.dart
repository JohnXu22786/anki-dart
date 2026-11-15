/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
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
 * Source-derived from CoroutineWorker.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('coroutineWorkerTrySetForeground', () {
    test('awaits the foreground callback once and returns normally', () async {
      final foregroundInfo = Object();
      final events = <String>[];
      final foreground = Completer<void>();

      final result = coroutineWorkerTrySetForeground(
        foregroundInfo: foregroundInfo,
        setForeground: (info) {
          events.add('foreground:${identical(info, foregroundInfo)}');
          return foreground.future;
        },
        warn: (_) => fail('unexpected warning'),
      );

      expect(events, ['foreground:true']);
      foreground.complete();
      await expectLater(result, completes);
      expect(events, ['foreground:true']);
    });

    test(
      'warns after the failed callback with the identical error object',
      () async {
        final foregroundInfo = Object();
        final failure = StateError('foreground failed');
        final events = <String>[];

        await coroutineWorkerTrySetForeground(
          foregroundInfo: foregroundInfo,
          setForeground: (info) async {
            events.add('foreground:${identical(info, foregroundInfo)}');
            throw failure;
          },
          warn: (error) {
            events.add('warn:${identical(error, failure)}');
          },
        );

        expect(events, ['foreground:true', 'warn:true']);
      },
    );

    test('catches a broad Error, warns once, and swallows it', () async {
      final failure = AssertionError('foreground assertion failed');
      final warnings = <Object>[];
      var calls = 0;

      await expectLater(
        coroutineWorkerTrySetForeground(
          foregroundInfo: Object(),
          setForeground: (_) async {
            calls++;
            throw failure;
          },
          warn: warnings.add,
        ),
        completes,
      );

      expect(calls, 1);
      expect(warnings, [same(failure)]);
    });

    test('propagates warning callback failure unchanged', () async {
      final failure = StateError('foreground failed');
      final warningFailure = StateError('warning failed');
      final events = <String>[];

      await expectLater(
        coroutineWorkerTrySetForeground(
          foregroundInfo: Object(),
          setForeground: (_) async {
            events.add('foreground');
            throw failure;
          },
          warn: (error) {
            events.add('warn:${identical(error, failure)}');
            throw warningFailure;
          },
        ),
        throwsA(same(warningFailure)),
      );

      expect(events, ['foreground', 'warn:true']);
    });
  });
}
