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
 * Source-derived from DeckPickerViewModel.kt:389–428 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'deck_picker_options_menu_projection.dart';
import 'deck_picker_scheduler_upgrade_prompt.dart';

/// Begins a reload plan after the host has read the due tree and emptiness.
DeckPickerReloadDeckCountsStartPlan planDeckPickerReloadDeckCounts({
  required Object? dueTree,
  required bool collectionHasNoCards,
}) => DeckPickerReloadDeckCountsStartPlan(
  dueTree: dueTree,
  collectionHasNoCards: collectionHasNoCards,
);

/// Host operations inside `reloadDeckCounts`, in source order.
enum DeckPickerReloadDeckCountsEffect {
  publishDueTree,
  publishCollectionHasNoCards,
  readStudiedToday,
  publishStudiedToday,
  readSchedulerVersion,
  updateSchedulerUpgradeShownVersion,
  emitSchedulerUpgradePrompt,
  readFocusedDeck,
  publishFocusedDeck,
  readUndoMenuState,
  refreshUndoMenu,
  emitDecksReloaded,
}

/// The first host-resolved values and operations for a reload-count sequence.
///
/// The host publishes [dueTree] and [collectionHasNoCards] before performing
/// the `readStudiedToday` operation in [effects]. This stage split preserves
/// source failure boundaries: a later read does not prevent earlier
/// publications. The host performs all listed operations; this plan does not
/// read the collection or execute flows, jobs, IO, or UI work.
final class DeckPickerReloadDeckCountsStartPlan {
  DeckPickerReloadDeckCountsStartPlan({
    required this.dueTree,
    required this.collectionHasNoCards,
  }) : effects = const [
         DeckPickerReloadDeckCountsEffect.publishDueTree,
         DeckPickerReloadDeckCountsEffect.publishCollectionHasNoCards,
         DeckPickerReloadDeckCountsEffect.readStudiedToday,
       ];

  /// The due tree already read by the host from the collection.
  final Object? dueTree;

  /// The collection's `isEmpty` value read with the due tree.
  final bool collectionHasNoCards;

  /// Publications followed by the next host read in source order.
  final List<DeckPickerReloadDeckCountsEffect> effects;

  /// Continues after the host has read the studied-today value.
  DeckPickerReloadDeckCountsStudiedPlan afterStudiedToday(
    String studiedToday,
  ) => DeckPickerReloadDeckCountsStudiedPlan(studiedToday: studiedToday);
}

/// The studied-today publication and subsequent scheduler-config read.
final class DeckPickerReloadDeckCountsStudiedPlan {
  DeckPickerReloadDeckCountsStudiedPlan({required String studiedToday})
    : studiedToday = studiedToday.replaceAll('\n', ' '),
      effects = const [
        DeckPickerReloadDeckCountsEffect.publishStudiedToday,
        DeckPickerReloadDeckCountsEffect.readSchedulerVersion,
      ];

  /// The host-read value with literal LF characters replaced by one space.
  final String studiedToday;

  /// Publishes the value, then lets the host read scheduler config.
  final List<DeckPickerReloadDeckCountsEffect> effects;

  /// Continues after the host has read `schedVer` and current shown version.
  DeckPickerReloadDeckCountsSchedulerPlan afterSchedulerVersion({
    required int? schedulerVersion,
    required int? schedulerUpgradeDialogShownForVersion,
  }) {
    final prompt = projectDeckPickerSchedulerUpgradePrompt(
      schedulerVersion: schedulerVersion,
      schedulerUpgradeDialogShownForVersion:
          schedulerUpgradeDialogShownForVersion,
    );
    return DeckPickerReloadDeckCountsSchedulerPlan(
      schedulerUpgradePrompt: prompt,
      effects: [
        DeckPickerReloadDeckCountsEffect.updateSchedulerUpgradeShownVersion,
        if (prompt.shouldShowPrompt)
          DeckPickerReloadDeckCountsEffect.emitSchedulerUpgradePrompt,
        DeckPickerReloadDeckCountsEffect.readFocusedDeck,
      ],
    );
  }
}

/// Scheduler update/prompt effects, followed by the current-deck read.
final class DeckPickerReloadDeckCountsSchedulerPlan {
  DeckPickerReloadDeckCountsSchedulerPlan({
    required this.schedulerUpgradePrompt,
    required Iterable<DeckPickerReloadDeckCountsEffect> effects,
  }) : effects = List.unmodifiable(effects);

  /// The composed existing scheduler-upgrade decision.
  final DeckPickerSchedulerUpgradePromptProjection schedulerUpgradePrompt;

  /// Stores the shown version, optionally emits the prompt, then reads focus.
  final List<DeckPickerReloadDeckCountsEffect> effects;

  /// Continues after the host has read the current deck ID.
  DeckPickerReloadDeckCountsFocusedPlan afterFocusedDeck(int focusedDeckId) =>
      DeckPickerReloadDeckCountsFocusedPlan(focusedDeckId: focusedDeckId);
}

/// Focused-deck publication followed by the host's undo-menu reads.
final class DeckPickerReloadDeckCountsFocusedPlan {
  DeckPickerReloadDeckCountsFocusedPlan({required this.focusedDeckId})
    : effects = const [
        DeckPickerReloadDeckCountsEffect.publishFocusedDeck,
        DeckPickerReloadDeckCountsEffect.readUndoMenuState,
      ];

  /// The host-resolved current deck ID.
  final int focusedDeckId;

  /// Publishes focus, then lets the host resolve undo-menu values.
  final List<DeckPickerReloadDeckCountsEffect> effects;

  /// Continues after the host has resolved current menu and undo values.
  DeckPickerReloadDeckCountsCompletePlan afterUndoMenuState({
    required bool collectionAccessible,
    required DeckPickerOptionsMenuState? currentState,
    required String? undoLabel,
    required bool undoAvailable,
  }) => DeckPickerReloadDeckCountsCompletePlan(
    undoMenuRefresh: planDeckPickerUndoMenuRefresh(
      collectionAccessible: collectionAccessible,
      currentState: currentState,
      undoLabel: undoLabel,
      undoAvailable: undoAvailable,
    ),
  );
}

/// The undo-menu update and final deck-reloaded event.
final class DeckPickerReloadDeckCountsCompletePlan {
  const DeckPickerReloadDeckCountsCompletePlan({required this.undoMenuRefresh})
    : effects = const [
        DeckPickerReloadDeckCountsEffect.refreshUndoMenu,
        DeckPickerReloadDeckCountsEffect.emitDecksReloaded,
      ];

  /// The composed existing undo-menu refresh decision.
  final DeckPickerUndoMenuRefreshPlan undoMenuRefresh;

  /// The final source operations; deck reload is emitted last.
  final List<DeckPickerReloadDeckCountsEffect> effects;
}
