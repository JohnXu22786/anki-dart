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
 * Source-derived from ProfileName.kt and ProfileNameTest.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileName', () {
    test('trims Kotlin whitespace but preserves interior whitespace', () {
      expect(ProfileName.validate(''), isA<ProfileNameEmpty>());
      expect(ProfileName.validate('\t\n  '), isA<ProfileNameEmpty>());
      expect(
        ProfileName.validate('\u00a0\u202fA  B\u3000'),
        isA<ProfileNameValid>(),
      );
      final result = ProfileName.validate('  Ashish    Yadav  ');
      expect(result, isA<ProfileNameValid>());
      expect((result as ProfileNameValid).name.value, 'Ashish    Yadav');
    });

    test(
      'accepts MAX_LENGTH UTF-16 units and reports trimmed actual length',
      () {
        final name = 'a' * 50;
        expect(ProfileName.maxLength, 50);
        expect(
          (ProfileName.validate(name) as ProfileNameValid).name.value,
          name,
        );
        expect(
          ProfileName.validate('  ${'a' * 49}😀  '),
          isA<ProfileNameTooLong>(),
        );
        final tooLong =
            ProfileName.validate('  ${'a' * 49}😀  ') as ProfileNameTooLong;
        expect(tooLong.actualLength, 51);
      },
    );

    test('accepts and preserves arbitrary interior characters', () {
      for (final name in [
        '日本語',
        'José',
        'user_1-profile',
        'Bob!@#',
        'Ashish 🎉',
      ]) {
        final result = ProfileName.validate(name);
        expect(result, isA<ProfileNameValid>());
        expect((result as ProfileNameValid).name.value, name);
      }
    });

    test(
      'trusted-source construction does not trim or validate persisted text',
      () {
        const persisted = '  weird!! value  ';
        final name = ProfileName.fromTrustedSource(persisted);
        expect(name.value, persisted);
        expect(name.toString(), persisted);
      },
    );
  });
}
