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
 * Source-derived from NonLeadingZeroInputFilter.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('nonLeadingZeroInputFilter', () {
    test('insertion evaluates the destination after replacement', () {
      expect(
        nonLeadingZeroInputFilter(
          source: '0',
          start: 0,
          end: 1,
          destination: '2',
          destinationStart: 0,
          destinationEnd: 0,
        ),
        '',
      );
      expect(
        nonLeadingZeroInputFilter(
          source: '0',
          start: 0,
          end: 1,
          destination: '2',
          destinationStart: 1,
          destinationEnd: 1,
        ),
        isNull,
      );
    });

    test('replacement honors both source and destination boundaries', () {
      expect(
        nonLeadingZeroInputFilter(
          source: 'x0y',
          start: 1,
          end: 2,
          destination: '12',
          destinationStart: 0,
          destinationEnd: 1,
        ),
        '',
      );
      expect(
        nonLeadingZeroInputFilter(
          source: 'x9y',
          start: 1,
          end: 2,
          destination: '01',
          destinationStart: 0,
          destinationEnd: 1,
        ),
        isNull,
      );
    });

    test('deletion checks the remaining destination', () {
      expect(
        nonLeadingZeroInputFilter(
          source: '',
          start: 0,
          end: 0,
          destination: '012',
          destinationStart: 0,
          destinationEnd: 1,
        ),
        isNull,
      );
      expect(
        nonLeadingZeroInputFilter(
          source: '',
          start: 0,
          end: 0,
          destination: '012',
          destinationStart: 2,
          destinationEnd: 3,
        ),
        '',
      );
      expect(
        nonLeadingZeroInputFilter(
          source: '',
          start: 0,
          end: 0,
          destination: '0',
          destinationStart: 0,
          destinationEnd: 1,
        ),
        isNull,
      );
    });

    test(
      'only a multi-code-unit result with leading ASCII zero is rejected',
      () {
        for (final destination in ['', '0', '1', '00', '0.5', '01']) {
          final result = nonLeadingZeroInputFilter(
            source: '',
            start: 0,
            end: 0,
            destination: destination,
            destinationStart: 0,
            destinationEnd: 0,
          );
          expect(
            result,
            destination.length > 1 && destination.startsWith('0') ? '' : isNull,
          );
        }
      },
    );

    test('source and destination offsets use Dart UTF-16 string indices', () {
      expect(
        nonLeadingZeroInputFilter(
          source: '😀0x',
          start: 2,
          end: 3,
          destination: '1',
          destinationStart: 1,
          destinationEnd: 1,
        ),
        isNull,
      );
    });
  });
}
