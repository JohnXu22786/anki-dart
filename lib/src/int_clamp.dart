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
 * Source-derived from Int.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 *
 * This file incorporates code under the following license:
 *
 * Copyright 2010-2024 JetBrains s.r.o. and Kotlin Programming Language contributors.
 * Use of this source code is governed by the Apache 2.0 license that can be found in the license/LICENSE.txt file.
 *
 * https://github.com/JetBrains/kotlin/blob/6ea9f879abd61ba9578b322eb07ff6a8450de11f/libraries/stdlib/common/src/generated/_Ranges.kt#L1447
 */

/// Returns [value] clamped between [minimumValue] and [maximumValue].
///
/// This preserves Kotlin `Int.clamp` comparison order and does not validate the
/// bounds. When the bounds are reversed, the first matching comparison wins.
int clampInt(int value, int minimumValue, int maximumValue) {
  if (value < minimumValue) return minimumValue;
  if (value > maximumValue) return maximumValue;
  return value;
}
