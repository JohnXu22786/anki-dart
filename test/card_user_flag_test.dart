/*
 * Copyright (c) 2009 Daniel Svärd daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold norbert.nagold@gmail.com>
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
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardUserFlag', () {
    test('returns only the low three bits for every flag code', () {
      for (final higherBits in [0x123450, -0x123450]) {
        for (var flag = 0; flag <= 7; flag++) {
          expect(cardUserFlag(higherBits | flag), flag);
        }
      }
    });
  });

  group('setFlagInInt', () {
    test('sets each low-three-bit value while preserving higher bits', () {
      for (final higherBits in [0x123450, -0x123450]) {
        for (var flag = 0; flag <= 7; flag++) {
          final flags = higherBits | (7 - flag);

          expect(setFlagInInt(flags, flag), (flags & ~7) | flag);
        }
      }
    });

    test(
      'rejects values outside the source interval with the source message',
      () {
        for (final flag in [-1, 8]) {
          expect(
            () => setFlagInInt(0, flag),
            throwsA(
              isA<ArgumentError>().having(
                (error) => error.message,
                'message',
                'flag outside of expected [0, 7] interval',
              ),
            ),
          );
        }
      },
    );
  });
}
