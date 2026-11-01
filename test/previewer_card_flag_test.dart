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
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('previewerCardFlag', () {
    test('resolves every source flag code', () {
      for (var code = 0; code <= 7; code++) {
        expect(previewerCardFlag(() => code), PreviewerFlag.values[code]);
      }
    });

    test('calls userFlag exactly once', () {
      var calls = 0;

      final result = previewerCardFlag(() {
        calls++;
        return 3;
      });

      expect(result, PreviewerFlag.green);
      expect(calls, 1);
    });

    test('propagates the userFlag exception unchanged', () {
      final failure = StateError('card flag unavailable');

      expect(
        () => previewerCardFlag(() => throw failure),
        throwsA(same(failure)),
      );
    });

    test('preserves unknown-code lookup failure', () {
      expect(() => previewerCardFlag(() => 8), throwsA(isA<StateError>()));
    });
  });
}
