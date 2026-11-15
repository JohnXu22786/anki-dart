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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'previewer_flag_effects.dart';
import 'reviewer_set_flag_plan.dart';

/// Runs Reviewer `setFlag(flag)` through host-owned callbacks.
///
/// The host supplies the current-card ID lookup, undoable collection update,
/// and flag publication. Lookup and update failures propagate unchanged; a
/// failed update prevents publication. Card lookup, collection access and
/// mutation, undo, and StateFlow delivery remain host-side.
Future<void> executeReviewerSetFlagOperation({
  required FutureOr<int> Function() currentCardId,
  required FutureOr<void> Function(List<int> cardIds, PreviewerFlag flag)
  updateFlags,
  required FutureOr<void> Function(PreviewerFlag flag) publishFlag,
  required PreviewerFlag flag,
}) async {
  final cardId = await currentCardId();
  final plan = planReviewerSetFlag(cardId: cardId, flag: flag);
  await updateFlags(plan.updateEffect.cardIds, plan.updateEffect.flag);
  final publication = plan.publicationAfterUpdate(succeeded: true)!;
  await publishFlag(publication.flag);
}

/// Runs Reviewer `toggleFlag(flag)` through host-owned callbacks.
///
/// Reads the current flag once, then delegates target selection and the ordered
/// set operation to the existing Reviewer plan. The host retains action
/// routing, current-flag and card lookup, collection mutation/undo, and
/// StateFlow delivery. Callback failures propagate unchanged and stop later
/// callbacks.
Future<void> executeReviewerToggleFlagOperation({
  required FutureOr<PreviewerFlag> Function() currentFlag,
  required FutureOr<int> Function() currentCardId,
  required FutureOr<void> Function(List<int> cardIds, PreviewerFlag flag)
  updateFlags,
  required FutureOr<void> Function(PreviewerFlag flag) publishFlag,
  required PreviewerFlag flag,
}) async {
  final observedFlag = await currentFlag();
  final cardId = await currentCardId();
  final plan = planReviewerToggleFlag(
    cardId: cardId,
    currentFlag: observedFlag,
    requestedFlag: flag,
  );
  await updateFlags(plan.updateEffect.cardIds, plan.updateEffect.flag);
  final publication = plan.publicationAfterUpdate(succeeded: true)!;
  await publishFlag(publication.flag);
}
