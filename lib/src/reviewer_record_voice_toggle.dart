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

/// One ordered host effect from the Reviewer record-voice toggle action.
sealed class ReviewerRecordVoiceToggleEffect {
  const ReviewerRecordVoiceToggleEffect();
}

/// Publishes the new value through the host voice-recorder enabled state flow.
final class PublishRecordVoiceEnabledEffect
    extends ReviewerRecordVoiceToggleEffect {
  const PublishRecordVoiceEnabledEffect(this.enabled);

  final bool enabled;
}

/// Requests assigning the new value to the host repository setting.
final class SetRecordVoiceRepositoryEnabledEffect
    extends ReviewerRecordVoiceToggleEffect {
  const SetRecordVoiceRepositoryEnabledEffect(this.enabled);

  final bool enabled;
}

/// Projects `ReviewerViewModel.toggleRecordVoice()` into ordered host effects.
///
/// The host supplies the current StateFlow value and performs the state
/// publication followed by the repository preference assignment.
List<ReviewerRecordVoiceToggleEffect> planReviewerRecordVoiceToggle({
  required bool wasEnabled,
}) {
  final enabled = !wasEnabled;
  return List.unmodifiable([
    PublishRecordVoiceEnabledEffect(enabled),
    SetRecordVoiceRepositoryEnabledEffect(enabled),
  ]);
}
