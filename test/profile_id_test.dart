/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ProfileId.kt and ProfileIdTest.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileId', () {
    test('default, value, equality, and string conversion are exact', () {
      expect(ProfileId.defaultId.value, 'default');
      expect(ProfileId.defaultId.toString(), 'default');
      expect(ProfileId.defaultId.isDefault, isTrue);
      expect(const ProfileId('default').isDefault, isTrue);
      expect(const ProfileId('p_12345678').isDefault, isFalse);
      expect(const ProfileId('p_12345678'), ProfileId('p_12345678'));
    });

    test('generation uses eight lowercase random hexadecimal digits', () {
      final values = List.generate(1000, (_) => ProfileId.generate().value);
      for (final value in values) {
        expect(value, matches(RegExp(r'^p_[0-9a-f]{8}$')));
      }
      for (var index = 2; index < 10; index++) {
        expect(
          values.map((value) => value[index]).toSet().length,
          greaterThan(1),
        );
      }
    });
  });
}
