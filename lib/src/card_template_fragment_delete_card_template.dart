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
 * Source-derived from CardTemplateFragment.deleteCardTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.deleteCardTemplate`.
///
/// Android lifecycle, model and template access, localized dialogs, logging,
/// collection access, and delete confirmation remain host-side. The callbacks
/// run lazily in source order, and failures propagate without later effects.
final class CardTemplateFragmentDeleteCardTemplateCallbacks<
  TModel,
  TTemplate,
  TNotetype
> {
  const CardTemplateFragmentDeleteCardTemplateCallbacks({
    required this.readTemporaryModel,
    required this.readCurrentOrdinal,
    required this.readTemplate,
    required this.readTemplateCount,
    required this.showCannotDeleteDialog,
    required this.deletionWouldOrphanNote,
    required this.showOrphanNoteDialog,
    required this.isOrdinalPendingAdd,
    required this.logNotPendingAdd,
    required this.readNotetype,
    required this.queryTemplateUseCount,
    required this.confirmDeleteCards,
  });

  final TModel Function() readTemporaryModel;
  final int Function() readCurrentOrdinal;
  final TTemplate Function(TModel model, int ordinal) readTemplate;
  final int Function(TModel model) readTemplateCount;
  final void Function() showCannotDeleteDialog;
  final Future<bool> Function(TModel model, int ordinal)
  deletionWouldOrphanNote;
  final void Function() showOrphanNoteDialog;
  final bool Function(TModel model, int ordinal) isOrdinalPendingAdd;
  final void Function() logNotPendingAdd;
  final TNotetype Function(TModel model) readNotetype;
  final Future<int> Function(int ordinal, TNotetype Function() readNotetype)
  queryTemplateUseCount;
  final void Function(TTemplate template, TNotetype notetype, int count)
  confirmDeleteCards;
}

/// Runs the host callback sequence for `CardTemplateFragment.deleteCardTemplate`.
///
/// The model, ordinal, and template are read once in that order. The source's
/// single-template and orphan guards return before count confirmation. Pending
/// additions confirm with zero; other ordinals log and query the exact host
/// template-use count. Repeated notetype reads and callback failures preserve
/// their source order and behavior.
Future<void>
cardTemplateFragmentDeleteCardTemplate<TModel, TTemplate, TNotetype>({
  required CardTemplateFragmentDeleteCardTemplateCallbacks<
    TModel,
    TTemplate,
    TNotetype
  >
  callbacks,
}) async {
  final tempModel = callbacks.readTemporaryModel();
  final ordinal = callbacks.readCurrentOrdinal();
  final template = callbacks.readTemplate(tempModel, ordinal);

  if (callbacks.readTemplateCount(tempModel) < 2) {
    callbacks.showCannotDeleteDialog();
    return;
  }

  if (await callbacks.deletionWouldOrphanNote(tempModel, ordinal)) {
    callbacks.showOrphanNoteDialog();
    return;
  }

  int affectedCardCount;
  if (callbacks.isOrdinalPendingAdd(tempModel, ordinal)) {
    affectedCardCount = 0;
  } else {
    callbacks.logNotPendingAdd();
    affectedCardCount = await callbacks.queryTemplateUseCount(
      ordinal,
      () => callbacks.readNotetype(tempModel),
    );
  }
  callbacks.confirmDeleteCards(
    template,
    callbacks.readNotetype(tempModel),
    affectedCardCount,
  );
}
