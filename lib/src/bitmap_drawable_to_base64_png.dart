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
 * Source-derived from BitmapDrawable.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Host-owned output stream used during PNG compression.
///
/// [hostOutputStream] is the concrete stream passed to Android Bitmap
/// compression. The host owns its implementation and byte accumulation.
abstract interface class BitmapPngOutputStream {
  Object get hostOutputStream;

  /// Returns one snapshot of the accumulated bytes.
  Uint8List toByteArray();

  /// Closes the stream, matching `ByteArrayOutputStream.use` ownership.
  void close();
}

/// Compresses a host bitmap using the supplied Android PNG format and stream.
///
/// The result mirrors `Bitmap.compress`; `bitmapDrawableToBase64Png` ignores it.
typedef BitmapPngCompress =
    bool Function(
      Object bitmap,
      Object format,
      int quality,
      Object outputStream,
    );

/// Encodes bytes with the supplied host Base64 flag and returns its exact text.
typedef BitmapPngBase64Encoder = String Function(Uint8List bytes, Object flag);

/// Projects `BitmapDrawable.toBase64Png()` over Android-owned operations.
///
/// The host supplies the drawable's bitmap, `Bitmap.CompressFormat.PNG`,
/// `Base64.DEFAULT`, a `ByteArrayOutputStream` adapter, Android compression,
/// and Android Base64 encoding. This function creates one owned stream, passes
/// quality 100, ignores the compression result, snapshots the bytes once, and
/// passes that same byte array to the encoder. The stream closes after encoding
/// and also when compression, snapshotting, or encoding throws. If an
/// operation throws, its original error object remains primary over a close
/// failure, as with Kotlin `use`; the host's ByteArrayOutputStream close is
/// non-throwing.
String bitmapDrawableToBase64Png({
  required Object bitmap,
  required Object pngFormat,
  required Object base64Default,
  required BitmapPngOutputStream Function() createOutputStream,
  required BitmapPngCompress compress,
  required BitmapPngBase64Encoder encodeToString,
}) {
  final outputStream = createOutputStream();
  late String result;
  try {
    compress(bitmap, pngFormat, 100, outputStream.hostOutputStream);
    final byteArray = outputStream.toByteArray();
    result = encodeToString(byteArray, base64Default);
  } on Object catch (error, stackTrace) {
    try {
      outputStream.close();
    } on Object {
      // Kotlin use keeps the body failure primary and suppresses close errors.
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
  outputStream.close();
  return result;
}
