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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The visible side for which the host requests Auto Advance scheduling.
enum ReviewerAutoAdvanceSide { question, answer }

/// One ordered host effect from the Reviewer Auto Advance toggle action.
sealed class ReviewerAutoAdvanceToggleEffect {
  const ReviewerAutoAdvanceToggleEffect();
}

/// Updates the host AutoAdvance instance's enabled state.
final class SetAutoAdvanceEnabledEffect
    extends ReviewerAutoAdvanceToggleEffect {
  const SetAutoAdvanceEnabledEffect(this.enabled);

  final bool enabled;
}

/// Publishes the new enabled value through the host state flow.
final class PublishAutoAdvanceEnabledEffect
    extends ReviewerAutoAdvanceToggleEffect {
  const PublishAutoAdvanceEnabledEffect(this.enabled);

  final bool enabled;
}

/// Emits the already-localized activated/deactivated feedback in the host.
final class PublishAutoAdvanceFeedbackEffect
    extends ReviewerAutoAdvanceToggleEffect {
  const PublishAutoAdvanceFeedbackEffect(this.message);

  final String message;
}

/// Requests scheduling for the currently shown side.
final class RequestAutoAdvanceScheduleEffect
    extends ReviewerAutoAdvanceToggleEffect {
  const RequestAutoAdvanceScheduleEffect(this.side);

  final ReviewerAutoAdvanceSide side;
}

/// Projects `ReviewerViewModel.toggleAutoAdvance()` into ordered host effects.
///
/// Feedback strings and current settings/media/side values are resolved by the
/// host. Scheduling is omitted only when both wait-for-audio and playback are
/// true. Otherwise the source requests scheduling even after disabling Auto
/// Advance; the host AutoAdvance implementation may no-op because it is off.
List<ReviewerAutoAdvanceToggleEffect> planReviewerAutoAdvanceToggle({
  required bool wasEnabled,
  required String activatedMessage,
  required String deactivatedMessage,
  required bool shouldWaitForAudio,
  required bool isPlaying,
  required bool showingAnswer,
}) {
  final enabled = !wasEnabled;
  final effects = <ReviewerAutoAdvanceToggleEffect>[
    SetAutoAdvanceEnabledEffect(enabled),
    PublishAutoAdvanceEnabledEffect(enabled),
    PublishAutoAdvanceFeedbackEffect(
      enabled ? activatedMessage : deactivatedMessage,
    ),
  ];

  if (!(shouldWaitForAudio && isPlaying)) {
    effects.add(
      RequestAutoAdvanceScheduleEffect(
        showingAnswer
            ? ReviewerAutoAdvanceSide.answer
            : ReviewerAutoAdvanceSide.question,
      ),
    );
  }

  return List.unmodifiable(effects);
}
