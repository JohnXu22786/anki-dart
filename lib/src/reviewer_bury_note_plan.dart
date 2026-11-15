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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Runs the Reviewer's bury-note effect sequence through host-owned effects.
///
/// The host supplies the current note ID and callbacks for the scheduler,
/// localized feedback, delivery, and current-card reload. [buryNote] returns
/// the scheduler operation's count; it is passed unchanged to
/// [localizedFeedbackForCount]. Effects run in source order, and an error from
/// burying prevents feedback and reload.
Future<void> executeReviewerBuryNotePlan({
  required int noteId,
  required Future<int> Function(List<int> noteIds) buryNote,
  required String Function(int noteCount) localizedFeedbackForCount,
  required Future<void> Function(String message) showFeedback,
  required Future<void> Function() reloadCurrentCard,
}) async {
  final noteCount = await buryNote(List.unmodifiable([noteId]));
  final message = localizedFeedbackForCount(noteCount);
  await showFeedback(message);
  await reloadCurrentCard();
}
