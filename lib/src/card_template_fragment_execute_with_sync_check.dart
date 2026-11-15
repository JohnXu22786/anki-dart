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
 * Source-derived from CardTemplateFragment.executeWithSyncCheck in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.executeWithSyncCheck`.
///
/// Collection/schema access, exception classification and logging, Android
/// confirmation UI and resources, previewer state, and lifecycle remain
/// host-side. Only Exceptions classified by the host as
/// `ConfirmModSchemaException` are handled; Dart `Error` values and other
/// callback failures propagate.
final class CardTemplateFragmentExecuteWithSyncCheckCallbacks<TDialog> {
  const CardTemplateFragmentExecuteWithSyncCheckCallbacks({
    required this.modSchema,
    required this.updateDiscardChangesState,
    required this.isFragmented,
    required this.reloadPreviewer,
    required this.isConfirmModSchemaException,
    required this.logConfirmModSchemaException,
    required this.createDialog,
    required this.getFullSyncConfirmationMessage,
    required this.setDialogArgs,
    required this.setConfirm,
    required this.setCancel,
    required this.showDialog,
    required this.dismissAllDialogFragments,
  });

  final void Function(bool check) modSchema;
  final void Function() updateDiscardChangesState;
  final bool Function() isFragmented;
  final void Function() reloadPreviewer;
  final bool Function(Object error) isConfirmModSchemaException;
  final void Function(Object error) logConfirmModSchemaException;
  final TDialog Function() createDialog;
  final String Function() getFullSyncConfirmationMessage;
  final void Function(TDialog dialog, String message) setDialogArgs;
  final void Function(TDialog dialog, void Function() confirm) setConfirm;
  final void Function(TDialog dialog, void Function() cancel) setCancel;
  final void Function(TDialog dialog) showDialog;
  final void Function() dismissAllDialogFragments;
}

/// Runs the source-ordered schema check and action, with full-sync confirmation.
///
/// The initial `modSchema(check: true)`, action, discard-state update, and
/// conditional previewer reload share one catch boundary. If the host
/// classifies a failure in that sequence as `ConfirmModSchemaException`, a
/// localized confirmation dialog is registered and shown. Confirm re-runs the
/// same action after `modSchema(check: false)`, updates discard state, and
/// dismisses dialogs; cancel only dismisses dialogs.
void cardTemplateFragmentExecuteWithSyncCheck<TDialog>({
  required void Function() schemaChangingAction,
  required CardTemplateFragmentExecuteWithSyncCheckCallbacks<TDialog> callbacks,
}) {
  try {
    callbacks.modSchema(true);
    schemaChangingAction();
    callbacks.updateDiscardChangesState();
    if (callbacks.isFragmented()) {
      callbacks.reloadPreviewer();
    }
  } catch (error) {
    if (error is! Exception || !callbacks.isConfirmModSchemaException(error)) {
      rethrow;
    }

    callbacks.logConfirmModSchemaException(error);
    final dialog = callbacks.createDialog();
    callbacks.setDialogArgs(dialog, callbacks.getFullSyncConfirmationMessage());
    final confirm = () {
      callbacks.modSchema(false);
      schemaChangingAction();
      callbacks.updateDiscardChangesState();
      callbacks.dismissAllDialogFragments();
    };
    final cancel = () => callbacks.dismissAllDialogFragments();
    callbacks.setConfirm(dialog, confirm);
    callbacks.setCancel(dialog, cancel);
    callbacks.showDialog(dialog);
  }
}
