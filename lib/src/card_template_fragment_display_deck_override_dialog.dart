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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'card_template_editor_current_template_name.dart';

/// Host callbacks for `CardTemplateFragment.displayDeckOverrideDialog`.
///
/// Android Activity validation, temporary note-type/template models,
/// localization, Snackbar, deck-selection UI, and task/error handling stay
/// host-side. The supplied temporary model and localized values pass through
/// unchanged. The current template name uses the existing source-compatible
/// `cardTemplateEditorCurrentTemplateName()` exception boundary.
final class CardTemplateFragmentDisplayDeckOverrideDialogCallbacks<
  TModel,
  TSnackbarDuration
> {
  const CardTemplateFragmentDisplayDeckOverrideDialogCallbacks({
    required this.launchCatchingTask,
    required this.requireAnkiActivity,
    required this.isCloze,
    required this.multimediaEditorErrorString,
    required this.showSnackbar,
    required this.snackbarLengthShort,
    required this.readCurrentOrdinal,
    required this.readTemplateName,
    required this.warnTemplateNameRead,
    required this.deckOverrideTitle,
    required this.deckOverrideExplanation,
    required this.showDeckSelectionDialog,
  });

  final void Function(void Function() action) launchCatchingTask;
  final void Function() requireAnkiActivity;
  final bool Function(TModel tempModel) isCloze;
  final String Function() multimediaEditorErrorString;
  final void Function(String message, TSnackbarDuration duration) showSnackbar;
  final TSnackbarDuration snackbarLengthShort;
  final int Function() readCurrentOrdinal;
  final String Function(TModel tempModel, int ordinal) readTemplateName;
  final void Function(Exception exception) warnTemplateNameRead;
  final String Function() deckOverrideTitle;
  final String Function(String templateName) deckOverrideExplanation;
  final void Function(
    String title,
    String explanation, {
    required bool allowAll,
    required bool allowFiltered,
  })
  showDeckSelectionDialog;
}

/// Runs the host orchestration for `CardTemplateFragment.displayDeckOverrideDialog()`.
///
/// Activity validation precedes any temporary-model read. Cloze models show
/// the short multimedia-editor error and return before template-name or dialog
/// callbacks. Otherwise the existing current-template-name helper runs once,
/// followed by localized title, formatted explanation, and the host dialog
/// with both deck-selection flags false. Callback failures propagate and stop
/// later callbacks, except for the helper's existing `Exception` warning and
/// empty-name fallback.
void cardTemplateFragmentDisplayDeckOverrideDialog<TModel, TSnackbarDuration>({
  required TModel tempModel,
  required CardTemplateFragmentDisplayDeckOverrideDialogCallbacks<
    TModel,
    TSnackbarDuration
  >
  callbacks,
}) {
  callbacks.launchCatchingTask(() {
    callbacks.requireAnkiActivity();
    if (callbacks.isCloze(tempModel)) {
      callbacks.showSnackbar(
        callbacks.multimediaEditorErrorString(),
        callbacks.snackbarLengthShort,
      );
      return;
    }

    final templateName = cardTemplateEditorCurrentTemplateName(
      readCurrentOrdinal: callbacks.readCurrentOrdinal,
      readTemplateName: (ordinal) =>
          callbacks.readTemplateName(tempModel, ordinal),
      warn: callbacks.warnTemplateNameRead,
    );
    final title = callbacks.deckOverrideTitle();
    final explanation = callbacks.deckOverrideExplanation(templateName);
    // Anki Desktop allows Dynamic decks; this was reported as a bug:
    // https://forums.ankiweb.net/t/minor-bug-deck-override-to-filtered-deck/1493
    callbacks.showDeckSelectionDialog(
      title,
      explanation,
      allowAll: false,
      allowFiltered: false,
    );
  });
}
