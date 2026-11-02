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
 * Source-derived from Context.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Runs [block] on the opaque host typed-array token and recycles it on success.
///
/// The host owns Android `Context`, `AttributeSet`, `IntArray`, and `TypedArray`
/// access. [obtainStyledAttributes] receives the exact host arguments and must
/// return an opaque token for the acquired `TypedArray`; [block] and [recycle]
/// receive that identical token. Acquisition happens once, then [block] runs
/// once, and [recycle] runs once only if [block] returns normally. A block
/// failure therefore propagates unchanged without recycling, matching the
/// pinned Kotlin `typedArray.block().also { typedArray.recycle() }` sequence.
T usingStyledAttributes<T>({
  required Object? set,
  required Object attrs,
  int defStyleAttr = 0,
  int defStyleRes = 0,
  required Object Function(
    Object? set,
    Object attrs,
    int defStyleAttr,
    int defStyleRes,
  )
  obtainStyledAttributes,
  required T Function(Object typedArray) block,
  required void Function(Object typedArray) recycle,
}) {
  final typedArray = obtainStyledAttributes(
    set,
    attrs,
    defStyleAttr,
    defStyleRes,
  );
  final result = block(typedArray);
  recycle(typedArray);
  return result;
}
