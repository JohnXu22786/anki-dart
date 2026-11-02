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
 * Source-derived from SearchHistory.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. The host provides the preference key and storage.
 */

import 'browser_search_history.dart';
import 'browser_search_history_json.dart';

/// Reads a nullable string using a host preference key and source default.
typedef BrowserSearchHistoryGetString =
    String? Function(Object key, String defaultValue);

/// Writes a string using a host preference key.
typedef BrowserSearchHistoryPutString = void Function(Object key, String value);

/// The Card Browser history persistence boundary from AnkiDroid's SearchHistory.
///
/// The host supplies the Android resource key and preference callbacks. This
/// adapter owns only the source's JSON fallback and encode/decode boundary.
final class BrowserSearchHistoryPersistence {
  const BrowserSearchHistoryPersistence({
    required this.preferenceKey,
    required this.getString,
    required this.putString,
  });

  final Object preferenceKey;
  final BrowserSearchHistoryGetString getString;
  final BrowserSearchHistoryPutString putString;

  /// Reads one stored value; a null value or decode failure yields no entries.
  /// Failures from the host getter propagate unchanged.
  List<BrowserSearchHistoryEntry> get entries {
    final stored = getString(preferenceKey, '[]') ?? '[]';
    try {
      return BrowserSearchHistoryJsonCodec.decode(stored);
    } catch (_) {
      return const [];
    }
  }

  /// Encodes [value] before writing it once under the same host key.
  /// Encoding and host write failures propagate unchanged.
  set entries(List<BrowserSearchHistoryEntry> value) {
    final encoded = BrowserSearchHistoryJsonCodec.encode(value);
    putString(preferenceKey, encoded);
  }
}
