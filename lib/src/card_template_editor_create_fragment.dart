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

/// Host callbacks for `TemplatePagerAdapter.createFragment(position)`.
///
/// The host retains its Android view-ID map, note ID, Fragment factory, and
/// Fragment/Bundle construction.
final class CardTemplateEditorCreateFragmentCallbacks<
  TNoteId,
  TViewId,
  TFragment
> {
  const CardTemplateEditorCreateFragmentCallbacks({
    required this.readTabToViewId,
    required this.createFragment,
  });

  final TViewId? Function(int position) readTabToViewId;
  final TFragment Function(int position, TNoteId noteId, TViewId editorViewId)
  createFragment;
}

/// Projects `TemplatePagerAdapter.createFragment(position)` in source order.
///
/// It performs one host map lookup with the original [position], selects
/// [frontEditViewId] only when the mapped value is null, then returns the exact
/// Fragment created by the host. Callback failures propagate unchanged.
TFragment cardTemplateEditorCreateFragment<TNoteId, TViewId, TFragment>({
  required int position,
  required TNoteId noteId,
  required TViewId frontEditViewId,
  required CardTemplateEditorCreateFragmentCallbacks<
    TNoteId,
    TViewId,
    TFragment
  >
  callbacks,
}) {
  final editorViewId = callbacks.readTabToViewId(position) ?? frontEditViewId;
  return callbacks.createFragment(position, noteId, editorViewId);
}
