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
 * Source-derived from MenuHost.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Registers a provider that forwards preparation of an existing menu.
///
/// Android MenuHost, MenuProvider, Menu, MenuInflater, and MenuItem values stay
/// in the host and are represented by opaque generic tokens here. Provider
/// creation precedes one registration call. Creating a menu does nothing,
/// preparing it forwards the identical menu token to [onPrepare], and selecting
/// an item returns false. Callback failures propagate unchanged.
void menuHostAddPrepareMenuProvider<
  TMenuHost,
  TMenu,
  TMenuInflater,
  TMenuItem,
  TMenuProvider
>({
  required TMenuHost menuHost,
  required void Function(TMenu) onPrepare,
  required TMenuProvider Function(
    void Function(TMenu menu, TMenuInflater inflater) onCreateMenu,
    void Function(TMenu menu) onPrepareMenu,
    bool Function(TMenuItem item) onMenuItemSelected,
  )
  createMenuProvider,
  required void Function(TMenuHost menuHost, TMenuProvider menuProvider)
  addMenuProvider,
}) {
  final menuProvider = createMenuProvider(
    (menu, inflater) {},
    onPrepare,
    (item) => false,
  );
  addMenuProvider(menuHost, menuProvider);
}
