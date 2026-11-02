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
 * Source-derived from TextView.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Forwards compound drawable resource IDs to the host TextView method.
///
/// The host owns Android TextView behavior and resource resolution. Omitted
/// resource IDs default to zero, as in AnkiDroid; callback failures propagate.
void textViewSetCompoundDrawablesRelativeWithIntrinsicBounds({
  required Object textView,
  int start = 0,
  int top = 0,
  int end = 0,
  int bottom = 0,
  required void Function(
    Object textView,
    int start,
    int top,
    int end,
    int bottom,
  )
  setCompoundDrawablesRelativeWithIntrinsicBounds,
}) {
  setCompoundDrawablesRelativeWithIntrinsicBounds(
    textView,
    start,
    top,
    end,
    bottom,
  );
}
