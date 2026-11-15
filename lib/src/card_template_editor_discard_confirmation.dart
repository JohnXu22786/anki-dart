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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Registers the source discard-confirmation action with the host dialog.
///
/// The dialog's opaque result is returned unchanged. Effects are deferred until
/// [showDialog] invokes the confirmation callback, then run in source order.
/// Callback failures propagate unchanged and stop later effects. Android
/// dialog behavior, logging, temporary-note-type storage, and Activity lifecycle
/// remain host-side.
TDialog cardTemplateEditorShowDiscardChangesDialog<TDialog, TNoteType>({
  required TDialog Function(void Function() onConfirmed) showDialog,
  required void Function(String message) logConfirmation,
  required void Function() clearTempNoteTypeFiles,
  required void Function(TNoteType? value) setTempNoteType,
  required void Function() finish,
}) => showDialog(() {
  logConfirmation(
    'TemplateEditor:: OK button pressed to confirm discard changes',
  );
  clearTempNoteTypeFiles();
  setTempNoteType(null);
  finish();
});
