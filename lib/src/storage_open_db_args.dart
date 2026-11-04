/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from Storage.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callback for the `File.exists()` read used by [OpenDbPath].
typedef OpenDbFileExists = bool Function(Object path);

/// Host callback for the `File.absolutePath` read used by [OpenDbPath].
typedef OpenDbFileAbsolutePath = String Function(Object path);

/// Arguments for opening either a file-backed or in-memory collection.
sealed class OpenDbArgs {
  const OpenDbArgs();

  /// Whether the collection database does not yet exist.
  bool isNewDatabase();

  /// The path passed to the collection backend.
  String get collectionPath;
}

/// File-backed arguments, retaining the opaque host file as the value component.
final class OpenDbPath extends OpenDbArgs {
  const OpenDbPath(
    this.path, {
    required this.exists,
    required this.absolutePath,
  });

  /// The host's opaque File value.
  final Object path;

  /// Reads whether [path] exists in the host filesystem.
  final OpenDbFileExists exists;

  /// Reads the host's absolute path without Dart-side normalization.
  final OpenDbFileAbsolutePath absolutePath;

  /// Copies this data value, retaining its host callbacks when [path] is omitted.
  OpenDbPath copyWith({Object? path}) =>
      OpenDbPath(path ?? this.path, exists: exists, absolutePath: absolutePath);

  @override
  bool isNewDatabase() => !exists(path);

  @override
  String get collectionPath => absolutePath(path);

  @override
  bool operator ==(Object other) => other is OpenDbPath && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// Canonical arguments for an in-memory collection.
final class OpenDbInMemory extends OpenDbArgs {
  const OpenDbInMemory._();

  /// The sole in-memory variant, matching Kotlin's `data object`.
  static const instance = OpenDbInMemory._();

  @override
  bool isNewDatabase() => true;

  @override
  String get collectionPath => ':memory:';
}
