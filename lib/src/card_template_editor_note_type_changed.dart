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
 * Source-derived from CardTemplateEditor.kt; see ANKIDROID_UPSTREAM.md.
 */

/// Preserves the source `noteTypeHasChanged()` decision.
///
/// [lookupStoredJsonEquality] is called only when a temporary note type exists,
/// and at most once. Its host-projected result is null when the stored note type
/// is absent, otherwise it is the result of comparing the two JSON objects
/// with the host's source-compatible content equality. Callback errors propagate.
bool cardTemplateNoteTypeHasChanged({
  required bool hasTemporaryNoteType,
  required bool? Function() lookupStoredJsonEquality,
}) {
  // Early lifecycle callbacks can arrive before loading; do not open the
  // collection unless a temporary note type is available.
  if (!hasTemporaryNoteType) return false;

  final storedJsonIsEqual = lookupStoredJsonEquality();
  if (storedJsonIsEqual == null) return true;
  return !storedJsonIsEqual;
}
