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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Source-mapped transition direction for the Card Browser note editor.
enum BrowserNoteEditorTransitionDirection { defaultDirection }

/// Arguments for the source `NoteEditorDestination.EditSelection` variant.
class BrowserEditSelectionDestination {
  const BrowserEditSelectionDestination({
    required this.cardIds,
    required this.animation,
    required this.inCardBrowserActivity,
  });

  /// The host-resolved card IDs, retained exactly as supplied.
  final List<int> cardIds;

  /// The source transition direction.
  final BrowserNoteEditorTransitionDirection animation;

  /// Whether the browser itself hosts the editor pane.
  final bool inCardBrowserActivity;
}

/// Builds the source Card Browser EditSelection destination, or null when
/// there are no host-resolved card IDs. The host retains warning/logging and
/// destination delivery.
BrowserEditSelectionDestination? browserEditNoteDestination({
  required List<int> cardIds,
  required bool isFragmented,
}) {
  if (cardIds.isEmpty) return null;

  return BrowserEditSelectionDestination(
    cardIds: cardIds,
    animation: BrowserNoteEditorTransitionDirection.defaultDirection,
    inCardBrowserActivity: isFragmented,
  );
}
