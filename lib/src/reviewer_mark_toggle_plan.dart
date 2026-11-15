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

/// One ordered host effect from the Reviewer's mark-toggle action.
sealed class ReviewerMarkToggleEffect {
  const ReviewerMarkToggleEffect();
}

/// Toggles the `marked` tag on the host-resolved current note.
final class ReviewerToggleMarkEffect extends ReviewerMarkToggleEffect {
  const ReviewerToggleMarkEffect();
}

/// Reads the marked state after the host's toggle succeeds.
final class ReviewerReadMarkStateEffect extends ReviewerMarkToggleEffect {
  const ReviewerReadMarkStateEffect._();
}

/// Publishes the marked state returned by the successful host read.
final class ReviewerPublishMarkStateEffect extends ReviewerMarkToggleEffect {
  const ReviewerPublishMarkStateEffect({
    required this.readEffect,
    required this.isMarked,
  });

  final ReviewerReadMarkStateEffect readEffect;
  final bool isMarked;
}

/// Orders the Reviewer's note-mark toggle, state read, and state publication.
///
/// The host resolves the current card and note, then performs [toggleEffect].
/// It may request [readStateAfterToggle] only after that operation succeeds,
/// and may request [publicationAfterRead] only after the state read succeeds.
/// Note lookup, tag mutation, undoable persistence, exception handling, and
/// StateFlow delivery remain host-side.
final class ReviewerMarkTogglePlan {
  const ReviewerMarkTogglePlan();

  final ReviewerToggleMarkEffect toggleEffect =
      const ReviewerToggleMarkEffect();

  ReviewerReadMarkStateEffect? readStateAfterToggle({
    required bool succeeded,
  }) => succeeded ? const ReviewerReadMarkStateEffect._() : null;

  ReviewerPublishMarkStateEffect? publicationAfterRead({
    required ReviewerReadMarkStateEffect readEffect,
    required bool succeeded,
    required bool isMarked,
  }) => succeeded
      ? ReviewerPublishMarkStateEffect(
          readEffect: readEffect,
          isMarked: isMarked,
        )
      : null;
}

/// Projects `ReviewerViewModel.toggleMark()` into its ordered host plan.
ReviewerMarkTogglePlan planReviewerMarkToggle() =>
    const ReviewerMarkTogglePlan();
