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
 * Source-derived from Directory.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// A host-backed directory that was verified to exist when it was created.
///
/// The host owns file and filesystem operations. This adapter preserves the
/// supplied file object and delegates listing and canonical-path reads to the
/// host callbacks without normalizing paths or intercepting failures.
class Directory<TFile> {
  Directory._({
    required this.file,
    required List<TFile>? Function(TFile file) listFiles,
    required String Function(TFile file) canonicalPath,
  }) : _listFiles = listFiles,
       _canonicalPath = canonicalPath;

  /// The exact host file object accepted by the factory.
  final TFile file;

  final List<TFile>? Function(TFile file) _listFiles;
  final String Function(TFile file) _canonicalPath;

  /// Creates a directory from a path using one host file object.
  ///
  /// The host creates the file from [path]. Existence is checked once, and
  /// directory status is checked once only when the file exists. Callback
  /// failures propagate unchanged.
  static Directory<TFile>? createInstanceFromPath<TFile>({
    required String path,
    required TFile Function(String path) createFile,
    required bool Function(TFile file) exists,
    required bool Function(TFile file) isDirectory,
    required List<TFile>? Function(TFile file) listFiles,
    required String Function(TFile file) canonicalPath,
  }) {
    final file = createFile(path);
    return createInstanceFromFile<TFile>(
      file: file,
      exists: exists,
      isDirectory: isDirectory,
      listFiles: listFiles,
      canonicalPath: canonicalPath,
    );
  }

  /// Creates a directory from an existing host file object.
  ///
  /// Returns null when the object does not exist or is not a directory. The
  /// directory check is skipped when the existence check returns false.
  static Directory<TFile>? createInstanceFromFile<TFile>({
    required TFile file,
    required bool Function(TFile file) exists,
    required bool Function(TFile file) isDirectory,
    required List<TFile>? Function(TFile file) listFiles,
    required String Function(TFile file) canonicalPath,
  }) {
    if (!exists(file) || !isDirectory(file)) {
      return null;
    }

    return Directory<TFile>._(
      file: file,
      listFiles: listFiles,
      canonicalPath: canonicalPath,
    );
  }

  /// Lists files through the host, returning a fresh empty list for a null
  /// host result and otherwise the exact list supplied by the host.
  List<TFile> listFiles() => _listFiles(file) ?? <TFile>[];

  /// Returns the host's canonical path each time this method is called.
  @override
  String toString() => _canonicalPath(file);
}
