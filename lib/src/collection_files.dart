/*
 * Copyright (c) 2025 Arthur Milchior <arthur@milchior.fr>
 * Copyright (c) 2025 David Allison <davidallisongithub@gmail.com>
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
 * SPDX-FileCopyrightText: 2025 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2025 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CollectionFiles.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. Android File and Collection integration remain
 * host-owned.
 */

/// Constructs a host-owned Java File child from its parent and unmodified name.
///
/// The callback owns all path semantics, including platform-specific joining.
typedef CollectionFileChildConstructor =
    Object Function(Object parent, String child);

/// The backing files associated with a disk or in-memory collection.
sealed class CollectionFiles {
  const CollectionFiles();

  /// The collection's media directory, when that collection supports media.
  Object? get mediaFolder;

  /// Returns the disk-based collection or throws for an in-memory collection.
  FolderBasedCollection requireDiskBasedCollection() => switch (this) {
    FolderBasedCollection collection => collection,
    InMemory() || InMemoryWithMedia() => throw UnsupportedOperationException(
      'collection is in-memory',
    ),
  };

  /// Returns the media folder or throws when the collection has no disk path.
  Object requireMediaFolder() => switch (this) {
    InMemory() => throw UnsupportedOperationException(
      'collection is in-memory',
    ),
    FolderBasedCollection(:final mediaFolder) => mediaFolder,
    InMemoryWithMedia(:final mediaFolder) => mediaFolder,
  };
}

/// The conventional on-disk collection files.
final class FolderBasedCollection extends CollectionFiles {
  /// Builds the three child files in source order using the host File callback.
  FolderBasedCollection({
    required Object folderPath,
    required CollectionFileChildConstructor fileChild,
    String collectionName = 'collection',
  }) : colDb = fileChild(folderPath, '$collectionName.anki2'),
       mediaFolder = fileChild(folderPath, '$collectionName.media'),
       mediaDb = fileChild(folderPath, '$collectionName.media.db');

  /// The `collection.anki2` database file.
  final Object colDb;

  @override
  final Object mediaFolder;

  /// The `collection.media.db` database file.
  final Object mediaDb;
}

/// The singleton in-memory collection without media support.
final class InMemory extends CollectionFiles {
  const InMemory._();

  /// The source data-object instance.
  static const InMemory instance = InMemory._();

  @override
  Object? get mediaFolder => null;
}

/// An in-memory collection whose host provides a media folder.
final class InMemoryWithMedia extends CollectionFiles {
  const InMemoryWithMedia({required this.mediaFolder});

  @override
  final Object mediaFolder;
}

/// A source-compatible unsupported-operation exception that is catchable as
/// Dart [Exception], unlike [UnsupportedError].
final class UnsupportedOperationException implements Exception {
  const UnsupportedOperationException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedOperationException: $message';
}
