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
 * Source-derived from CardTemplateFragment.saveNoteType in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.saveNoteType`.
///
/// Android views, Activity/lifecycle checks, localization, task scheduling,
/// progress UI, the temporary model/database, logging, and model-saved effects
/// remain host-side. The callbacks preserve the source sequence and its
/// `Exception`-only task failure boundary.
final class CardTemplateFragmentSaveNoteTypeCallbacks<
  TActivity,
  TModel,
  TButton
> {
  const CardTemplateFragmentSaveNoteTypeCallbacks({
    required this.noteTypeHasChanged,
    required this.debug,
    required this.finish,
    required this.findConfirmButton,
    required this.isButtonEnabled,
    required this.setButtonEnabled,
    required this.saveErrorMessage,
    required this.launchCatchingTask,
    required this.requireActivity,
    required this.savingProgressMessage,
    required this.withProgress,
    required this.readTemporaryModel,
    required this.saveToDatabase,
    required this.onModelSaved,
    required this.logError,
    required this.post,
  });

  final bool Function() noteTypeHasChanged;
  final void Function(String message) debug;
  final void Function() finish;
  final TButton? Function() findConfirmButton;
  final bool Function(TButton button) isButtonEnabled;
  final void Function(TButton button, bool enabled) setButtonEnabled;
  final String Function() saveErrorMessage;
  final void Function(String errorMessage, void Function() action)
  launchCatchingTask;
  final TActivity Function() requireActivity;
  final String Function() savingProgressMessage;
  final void Function(
    TActivity activity,
    String message,
    void Function() action,
  )
  withProgress;
  final TModel Function() readTemporaryModel;
  final void Function(TModel model) saveToDatabase;
  final void Function() onModelSaved;
  final void Function(String message, Exception exception) logError;
  final void Function(TButton button, void Function() action) post;
}

/// Runs the host callback sequence for `CardTemplateFragment.saveNoteType()`.
///
/// Unchanged note types finish immediately. Changed note types disable the
/// confirm button before task scheduling; the task then validates the Activity,
/// resolves progress text, saves the non-null temporary model, and signals
/// success. Only `Exception` failures from that task body are logged and post a
/// re-enable callback before the same failure is rethrown.
bool cardTemplateFragmentSaveNoteType<TActivity, TModel, TButton>({
  required CardTemplateFragmentSaveNoteTypeCallbacks<TActivity, TModel, TButton>
  callbacks,
}) {
  if (!callbacks.noteTypeHasChanged()) {
    callbacks.debug('CardTemplateEditor:: note type has not changed, exiting');
    callbacks.finish();
    return true;
  }

  final confirmButton = callbacks.findConfirmButton();
  if (confirmButton != null) {
    if (!callbacks.isButtonEnabled(confirmButton)) {
      callbacks.debug(
        'CardTemplateEditor::discarding extra click after button disabled',
      );
      return true;
    }
    callbacks.setButtonEnabled(confirmButton, false);
  }

  final errorMessage = callbacks.saveErrorMessage();
  callbacks.launchCatchingTask(errorMessage, () {
    try {
      final activity = callbacks.requireActivity();
      final progressMessage = callbacks.savingProgressMessage();
      callbacks.withProgress(activity, progressMessage, () {
        callbacks.saveToDatabase(callbacks.readTemporaryModel());
      });
      callbacks.onModelSaved();
    } on Exception catch (exception) {
      callbacks.logError(
        'CardTemplateEditor:: saveNoteType() failed',
        exception,
      );
      if (confirmButton != null) {
        callbacks.post(confirmButton, () {
          callbacks.setButtonEnabled(confirmButton, true);
        });
      }
      rethrow;
    }
  });
  return true;
}
