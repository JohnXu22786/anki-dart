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
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// One ordered host operation for a DeckPicker navigation action.
sealed class DeckPickerNavigationStep {
  const DeckPickerNavigationStep();
}

/// The host selects [deckId] in its collection before continuing the plan.
final class DeckPickerSelectForNavigation extends DeckPickerNavigationStep {
  const DeckPickerSelectForNavigation(this.deckId);

  final int deckId;
}

/// The host navigates to the browser for [deckId].
final class DeckPickerNavigateToBrowser extends DeckPickerNavigationStep {
  const DeckPickerNavigateToBrowser(this.deckId);

  final int deckId;
}

/// The host navigates to the add-note editor with the original nullable ID.
final class DeckPickerNavigateToAddNote extends DeckPickerNavigationStep {
  const DeckPickerNavigateToAddNote(this.deckId);

  final int? deckId;
}

/// How the host obtains the filtered-deck value for deck-options navigation.
sealed class DeckPickerFilteredState {
  const DeckPickerFilteredState();
}

/// Uses the explicit value supplied to `openDeckOptions` without a lookup.
final class DeckPickerUseFilteredState extends DeckPickerFilteredState {
  const DeckPickerUseFilteredState(this.isFiltered);

  final bool isFiltered;
}

/// Asks the host to resolve `decks.isFiltered(deckId)` from its collection.
final class DeckPickerResolveFilteredStateFromCollection
    extends DeckPickerFilteredState {
  const DeckPickerResolveFilteredStateFromCollection(this.deckId);

  final int deckId;
}

/// The host creates and navigates to deck options using [filteredState].
final class DeckPickerNavigateToDeckOptions extends DeckPickerNavigationStep {
  const DeckPickerNavigateToDeckOptions({
    required this.deckId,
    required this.filteredState,
  });

  final int deckId;
  final DeckPickerFilteredState filteredState;
}

/// Immutable ordered operations for one DeckPicker navigation action.
final class DeckPickerNavigationPlan {
  DeckPickerNavigationPlan(Iterable<DeckPickerNavigationStep> steps)
    : steps = List.unmodifiable(steps);

  final List<DeckPickerNavigationStep> steps;
}

/// Projects `browseCards`: collection selection precedes browser navigation.
DeckPickerNavigationPlan planDeckPickerBrowseCards(int deckId) =>
    DeckPickerNavigationPlan([
      DeckPickerSelectForNavigation(deckId),
      DeckPickerNavigateToBrowser(deckId),
    ]);

/// Projects `addNote`, selecting only for a non-null ID marked as current.
///
/// Navigation always carries [deckId] unchanged, including when null or when
/// [setAsCurrent] is false. Collection access and navigation remain host-side.
DeckPickerNavigationPlan planDeckPickerAddNote({
  required int? deckId,
  required bool setAsCurrent,
}) => DeckPickerNavigationPlan([
  if (deckId != null && setAsCurrent) DeckPickerSelectForNavigation(deckId),
  DeckPickerNavigateToAddNote(deckId),
]);

/// Projects `openDeckOptions` without resolving collection state in Dart.
///
/// Any explicit [isFiltered] value, including false, is used directly. A null
/// value asks the host to resolve `decks.isFiltered(deckId)` before creating
/// the destination. Collection access, destination construction, and navigation
/// remain host-side.
DeckPickerNavigationPlan planDeckPickerOpenDeckOptions({
  required int deckId,
  bool? isFiltered,
}) => DeckPickerNavigationPlan([
  DeckPickerNavigateToDeckOptions(
    deckId: deckId,
    filteredState: isFiltered == null
        ? DeckPickerResolveFilteredStateFromCollection(deckId)
        : DeckPickerUseFilteredState(isFiltered),
  ),
]);
