/*
 * Copyright (c) 2011 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Media.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'empty_media_exception.dart';

/// Portable operations from AnkiDroid's `Media` class.
abstract final class Media {
  /// Adds [file] to the host media backend and returns its stored filename.
  ///
  /// File access and ByteString conversion remain host-owned. An empty file
  /// raises [EmptyMediaException] before its name or contents are read.
  static TResult addFile<TFile, TBytes, TByteString, TResult>(
    TFile file, {
    required int Function(TFile file) fileLength,
    required String Function(TFile file) fileName,
    required TBytes Function(TFile file) readBytes,
    required TByteString Function(TBytes bytes) toByteString,
    required TResult Function({
      required String desiredName,
      required TByteString data,
    })
    addMediaFile,
  }) {
    if (fileLength(file) == 0) throw const EmptyMediaException();

    final name = fileName(file);
    final bytes = readBytes(file);
    final data = toByteString(bytes);
    return writeData(name, data, addMediaFile: addMediaFile);
  }

  /// Writes [data] to the host media backend under [desiredFname].
  ///
  /// Media bytes and the returned filename remain opaque host values.
  static TResult writeData<TData, TResult>(
    String desiredFname,
    TData data, {
    required TResult Function({
      required String desiredName,
      required TData data,
    })
    addMediaFile,
  }) => addMediaFile(desiredName: desiredFname, data: data);

  /// Returns the host result of checking collection media.
  static TResult check<TResult>({required TResult Function() checkMedia}) =>
      checkMedia();

  /// Returns the host result of emptying the media trash.
  static TResult emptyTrash<TResult>({
    required TResult Function() emptyTrash,
  }) => emptyTrash();

  /// Removes the host media database for the collection's absolute DB path.
  static void forceResync({
    required String Function() collectionDbAbsolutePath,
    required void Function({required String colPath}) removeMediaDb,
  }) {
    final path = collectionDbAbsolutePath();
    removeMediaDb(colPath: path);
  }

  /// Logs and moves [fnames] to the host media trash in source order.
  ///
  /// The directory is resolved only for the info log. The host owns the
  /// directory value, logging, and trash operation.
  static void trashFiles<TDirectory>(
    List<String> fnames, {
    required TDirectory Function() mediaDirectory,
    required void Function(String message, int count, TDirectory directory)
    logInfo,
    required void Function({required List<String> fnames}) trashMediaFiles,
  }) {
    logInfo('Deleting %d file(s) from %s', fnames.length, mediaDirectory());
    trashMediaFiles(fnames: fnames);
  }

  /// Returns the host result of restoring the media trash.
  static TResult restoreTrash<TResult>({
    required TResult Function() restoreTrash,
  }) => restoreTrash();

  /// Encodes or decodes media IRI paths using the host backend callbacks.
  ///
  /// By default, [encodeIriPaths] is called. When [unescape] is true,
  /// [decodeIriPaths] is called instead. The host owns IRI conversion; this
  /// helper passes [string] through unchanged and returns the callback result.
  static String escapeMediaFilenames(
    String string, {
    bool unescape = false,
    required String Function(String) encodeIriPaths,
    required String Function(String) decodeIriPaths,
  }) => unescape ? decodeIriPaths(string) : encodeIriPaths(string);
}
