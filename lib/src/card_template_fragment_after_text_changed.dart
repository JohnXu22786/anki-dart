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

import 'card_template_editor_edit_tab.dart';

/// Host callbacks for `CardTemplateFragment`'s `afterTextChanged` watcher.
///
/// Android `Editable`, editor/model mutation, the Handler and Runnable, and
/// pager state stay host-side. The host supplies its exact refresh delay and
/// wraps [loadTemplatePreviewerFragmentIfFragmented] in its Runnable factory;
/// that callback must invoke the host method with no ordinal argument when the
/// runnable executes, so the host's default current-page lookup stays deferred.
final class CardTemplateFragmentAfterTextChangedCallbacks<
  TTemplate,
  TModel,
  TRunnable,
  TDelay
> {
  const CardTemplateFragmentAfterTextChangedCallbacks({
    required this.currentRefreshRunnable,
    required this.removeCallbacks,
    required this.currentEditTab,
    required this.editorText,
    required this.template,
    required this.temporaryModel,
    required this.cardIndex,
    required this.setCss,
    required this.setAnswerFormat,
    required this.setQuestionFormat,
    required this.updateTemplate,
    required this.createRunnable,
    required this.setCurrentRefreshRunnable,
    required this.postDelayed,
    required this.refreshPreviewDelay,
    required this.loadTemplatePreviewerFragmentIfFragmented,
    required this.updateDiscardChangesCallback,
  });

  final TRunnable? Function() currentRefreshRunnable;
  final void Function(TRunnable runnable) removeCallbacks;
  final Object? Function() currentEditTab;
  final String Function() editorText;
  final TTemplate template;
  final TModel Function() temporaryModel;
  final int Function() cardIndex;
  final void Function(TModel model, String text) setCss;
  final void Function(TTemplate template, String text) setAnswerFormat;
  final void Function(TTemplate template, String text) setQuestionFormat;
  final void Function(TModel model, int cardIndex, TTemplate template)
  updateTemplate;
  final TRunnable Function(void Function() action) createRunnable;
  final void Function(TRunnable runnable) setCurrentRefreshRunnable;
  final void Function(TRunnable runnable, TDelay delay) postDelayed;
  final TDelay refreshPreviewDelay;
  final void Function() loadTemplatePreviewerFragmentIfFragmented;
  final void Function() updateDiscardChangesCallback;
}

/// Projects `TextWatcher.afterTextChanged` in pinned source callback order.
///
/// [editable] is deliberately unused, matching the source parameter. A null or
/// unrecognized edit tab follows the source's `else` branch and writes the
/// question format. Callback failures propagate and stop later operations.
void
cardTemplateFragmentAfterTextChanged<TTemplate, TModel, TRunnable, TDelay>({
  required Object? editable,
  required CardTemplateFragmentAfterTextChangedCallbacks<
    TTemplate,
    TModel,
    TRunnable,
    TDelay
  >
  callbacks,
}) {
  final previousRunnable = callbacks.currentRefreshRunnable();
  if (previousRunnable != null) {
    callbacks.removeCallbacks(previousRunnable);
  }

  final editTab = callbacks.currentEditTab();
  if (editTab == CardTemplateEditorEditTab.STYLING) {
    final model = callbacks.temporaryModel();
    callbacks.setCss(model, callbacks.editorText());
  } else if (editTab == CardTemplateEditorEditTab.BACK) {
    callbacks.setAnswerFormat(callbacks.template, callbacks.editorText());
  } else {
    callbacks.setQuestionFormat(callbacks.template, callbacks.editorText());
  }

  callbacks.updateTemplate(
    callbacks.temporaryModel(),
    callbacks.cardIndex(),
    callbacks.template,
  );
  final updateRunnable = callbacks.createRunnable(
    callbacks.loadTemplatePreviewerFragmentIfFragmented,
  );
  callbacks.setCurrentRefreshRunnable(updateRunnable);
  callbacks.postDelayed(updateRunnable, callbacks.refreshPreviewDelay);
  callbacks.updateDiscardChangesCallback();
}
