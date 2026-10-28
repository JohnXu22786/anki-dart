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

import 'previewer_flag_effects.dart';
import 'reviewer_flag_toggle_target.dart';

/// One ordered host effect from the Reviewer's explicit set-flag action.
sealed class ReviewerSetFlagEffect {
  const ReviewerSetFlagEffect();
}

/// Requests updating the single current card with [flag].
final class SetReviewerFlagForCardEffect extends ReviewerSetFlagEffect {
  SetReviewerFlagForCardEffect({required int cardId, required this.flag})
    : cardIds = List<int>.unmodifiable([cardId]);

  final List<int> cardIds;
  final PreviewerFlag flag;
}

/// Publishes [flag] after the undoable update succeeds.
final class PublishReviewerFlagOnSuccessEffect extends ReviewerSetFlagEffect {
  const PublishReviewerFlagOnSuccessEffect(this.flag);

  final PreviewerFlag flag;
}

/// Ordered plan for Reviewer `setFlag(flag)`.
///
/// The host executes [updateEffect] first and calls [publicationAfterUpdate]
/// only when that undoable collection update has completed. A failed update
/// produces no publication effect. The host supplies the current card ID and
/// retains card lookup, collection mutation/undo, exception handling, and
/// StateFlow delivery.
final class ReviewerSetFlagPlan {
  ReviewerSetFlagPlan({required int cardId, required PreviewerFlag flag})
    : updateEffect = SetReviewerFlagForCardEffect(cardId: cardId, flag: flag),
      _flag = flag;

  final SetReviewerFlagForCardEffect updateEffect;
  final PreviewerFlag _flag;

  PublishReviewerFlagOnSuccessEffect? publicationAfterUpdate({
    required bool succeeded,
  }) => succeeded ? PublishReviewerFlagOnSuccessEffect(_flag) : null;
}

/// Projects explicit Reviewer `setFlag(flag)` into its ordered host plan.
///
/// The flag is passed through unchanged. Action selection remains in the host;
/// in particular, this does not implement `toggleFlag()`'s target choice.
ReviewerSetFlagPlan planReviewerSetFlag({
  required int cardId,
  required PreviewerFlag flag,
}) => ReviewerSetFlagPlan(cardId: cardId, flag: flag);

/// Projects Reviewer `toggleFlag(flag)` into the existing set-flag plan.
///
/// The host supplies its current flag, requested flag, and current card ID.
/// Matching flags select NONE; otherwise the requested flag passes unchanged
/// to the singleton-card write and its publication-after-success gate. The
/// host retains flow reads, action dispatch, card lookup, undoable collection
/// mutation, exception handling, and StateFlow delivery.
ReviewerSetFlagPlan planReviewerToggleFlag({
  required int cardId,
  required PreviewerFlag currentFlag,
  required PreviewerFlag requestedFlag,
}) => planReviewerSetFlag(
  cardId: cardId,
  flag: reviewerFlagToggleTarget(currentFlag, requestedFlag),
);
