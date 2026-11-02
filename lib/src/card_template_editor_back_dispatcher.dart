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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt; see ANKIDROID_UPSTREAM.md.
 */

/// Dispatches Back to the host's discard-changes dialog callback.
///
/// The host supplies the callback registered with Android's
/// `OnBackPressedCallback`. It is invoked once unconditionally; dispatcher
/// state, lifecycle, and dialog behavior remain host-side. Callback failures
/// propagate unchanged.
void cardTemplateEditorBackDispatcherPressed({
  required void Function() showDiscardChangesDialog,
}) {
  showDiscardChangesDialog();
}
