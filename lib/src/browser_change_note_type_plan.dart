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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Result of AnkiDroid's selected-note type compatibility check.
sealed class BrowserChangeNoteTypePlan {
  const BrowserChangeNoteTypePlan();
}

/// The source selected-note list was empty.
final class BrowserChangeNoteTypeNoSelection extends BrowserChangeNoteTypePlan {
  const BrowserChangeNoteTypeNoSelection();
}

/// At least one selected note was not in the first note's type membership set.
final class BrowserChangeNoteTypeMixedSelection
    extends BrowserChangeNoteTypePlan {
  const BrowserChangeNoteTypeMixedSelection();
}

/// Distinct note IDs for the source ChangeNoteType response.
final class BrowserChangeNoteTypeSelection extends BrowserChangeNoteTypePlan {
  BrowserChangeNoteTypeSelection._(List<int> noteIds)
    : noteIds = List.unmodifiable(noteIds);

  /// Applies the source factory's non-empty precondition and `distinct()`.
  factory BrowserChangeNoteTypeSelection.fromNoteIds(Iterable<int> noteIds) {
    final ids = noteIds.toList();
    if (ids.isEmpty) {
      throw ArgumentError.value(ids, 'noteIds', 'a non-empty list is required');
    }

    final seen = <int>{};
    final distinctIds = <int>[];
    for (final id in ids) {
      if (seen.add(id)) distinctIds.add(id);
    }
    return BrowserChangeNoteTypeSelection._(distinctIds);
  }

  final List<int> noteIds;
}

/// Plans the host's change-note-type response without resolving note types.
///
/// Empty [selectedNoteIds] returns [BrowserChangeNoteTypeNoSelection] without
/// needing [firstNoteTypeMembershipIds]. Otherwise the host must supply the
/// first selected note's type membership IDs. IDs absent from that set select
/// [BrowserChangeNoteTypeMixedSelection]; a compatible selection is deduplicated
/// in first-occurrence order.
BrowserChangeNoteTypePlan planBrowserChangeNoteType({
  required Iterable<int> selectedNoteIds,
  Iterable<int>? firstNoteTypeMembershipIds,
}) {
  final selected = selectedNoteIds.toList();
  if (selected.isEmpty) return const BrowserChangeNoteTypeNoSelection();

  final membershipIds = firstNoteTypeMembershipIds;
  if (membershipIds == null) {
    throw ArgumentError.notNull('firstNoteTypeMembershipIds');
  }
  final membership = membershipIds.toSet();
  if (!selected.every(membership.contains)) {
    return const BrowserChangeNoteTypeMixedSelection();
  }

  return BrowserChangeNoteTypeSelection.fromNoteIds(selected);
}
