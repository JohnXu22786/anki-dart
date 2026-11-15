/*
 * Copyright (c) 2011 Kostas Spyropoulos <inigo.aldana@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Media.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Media.escapeMediaFilenames', () {
    test(
      'defaults to encoding and preserves the input and result references',
      () {
        final input = String.fromCharCodes([
          0x66,
          0x6f,
          0x6f,
          0x20,
          0x62,
          0x61,
          0x72,
        ]);
        final encoded = String.fromCharCodes([
          0x66,
          0x6f,
          0x6f,
          0x25,
          0x32,
          0x30,
          0x62,
          0x61,
          0x72,
        ]);
        var encodeCalls = 0;
        var decodeCalls = 0;

        final result = Media.escapeMediaFilenames(
          input,
          encodeIriPaths: (value) {
            encodeCalls++;
            expect(identical(value, input), isTrue);
            return encoded;
          },
          decodeIriPaths: (_) {
            decodeCalls++;
            return 'decoded';
          },
        );

        expect(encodeCalls, 1);
        expect(decodeCalls, 0);
        expect(identical(result, encoded), isTrue);
      },
    );

    test('explicit false selects encoding exactly once', () {
      const input = 'foo bar';
      const encoded = 'foo%20bar';
      var encodeCalls = 0;
      var decodeCalls = 0;

      final result = Media.escapeMediaFilenames(
        input,
        unescape: false,
        encodeIriPaths: (value) {
          encodeCalls++;
          expect(identical(value, input), isTrue);
          return encoded;
        },
        decodeIriPaths: (_) {
          decodeCalls++;
          return 'decoded';
        },
      );

      expect(result, encoded);
      expect(encodeCalls, 1);
      expect(decodeCalls, 0);
    });

    test('explicit true selects decoding and preserves references', () {
      final input = String.fromCharCodes([
        0x66,
        0x6f,
        0x6f,
        0x25,
        0x32,
        0x30,
        0x62,
        0x61,
        0x72,
      ]);
      final decoded = String.fromCharCodes([
        0x66,
        0x6f,
        0x6f,
        0x20,
        0x62,
        0x61,
        0x72,
      ]);
      var encodeCalls = 0;
      var decodeCalls = 0;

      final result = Media.escapeMediaFilenames(
        input,
        unescape: true,
        encodeIriPaths: (_) {
          encodeCalls++;
          return 'encoded';
        },
        decodeIriPaths: (value) {
          decodeCalls++;
          expect(identical(value, input), isTrue);
          return decoded;
        },
      );

      expect(encodeCalls, 0);
      expect(decodeCalls, 1);
      expect(identical(result, decoded), isTrue);
    });

    test('propagates the selected callback error object unchanged', () {
      final encodeError = StateError('encode failed');
      var decodeCalls = 0;
      expect(
        () => Media.escapeMediaFilenames(
          'input',
          encodeIriPaths: (_) => throw encodeError,
          decodeIriPaths: (_) {
            decodeCalls++;
            return 'decoded';
          },
        ),
        throwsA(same(encodeError)),
      );
      expect(decodeCalls, 0);

      final decodeError = StateError('decode failed');
      var encodeCalls = 0;
      expect(
        () => Media.escapeMediaFilenames(
          'input',
          unescape: true,
          encodeIriPaths: (_) {
            encodeCalls++;
            return 'encoded';
          },
          decodeIriPaths: (_) => throw decodeError,
        ),
        throwsA(same(decodeError)),
      );
      expect(encodeCalls, 0);
    });
  });
}
