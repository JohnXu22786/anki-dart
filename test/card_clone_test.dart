/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Card clone', () {
    test('returns the exact host clone and invokes cloning once', () {
      final clone = _HostCard();
      var cloneCalls = 0;
      var castCalls = 0;

      final result = libankiCardClone<_HostCard>(
        shallowClone: () {
          cloneCalls++;
          return clone;
        },
        castToCard: (value) {
          castCalls++;
          return value as _HostCard;
        },
        isCloneNotSupportedException: (_) => false,
        runtimeException: _HostRuntimeException.new,
      );

      expect(result, same(clone));
      expect(cloneCalls, 1);
      expect(castCalls, 1);
    });

    test('wraps only CloneNotSupportedException with the exact cause', () {
      final failure = _CloneNotSupportedException();
      final wrappers = <_HostRuntimeException>[];
      final classified = <Object>[];

      expect(
        () => libankiCardClone<_HostCard>(
          shallowClone: () => throw failure,
          castToCard: (value) => value as _HostCard,
          isCloneNotSupportedException: (error) {
            classified.add(error);
            return error is _CloneNotSupportedException;
          },
          runtimeException: (cause) {
            final wrapper = _HostRuntimeException(cause);
            wrappers.add(wrapper);
            return wrapper;
          },
        ),
        throwsA(isA<_HostRuntimeException>()),
      );

      expect(classified, [same(failure)]);
      expect(wrappers, hasLength(1));
      expect(wrappers.single.cause, same(failure));
    });

    test('propagates unrelated clone failures unchanged', () {
      final failure = StateError('clone failed');
      var wrapperCalls = 0;

      expect(
        () => libankiCardClone<_HostCard>(
          shallowClone: () => throw failure,
          castToCard: (value) => value as _HostCard,
          isCloneNotSupportedException: (error) =>
              error is _CloneNotSupportedException,
          runtimeException: (cause) {
            wrapperCalls++;
            return _HostRuntimeException(cause);
          },
        ),
        throwsA(same(failure)),
      );
      expect(wrapperCalls, 0);
    });

    test('propagates Card cast failures unchanged', () {
      final failure = StateError('wrong host clone type');
      var wrapperCalls = 0;

      expect(
        () => libankiCardClone<_HostCard>(
          shallowClone: Object.new,
          castToCard: (_) => throw failure,
          isCloneNotSupportedException: (error) =>
              error is _CloneNotSupportedException,
          runtimeException: (cause) {
            wrapperCalls++;
            return _HostRuntimeException(cause);
          },
        ),
        throwsA(same(failure)),
      );
      expect(wrapperCalls, 0);
    });
  });
}

final class _HostCard {}

final class _CloneNotSupportedException implements Exception {}

final class _HostRuntimeException implements Exception {
  _HostRuntimeException(this.cause);

  final Object cause;
}
