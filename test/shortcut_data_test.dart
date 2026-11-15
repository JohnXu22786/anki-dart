/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ShortcutData', () {
    test(
      'projects the host-resolved full name to a source-equivalent payload',
      () {
        final data = ShortcutData(42, 'Science::Math::Algebra');

        expect(data.deckId, 42);
        expect(data.shortLabel, 'Algebra');
        expect(data.longLabel, 'Science::Math::Algebra');

        expect(ShortcutData(43, 'Science::').shortLabel, '');
        expect(ShortcutData(44, '').shortLabel, '');
      },
    );

    test('uses structural equality and hash code for all payload fields', () {
      final first = ShortcutData(42, 'Science::Math');
      final equal = ShortcutData(42, 'Science::Math');

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(ShortcutData(43, 'Science::Math')));
      expect(first, isNot(ShortcutData(42, 'Other::Math')));
    });
  });
}
