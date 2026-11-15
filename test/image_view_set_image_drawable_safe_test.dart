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
 * Source-derived from ImageView.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('imageViewSetImageDrawableSafe', () {
    test('sets the identical drawable once and returns true', () {
      final drawable = Object();
      final assigned = <Object?>[];

      final result = imageViewSetImageDrawableSafe<Object, _HostOomFailure>(
        drawable,
        setImageDrawable: assigned.add,
        runWithOomCheck: _runWithHostOomCheck,
      );

      expect(result, isTrue);
      expect(assigned, hasLength(1));
      expect(identical(assigned.single, drawable), isTrue);
    });

    test('host-classified OOM calls onError once then returns false', () {
      final failure = _HostOomFailure();
      final events = <String>[];
      final receivedErrors = <_HostOomFailure>[];

      final result = imageViewSetImageDrawableSafe<Object, _HostOomFailure>(
        null,
        setImageDrawable: (_) {
          events.add('setImageDrawable');
          throw failure;
        },
        runWithOomCheck: (action, {onError}) => _runWithHostOomCheck(
          action,
          onError: (error) {
            events.add('onError');
            onError?.call(error);
          },
        ),
        onError: receivedErrors.add,
      );

      expect(result, isFalse);
      expect(events, ['setImageDrawable', 'onError']);
      expect(receivedErrors, hasLength(1));
      expect(identical(receivedErrors.single, failure), isTrue);
    });

    test('propagates non-OOM setter failures without calling onError', () {
      final failure = StateError('setter failed');
      var errorCalls = 0;

      expect(
        () => imageViewSetImageDrawableSafe<Object, _HostOomFailure>(
          null,
          setImageDrawable: (_) => throw failure,
          runWithOomCheck: _runWithHostOomCheck,
          onError: (_) => errorCalls++,
        ),
        throwsA(same(failure)),
      );
      expect(errorCalls, 0);
    });

    test('propagates an onError failure unchanged', () {
      final oomFailure = _HostOomFailure();
      final handlerFailure = StateError('handler failed');

      expect(
        () => imageViewSetImageDrawableSafe<Object, _HostOomFailure>(
          null,
          setImageDrawable: (_) => throw oomFailure,
          runWithOomCheck: _runWithHostOomCheck,
          onError: (_) => throw handlerFailure,
        ),
        throwsA(same(handlerFailure)),
      );
    });
  });
}

class _HostOomFailure extends Error {}

bool? _runWithHostOomCheck(
  bool Function() action, {
  void Function(_HostOomFailure error)? onError,
}) {
  try {
    return action();
  } on _HostOomFailure catch (error) {
    onError?.call(error);
    return null;
  }
}
