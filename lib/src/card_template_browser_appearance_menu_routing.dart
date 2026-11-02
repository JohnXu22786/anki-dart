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
 * Behavioral reference: CardTemplateBrowserAppearanceEditor.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Semantic browser-appearance menu actions resolved by the host.
enum BrowserAppearanceMenuAction { confirm, restoreDefault, home, other }

/// Routes a resolved menu action through host callbacks in source order.
///
/// Only [BrowserAppearanceMenuAction.home] calls [hasChanges]. Callback
/// exceptions propagate immediately, preventing later callbacks from running.
/// Android item ID resolution, logging, dialogs, saving, Activity behavior, and
/// superclass handling remain with the host.
bool routeBrowserAppearanceMenuAction({
  required BrowserAppearanceMenuAction action,
  required void Function() saveAndExit,
  required void Function() showRestoreDefaultDialog,
  required bool Function() hasChanges,
  required void Function() showDiscardChangesDialog,
  required void Function() finish,
  required bool Function() superOnOptionsItemSelected,
}) {
  switch (action) {
    case BrowserAppearanceMenuAction.confirm:
      saveAndExit();
      return true;
    case BrowserAppearanceMenuAction.restoreDefault:
      showRestoreDefaultDialog();
      return true;
    case BrowserAppearanceMenuAction.home:
      if (hasChanges()) {
        showDiscardChangesDialog();
      } else {
        finish();
      }
      return true;
    case BrowserAppearanceMenuAction.other:
      return superOnOptionsItemSelected();
  }
}
