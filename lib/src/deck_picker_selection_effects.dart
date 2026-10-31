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
 * Behavioral reference: `selectDeck`, `requestContextMenu`, and
 * `requestRightClickContextMenu` in DeckPickerViewModel.kt, AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// One host operation inside AnkiDroid's deck-selection job.
sealed class DeckPickerSelectionEffect {
  const DeckPickerSelectionEffect();
}

/// The host calls its collection's `decks.select` with [deckId].
final class DeckPickerSelectDeck extends DeckPickerSelectionEffect {
  const DeckPickerSelectDeck(this.deckId);

  final int deckId;
}

/// The host sets its focused-deck state to [deckId].
final class DeckPickerSetFocusedDeck extends DeckPickerSelectionEffect {
  const DeckPickerSetFocusedDeck(this.deckId);

  final int deckId;
}

/// The host emits one deck-list refresh request.
final class DeckPickerRefreshDeckList extends DeckPickerSelectionEffect {
  const DeckPickerRefreshDeckList();
}

/// A menu request emitted after joining the separate selection job.
sealed class DeckPickerMenuPublication {
  const DeckPickerMenuPublication();
}

/// The host emits [deckId] on its existing context-menu flow.
final class DeckPickerPublishContextMenu extends DeckPickerMenuPublication {
  const DeckPickerPublishContextMenu(this.deckId);

  final int deckId;
}

/// The host emits the exact request on its existing right-click menu flow.
final class DeckPickerPublishRightClickContextMenu
    extends DeckPickerMenuPublication {
  const DeckPickerPublishRightClickContextMenu({
    required this.deckId,
    required this.x,
    required this.y,
  });

  final int deckId;
  final double x;
  final double y;
}

/// Selection-job effects and an optional post-join menu publication.
///
/// The host must execute [selectionEffects] sequentially within the selection
/// job. If `decks.select` fails, that job stops before focused-deck assignment
/// and list refresh. For a menu request, the source then joins that job and
/// publishes [menuPublication] after it completes. Kotlin `Job.join()` waits but
/// does not rethrow the joined job's failure, so menu publication still occurs
/// after a failed selection. The host retains collection mutation,
/// state/flow publication, coroutine jobs, and UI. No operation here resets the
/// Card Browser default deck, matching the source TODO omission.
final class DeckPickerSelectionEffectPlan {
  DeckPickerSelectionEffectPlan({
    required Iterable<DeckPickerSelectionEffect> selectionEffects,
    this.menuPublication,
  }) : selectionEffects = List.unmodifiable(selectionEffects);

  final List<DeckPickerSelectionEffect> selectionEffects;
  final DeckPickerMenuPublication? menuPublication;
}

/// Projects `selectDeck` followed by focused-deck and deck-list refresh effects.
DeckPickerSelectionEffectPlan planDeckPickerSelection(int deckId) =>
    DeckPickerSelectionEffectPlan(selectionEffects: _selectionEffects(deckId));

/// Projects selection followed by a menu publication after `Job.join()`.
DeckPickerSelectionEffectPlan planDeckPickerContextMenu(int deckId) =>
    DeckPickerSelectionEffectPlan(
      selectionEffects: _selectionEffects(deckId),
      menuPublication: DeckPickerPublishContextMenu(deckId),
    );

/// Projects selection followed by right-click publication after `Job.join()`.
///
/// The host supplies coordinates in the source's coordinate space; this
/// projection passes their values through without conversion.
DeckPickerSelectionEffectPlan planDeckPickerRightClickContextMenu({
  required int deckId,
  required double x,
  required double y,
}) => DeckPickerSelectionEffectPlan(
  selectionEffects: _selectionEffects(deckId),
  menuPublication: DeckPickerPublishRightClickContextMenu(
    deckId: deckId,
    x: x,
    y: y,
  ),
);

List<DeckPickerSelectionEffect> _selectionEffects(int deckId) => [
  DeckPickerSelectDeck(deckId),
  DeckPickerSetFocusedDeck(deckId),
  const DeckPickerRefreshDeckList(),
];
