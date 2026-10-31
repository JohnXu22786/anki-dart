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
 * Source-derived from CardTemplateFragment.confirmAddCards in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.confirmAddCards`.
///
/// Android dialog/resources/localization, quantity formatting, note-type and
/// model access, actual template creation and sync behavior, lifecycle, and UI
/// remain host-side. The add action is lazy until the confirmation callback is
/// invoked, and callback failures propagate without running later effects.
final class CardTemplateFragmentConfirmAddCardsCallbacks<TNotetype, TDialog> {
  const CardTemplateFragmentConfirmAddCardsCallbacks({
    required this.createDialog,
    required this.getQuantityString,
    required this.formatMessage,
    required this.getTitle,
    required this.getPositiveButtonText,
    required this.setArgs,
    required this.addNewTemplate,
    required this.executeWithSyncCheck,
    required this.setConfirm,
    required this.showDialog,
  });

  final TDialog Function() createDialog;
  final String Function(int quantity) getQuantityString;
  final String Function(String template, int count) formatMessage;
  final String Function() getTitle;
  final String Function() getPositiveButtonText;
  final void Function(
    TDialog dialog,
    String title,
    String message,
    String positiveButtonText,
  )
  setArgs;
  final void Function(TNotetype notetype) addNewTemplate;
  final void Function(void Function() addAction) executeWithSyncCheck;
  final void Function(TDialog dialog, void Function() confirm) setConfirm;
  final void Function(TDialog dialog) showDialog;
}

/// Projects `CardTemplateFragment.confirmAddCards` in pinned source order.
///
/// The host supplies the unchanged affected-card count and quantity formatting.
/// Adding a card template is deferred until the host invokes the registered
/// confirmation; neither the sync check nor the add action runs beforehand.
void cardTemplateFragmentConfirmAddCards<TNotetype, TDialog>({
  required TNotetype notetype,
  required int numAffectedCards,
  required CardTemplateFragmentConfirmAddCardsCallbacks<TNotetype, TDialog>
  callbacks,
}) {
  final dialog = callbacks.createDialog();
  final messageTemplate = callbacks.getQuantityString(numAffectedCards);
  final message = callbacks.formatMessage(messageTemplate, numAffectedCards);
  final title = callbacks.getTitle();
  final positiveButtonText = callbacks.getPositiveButtonText();
  callbacks.setArgs(dialog, title, message, positiveButtonText);

  final addCard = () => callbacks.addNewTemplate(notetype);
  final confirm = () => callbacks.executeWithSyncCheck(addCard);
  callbacks.setConfirm(dialog, confirm);
  callbacks.showDialog(dialog);
}
