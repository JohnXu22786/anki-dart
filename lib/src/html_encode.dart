/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (C) 2006 The Android Open Source Project
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
 * SPDX-FileCopyrightText: 2006 The Android Open Source Project
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from android.text.TextUtils.htmlEncode as incorporated by
 * StringUtils.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md and
 * LICENSES/Apache-2.0.txt.
 */

/// HTML-encodes the same five UTF-16 characters as Android TextUtils.
///
/// The single pass leaves generated entities untouched and preserves every
/// other code unit, including paired surrogate code units.
String htmlEncode(String value) {
  final result = StringBuffer();
  for (final codeUnit in value.codeUnits) {
    switch (codeUnit) {
      case 0x3c: // <
        result.write('&lt;');
      case 0x3e: // >
        result.write('&gt;');
      case 0x26: // &
        result.write('&amp;');
      case 0x27: // '
        result.write('&#39;');
      case 0x22: // "
        result.write('&quot;');
      default:
        result.writeCharCode(codeUnit);
    }
  }
  return result.toString();
}
