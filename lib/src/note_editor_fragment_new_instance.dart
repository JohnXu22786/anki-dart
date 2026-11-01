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
 * Source-derived from NoteEditorFragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts `NoteEditorFragment.Companion.newInstance(args)`.
///
/// The host supplies Android fragment construction and its arguments property
/// setter. The exact [args] value is assigned once to the single fragment
/// created, and that fragment is returned. Callback failures propagate
/// unchanged and stop subsequent work.
TFragment noteEditorFragmentNewInstance<TFragment, TArguments>({
  required TArguments args,
  required TFragment Function() createFragment,
  required void Function(TFragment fragment, TArguments arguments)
  assignArguments,
}) {
  final fragment = createFragment();
  assignArguments(fragment, args);
  return fragment;
}
