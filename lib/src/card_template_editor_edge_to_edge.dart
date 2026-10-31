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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Installs the host's source-ordered Card Template Editor inset callbacks.
///
/// The host callbacks retain Android edge-to-edge configuration, listener and
/// view registration, inset masks, resource IDs, and padding updates. Inset
/// masks, inset values, views, and the fragmented state are read only at their
/// source call sites. Callback failures propagate and stop later work.
void setupCardTemplateEditorEdgeToEdge<Insets, InsetsTypes, View>({
  required void Function() enableEdgeToEdgeDarkTransparent,
  required void Function(Insets Function(Insets insets) listener)
  installTopInsetsListener,
  required void Function(Insets Function(Insets insets) listener)
  installRootInsetsListener,
  required InsetsTypes Function() topInsetTypes,
  required InsetsTypes Function() rootInsetTypes,
  required Insets Function(Insets insets, InsetsTypes types) getInsets,
  required bool Function() isFragmented,
  required View? Function() findTopView,
  required View? Function() findEditorView,
  required View? Function() findFragmentContainerView,
  required int Function(Insets insets) leftInset,
  required int Function(Insets insets) topInset,
  required int Function(Insets insets) rightInset,
  required void Function(View view, {int? left, int? top, int? right})
  updatePadding,
}) {
  enableEdgeToEdgeDarkTransparent();
  installTopInsetsListener((insets) {
    final constraints = getInsets(insets, topInsetTypes());
    final view = findTopView();
    if (view != null) {
      updatePadding(
        view,
        left: leftInset(constraints),
        top: topInset(constraints),
        right: rightInset(constraints),
      );
    }
    return insets;
  });
  installRootInsetsListener((insets) {
    final constraints = getInsets(insets, rootInsetTypes());
    if (isFragmented()) {
      final editor = findEditorView();
      if (editor != null) {
        updatePadding(editor, left: leftInset(constraints));
      }
      final fragmentContainer = findFragmentContainerView();
      if (fragmentContainer != null) {
        updatePadding(fragmentContainer, right: rightInset(constraints));
      }
    }
    return insets;
  });
}
