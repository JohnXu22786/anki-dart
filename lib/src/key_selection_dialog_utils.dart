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
 * Source-derived from KeySelectionDialogUtils.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Creates a predicate that rejects the supplied modifier key codes.
///
/// [modifierKeyCodes] contains host-provided Android `KeyEvent` values for
/// `SHIFT_LEFT`, `SHIFT_RIGHT`, `CTRL_LEFT`, `CTRL_RIGHT`, `ALT_LEFT`,
/// `ALT_RIGHT`, `META_LEFT`, `META_RIGHT`, and `FUNCTION`. The returned
/// predicate captures a snapshot, so later changes to [modifierKeyCodes] do
/// not affect it. Android key events and the platform constants remain
/// host-side.
bool Function(int) disallowModifierKeyCodes(Set<int> modifierKeyCodes) {
  final blocked = {...modifierKeyCodes};
  return (code) => !blocked.contains(code);
}
