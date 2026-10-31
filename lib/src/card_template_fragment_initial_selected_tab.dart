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

/// Host callbacks for `CardTemplateFragment.onViewCreated()` initial tab setup.
///
/// The Android tab map, Bundle, generated editor-view key, bottom navigation,
/// and UI remain host-side. The host's [readEditorViewId] callback reads the
/// required arguments and calls `getInt` with the generated key.
final class CardTemplateFragmentInitialSelectedTabCallbacks<TArguments> {
  const CardTemplateFragmentInitialSelectedTabCallbacks({
    required this.readCardIndex,
    required this.readTabToViewId,
    required this.requireArguments,
    required this.readEditorViewId,
    required this.setSelectedItemId,
  });

  final int Function() readCardIndex;
  final int? Function(int cardIndex) readTabToViewId;
  final TArguments Function() requireArguments;
  final int Function(TArguments arguments) readEditorViewId;
  final void Function(int selectedItemId) setSelectedItemId;
}

/// Resolves and assigns the initial editor tab in source evaluation order.
///
/// It reads [callbacks.readCardIndex] once, then looks up that index in the
/// host tab map. A non-null ID skips the required-arguments fallback; otherwise
/// the host reads required arguments and the editor-view ID. The selected ID is
/// assigned to the host bottom navigation exactly once. The host handles any
/// listener effects caused by that assignment. Callback failures propagate
/// unchanged and stop later work.
void cardTemplateFragmentInitialSelectedTab<TArguments>({
  required CardTemplateFragmentInitialSelectedTabCallbacks<TArguments>
  callbacks,
}) {
  final cardIndex = callbacks.readCardIndex();
  final selectedItemId =
      callbacks.readTabToViewId(cardIndex) ??
      callbacks.readEditorViewId(callbacks.requireArguments());
  callbacks.setSelectedItemId(selectedItemId);
}
