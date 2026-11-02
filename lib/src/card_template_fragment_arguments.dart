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

/// Host callbacks needed to create a `CardTemplateFragment` and its arguments.
///
/// The host supplies Android fragment and Bundle construction, argument keys,
/// and typed Bundle writes. This class preserves the source's `putInt` versus
/// `putLong` boundary without importing Android types into the Dart library.
final class CardTemplateFragmentArgumentCallbacks<TFragment, TBundle> {
  const CardTemplateFragmentArgumentCallbacks({
    required this.createFragment,
    required this.createBundle,
    required this.putInt,
    required this.putLong,
    required this.assignArguments,
  });

  final TFragment Function() createFragment;
  final TBundle Function() createBundle;
  final void Function(TBundle bundle, String key, int value) putInt;
  final void Function(TBundle bundle, String key, int value) putLong;
  final void Function(TFragment fragment, TBundle bundle) assignArguments;
}

/// Creates a host fragment with the source-ordered card-template arguments.
///
/// The fragment is created before its Bundle. The Bundle receives the card
/// index as an integer, note ID as a long, and view ID as an integer, then is
/// assigned to that exact fragment. Android object construction, key constants
/// and runtime ID types remain host-side. Callback errors propagate immediately.
TFragment createCardTemplateFragment<TFragment, TBundle>({
  required int cardIndex,
  required int noteId,
  required int viewId,
  required String cardIndexKey,
  required String noteIdKey,
  required String viewIdKey,
  required CardTemplateFragmentArgumentCallbacks<TFragment, TBundle> callbacks,
}) {
  final fragment = callbacks.createFragment();
  final arguments = callbacks.createBundle();
  callbacks.putInt(arguments, cardIndexKey, cardIndex);
  callbacks.putLong(arguments, noteIdKey, noteId);
  callbacks.putInt(arguments, viewIdKey, viewId);
  callbacks.assignArguments(fragment, arguments);
  return fragment;
}
