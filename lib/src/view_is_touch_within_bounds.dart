/*
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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from View.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Projects `View.isTouchWithinBounds()` over host-supplied Android values.
///
/// [viewLeft] and [viewTop] are the View's layout coordinates. The four
/// [drawingLeft], [drawingTop], [drawingRight], and [drawingBottom] values are
/// the rectangle returned by `getDrawingRect()`. [eventX] and [eventY] are the
/// local coordinates from `MotionEvent`. The host retains those Android APIs.
///
/// The translation follows JVM Float arithmetic and `Float.toInt()`, then the
/// Android `Rect.contains()` half-open bounds check.
bool isTouchWithinBounds({
  required int viewLeft,
  required int viewTop,
  required int drawingLeft,
  required int drawingTop,
  required int drawingRight,
  required int drawingBottom,
  required double eventX,
  required double eventY,
}) {
  if (drawingLeft >= drawingRight || drawingTop >= drawingBottom) return false;

  final x = _kotlinFloatToInt(_kotlinFloatAdd(viewLeft, eventX));
  if (x < drawingLeft || x >= drawingRight) return false;

  final y = _kotlinFloatToInt(_kotlinFloatAdd(viewTop, eventY));
  return y >= drawingTop && y < drawingBottom;
}

double _kotlinFloatAdd(int integer, double float) =>
    _toFloat32(_toFloat32(integer.toDouble()) + _toFloat32(float));

double _toFloat32(double value) {
  final bytes = ByteData(4)..setFloat32(0, value);
  return bytes.getFloat32(0);
}

int _kotlinFloatToInt(double value) {
  if (value.isNaN) return 0;
  if (value <= -0x80000000) return -0x80000000;
  if (value >= 0x7fffffff) return 0x7fffffff;
  return value.toInt();
}
