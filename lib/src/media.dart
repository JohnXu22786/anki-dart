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
  /// HTML media attributes recognized by [filesInStr], in source order.
  ///
  /// These patterns preserve AnkiDroid's quoted and unquoted `src`/`data`
  /// forms and their capture-group layout.
  static final List<RegExp> htmlMediaRegexps = List.unmodifiable([
    RegExp(
      r'''(<(?:img|audio|source)\b[^>]* src=(['"])([^>]+?)\2[^>]*>)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''(<(?:img|audio|source)\b[^>]* src=(?!['"])([^ >]+)[^>]*?>)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''(<object\b[^>]* data=(['"])([^>]+?)\2[^>]*>)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''(<object\b[^>]* data=(?!['"])([^ >]+)[^>]*?>)''',
      caseSensitive: false,
    ),
  ]);

  static final RegExp _remoteMediaUrlPattern = RegExp(
    r'https?|ftp://',
    caseSensitive: false,
  );

  static const List<int> _filenameCaptureGroups = [3, 2, 3, 2];

  static String? _extractFilename(int patternIndex, RegExpMatch match) =>
      match.group(_filenameCaptureGroups[patternIndex]);

  /// Returns distinct HTML and sound/video filenames from a rendered card.
  ///
  /// Card, note, model, render output, LaTeX, and AV tag behavior remain
  /// host-owned. The host supplies opaque values and callbacks; callback errors
  /// propagate unchanged. HTML matches follow pattern order, then match order,
  /// before question and answer AV tag filenames are appended.
  static List<String>
  filesInStr<TCard, TCollection, TNote, TModel, TRenderOutput, TAvTag>(
    TCard currentCard, {
    required TCollection collection,
    bool includeRemote = false,
    required TNote Function(TCard card, TCollection collection) note,
    required TModel Function(TNote note) notetype,
    required TRenderOutput Function(TCard card, TCollection collection)
    renderOutput,
    required String Function(TRenderOutput output) questionText,
    required String Function(TRenderOutput output) answerText,
    required String Function(String text, TModel model, TCollection collection)
    renderLatex,
    required List<TAvTag> Function(TRenderOutput output) questionAvTags,
    required List<TAvTag> Function(TRenderOutput output) answerAvTags,
    required bool Function(TAvTag tag) isSoundOrVideoTag,
    required String Function(TAvTag tag) soundOrVideoFilename,
  }) {
    final model = notetype(note(currentCard, collection));
    final output = renderOutput(currentCard, collection);
    final processedText = renderLatex(
      questionText(output) + answerText(output),
      model,
      collection,
    );

    final files = <String>[];
    for (
      var patternIndex = 0;
      patternIndex < htmlMediaRegexps.length;
      patternIndex++
    ) {
      final pattern = htmlMediaRegexps[patternIndex];
      for (final match in pattern.allMatches(processedText)) {
        final filename = _extractFilename(patternIndex, match);
        if (filename == null) continue;
        final isLocal = !_remoteMediaUrlPattern.hasMatch(filename);
        if (isLocal || includeRemote) files.add(filename);
      }
    }

    final avTags = [...questionAvTags(output), ...answerAvTags(output)];
    final soundOrVideoTags = avTags.where(isSoundOrVideoTag).toList();
    files.addAll(soundOrVideoTags.map(soundOrVideoFilename));
    return files.toSet().toList();
  }

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

  /// Returns host Files for every unused media filename in source order.
  ///
  /// The media check and unused list are read once. [mediaDirectory] remains
  /// lazy when the list is empty and its exact result is reused for every
  /// host File construction. File construction and filesystem behavior remain
  /// host-owned.
  static List<TFile> findUnusedMediaFiles<TResponse, TDirectory, TFile>({
    required TResponse Function() checkMedia,
    required List<String> Function(TResponse response) unusedList,
    required TDirectory Function() mediaDirectory,
    required TFile Function(TDirectory directory, String filename) file,
  }) {
    final filenames = unusedList(checkMedia());
    late final TDirectory directory = mediaDirectory();
    return filenames.map((filename) => file(directory, filename)).toList();
  }

  /// Returns whether the host File for [fname] exists.
  ///
  /// Directory resolution, File construction, and filesystem existence checks
  /// remain host-owned and their errors pass through unchanged.
  static bool have<TDirectory, TFile>(
    String fname, {
    required TDirectory Function() mediaDirectory,
    required TFile Function(TDirectory directory, String filename) file,
    required bool Function(TFile file) exists,
  }) {
    final directory = mediaDirectory();
    final hostFile = file(directory, fname);
    return exists(hostFile);
  }
}
