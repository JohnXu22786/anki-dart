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

/// Portable media filename helpers from AnkiDroid's `Media` class.
abstract final class Media {
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
