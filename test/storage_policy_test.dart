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
 * Source-derived from StoragePolicyTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('StoragePolicy', () {
    test(
      'fixed folders are persisted with or without required permissions',
      () {
        for (final folder in AnkiDroidFolder.values) {
          final policy = Fixed(folder);
          expect(policy.folderToPersist(hasRequiredPermissions: true), folder);
          expect(policy.folderToPersist(hasRequiredPermissions: false), folder);
        }
      },
    );

    test('user choice is deferred until required permissions are granted', () {
      const policy = UserChoosesOnPermissionScreen();
      expect(
        policy.folderToPersist(hasRequiredPermissions: true),
        AnkiDroidFolder.PUBLIC,
      );
      expect(policy.folderToPersist(hasRequiredPermissions: false), isNull);
    });

    test(
      'folder and policy variants preserve value equality and string forms',
      () {
        expect(AnkiDroidFolder.values.map((folder) => folder.toString()), [
          'PUBLIC',
          'APP_PRIVATE',
        ]);
        expect(Fixed(AnkiDroidFolder.PUBLIC), Fixed(AnkiDroidFolder.PUBLIC));
        expect(
          Fixed(AnkiDroidFolder.PUBLIC).toString(),
          'Fixed(folder=PUBLIC)',
        );
        expect(
          const UserChoosesOnPermissionScreen(),
          const UserChoosesOnPermissionScreen(),
        );
        expect(
          const UserChoosesOnPermissionScreen().toString(),
          'UserChoosesOnPermissionScreen',
        );
      },
    );
  });
}
