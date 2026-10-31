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
 * Source-derived from CardTemplateFragment.onModelSaved in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.onModelSaved`.
///
/// Android view lookup and IDs, Timber logging, temporary-model mutation, and
/// Activity lifecycle remain host-side. Callback failures propagate immediately
/// and prevent later source effects.
final class CardTemplateFragmentOnModelSavedCallbacks<TButton> {
  const CardTemplateFragmentOnModelSavedCallbacks({
    required this.debug,
    required this.findConfirmButton,
    required this.enableButton,
    required this.clearTemporaryNoteType,
    required this.finishActivity,
  });

  final void Function(String message) debug;
  final TButton? Function() findConfirmButton;
  final void Function(TButton button) enableButton;
  final void Function() clearTemporaryNoteType;
  final void Function() finishActivity;
}

/// Runs the host callback sequence for `CardTemplateFragment.onModelSaved()`.
///
/// Logs, resolves the confirm button and conditionally enables it, then clears
/// the temporary note type and finishes the Activity in source order.
void cardTemplateFragmentOnModelSaved<TButton>({
  required CardTemplateFragmentOnModelSavedCallbacks<TButton> callbacks,
}) {
  callbacks.debug('saveModelAndExitHandler::postExecute called');
  final button = callbacks.findConfirmButton();
  if (button != null) callbacks.enableButton(button);
  callbacks.clearTemporaryNoteType();
  callbacks.finishActivity();
}
