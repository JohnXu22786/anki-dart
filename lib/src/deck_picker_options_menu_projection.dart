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
 * Behavioral reference: `refreshMenuState`, `refreshUndoMenuState`, and
 * `OptionsMenuState` in DeckPickerViewModel.kt, AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'deck_picker_sync_icon_projection.dart';

/// The source data-class state of AnkiDroid's Deck Picker options menu.
final class DeckPickerOptionsMenuState {
  const DeckPickerOptionsMenuState({
    required this.searchIcon,
    required this.undoLabel,
    required this.syncIcon,
    required this.undoAvailable,
    required this.isColEmpty,
  });

  final bool searchIcon;
  final String? undoLabel;
  final DeckPickerSyncIconState syncIcon;
  final bool undoAvailable;
  final bool isColEmpty;

  DeckPickerOptionsMenuState copyWithUndo({
    required String? undoLabel,
    required bool undoAvailable,
  }) => DeckPickerOptionsMenuState(
    searchIcon: searchIcon,
    undoLabel: undoLabel,
    syncIcon: syncIcon,
    undoAvailable: undoAvailable,
    isColEmpty: isColEmpty,
  );

  DeckPickerOptionsMenuState copyWithSyncIcon(
    DeckPickerSyncIconState syncIcon,
  ) => DeckPickerOptionsMenuState(
    searchIcon: searchIcon,
    undoLabel: undoLabel,
    syncIcon: syncIcon,
    undoAvailable: undoAvailable,
    isColEmpty: isColEmpty,
  );

  @override
  bool operator ==(Object other) =>
      other is DeckPickerOptionsMenuState &&
      other.searchIcon == searchIcon &&
      other.undoLabel == undoLabel &&
      other.syncIcon == syncIcon &&
      other.undoAvailable == undoAvailable &&
      other.isColEmpty == isColEmpty;

  @override
  int get hashCode =>
      Object.hash(searchIcon, undoLabel, syncIcon, undoAvailable, isColEmpty);
}

/// The host inputs used by `refreshMenuState` and its intermediate result.
///
/// A null [placeholderState] means `withOpenColOrNull` found no open collection.
/// Otherwise the source constructs this state before invoking
/// `fetchSyncIconState`; it does not assign this intermediate value to the
/// StateFlow. The host assigns only [completeDeckPickerOptionsMenuRefresh]'s
/// result after the sync fetch returns.
final class DeckPickerOptionsMenuRefreshPlan {
  const DeckPickerOptionsMenuRefreshPlan({
    required this.placeholderState,
    required this.shouldFetchSyncIcon,
  });

  final DeckPickerOptionsMenuState? placeholderState;
  final bool shouldFetchSyncIcon;
}

/// Projects the intermediate state and sync-fetch decision for a full refresh.
///
/// The host supplies values read from an open collection and performs the
/// actual StateFlow assignment and sync request. A closed collection projects
/// null, matching assignment of null from `withOpenColOrNull`.
DeckPickerOptionsMenuRefreshPlan planDeckPickerOptionsMenuRefresh({
  required bool collectionAccessible,
  required int deckCount,
  required bool isEmpty,
  required String? undoLabel,
  required bool undoAvailable,
}) {
  if (!collectionAccessible) {
    return const DeckPickerOptionsMenuRefreshPlan(
      placeholderState: null,
      shouldFetchSyncIcon: false,
    );
  }

  return DeckPickerOptionsMenuRefreshPlan(
    placeholderState: DeckPickerOptionsMenuState(
      searchIcon: deckCount >= 10,
      undoLabel: undoLabel,
      syncIcon: DeckPickerSyncIconState.normal,
      undoAvailable: undoAvailable,
      isColEmpty: isEmpty && deckCount == 1,
    ),
    shouldFetchSyncIcon: true,
  );
}

/// Completes a full menu refresh after the host's sync-icon fetch returns.
///
/// The source does not catch a `fetchSyncIconState` failure here; the host must
/// let that failure propagate before assigning a final options-menu state.
DeckPickerOptionsMenuState? completeDeckPickerOptionsMenuRefresh(
  DeckPickerOptionsMenuRefreshPlan plan,
  DeckPickerSyncIconState syncIcon,
) {
  final placeholder = plan.placeholderState;
  if (placeholder == null) return null;
  return placeholder.copyWithSyncIcon(syncIcon);
}

/// The projected result of `refreshUndoMenuState`'s StateFlow update.
///
/// [shouldUpdateState] is false when no collection is open, because the source
/// does not invoke `update` in that case. When true, [state] can still be null
/// if the current StateFlow value is null.
final class DeckPickerUndoMenuRefreshPlan {
  const DeckPickerUndoMenuRefreshPlan({
    required this.shouldUpdateState,
    required this.state,
  });

  final bool shouldUpdateState;
  final DeckPickerOptionsMenuState? state;
}

/// Projects the undo-only StateFlow update from `refreshUndoMenuState`.
DeckPickerUndoMenuRefreshPlan planDeckPickerUndoMenuRefresh({
  required bool collectionAccessible,
  required DeckPickerOptionsMenuState? currentState,
  required String? undoLabel,
  required bool undoAvailable,
}) {
  if (!collectionAccessible) {
    return DeckPickerUndoMenuRefreshPlan(
      shouldUpdateState: false,
      state: currentState,
    );
  }

  return DeckPickerUndoMenuRefreshPlan(
    shouldUpdateState: true,
    state: currentState?.copyWithUndo(
      undoLabel: undoLabel,
      undoAvailable: undoAvailable,
    ),
  );
}
