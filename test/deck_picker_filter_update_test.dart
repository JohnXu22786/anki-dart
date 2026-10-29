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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectDeckPickerFilterUpdate', () {
    test('builds a fresh filter from the exact supplied query each time', () {
      const filterText = 'u o::ba';

      final first = projectDeckPickerFilterUpdate(filterText);
      final second = projectDeckPickerFilterUpdate(filterText);

      expect(identical(first, second), isFalse);
      expect(first.accept('foo::bar::buz'), isTrue);
      expect(second.accept('foo::bar::buz'), isTrue);
    });

    test('passes through host locale configuration', () {
      final filter = projectDeckPickerFilterUpdate('I', localeName: 'tr_TR');

      expect(filter.accept('ı'), isFalse);
      expect(filter.accept('i'), isTrue);
    });
  });
}
