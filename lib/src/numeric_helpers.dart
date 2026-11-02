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
 * Source-derived from Long.kt and Float.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Returns [value] when nonzero; otherwise evaluates [defaultValue] once.
int longIfZero(int value, int Function() defaultValue) =>
    value == 0 ? defaultValue() : value;

/// Clamps Kotlin Float32 [value] with the source's ordered comparisons.
///
/// Bounds are not validated. All inputs are narrowed to binary32, as they are
/// in the source's JVM Float representation.
double clampFloat(double value, double min, double max) {
  final source = _float32(value);
  final lower = _float32(min);
  final upper = _float32(max);
  if (source < lower) return lower;
  if (source > upper) return upper;
  return source;
}

double _float32(double value) => Float32List.fromList([value])[0];
