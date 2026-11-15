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
 * Source-derived from NamedJSONComparator.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// An object whose [name] is used by [NamedJSONComparator].
abstract interface class NamedObject {
  String get name;
}

/// Compares [NamedObject.name] values using the host's JVM-compatible compare.
///
/// The host supplies the case-insensitive String comparison because Dart's
/// string comparison does not define Kotlin/JVM `compareTo(ignoreCase = true)`
/// semantics. Each name is read once, left before right; the host's exact result
/// is returned and any getter or comparison failure propagates unchanged.
final class NamedJSONComparator {
  const NamedJSONComparator._();

  /// The singleton comparator, matching Kotlin's `INSTANCE` entry point.
  static const NamedJSONComparator INSTANCE = NamedJSONComparator._();

  /// Compares [lhs]'s name with [rhs]'s name, ignoring case in the host.
  int compare(
    NamedObject lhs,
    NamedObject rhs, {
    required int Function(String lhs, String rhs) compareIgnoreCase,
  }) {
    final lhsName = lhs.name;
    final rhsName = rhs.name;
    return compareIgnoreCase(lhsName, rhsName);
  }
}
