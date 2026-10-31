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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for CardTemplateFragment's bottom-navigation selection.
///
/// Android MenuItem/title and resource IDs, the tab map, fragment/model/template
/// state, view state, and menu invalidation remain host-side. The callbacks
/// expose each source read and write so the host's state is accessed in source
/// order.
final class CardTemplateFragmentBottomNavigationSelectionCallbacks<TMenuItem> {
  const CardTemplateFragmentBottomNavigationSelectionCallbacks({
    required this.itemId,
    required this.itemTitle,
    required this.cardIndex,
    required this.writeTabToViewId,
    required this.logInfo,
    required this.stylingEditId,
    required this.backEditId,
    required this.fragmentTempModelCss,
    required this.currentTemplateAnswerFormat,
    required this.currentTemplateQuestionFormat,
    required this.setCurrentEditorView,
    required this.invalidateOptionsMenu,
  });

  final int Function(TMenuItem item) itemId;
  final Object? Function(TMenuItem item) itemTitle;
  final int Function() cardIndex;
  final void Function(int cardIndex, int selectedId) writeTabToViewId;
  final void Function(String message, Object? argument) logInfo;
  final int stylingEditId;
  final int backEditId;
  final String Function() fragmentTempModelCss;
  final String Function() currentTemplateAnswerFormat;
  final String Function() currentTemplateQuestionFormat;
  final void Function(int selectedId, int cardIndex, String content)
  setCurrentEditorView;
  final void Function() invalidateOptionsMenu;
}

/// Handles a host bottom-navigation selection in pinned source callback order.
///
/// The menu item ID is read once. Its tab mapping is written before title logging;
/// the selected branch then freshly reads its index and content. Callback
/// failures propagate unchanged and stop subsequent source operations.
bool cardTemplateFragmentBottomNavigationSelection<TMenuItem>({
  required TMenuItem item,
  required CardTemplateFragmentBottomNavigationSelectionCallbacks<TMenuItem>
  callbacks,
}) {
  final selectedId = callbacks.itemId(item);
  callbacks.writeTabToViewId(callbacks.cardIndex(), selectedId);
  callbacks.logInfo('selected editor view: %s', callbacks.itemTitle(item));

  if (selectedId == callbacks.stylingEditId) {
    callbacks.setCurrentEditorView(
      selectedId,
      callbacks.cardIndex(),
      callbacks.fragmentTempModelCss(),
    );
  } else if (selectedId == callbacks.backEditId) {
    callbacks.setCurrentEditorView(
      selectedId,
      callbacks.cardIndex(),
      callbacks.currentTemplateAnswerFormat(),
    );
  } else {
    callbacks.setCurrentEditorView(
      selectedId,
      callbacks.cardIndex(),
      callbacks.currentTemplateQuestionFormat(),
    );
  }

  callbacks.invalidateOptionsMenu();
  return true;
}
