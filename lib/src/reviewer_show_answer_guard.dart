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

import 'gesture_command_router.dart' show ViewerCommand;

/// A host-side operation requested when the Reviewer answer is not yet shown.
enum ReviewerShowAnswerDirective { showAnswer }

/// Applies AnkiDroid's guard before requesting the host to show the answer.
ReviewerShowAnswerDirective? reviewerShowAnswerDirective(
  ViewerCommand command, {
  required bool showingAnswer,
}) => switch (command) {
  ViewerCommand.SHOW_ANSWER when !showingAnswer =>
    ReviewerShowAnswerDirective.showAnswer,
  _ => null,
};
