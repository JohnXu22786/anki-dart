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

/// Portable actions selected by `CardTemplateEditor.onKeyUp` Ctrl shortcuts.
///
/// Android key values and the effects for these actions are supplied and kept
/// by the host application.
enum CardTemplateEditorCtrlAction {
  performPreview,
  selectFrontTab,
  selectBackTab,
  selectStylingTab,
  saveNoteType,
  showInsertFieldDialog,
  addCardTemplate,
  showRenameDialog,
  openBrowserAppearance,
  deleteCardTemplate,
  displayDeckOverrideDialog,
  copyMarkdown,
}

/// Android keycode values supplied by the host for the source shortcut keys.
final class CardTemplateEditorCtrlKeyCodes {
  const CardTemplateEditorCtrlKeyCodes({
    required this.p,
    required this.one,
    required this.two,
    required this.three,
    required this.s,
    required this.i,
    required this.n,
    required this.r,
    required this.b,
    required this.d,
    required this.o,
    required this.m,
  });

  final int p;
  final int one;
  final int two;
  final int three;
  final int s;
  final int i;
  final int n;
  final int r;
  final int b;
  final int d;
  final int o;
  final int m;

  CardTemplateEditorCtrlAction? actionFor(int keyCode) {
    if (keyCode == p) return CardTemplateEditorCtrlAction.performPreview;
    if (keyCode == one) return CardTemplateEditorCtrlAction.selectFrontTab;
    if (keyCode == two) return CardTemplateEditorCtrlAction.selectBackTab;
    if (keyCode == three) return CardTemplateEditorCtrlAction.selectStylingTab;
    if (keyCode == s) return CardTemplateEditorCtrlAction.saveNoteType;
    if (keyCode == i) return CardTemplateEditorCtrlAction.showInsertFieldDialog;
    if (keyCode == n) return CardTemplateEditorCtrlAction.addCardTemplate;
    if (keyCode == r) return CardTemplateEditorCtrlAction.showRenameDialog;
    if (keyCode == b) return CardTemplateEditorCtrlAction.openBrowserAppearance;
    if (keyCode == d) return CardTemplateEditorCtrlAction.deleteCardTemplate;
    if (keyCode == o) {
      return CardTemplateEditorCtrlAction.displayDeckOverrideDialog;
    }
    if (keyCode == m) return CardTemplateEditorCtrlAction.copyMarkdown;
    return null;
  }
}

/// Host integration points for `CardTemplateEditor.onKeyUp` shortcut routing.
///
/// The host resolves the current Fragment, reads KeyEvent modifier state,
/// delegates to Activity's superclass, logs, and performs Android effects. The
/// action callback receives the same resolved Fragment; for deck override the
/// host passes that fragment's temporary model to its dialog.
final class CardTemplateEditorCtrlShortcutCallbacks<TFragment, TEvent> {
  const CardTemplateEditorCtrlShortcutCallbacks({
    required this.currentFragment,
    required this.isCtrlPressed,
    required this.superclassOnKeyUp,
    required this.log,
    required this.performAction,
  });

  final TFragment? Function() currentFragment;
  final bool Function(TEvent event) isCtrlPressed;
  final bool Function(int keyCode, TEvent event) superclassOnKeyUp;
  final void Function(CardTemplateEditorCtrlAction action) log;
  final void Function(TFragment fragment, CardTemplateEditorCtrlAction action)
  performAction;
}

/// Routes one key-up event in the same decision and callback order as source.
///
/// The current fragment is resolved once before Ctrl state. Missing fragments,
/// non-Ctrl events, and unknown Ctrl keys return the host superclass result.
/// Recognized Ctrl actions log before one host action and return true. Host
/// callback failures propagate and prevent subsequent work.
bool dispatchCardTemplateEditorCtrlShortcut<TFragment, TEvent>({
  required int keyCode,
  required TEvent event,
  required CardTemplateEditorCtrlKeyCodes keyCodes,
  required CardTemplateEditorCtrlShortcutCallbacks<TFragment, TEvent> callbacks,
}) {
  final fragment = callbacks.currentFragment();
  if (fragment == null) {
    return callbacks.superclassOnKeyUp(keyCode, event);
  }
  if (!callbacks.isCtrlPressed(event)) {
    return callbacks.superclassOnKeyUp(keyCode, event);
  }

  final action = keyCodes.actionFor(keyCode);
  if (action == null) {
    return callbacks.superclassOnKeyUp(keyCode, event);
  }

  callbacks.log(action);
  callbacks.performAction(fragment, action);
  return true;
}
