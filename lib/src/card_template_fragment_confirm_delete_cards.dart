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
 * Source-derived from CardTemplateFragment.confirmDeleteCards in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.confirmDeleteCards`.
///
/// Android dialogs, plural resources, generated template JSON, sync behavior,
/// and template mutation remain host-side. The sequence is synchronous and
/// stops at the first callback failure; the registered confirmation stays
/// lazy until invoked by the host dialog.
final class CardTemplateFragmentConfirmDeleteCardsCallbacks<
  TTemplate,
  TNotetype,
  TDialog
> {
  const CardTemplateFragmentConfirmDeleteCardsCallbacks({
    required this.createDialog,
    required this.getQuantityString,
    required this.readTemplateName,
    required this.formatMessage,
    required this.getTitle,
    required this.getPositiveButtonText,
    required this.setArgs,
    required this.deleteTemplate,
    required this.executeWithSyncCheck,
    required this.setConfirm,
    required this.showDialog,
  });

  final TDialog Function() createDialog;
  final String Function(int quantity) getQuantityString;
  final String Function(TTemplate template) readTemplateName;
  final String Function(String template, int count, String name) formatMessage;
  final String Function() getTitle;
  final String Function() getPositiveButtonText;
  final void Function(
    TDialog dialog,
    String title,
    String message,
    String positiveButtonText,
  )
  setArgs;
  final void Function(TTemplate template, TNotetype notetype) deleteTemplate;
  final void Function(void Function() deleteAction) executeWithSyncCheck;
  final void Function(TDialog dialog, void Function() confirm) setConfirm;
  final void Function(TDialog dialog) showDialog;
}

/// Projects `CardTemplateFragment.confirmDeleteCards` in pinned source order.
///
/// The host supplies the unchanged affected-card count, the quantity string,
/// and the template name projected from `tmpl.jsonObject.optString("name")`.
/// The delete action is registered lazily inside the confirmation callback, so
/// neither sync checking nor template deletion runs before confirmation.
void cardTemplateFragmentConfirmDeleteCards<TTemplate, TNotetype, TDialog>({
  required TTemplate template,
  required TNotetype notetype,
  required int numAffectedCards,
  required CardTemplateFragmentConfirmDeleteCardsCallbacks<
    TTemplate,
    TNotetype,
    TDialog
  >
  callbacks,
}) {
  final dialog = callbacks.createDialog();
  final messageTemplate = callbacks.getQuantityString(numAffectedCards);
  final templateName = callbacks.readTemplateName(template);
  final message = callbacks.formatMessage(
    messageTemplate,
    numAffectedCards,
    templateName,
  );
  final title = callbacks.getTitle();
  final positiveButtonText = callbacks.getPositiveButtonText();
  callbacks.setArgs(dialog, title, message, positiveButtonText);

  final deleteCard = () => callbacks.deleteTemplate(template, notetype);
  final confirm = () => callbacks.executeWithSyncCheck(deleteCard);
  callbacks.setConfirm(dialog, confirm);
  callbacks.showDialog(dialog);
}
