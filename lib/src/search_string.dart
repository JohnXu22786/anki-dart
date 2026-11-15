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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SearchString.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_string_hash_code.dart';

/// A search string that has already been built and validated by the host.
///
/// Query construction, parsing, validation, and search execution remain
/// host-side. This value only wraps an existing search string.
final class SearchString {
  const SearchString._(this.value);

  /// Wraps a search string already built and validated by the backend.
  ///
  /// This factory preserves [value] exactly; it does not parse, validate, or
  /// normalize a query.
  factory SearchString.fromValidatedBackendSearchString(String value) =>
      SearchString._(value);

  /// The exact wrapped search string.
  final String value;

  /// The wrapped string's length in UTF-16 code units.
  int get length => value.length;

  /// The empty search string value.
  static const SearchString EMPTY = SearchString._('');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SearchString && other.value == value;

  @override
  int get hashCode => kotlinStringHashCode(value);

  @override
  String toString() => value;
}
