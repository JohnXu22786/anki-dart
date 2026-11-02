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
 * Source-derived from Context.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The dimensions reported by Android's bounds-only bitmap decode.
///
/// Android may report `-1` for either dimension when decoding fails.
final class BitmapSize {
  const BitmapSize(this.width, this.height);

  final int width;
  final int height;

  BitmapSize copy({int? width, int? height}) =>
      BitmapSize(width ?? this.width, height ?? this.height);

  int component1() => width;

  int component2() => height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitmapSize && other.width == width && other.height == height;

  @override
  int get hashCode => _kotlinInt32(31 * width + height);

  @override
  String toString() => 'BitmapSize(width=$width, height=$height)';
}

/// Projects `Context.getSizeOfBitmapFromCollection(filename)` over Android
/// operations supplied by the host.
///
/// The callbacks represent `CollectionHelper.getCurrentAnkiDroidDirectory`,
/// `File(directory, filename)`, `File.exists`, `BitmapFactory.Options`, setting
/// `inJustDecodeBounds`, `File.absolutePath`, `BitmapFactory.decodeFile`, then
/// reading `outWidth` and `outHeight`. Android Context, CollectionHelper, File,
/// BitmapFactory, Options, and decoding remain host-side. Each callback is
/// invoked at most once in source order; failures propagate unchanged and stop
/// later operations. The decode result is intentionally ignored.
BitmapSize? getSizeOfBitmapFromCollection({
  required Object context,
  required String filename,
  required Object Function(Object context) getCurrentAnkiDroidDirectory,
  required Object Function(Object directory, String filename) createFile,
  required bool Function(Object file) fileExists,
  required Object Function() createBitmapFactoryOptions,
  required void Function(Object options, bool value) setInJustDecodeBounds,
  required String Function(Object file) getAbsolutePath,
  required Object? Function(String path, Object options) decodeFile,
  required int Function(Object options) getOutWidth,
  required int Function(Object options) getOutHeight,
}) {
  final currentAnkiDroidDirectory = getCurrentAnkiDroidDirectory(context);
  final destFile = createFile(currentAnkiDroidDirectory, filename);
  if (!fileExists(destFile)) return null;
  final options = createBitmapFactoryOptions();
  setInJustDecodeBounds(options, true);
  final absolutePath = getAbsolutePath(destFile);
  decodeFile(absolutePath, options);
  return BitmapSize(getOutWidth(options), getOutHeight(options));
}

int _kotlinInt32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
