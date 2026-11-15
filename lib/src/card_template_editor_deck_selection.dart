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

/// Host callbacks used by `CardTemplateEditor.onDeckSelected`.
///
/// The host keeps deck and template models, JSON mutation, filtered-deck
/// lookup, logging, localization, snackbar duration, menu invalidation, and
/// discard-change UI. Dart only sequences the lazy operations.
final class CardTemplateDeckSelectionCallbacks<
  TDeck extends Object,
  TTemplate
> {
  const CardTemplateDeckSelectionCallbacks({
    required this.validateDeck,
    required this.isCloze,
    required this.warnCloze,
    required this.clozeErrorMessage,
    required this.currentOrdinal,
    required this.templateAt,
    required this.templateName,
    required this.deckId,
    required this.isFilteredDeck,
    required this.deckName,
    required this.warnFilteredDeck,
    required this.logRemoval,
    required this.logAddition,
    required this.setDeckOverride,
    required this.deckOverrideRemovedMessage,
    required this.deckOverrideAddedMessage,
    required this.filteredDeckErrorMessage,
    required this.showShortSnackbar,
    required this.invalidateOptionsMenu,
    required this.updateDiscardChanges,
  });

  /// Performs the host equivalent of `require(deck is SelectableDeck.Deck?)`.
  final void Function(TDeck? deck) validateDeck;
  final bool Function() isCloze;
  final void Function() warnCloze;
  final String Function() clozeErrorMessage;
  final int Function() currentOrdinal;
  final TTemplate Function(int ordinal) templateAt;
  final String Function(TTemplate template) templateName;
  final int Function(TDeck deck) deckId;
  final bool Function(int deckId) isFilteredDeck;
  final String Function(TDeck deck) deckName;
  final void Function(String templateName, String deckName) warnFilteredDeck;
  final void Function(String templateName) logRemoval;
  final void Function(String templateName, String deckName) logAddition;
  final void Function(TTemplate template, int? deckId) setDeckOverride;
  final String Function(String templateName) deckOverrideRemovedMessage;
  final String Function(String templateName, String deckName)
  deckOverrideAddedMessage;
  final String Function() filteredDeckErrorMessage;
  final void Function(String message) showShortSnackbar;
  final void Function() invalidateOptionsMenu;
  final void Function() updateDiscardChanges;
}

/// Applies a selected card-template deck override in source callback order.
///
/// Cloze note types and filtered decks show the host's error message and
/// return before mutation or final UI effects. Callback failures propagate
/// unchanged and stop later work.
void cardTemplateEditorDeckSelected<TDeck extends Object, TTemplate>({
  required TDeck? deck,
  required CardTemplateDeckSelectionCallbacks<TDeck, TTemplate> callbacks,
}) {
  callbacks.validateDeck(deck);

  if (callbacks.isCloze()) {
    callbacks.warnCloze();
    final message = callbacks.clozeErrorMessage();
    callbacks.showShortSnackbar(message);
    return;
  }

  final ordinal = callbacks.currentOrdinal();
  final template = callbacks.templateAt(ordinal);
  final templateName = callbacks.templateName(template);

  if (deck != null && callbacks.isFilteredDeck(callbacks.deckId(deck))) {
    final selectedDeckName = callbacks.deckName(deck);
    callbacks.warnFilteredDeck(templateName, selectedDeckName);
    final message = callbacks.filteredDeckErrorMessage();
    callbacks.showShortSnackbar(message);
    return;
  }

  late final String message;
  if (deck == null) {
    callbacks.logRemoval(templateName);
    callbacks.setDeckOverride(template, null);
    message = callbacks.deckOverrideRemovedMessage(templateName);
  } else {
    final selectedDeckName = callbacks.deckName(deck);
    callbacks.logAddition(templateName, selectedDeckName);
    callbacks.setDeckOverride(template, callbacks.deckId(deck));
    message = callbacks.deckOverrideAddedMessage(
      templateName,
      callbacks.deckName(deck),
    );
  }

  callbacks.showShortSnackbar(message);
  callbacks.invalidateOptionsMenu();
  callbacks.updateDiscardChanges();
}
