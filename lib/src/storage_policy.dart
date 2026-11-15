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
 * Adapted from StoragePolicy.kt and AnkiDroidFolder.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Where AnkiDroid stores its collection.
enum AnkiDroidFolder {
  /// The `~/AnkiDroid` folder, which is retained after uninstall.
  PUBLIC,

  /// The app-private `.../files/AnkiDroid` folder, which may be removed on uninstall.
  APP_PRIVATE;

  @override
  String toString() => name;
}

/// How the host selects a collection folder on a fresh install.
sealed class StoragePolicy {
  const StoragePolicy();
}

/// A policy where only one folder is possible.
final class Fixed extends StoragePolicy {
  const Fixed(this.folder);

  final AnkiDroidFolder folder;

  @override
  String toString() => 'Fixed(folder=$folder)';

  @override
  bool operator ==(Object other) => other is Fixed && other.folder == folder;

  @override
  int get hashCode => folder.hashCode;
}

/// A policy where the user chooses on the permission screen.
final class UserChoosesOnPermissionScreen extends StoragePolicy {
  const UserChoosesOnPermissionScreen();

  @override
  String toString() => 'UserChoosesOnPermissionScreen';

  @override
  bool operator ==(Object other) => other is UserChoosesOnPermissionScreen;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The folder to persist on startup, or `null` while the user has yet to choose.
extension StoragePolicyFolderToPersist on StoragePolicy {
  AnkiDroidFolder? folderToPersist({required bool hasRequiredPermissions}) =>
      switch (this) {
        Fixed(:final folder) => folder,
        UserChoosesOnPermissionScreen() =>
          hasRequiredPermissions ? AnkiDroidFolder.PUBLIC : null,
      };
}
