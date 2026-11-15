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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: MimeTypeUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// CSV and TSV MIME types used by the host import picker.
///
/// The Android picker and Intent construction remain host-side.
final class MimeTypeUtils {
  MimeTypeUtils._();

  /// MIME values in the order supplied by AnkiDroid's CSV/TSV picker.
  ///
  /// This list is shared and mutable, like the source Kotlin array.
  static final List<String> csvTsvMimeTypes = [
    'text/comma-separated-values',
    'text/csv',
    'text/tab-separated-values',
    'text/tsv',
    'text/plain',
  ];
}
