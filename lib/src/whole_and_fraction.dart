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
 * Source-derived from Double.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// The whole `Long` portion and the remaining `double` from a source value.
typedef WholeAndFraction = ({int whole, double fraction});

const _longUpperBound = 9223372036854775808.0;
const _longLowerBound = -9223372036854775808.0;
const _longMax = 9223372036854775807;
const _longMin = -9223372036854775808;

/// Splits [value] using Kotlin/JVM `Double.toLong()` and subtraction semantics.
///
/// Conversion truncates finite in-range values toward zero, maps NaN to zero,
/// and saturates infinities and out-of-range values to signed 64-bit bounds.
/// The fraction is computed from [value] and the converted whole value in that
/// order, using binary64 arithmetic.
WholeAndFraction wholeAndFraction(double value) {
  final whole = _toKotlinLong(value);
  final fraction = value - whole;
  return (whole: whole, fraction: fraction);
}

int _toKotlinLong(double value) {
  if (value.isNaN) return 0;
  if (value >= _longUpperBound) return _longMax;
  if (value <= _longLowerBound) return _longMin;
  return value.toInt();
}
