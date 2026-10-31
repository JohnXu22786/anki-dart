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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'card_template_editor_dynamic_note_type.dart';

/// Host callbacks for `CardTemplateFragment.showRenameDialog`.
///
/// Android models, `CardTypeName`, Context/dialog, logging, pager adapter, and
/// previewer remain host-side. The callbacks expose lazy reads and effects in
/// the order used by the pinned source.
final class CardTemplateFragmentShowRenameDialogCallbacks<
  TModel,
  TTemplate,
  TContext,
  TCardTypeName,
  TNewName,
  TAdapter
> {
  const CardTemplateFragmentShowRenameDialogCallbacks({
    required this.isCloze,
    required this.isImageOcclusion,
    required this.warn,
    required this.readOrdinal,
    required this.readTemporaryModel,
    required this.readSelectedTemplate,
    required this.readNotetypeTemplates,
    required this.readTemplateName,
    required this.cardTypeNameFromString,
    required this.requireContext,
    required this.showRenameDialog,
    required this.readNewNameValue,
    required this.assignTemplateName,
    required this.updateDiscardChangesCallback,
    required this.infoLog,
    required this.debugLog,
    required this.readPagerAdapter,
    required this.notifyAdapterDataSetChanged,
    required this.loadTemplatePreviewerIfFragmented,
  });

  final bool Function() isCloze;
  final bool Function() isImageOcclusion;
  final void Function(String message) warn;
  final int Function() readOrdinal;
  final TModel? Function() readTemporaryModel;
  final TTemplate Function(TModel model, int ordinal) readSelectedTemplate;
  final Iterable<TTemplate> Function(TModel model) readNotetypeTemplates;
  final String Function(TTemplate template) readTemplateName;
  final TCardTypeName Function(String name) cardTypeNameFromString;
  final TContext Function() requireContext;
  final void Function({
    required TContext context,
    required String prefill,
    required TCardTypeName currentName,
    required List<TCardTypeName> existingNames,
    required void Function(TNewName newName) onConfirm,
  })
  showRenameDialog;
  final String Function(TNewName newName) readNewNameValue;
  final void Function(TTemplate template, String name) assignTemplateName;
  final void Function() updateDiscardChangesCallback;
  final void Function(String message) infoLog;
  final void Function(String format, int ordinal, TNewName newName) debugLog;
  final TAdapter? Function() readPagerAdapter;
  final void Function(TAdapter adapter) notifyAdapterDataSetChanged;
  final void Function() loadTemplatePreviewerIfFragmented;
}

/// Projects `CardTemplateFragment.showRenameDialog` in pinned source order.
///
/// Dynamic note types warn and return before later reads. The selected template
/// name is intentionally read once for dialog prefill and again for conversion;
/// confirmation effects remain deferred in the host dialog callback.
void cardTemplateFragmentShowRenameDialog<
  TModel,
  TTemplate,
  TContext,
  TCardTypeName,
  TNewName,
  TAdapter
>({
  required CardTemplateFragmentShowRenameDialogCallbacks<
    TModel,
    TTemplate,
    TContext,
    TCardTypeName,
    TNewName,
    TAdapter
  >
  callbacks,
}) {
  if (cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
    isCloze: callbacks.isCloze,
    isImageOcclusion: callbacks.isImageOcclusion,
  )) {
    callbacks.warn('attempted to rename a dynamic note type');
    return;
  }

  final ordinal = callbacks.readOrdinal();
  final template = callbacks.readSelectedTemplate(
    callbacks.readTemporaryModel()!,
    ordinal,
  );

  final existingNames = callbacks
      .readNotetypeTemplates(callbacks.readTemporaryModel()!)
      .map(
        (existingTemplate) => callbacks.cardTypeNameFromString(
          callbacks.readTemplateName(existingTemplate),
        ),
      )
      .toList();

  final context = callbacks.requireContext();
  final prefill = callbacks.readTemplateName(template);
  final currentName = callbacks.cardTypeNameFromString(
    callbacks.readTemplateName(template),
  );

  callbacks.showRenameDialog(
    context: context,
    prefill: prefill,
    currentName: currentName,
    existingNames: existingNames,
    onConfirm: (newName) {
      callbacks.assignTemplateName(
        template,
        callbacks.readNewNameValue(newName),
      );
      callbacks.updateDiscardChangesCallback();
      callbacks.infoLog('updated card template name');
      callbacks.debugLog(
        "updated name of template %d to '%s'",
        ordinal,
        newName,
      );
      callbacks.notifyAdapterDataSetChanged(callbacks.readPagerAdapter()!);
      callbacks.loadTemplatePreviewerIfFragmented();
    },
  );
}
