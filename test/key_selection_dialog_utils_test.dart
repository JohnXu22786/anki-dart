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
 * Source-derived from KeySelectionDialogUtils.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('disallowModifierKeyCodes', () {
    test('rejects every supplied modifier code and allows other integers', () {
      const modifiers = {59, 60, 113, 114, 57, 58, 117, 118, 119};
      final isAllowed = disallowModifierKeyCodes(modifiers);

      for (final code in modifiers) {
        expect(isAllowed(code), isFalse, reason: 'modifier code $code');
      }
      expect(isAllowed(42), isTrue);
      expect(isAllowed(-1), isTrue);
      expect(isAllowed(10000), isTrue);
    });

    test('uses a snapshot taken when the predicate is created', () {
      final modifiers = {59};
      final isAllowed = disallowModifierKeyCodes(modifiers);

      modifiers
        ..remove(59)
        ..add(60);

      expect(isAllowed(59), isFalse);
      expect(isAllowed(60), isTrue);
    });

    test('factory calls capture independent snapshots', () {
      final modifiers = {59};
      final first = disallowModifierKeyCodes(modifiers);

      modifiers
        ..remove(59)
        ..add(60);
      final second = disallowModifierKeyCodes(modifiers);

      expect(first(59), isFalse);
      expect(first(60), isTrue);
      expect(second(59), isTrue);
      expect(second(60), isFalse);
    });
  });
}
