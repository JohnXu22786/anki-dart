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
 * Source-derived from CardTemplateFragment.addCardTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.addCardTemplate`.
///
/// Temporary models, notetypes, collection queries, Timber, and confirmation
/// UI stay host-side. Values pass through unchanged, including repeated lazy
/// model and ordinal reads.
final class CardTemplateFragmentAddCardTemplateCallbacks<
  TModel,
  TCollection,
  TNotetype
> {
  const CardTemplateFragmentAddCardTemplateCallbacks({
    required this.readTemporaryModel,
    required this.isCloze,
    required this.warn,
    required this.readCurrentOrdinal,
    required this.isOrdinalPendingAdd,
    required this.readCollection,
    required this.readNotetype,
    required this.queryTemplateUseCount,
    required this.confirmAddCards,
  });

  final TModel Function() readTemporaryModel;
  final bool Function(TModel model) isCloze;
  final void Function(String message) warn;
  final int Function() readCurrentOrdinal;
  final bool Function(TModel model, int ordinal) isOrdinalPendingAdd;
  final TCollection Function() readCollection;
  final TNotetype Function(TModel model) readNotetype;
  final int Function(TCollection collection, TNotetype notetype, int ordinal)
  queryTemplateUseCount;
  final void Function(TNotetype notetype, int affectedCardCount)
  confirmAddCards;
}

/// Runs the host callback sequence for `CardTemplateFragment.addCardTemplate`.
///
/// Cloze note types log and return before further reads. Pending-add ordinals
/// use zero affected cards and skip the collection query; other ordinals query
/// the exact template-use count. Repeated source model and ordinal reads remain
/// lazy, and callback failures propagate immediately.
void cardTemplateFragmentAddCardTemplate<TModel, TCollection, TNotetype>({
  required CardTemplateFragmentAddCardTemplateCallbacks<
    TModel,
    TCollection,
    TNotetype
  >
  callbacks,
}) {
  if (callbacks.isCloze(callbacks.readTemporaryModel())) {
    callbacks.warn('addCardTemplate attempted on cloze note type');
    return;
  }

  final pendingAdd = callbacks.isOrdinalPendingAdd(
    callbacks.readTemporaryModel(),
    callbacks.readCurrentOrdinal(),
  );
  final affectedCardCount = pendingAdd
      ? 0
      : callbacks.queryTemplateUseCount(
          callbacks.readCollection(),
          callbacks.readNotetype(callbacks.readTemporaryModel()),
          callbacks.readCurrentOrdinal(),
        );
  callbacks.confirmAddCards(
    callbacks.readNotetype(callbacks.readTemporaryModel()),
    affectedCardCount,
  );
}
