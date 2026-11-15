/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2009 Edu Zamora <edu.zasu@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2012 Kostas Spyropoulos <inigo.aldana@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2009 Edu Zamora <edu.zasu@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2012 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Utils.kt and Consts.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'libanki_consts.dart';

/// Portable formatting, field-separator, and checksum helpers from `Utils`.
///
/// Locale helpers are outside this bounded port.
abstract final class Utils {
  /// Formats [ids] as a parenthesized, comma-space-separated string.
  ///
  /// This single Dart method covers Kotlin's `IntArray?`, `LongArray?`, and
  /// `Iterable<T>` overloads. Dart `int` represents both Kotlin integer types.
  /// A null iterable and an empty iterable both produce `()`. Each value uses
  /// its Dart [Object.toString] representation, corresponding to Kotlin's
  /// `StringBuilder.append` element conversion.
  static String ids2str(Iterable<Object?>? ids) =>
      '(${ids?.map((id) => id.toString()).join(', ') ?? ''})';

  /// Joins [fields] using the pinned AnkiDroid U+001F field separator.
  static String joinFields(List<String> fields) =>
      fields.join(LibAnkiConsts.fieldSeparator);

  /// Splits [fields] on U+001F while retaining leading, adjacent, and trailing
  /// empty fields, matching Kotlin's `String.split` behavior.
  static List<String> splitFields(String fields) =>
      fields.split(LibAnkiConsts.fieldSeparator);

  /// Returns the lowercase, 40-character SHA-1 checksum of UTF-8 [data].
  ///
  /// A null input returns the empty string, matching AnkiDroid's
  /// `Utils.checksum`. Dart's statically available SHA-1 implementation does
  /// not perform the JVM's provider lookup or expose its
  /// `NoSuchAlgorithmException` path. Unpaired UTF-16 surrogates are replaced
  /// with `?`, matching the JVM UTF-8 encoder's default replacement byte.
  static String checksum(String? data) {
    if (data == null) {
      return '';
    }
    return sha1.convert(_javaUtf8Bytes(data)).toString();
  }

  static List<int> _javaUtf8Bytes(String data) {
    final codeUnits = data.codeUnits;
    final normalized = StringBuffer();
    for (var index = 0; index < codeUnits.length; index++) {
      final codeUnit = codeUnits[index];
      if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
        if (index + 1 < codeUnits.length &&
            codeUnits[index + 1] >= 0xdc00 &&
            codeUnits[index + 1] <= 0xdfff) {
          final codePoint =
              0x10000 +
              ((codeUnit - 0xd800) << 10) +
              (codeUnits[++index] - 0xdc00);
          normalized.writeCharCode(codePoint);
        } else {
          normalized.write('?');
        }
      } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
        normalized.write('?');
      } else {
        normalized.writeCharCode(codeUnit);
      }
    }
    return utf8.encode(normalized.toString());
  }
}
