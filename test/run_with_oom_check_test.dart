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
 * Source-derived from Exceptions.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('runWithOomCheck', () {
    test('returns the identical successful result without classifying', () {
      final resultToken = Object();
      var actionCalls = 0;
      var classifierCalls = 0;

      final result = runWithOomCheck<Object>(
        action: () {
          actionCalls++;
          return resultToken;
        },
        isOutOfMemoryError: (_) {
          classifierCalls++;
          return false;
        },
        onError: (_) => fail('unexpected error handler'),
      );

      expect(identical(result, resultToken), isTrue);
      expect(actionCalls, 1);
      expect(classifierCalls, 0);
    });

    test('handles a classified OOM once and returns null in order', () {
      final oom = _HostOomFailure();
      final receivedErrors = <Object>[];
      final events = <String>[];

      final result = runWithOomCheck<Object>(
        action: () {
          events.add('action');
          throw oom;
        },
        isOutOfMemoryError: (error) {
          events.add('classify:${identical(error, oom)}');
          return identical(error, oom);
        },
        onError: (error) {
          events.add('onError:${identical(error, oom)}');
          receivedErrors.add(error);
        },
      );

      expect(result, isNull);
      expect(events, ['action', 'classify:true', 'onError:true']);
      expect(receivedErrors, hasLength(1));
      expect(identical(receivedErrors.single, oom), isTrue);

      final noHandlerResult = runWithOomCheck<Object>(
        action: () => throw oom,
        isOutOfMemoryError: (error) => identical(error, oom),
      );

      expect(noHandlerResult, isNull);
    });

    test('rethrows non-OOM objects unchanged without calling the handler', () {
      final failure = StateError('not OOM');
      var handlerCalls = 0;
      var classifierCalls = 0;

      expect(
        () => runWithOomCheck<Object>(
          action: () => throw failure,
          isOutOfMemoryError: (_) {
            classifierCalls++;
            return false;
          },
          onError: (_) => handlerCalls++,
        ),
        throwsA(same(failure)),
      );
      expect(classifierCalls, 1);
      expect(handlerCalls, 0);
    });

    test('propagates a handler failure unchanged', () {
      final oom = _HostOomFailure();
      final handlerFailure = StateError('handler failed');
      var handlerCalls = 0;

      expect(
        () => runWithOomCheck<Object>(
          action: () => throw oom,
          isOutOfMemoryError: (error) => identical(error, oom),
          onError: (_) {
            handlerCalls++;
            throw handlerFailure;
          },
        ),
        throwsA(same(handlerFailure)),
      );
      expect(handlerCalls, 1);
    });

    test('propagates classifier failures without treating them as OOM', () {
      final actionFailure = StateError('action failed');
      final classifierFailure = StateError('classifier failed');
      var classifierCalls = 0;
      var handlerCalls = 0;

      expect(
        () => runWithOomCheck<Object>(
          action: () => throw actionFailure,
          isOutOfMemoryError: (_) {
            classifierCalls++;
            throw classifierFailure;
          },
          onError: (_) => handlerCalls++,
        ),
        throwsA(same(classifierFailure)),
      );
      expect(classifierCalls, 1);
      expect(handlerCalls, 0);
    });
  });
}

class _HostOomFailure extends Error {}
