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

/// One ordered host effect from the Reviewer's suspend-note action.
sealed class ReviewerSuspendNoteEffect {
  const ReviewerSuspendNoteEffect();
}

/// Requests suspending the single note identified by [noteIds].
final class SuspendReviewerNoteEffect extends ReviewerSuspendNoteEffect {
  const SuspendReviewerNoteEffect(this.noteIds);

  final List<int> noteIds;
}

/// Delivers the host-localized suspension feedback [message].
final class ShowReviewerSuspendNoteFeedbackEffect
    extends ReviewerSuspendNoteEffect {
  const ShowReviewerSuspendNoteFeedbackEffect(this.message);

  final String message;
}

/// Requests reloading the Reviewer's current card after note suspension.
final class ReloadReviewerCurrentCardAfterNoteSuspendEffect
    extends ReviewerSuspendNoteEffect {
  const ReloadReviewerCurrentCardAfterNoteSuspendEffect();
}

/// Projects `ReviewerViewModel.suspendNote()` into its ordered host effects.
///
/// The host performs each effect in order and stops if suspending the note
/// fails, so feedback and the current-card reload occur only after success. The
/// host supplies the current note ID and localized message; lookup, scheduler
/// and collection access, localization, flow delivery, and reloading stay
/// host-side. The source discards the scheduler's suspend count, so the plan
/// carries none.
List<ReviewerSuspendNoteEffect> planReviewerSuspendNote({
  required int noteId,
  required String suspendedMessage,
}) => List.unmodifiable([
  SuspendReviewerNoteEffect(List.unmodifiable([noteId])),
  ShowReviewerSuspendNoteFeedbackEffect(suspendedMessage),
  const ReloadReviewerCurrentCardAfterNoteSuspendEffect(),
]);
