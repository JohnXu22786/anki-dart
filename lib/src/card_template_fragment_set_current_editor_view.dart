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

/// Sequences host callbacks for switching the current card-template editor.
///
/// Cursor maps are opaque host-owned values. The first and second map reads are
/// separate lookups, and nullable maps skip their corresponding callbacks.
/// Android views, map storage, and current-view state remain host-side. Callback
/// failures propagate immediately and prevent later callbacks.
void cardTemplateFragmentSetCurrentEditorView({
  required int cardId,
  required int viewId,
  required String editorContent,
  required Object? Function(int cardId) readCursorPositionMap,
  required int Function() readSelectionStart,
  required void Function(Object cursorMap, int selectionStart)
  saveSelectionForCurrentView,
  required void Function(int viewId) setCurrentEditorViewId,
  required void Function(String content) setText,
  required bool Function() isCurrentPage,
  required void Function() requestFocus,
  required int Function(Object cursorMap, int viewId) readCursorPosition,
  required void Function(int offset) setSelection,
}) {
  final previousCursorMap = readCursorPositionMap(cardId);
  if (previousCursorMap != null) {
    final selectionStart = readSelectionStart();
    saveSelectionForCurrentView(previousCursorMap, selectionStart);
  }

  setCurrentEditorViewId(viewId);
  setText(editorContent);
  if (isCurrentPage()) {
    requestFocus();
  }

  final currentCursorMap = readCursorPositionMap(cardId);
  final selection = currentCursorMap == null
      ? 0
      : readCursorPosition(currentCursorMap, viewId);
  setSelection(selection);
}
