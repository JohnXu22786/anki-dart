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
 * Source-derived from View.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// The host-supplied MaterialColors operation used by [setBackgroundTint].
abstract interface class MaterialColorsAccess {
  int compositeARGBWithAlpha(int color, int alpha);
}

/// The host-supplied `ColorStateList.valueOf` operation.
abstract interface class ColorStateListAccess<TTint> {
  TTint valueOf(int color);
}

/// The host-supplied Android View background tint assignment.
abstract interface class ViewBackgroundTintAccess<TTint> {
  set backgroundTintList(TTint value);
}

/// Applies AnkiDroid's background tint operation to host-owned Android objects.
///
/// [alpha] represents the source Kotlin `Float`. It is rounded to binary32
/// before multiplication, the product is rounded to binary32, and conversion
/// truncates toward zero with Kotlin `Float.toInt()` NaN and Int32 saturation
/// behavior. Alpha is not clamped or validated. Host operations run once in
/// source order; failures propagate unchanged and stop later operations.
void setBackgroundTint<TTint>(
  int color,
  double alpha,
  MaterialColorsAccess materialColors,
  ColorStateListAccess<TTint> colorStateList,
  ViewBackgroundTintAccess<TTint> view,
) {
  final alphaInt = _kotlinFloatToInt(_float32(_float32(alpha) * 255));
  final compositeColor = materialColors.compositeARGBWithAlpha(color, alphaInt);
  final tint = colorStateList.valueOf(compositeColor);
  view.backgroundTintList = tint;
}

double _float32(double value) => Float32List.fromList([value])[0];

int _kotlinFloatToInt(double value) {
  if (value.isNaN) return 0;
  if (value >= 0x7fffffff) return 0x7fffffff;
  if (value <= -0x80000000) return -0x80000000;
  return value.toInt();
}
