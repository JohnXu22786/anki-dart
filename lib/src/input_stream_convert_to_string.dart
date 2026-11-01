/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from InputStream.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host-supplied line reader for [inputStreamConvertToString].
///
/// The host adapts Android's `InputStreamReader` and `BufferedReader` here,
/// including its default charset and 4096-character buffer. It also owns the
/// byte stream and the behavior of [close].
abstract interface class InputStreamLineReader {
  /// Returns the next decoded line, without its line terminator, or null at EOF.
  String? readLine();

  /// Closes the reader and its underlying input stream.
  void close();
}

/// Concatenates host-read lines, following `InputStream.convertToString()`.
///
/// The reader is created inside the source's `Exception` boundary. Lines are
/// appended without separators; accumulated text is returned only after EOF
/// and a successful close. A Dart [Exception] from construction, reading,
/// closing, or final string conversion is passed to [warn] once and produces
/// an empty result, even if lines were already read. A failure from [warn]
/// propagates. Dart [Error] values are not caught, matching the source's Java
/// `Exception` catch rather than catching every throwable.
///
/// The host supplies actual byte decoding, the platform default charset, the
/// `InputStreamReader`/4096-character `BufferedReader`, and Timber logging. A
/// host exception that should map to Kotlin `Exception` must be surfaced as a
/// Dart [Exception]; other thrown objects remain outside this catch boundary.
String inputStreamConvertToString({
  required InputStreamLineReader Function() createReader,
  required void Function(Exception exception) warn,
}) {
  var content = '';
  try {
    final reader = createReader();
    final buffer = StringBuffer();
    String? line;
    while ((line = reader.readLine()) != null) {
      buffer.write(line);
    }
    reader.close();
    content = buffer.toString();
  } on Exception catch (exception) {
    warn(exception);
  }
  return content;
}
