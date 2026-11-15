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

/// Returns true when the host creates the text-selection action mode.
bool cardTemplateFragmentActionModeOnCreate() => true;

/// Projects `CardTemplateFragment.ActionModeCallback.onPrepareActionMode()`.
///
/// The Android menu, editor view, localized title, and menu item stay host-side.
/// Callback reads and writes retain source order, and failures propagate before
/// any later callback runs.
bool cardTemplateFragmentActionModeOnPrepare({
  required int insertFieldId,
  required int stylingEditId,
  required int menuFirst,
  required Object? Function(int itemId) findItem,
  required int Function() readMenuSize,
  required int Function() readCurrentEditorViewId,
  required String Function() readInsertFieldTitle,
  required void Function(int groupId, int itemId, int order, String title)
  addMenuItem,
}) {
  if (findItem(insertFieldId) != null) {
    return false;
  }
  final initialSize = readMenuSize();

  if (readCurrentEditorViewId() != stylingEditId) {
    addMenuItem(menuFirst, insertFieldId, 0, readInsertFieldTitle());
  }

  return initialSize != readMenuSize();
}

/// Projects `CardTemplateFragment.ActionModeCallback.onActionItemClicked()`.
///
/// Reads the host item ID once. The dialog callback runs before action-mode
/// finish, and failures propagate without invoking later callbacks.
bool cardTemplateFragmentActionModeOnActionItemClicked({
  required int insertFieldId,
  required int Function() readItemId,
  required void Function() showInsertFieldDialog,
  required void Function() finishActionMode,
}) {
  final itemId = readItemId();
  if (itemId == insertFieldId) {
    showInsertFieldDialog();
    finishActionMode();
    return true;
  }
  return false;
}

/// Mirrors the intentionally empty `onDestroyActionMode()` callback.
void cardTemplateFragmentActionModeOnDestroy() {}
