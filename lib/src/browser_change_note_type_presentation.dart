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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserFragment.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_change_note_type_plan.dart';

/// Android string resource used by the mixed-note-type snackbar.
enum BrowserChangeNoteTypeResourceId { differentNoteTypesSelected }

/// Host action implied by the fragment's change-note-type response handler.
sealed class BrowserChangeNoteTypePresentation {
  const BrowserChangeNoteTypePresentation();
}

/// Show the source mixed-note-type snackbar after host resource lookup.
final class BrowserChangeNoteTypeSnackbar
    extends BrowserChangeNoteTypePresentation {
  const BrowserChangeNoteTypeSnackbar({required this.messageResource});

  final BrowserChangeNoteTypeResourceId messageResource;
}

/// Create the change-note-type dialog with the response IDs unchanged.
final class BrowserChangeNoteTypeDialog
    extends BrowserChangeNoteTypePresentation {
  const BrowserChangeNoteTypeDialog({required this.noteIds});

  /// The exact ordered IDs held by the response plan.
  final List<int> noteIds;
}

/// Maps a ViewModel response to a host action without performing UI effects.
///
/// NoSelection produces no user-visible action. The host still owns the source
/// log, resource lookup, snackbar/dialog construction and delivery, flow
/// collection, and any subsequent note-type change.
BrowserChangeNoteTypePresentation? projectBrowserChangeNoteTypePresentation(
  BrowserChangeNoteTypePlan response,
) => switch (response) {
  BrowserChangeNoteTypeNoSelection() => null,
  BrowserChangeNoteTypeMixedSelection() => const BrowserChangeNoteTypeSnackbar(
    messageResource: BrowserChangeNoteTypeResourceId.differentNoteTypesSelected,
  ),
  BrowserChangeNoteTypeSelection(:final noteIds) => BrowserChangeNoteTypeDialog(
    noteIds: noteIds,
  ),
};
