/*
 * Copyright © 2021 Tarek Mohamed Abdalla <tarekkma@gmail.com>
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * SPDX-FileCopyrightText: 2021 Tarek Mohamed Abdalla <tarekkma@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from BundleUtils.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Narrow host adapter for the scalar reads used by [BundleUtilsAccess].
///
/// Android `Bundle` coercion and platform compatibility remain the host's
/// responsibility; this interface only supplies presence checks and typed
/// reads.
abstract interface class BundleUtilsAccess {
  bool containsKey(String key);

  int getLong(String key);

  int getInt(String key);

  String? getString(String key);

  bool getBoolean(String key);
}

/// Source-faithful scalar accessors for a host-supplied bundle adapter.
extension BundleUtilsScalarAccessors on BundleUtilsAccess {
  /// Returns the source `Bundle.getLongOrNull` result for [key].
  ///
  /// A missing key returns null without reading it. Host callback failures
  /// propagate unchanged.
  int? getLongOrNull(String key) => containsKey(key) ? getLong(key) : null;

  /// Returns the source `Bundle.getIntOrNull` result for [key].
  ///
  /// A missing key returns null without reading it. Host callback failures
  /// propagate unchanged.
  int? getIntOrNull(String key) => containsKey(key) ? getInt(key) : null;

  /// Returns the required long value associated with [key].
  ///
  /// A missing key throws [StateError] with the source message. Host callback
  /// failures propagate unchanged.
  int requireLong(String key) {
    if (!containsKey(key)) {
      throw StateError("key: '$key' not found");
    }
    return getLong(key);
  }

  /// Returns the required string associated with [key].
  ///
  /// A missing key throws [StateError]; a present key with a null value throws
  /// [ArgumentError], matching the respective Kotlin failure categories and
  /// messages. Host callback failures propagate unchanged.
  String requireString(String key) {
    if (!containsKey(key)) {
      throw StateError("key: '$key' not found");
    }
    final value = getString(key);
    if (value == null) {
      throw ArgumentError("String in '$key' was null");
    }
    return value;
  }

  /// Returns the required Boolean value associated with [key].
  ///
  /// A missing key throws [StateError] with the source message. Host callback
  /// failures propagate unchanged.
  bool requireBoolean(String key) {
    if (!containsKey(key)) {
      throw StateError("key: '$key' not found");
    }
    return getBoolean(key);
  }
}
