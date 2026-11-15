/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'deck_name_path.dart';

/// The host-resolved values used to create an AnkiDroid deck shortcut.
///
/// The host remains responsible for resolving [deckId] to [fullName] and for
/// emitting and delivering the shortcut.
final class ShortcutData {
  ShortcutData(this.deckId, String fullName)
    : shortLabel = deckNameBasename(fullName),
      longLabel = fullName;

  final int deckId;
  final String shortLabel;
  final String longLabel;

  @override
  bool operator ==(Object other) =>
      other is ShortcutData &&
      deckId == other.deckId &&
      shortLabel == other.shortLabel &&
      longLabel == other.longLabel;

  @override
  int get hashCode => Object.hash(deckId, shortLabel, longLabel);
}
