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
 * Source-derived from Note.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Adapts `Note.ephemeralCard()` orchestration while leaving host models,
/// template cloning, rendering context, and rendering behavior host-side.
/// Callback failures propagate unchanged after preserving earlier mutations.
TCard libankiNoteEphemeralCard<
  TCollection,
  TNote,
  TCard,
  TNoteType,
  TTemplate,
  TOutput
>({
  required TCollection collection,
  required TNote note,
  required int ord,
  required int deckId,
  TNoteType? customNoteType,
  TTemplate? customTemplate,
  bool fillEmpty = false,
  required TCard Function(TCollection collection, {required int? id})
  createCard,
  required void Function(TCard card, int ord) setCardOrd,
  required void Function(TCard card, int deckId) setCardDid,
  required TNoteType Function() getNoteType,
  required bool Function(TNoteType noteType) getIsStd,
  required List<TTemplate> Function(TNoteType noteType) getTemplates,
  required TTemplate Function(TTemplate template) deepCloneTemplate,
  required int Function(TCard card) getCardOrd,
  required void Function(TTemplate template, int ord) setTemplateOrd,
  required TOutput Function(
    TNote note,
    TCard card,
    TNoteType noteType,
    TTemplate template,
    bool fillEmpty,
    TCollection collection,
  )
  render,
  required void Function(TCard card, TOutput output) setCardRenderOutput,
  required void Function(TCard card, TNote note) setCardNote,
}) {
  final card = createCard(collection, id: null);
  setCardOrd(card, ord);
  setCardDid(card, deckId);

  final model = customNoteType ?? getNoteType();
  late final TTemplate template;
  if (customTemplate != null) {
    template = deepCloneTemplate(customTemplate);
  } else {
    final index = getIsStd(model) ? ord : 0;
    template = getTemplates(model)[index];
  }

  setTemplateOrd(template, getCardOrd(card));
  final output = render(note, card, model, template, fillEmpty, collection);
  setCardRenderOutput(card, output);
  setCardNote(card, note);
  return card;
}
