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

/// The whole `Long` portion as an exact [BigInt] and its remaining `double`.
/// The [whole] component is [BigInt] so it can retain every signed JVM Long
/// value on JavaScript as well as the Dart VM.
typedef WholeAndFraction = ({BigInt whole, double fraction});

const _longUpperBound = 9223372036854775808.0;
const _longLowerBound = -9223372036854775808.0;
final _longMax = BigInt.parse('9223372036854775807');
final _longMin = BigInt.parse('-9223372036854775808');

/// Splits [value] using Kotlin/JVM `Double.toLong()` and subtraction semantics.
///
/// Conversion truncates finite in-range values toward zero, maps NaN to zero,
/// and saturates infinities and out-of-range values to signed 64-bit bounds.
/// The fraction is computed from [value] and the converted whole value in that
/// order, using binary64 arithmetic.
WholeAndFraction wholeAndFraction(double value) {
  final whole = _toKotlinLong(value);
  final fraction = value - whole.toDouble();
  return (whole: whole, fraction: fraction);
}

BigInt _toKotlinLong(double value) {
  if (value.isNaN) return BigInt.zero;
  if (value >= _longUpperBound) return _longMax;
  if (value <= _longLowerBound) return _longMin;
  return BigInt.from(value);
}
