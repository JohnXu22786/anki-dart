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
 * Behavioral reference: ReviewerViewModel.kt, ViewerCommand.kt, and Flag.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_command_router.dart';
import 'previewer_flag_effects.dart';

/// The operation kind selected by a Reviewer flag [ViewerCommand].
sealed class ReviewerFlagCommandOperation {
  const ReviewerFlagCommandOperation(this.flag);

  final PreviewerFlag flag;
}

/// Requests that the host run the corresponding Reviewer toggle action.
final class ReviewerToggleFlagCommand extends ReviewerFlagCommandOperation {
  const ReviewerToggleFlagCommand(super.flag);
}

/// Requests that the host set the corresponding flag explicitly.
final class ReviewerSetFlagCommand extends ReviewerFlagCommandOperation {
  const ReviewerSetFlagCommand(super.flag);
}

/// Maps existing gesture commands to their Reviewer flag operation and value.
///
/// AnkiDroid's `ReviewerViewModel.executeAction()` maps toggle actions to
/// `toggleFlag(Flag.*)` and `UNSET_FLAG` to `setFlag(Flag.NONE)`. This pure
/// projection leaves action dispatch, current-flag reads, card lookup,
/// undoable collection writes, and publication with the host. Menu-only
/// `FLAG_RED` actions are not `ViewerCommand` values and are not added here.
ReviewerFlagCommandOperation? reviewerFlagCommandOperation(
  ViewerCommand? command,
) => switch (command) {
  ViewerCommand.TOGGLE_FLAG_RED => const ReviewerToggleFlagCommand(
    PreviewerFlag.red,
  ),
  ViewerCommand.TOGGLE_FLAG_ORANGE => const ReviewerToggleFlagCommand(
    PreviewerFlag.orange,
  ),
  ViewerCommand.TOGGLE_FLAG_GREEN => const ReviewerToggleFlagCommand(
    PreviewerFlag.green,
  ),
  ViewerCommand.TOGGLE_FLAG_BLUE => const ReviewerToggleFlagCommand(
    PreviewerFlag.blue,
  ),
  ViewerCommand.TOGGLE_FLAG_PINK => const ReviewerToggleFlagCommand(
    PreviewerFlag.pink,
  ),
  ViewerCommand.TOGGLE_FLAG_TURQUOISE => const ReviewerToggleFlagCommand(
    PreviewerFlag.turquoise,
  ),
  ViewerCommand.TOGGLE_FLAG_PURPLE => const ReviewerToggleFlagCommand(
    PreviewerFlag.purple,
  ),
  ViewerCommand.UNSET_FLAG => const ReviewerSetFlagCommand(PreviewerFlag.none),
  _ => null,
};
