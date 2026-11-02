/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

/// Host callbacks for `CardTemplateEditor.templateFragment(position)`.
///
/// The Android pager adapter, FragmentManager, and fragments remain host-side.
/// This projection only sequences adapter ID lookup and tagged fragment lookup.
final class CardTemplateEditorTemplateFragmentCallbacks<TAdapter, TFragment> {
  const CardTemplateEditorTemplateFragmentCallbacks({
    required this.readPagerAdapter,
    required this.getItemId,
    required this.findFragmentByTag,
  });

  final TAdapter? Function() readPagerAdapter;
  final BigInt Function(TAdapter adapter, int position) getItemId;
  final Object? Function(String tag) findFragmentByTag;
}

/// Looks up the source-tagged `CardTemplateFragment` for [position].
///
/// The pager adapter is read once. If it is absent, no other callback runs.
/// Otherwise its item ID is read once using the unchanged position, converted
/// to decimal with `BigInt.toString()`, and prefixed with lowercase `f`.
/// The host performs the nullable runtime type check; a different fragment type
/// returns null. Callback failures propagate unchanged and stop later work.
TFragment? cardTemplateEditorTemplateFragment<TAdapter, TFragment>({
  required int position,
  required CardTemplateEditorTemplateFragmentCallbacks<TAdapter, TFragment>
  callbacks,
}) {
  final adapter = callbacks.readPagerAdapter();
  if (adapter == null) return null;

  final itemId = callbacks.getItemId(adapter, position);
  final fragment = callbacks.findFragmentByTag('f${itemId.toString()}');
  return fragment is TFragment ? fragment : null;
}
