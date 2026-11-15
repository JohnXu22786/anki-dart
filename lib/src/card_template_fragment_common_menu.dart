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

import 'card_template_editor_dynamic_note_type.dart';

/// Host-supplied Android menu IDs and the source unknown stock-kind sentinel.
final class CardTemplateCommonMenuItemIds {
  const CardTemplateCommonMenuItemIds({
    required this.add,
    required this.reposition,
    required this.rename,
    required this.copyAsMarkdown,
    required this.insertField,
    required this.delete,
    required this.addDeckOverride,
    required this.preview,
    required this.confirm,
    required this.browserAppearance,
    required this.restoreToDefault,
    required this.unknownStockKind,
  });

  final int add;
  final int reposition;
  final int rename;
  final int copyAsMarkdown;
  final int insertField;
  final int delete;
  final int addDeckOverride;
  final int preview;
  final int confirm;
  final int browserAppearance;
  final int restoreToDefault;
  final int unknownStockKind;
}

/// Exact info/debug messages emitted by the pinned common-menu source.
abstract final class cardTemplateCommonMenuLogMessages {
  static const add = 'CardTemplateEditor:: Add template button pressed';
  static const rename = 'CardTemplateEditor:: Rename button pressed';
  static const copyAsMarkdown =
      'CardTemplateEditor:: Copy markdown button pressed';
  static const insertField = 'CardTemplateEditor:: Insert field button pressed';
  static const delete = 'CardTemplateEditor:: Delete template button pressed';
  static const addDeckOverride =
      'CardTemplateEditor:: Deck override button pressed';
  static const preview = 'CardTemplateEditor:: Preview button pressed';
  static const confirm = 'CardTemplateEditor:: Save note type button pressed';
  static const browserAppearance =
      'CardTemplateEditor::Card Browser Template button pressed';
  static const restoreToDefault =
      'CardTemplateEditor:: Restore to default button pressed';
  static const askingToRestore = 'Asking to restore to original stock kind %s';
  static const unknownStockKind =
      'Unknown stock kind: asking which kind to restore to';
  static const dynamicNoteTypeSetup =
      'Editing cloze/occlusion note type, disabling add/delete card template and deck override functionality';
}

/// The source menu entries configured by `CardTemplateFragment.setupCommonMenu`.
enum CardTemplateCommonMenuSetupItem {
  restoreToDefault,
  browserAppearance,
  add,
  rename,
  addDeckOverride,
  delete,
  preview,
  insertField,
}

/// Host callbacks for projecting `CardTemplateFragment.setupCommonMenu(menu)`.
///
/// The host resolves menu items and localized titles, and reads Android/model
/// state. The setup function keeps those callbacks lazy and source ordered;
/// callback failures propagate immediately.
final class CardTemplateCommonMenuSetupCallbacks<TTemplate, TMenuItem> {
  const CardTemplateCommonMenuSetupCallbacks({
    required this.findItem,
    required this.setTitle,
    required this.setVisible,
    required this.restoreToDefaultTitle,
    required this.browserAppearanceTitle,
    required this.deckOverrideTitle,
    required this.debugLog,
    required this.isCloze,
    required this.isImageOcclusion,
    required this.currentTemplate,
    required this.templateHasDid,
    required this.templateDidIsNull,
    required this.templateCount,
    required this.fragmented,
    required this.currentEditorViewId,
    required this.stylingViewId,
  });

  final TMenuItem Function(CardTemplateCommonMenuSetupItem item) findItem;
  final void Function(TMenuItem item, String title) setTitle;
  final void Function(TMenuItem item, bool visible) setVisible;
  final String Function() restoreToDefaultTitle;
  final String Function() browserAppearanceTitle;
  final String Function(bool hasOverride) deckOverrideTitle;
  final void Function(String message) debugLog;
  final bool Function() isCloze;
  final bool Function() isImageOcclusion;
  final TTemplate? Function() currentTemplate;
  final bool Function(TTemplate template) templateHasDid;
  final bool Function(TTemplate template) templateDidIsNull;
  final int Function() templateCount;
  final bool Function() fragmented;
  final int Function() currentEditorViewId;
  final int Function() stylingViewId;
}

/// Applies the common menu titles and visibility predicates in source order.
void setupCardTemplateCommonMenu<TTemplate, TMenuItem>({
  required CardTemplateCommonMenuSetupCallbacks<TTemplate, TMenuItem> callbacks,
}) {
  final restoreItem = callbacks.findItem(
    CardTemplateCommonMenuSetupItem.restoreToDefault,
  );
  callbacks.setTitle(restoreItem, callbacks.restoreToDefaultTitle());

  final browserAppearanceItem = callbacks.findItem(
    CardTemplateCommonMenuSetupItem.browserAppearance,
  );
  callbacks.setTitle(browserAppearanceItem, callbacks.browserAppearanceTitle());

  final createsDynamicNotes =
      cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
        isCloze: callbacks.isCloze,
        isImageOcclusion: callbacks.isImageOcclusion,
      );
  if (createsDynamicNotes) {
    callbacks.debugLog(cardTemplateCommonMenuLogMessages.dynamicNoteTypeSetup);
    callbacks.setVisible(
      callbacks.findItem(CardTemplateCommonMenuSetupItem.add),
      false,
    );
    callbacks.setVisible(
      callbacks.findItem(CardTemplateCommonMenuSetupItem.rename),
      false,
    );
    callbacks.setVisible(
      callbacks.findItem(CardTemplateCommonMenuSetupItem.addDeckOverride),
      false,
    );
  } else {
    final template = callbacks.currentTemplate();
    final hasOverride =
        template != null &&
        callbacks.templateHasDid(template) &&
        !callbacks.templateDidIsNull(template);
    final deckOverrideItem = callbacks.findItem(
      CardTemplateCommonMenuSetupItem.addDeckOverride,
    );
    callbacks.setTitle(
      deckOverrideItem,
      callbacks.deckOverrideTitle(hasOverride),
    );
  }

  if (callbacks.templateCount() < 2) {
    callbacks.setVisible(
      callbacks.findItem(CardTemplateCommonMenuSetupItem.delete),
      false,
    );
  }

  if (callbacks.fragmented()) {
    callbacks.setVisible(
      callbacks.findItem(CardTemplateCommonMenuSetupItem.preview),
      false,
    );
  }

  final isInsertFieldItemVisible =
      callbacks.currentEditorViewId() != callbacks.stylingViewId();
  callbacks.setVisible(
    callbacks.findItem(CardTemplateCommonMenuSetupItem.insertField),
    isInsertFieldItemVisible,
  );
}

/// Host callbacks for `CardTemplateFragment.handleCommonMenuItemSelected`.
///
/// Android menu/dialog/resource APIs, models, collection access, logging,
/// coroutine scheduling, and mutations remain in the host. Callback reads are
/// intentionally lazy and are invoked in the pinned source's branch order.
final class CardTemplateCommonMenuCallbacks<TModel, TKind> {
  const CardTemplateCommonMenuCallbacks({
    required this.infoLog,
    required this.debugLog,
    required this.addCardTemplate,
    required this.showRepositionDialog,
    required this.showRenameDialog,
    required this.copyMarkdownTemplateToClipboard,
    required this.showInsertFieldDialog,
    required this.deleteCardTemplate,
    required this.currentTempModel,
    required this.displayDeckOverrideDialog,
    required this.performPreview,
    required this.saveNoteType,
    required this.openBrowserAppearance,
    required this.originalStockKind,
    required this.scheduleTask,
    required this.getStockKinds,
    required this.getStockKindNames,
    required this.showStockKindPicker,
    required this.showRestoreConfirmation,
    required this.restoreNotetypeToStock,
  });

  final void Function(String message) infoLog;
  final void Function(String message, [Object? value]) debugLog;
  final void Function() addCardTemplate;
  final void Function() showRepositionDialog;
  final void Function() showRenameDialog;
  final void Function() copyMarkdownTemplateToClipboard;
  final void Function() showInsertFieldDialog;
  final void Function() deleteCardTemplate;
  final TModel Function() currentTempModel;
  final void Function(TModel model) displayDeckOverrideDialog;
  final void Function() performPreview;
  final bool Function() saveNoteType;
  final bool Function() openBrowserAppearance;
  final int Function() originalStockKind;
  final void Function(Future<void> Function() task) scheduleTask;
  final Future<List<TKind>> Function() getStockKinds;
  final Future<List<String>> Function(List<TKind> kinds) getStockKindNames;
  final void Function(List<String> names, void Function(int index) onSelected)
  showStockKindPicker;
  final void Function(
    TKind? kind,
    void Function() onConfirm,
    void Function() onCancel,
  )
  showRestoreConfirmation;
  final Future<void> Function(TKind? kind) restoreNotetypeToStock;
}

/// Routes one menu action, returning the source method's handled result.
///
/// Restore confirmation and unknown-kind lookup are scheduled through the host
/// callback, separate from the immediate handled return. Callback failures are
/// not intercepted here and prevent later source-ordered work.
bool handleCardTemplateCommonMenuItemSelected<TModel, TKind>({
  required int itemId,
  required CardTemplateCommonMenuItemIds ids,
  required CardTemplateCommonMenuCallbacks<TModel, TKind> callbacks,
}) {
  switch (itemId) {
    case final id when id == ids.add:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.add);
      callbacks.addCardTemplate();
      return true;
    case final id when id == ids.reposition:
      callbacks.showRepositionDialog();
      return true;
    case final id when id == ids.rename:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.rename);
      callbacks.showRenameDialog();
      return true;
    case final id when id == ids.copyAsMarkdown:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.copyAsMarkdown);
      callbacks.copyMarkdownTemplateToClipboard();
      return true;
    case final id when id == ids.insertField:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.insertField);
      callbacks.showInsertFieldDialog();
      return true;
    case final id when id == ids.delete:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.delete);
      callbacks.deleteCardTemplate();
      return true;
    case final id when id == ids.addDeckOverride:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.addDeckOverride);
      callbacks.displayDeckOverrideDialog(callbacks.currentTempModel());
      return true;
    case final id when id == ids.preview:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.preview);
      callbacks.performPreview();
      return true;
    case final id when id == ids.confirm:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.confirm);
      return callbacks.saveNoteType();
    case final id when id == ids.browserAppearance:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.browserAppearance);
      return callbacks.openBrowserAppearance();
    case final id when id == ids.restoreToDefault:
      callbacks.infoLog(cardTemplateCommonMenuLogMessages.restoreToDefault);
      final originalStockKind = callbacks.originalStockKind();

      void askUser(TKind? kind) {
        callbacks.showRestoreConfirmation(kind, () {
          callbacks.scheduleTask(() => callbacks.restoreNotetypeToStock(kind));
        }, () {});
      }

      if (originalStockKind != ids.unknownStockKind) {
        callbacks.debugLog(
          cardTemplateCommonMenuLogMessages.askingToRestore,
          originalStockKind,
        );
        askUser(null);
        return true;
      }

      callbacks.scheduleTask(() async {
        callbacks.debugLog(cardTemplateCommonMenuLogMessages.unknownStockKind);
        final stockKinds = await callbacks.getStockKinds();
        final stockNames = await callbacks.getStockKindNames(stockKinds);
        callbacks.showStockKindPicker(stockNames, (index) {
          askUser(stockKinds[index]);
        });
      });
      return true;
    default:
      return false;
  }
}
