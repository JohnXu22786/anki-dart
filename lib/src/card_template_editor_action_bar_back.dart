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

/// Routes the Card Template Editor action-bar Back callback in source order.
///
/// The host supplies the note-type-change projection, discard dialog, and
/// Activity finish callback. Keyboard state is not consulted: this is the
/// action-bar callback, separate from the Back dispatcher. Callback failures
/// propagate unchanged, and [true] is returned only after the selected action
/// succeeds. Android Activity, dialog, lifecycle, and view behavior remain
/// host-side.
bool cardTemplateEditorActionBarBackPressed({
  required bool Function() noteTypeHasChanged,
  required void Function() showDiscardChangesDialog,
  required void Function() finish,
}) {
  if (noteTypeHasChanged()) {
    showDiscardChangesDialog();
  } else {
    finish();
  }
  return true;
}
