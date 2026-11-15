/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Card description', () {
    test('uses host field order and exact field formatting', () {
      final objectValue = Object();
      final readNames = <String>[];
      final description = libankiCardDescription(
        declaredFieldNames: ['zeta', 'alpha'],
        readField: (name) {
          readNames.add(name);
          return name == 'zeta' ? objectValue : 'last';
        },
        stringifyValue: (value) =>
            value == objectValue ? 'host-object' : '$value',
        isReflectionFailure: (_) => false,
      );

      expect(description, "'zeta': host-object,  'alpha': last");
      expect(readNames, ['zeta', 'alpha']);
    });

    test('does not read any name in the full skip set', () {
      const skipped = [
        'Companion',
        'SKIP_PRINT',
        r'$assertionsDisabled',
        'note',
        'renderOutput',
        'timerStarted',
        'col',
      ];
      final readNames = <String>[];
      final description = libankiCardDescription(
        declaredFieldNames: skipped,
        readField: (name) {
          readNames.add(name);
          return name;
        },
        stringifyValue: (value) => '$value',
        isReflectionFailure: (_) => false,
      );

      expect(description, isEmpty);
      expect(readNames, isEmpty);
    });

    test('uses N/A for IllegalAccessException', () {
      final failure = _IllegalAccessFailure();
      final description = libankiCardDescription(
        declaredFieldNames: ['privateField'],
        readField: (_) => throw failure,
        stringifyValue: (value) => '$value',
        isReflectionFailure: (error) => error is _IllegalAccessFailure,
      );

      expect(description, "'privateField': N/A");
    });

    test('uses N/A for IllegalArgumentException', () {
      final failure = _IllegalArgumentFailure();
      final description = libankiCardDescription(
        declaredFieldNames: ['mismatchedField'],
        readField: (_) => throw failure,
        stringifyValue: (value) => '$value',
        isReflectionFailure: (error) => error is _IllegalArgumentFailure,
      );

      expect(description, "'mismatchedField': N/A");
    });

    test('propagates errors outside the two reflection failure categories', () {
      final failure = StateError('unrelated');
      expect(
        () => libankiCardDescription(
          declaredFieldNames: ['field'],
          readField: (_) => throw failure,
          stringifyValue: (value) => '$value',
          isReflectionFailure: (_) => false,
        ),
        throwsA(same(failure)),
      );
    });
  });
}

final class _IllegalAccessFailure implements Exception {}

final class _IllegalArgumentFailure implements Exception {}
