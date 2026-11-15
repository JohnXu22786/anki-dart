/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 or (at your option) any later version.
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
 * Source-derived from MenuItem.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Applies a host resource drawable to a host menu item, preserving the
/// operation order of AnkiDroid's `MenuItem.setIconRes()` extension.
///
/// The host owns [context], [menuItem], Android resource lookup, drawable
/// mutation, configuration access, layout-direction handling, and icon setting.
/// The callbacks expose only the operations needed by the source helper. If
/// [getDrawable] returns null, no other callback runs. Otherwise [mutate]'s
/// returned drawable token is passed to [setLayoutDirection] and [setIcon] in
/// that order; [getLayoutDirection] is called between mutation and direction
/// application. Callback failures propagate unchanged and stop later calls.
void menuItemSetIconRes({
  required Object context,
  required Object menuItem,
  required int resId,
  required Object? Function(Object context, int resId) getDrawable,
  required Object Function(Object drawable) mutate,
  required int Function(Object context) getLayoutDirection,
  required void Function(Object drawable, int layoutDirection)
  setLayoutDirection,
  required void Function(Object menuItem, Object drawable) setIcon,
}) {
  final drawable = getDrawable(context, resId);
  if (drawable == null) return;

  final mutatedDrawable = mutate(drawable);
  final layoutDirection = getLayoutDirection(context);
  setLayoutDirection(mutatedDrawable, layoutDirection);
  setIcon(menuItem, mutatedDrawable);
}
