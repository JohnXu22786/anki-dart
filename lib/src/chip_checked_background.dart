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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Chip.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Reads the host Chip's checked state for AnkiDroid's
/// `Chip.hasCheckedBackground` property.
///
/// The Android Material Chip and its visual background behavior remain
/// host-side.
bool readChipHasCheckedBackground({required bool Function() isChecked}) =>
    isChecked();

/// Applies AnkiDroid's `Chip.hasCheckedBackground` setter to a host Chip.
///
/// The callbacks run once in source order: enable checkability, set checked,
/// then disable checkability. A callback failure propagates unchanged and
/// stops later calls, matching the source setter's behavior.
void setChipHasCheckedBackground({
  required bool value,
  required void Function(bool value) setCheckable,
  required void Function(bool value) setChecked,
}) {
  setCheckable(true);
  setChecked(value);
  setCheckable(false);
}
