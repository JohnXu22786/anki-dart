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
 * Source-derived from AnalyticsSamplePercentage.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// A sampling percentage, or the source's uninitialized sentinel value.
final class AnalyticsSamplePercentage {
  /// Creates a value for the inclusive 0..100 range or the -1 sentinel.
  factory AnalyticsSamplePercentage(int value) {
    if (value != _uninitializedValue && (value < 0 || value > 100)) {
      throw ArgumentError(
        'Analytics sample percentage must be in 0..100 or '
        'Uninitialized (-1), got $value',
      );
    }
    return AnalyticsSamplePercentage._(value);
  }

  const AnalyticsSamplePercentage._(this.value);

  static const _uninitializedValue = -1;

  /// Sentinel for a percentage that has not yet been loaded.
  static const Uninitialized = AnalyticsSamplePercentage._(_uninitializedValue);

  /// A fully enabled sampling percentage.
  static const Full = AnalyticsSamplePercentage._(100);

  /// The integer percentage, or -1 while uninitialized.
  final int value;

  /// Whether this percentage has been initialized.
  bool get isInitialized => value != _uninitializedValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSamplePercentage && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AnalyticsSamplePercentage(value=$value)';
}
