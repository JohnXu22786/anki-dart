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
 * Source-derived from HashUtil.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Adapts `HashUtil.hashSetInit(size)` with a host-provided set constructor.
///
/// The callback receives the capacity calculated by AnkiDroid and its exact
/// result or failure is returned or propagated. The host owns the collection.
T hashSetInit<T>(int size, {required T Function(int capacity) createSet}) =>
    createSet(_hashCapacity(size));

/// Adapts `HashUtil.hashMapInit(size)` with a host-provided map constructor.
///
/// The callback receives the capacity calculated by AnkiDroid and its exact
/// result or failure is returned or propagated. The host owns the collection.
T hashMapInit<T>(int size, {required T Function(int capacity) createMap}) =>
    createMap(_hashCapacity(size));

int _hashCapacity(int size) {
  // Kotlin performs both the Int-to-Float conversion and division as Float32.
  final sizeAsFloat = Float32List.fromList([size.toDouble()])[0];
  final divided = Float32List.fromList([sizeAsFloat / 0.75])[0];
  final truncated = _floatToKotlinInt(divided);
  final capacity = _kotlinInt32(truncated + 1);
  return capacity < 16 ? 16 : capacity;
}

int _floatToKotlinInt(double value) {
  if (value >= 0x7fffffff) return 0x7fffffff;
  if (value <= -0x80000000) return -0x80000000;
  return value.toInt();
}

int _kotlinInt32(int value) {
  final unsigned = value & 0xffffffff;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
