/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

import 'card_template_editor_edit_tab.dart';
import 'insert_field_dialog_selection.dart';

/// Host callbacks for `CardTemplateFragment.showInsertFieldDialog`.
///
/// The host retains coroutine scheduling, template/model access, deletion
/// scanning, metadata/backend queries, dialog construction, and Android UI.
/// Reads and effects are invoked lazily in the pinned source order.
final class CardTemplateFragmentShowInsertFieldDialogCallbacks<
  TMetadata,
  TDialog
> {
  const CardTemplateFragmentShowInsertFieldDialogCallbacks({
    required this.launchCatchingTask,
    required this.readFieldNames,
    required this.readCurrentEditTab,
    required this.readNoteId,
    required this.hasTemplateDeletion,
    required this.readSelectedTemplateOrd,
    required this.readTemplateName,
    required this.readNoteTypeName,
    required this.queryMetadata,
    required this.newDialog,
    required this.insertFieldRequestKey,
    required this.showDialogFragment,
  });

  final void Function(void Function() task) launchCatchingTask;
  final List<String>? Function() readFieldNames;
  final CardTemplateEditorEditTab Function() readCurrentEditTab;
  final int Function() readNoteId;
  final bool Function() hasTemplateDeletion;
  final int Function() readSelectedTemplateOrd;
  final String Function() readTemplateName;
  final String Function() readNoteTypeName;
  final TMetadata Function({
    required SingleCardSide side,
    required int? noteId,
    required int? ord,
    required String templateName,
    required String notetypeName,
  })
  queryMetadata;
  final TDialog Function({
    required List<String> fieldItems,
    required TMetadata metadata,
    required String requestKey,
  })
  newDialog;
  final String insertFieldRequestKey;
  final void Function(TDialog dialog) showDialogFragment;
}

/// Projects `CardTemplateFragment.showInsertFieldDialog` in pinned source order.
///
/// The host's `launchCatchingTask` remains the launch and error boundary. A
/// null field-name list returns before any later host callback; callback errors
/// otherwise propagate to that same boundary and stop subsequent effects.
void cardTemplateFragmentShowInsertFieldDialog<TMetadata, TDialog>({
  required CardTemplateFragmentShowInsertFieldDialogCallbacks<
    TMetadata,
    TDialog
  >
  callbacks,
}) {
  callbacks.launchCatchingTask(() {
    final fieldNames = callbacks.readFieldNames();
    if (fieldNames == null) return;

    final side = switch (callbacks.readCurrentEditTab()) {
      CardTemplateEditorEditTab.FRONT => SingleCardSide.front,
      CardTemplateEditorEditTab.BACK => SingleCardSide.back,
      _ => SingleCardSide.front,
    };

    final currentNoteId = callbacks.readNoteId();
    final noteId = currentNoteId > 0 ? currentNoteId : null;

    final ord = callbacks.hasTemplateDeletion()
        ? null
        : callbacks.readSelectedTemplateOrd();

    final templateName = callbacks.readTemplateName();
    final noteTypeName = callbacks.readNoteTypeName();
    final metadata = callbacks.queryMetadata(
      side: side,
      noteId: noteId,
      ord: ord,
      templateName: templateName,
      notetypeName: noteTypeName,
    );
    final dialog = callbacks.newDialog(
      fieldItems: fieldNames,
      metadata: metadata,
      requestKey: callbacks.insertFieldRequestKey,
    );
    callbacks.showDialogFragment(dialog);
  });
}
