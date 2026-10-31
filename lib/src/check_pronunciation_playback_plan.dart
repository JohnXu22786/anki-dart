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
 * Behavioral reference: CheckPronunciationViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// One ordered host effect selected by Check Pronunciation playback routing.
sealed class CheckPronunciationPlaybackEffect {
  const CheckPronunciationPlaybackEffect();
}

/// Launches publication of the source `isPlayingFlow` value.
final class CheckPronunciationPlayingStateEffect
    extends CheckPronunciationPlaybackEffect {
  const CheckPronunciationPlayingStateEffect({required this.isPlaying});

  final bool isPlaying;
}

/// Calls the host audio player's replay operation.
final class CheckPronunciationReplayEffect
    extends CheckPronunciationPlaybackEffect {
  const CheckPronunciationReplayEffect();
}

/// Requests the source progress-bar update job.
final class CheckPronunciationProgressJobEffect
    extends CheckPronunciationPlaybackEffect {
  const CheckPronunciationProgressJobEffect();
}

/// Emits the source replay event.
final class CheckPronunciationReplayEventEffect
    extends CheckPronunciationPlaybackEffect {
  const CheckPronunciationReplayEventEffect();
}

/// Calls the host audio player's resume operation.
final class CheckPronunciationResumeEffect
    extends CheckPronunciationPlaybackEffect {
  const CheckPronunciationResumeEffect();
}

/// Starts the host audio player with the supplied absolute file path.
final class CheckPronunciationPlayEffect
    extends CheckPronunciationPlaybackEffect {
  const CheckPronunciationPlayEffect({required this.absolutePath});

  final String absolutePath;
}

/// Projects `CheckPronunciationViewModel.onPlayOrReplay()` into source-ordered
/// host effects.
///
/// The host supplies playback visibility, player status, and the current file's
/// absolute path. The source's playing-before-paused branch precedence and its
/// playing-state publication when the path is null are preserved. The host
/// retains coroutine scheduling and Job lifecycle, StateFlow/SharedFlow
/// delivery, audio-player behavior and errors, progress sampling, and callbacks.
List<CheckPronunciationPlaybackEffect> planCheckPronunciationPlayback({
  required bool isPlaybackVisible,
  required bool isPlayerPlaying,
  required bool isPlayerPaused,
  required String? currentFileAbsolutePath,
}) {
  if (!isPlaybackVisible) return const [];

  if (isPlayerPlaying) {
    return List.unmodifiable([
      const CheckPronunciationReplayEffect(),
      const CheckPronunciationProgressJobEffect(),
      const CheckPronunciationReplayEventEffect(),
    ]);
  }

  if (isPlayerPaused) {
    return List.unmodifiable([
      const CheckPronunciationPlayingStateEffect(isPlaying: true),
      const CheckPronunciationResumeEffect(),
      const CheckPronunciationProgressJobEffect(),
    ]);
  }

  return List.unmodifiable([
    const CheckPronunciationPlayingStateEffect(isPlaying: true),
    if (currentFileAbsolutePath != null)
      CheckPronunciationPlayEffect(absolutePath: currentFileAbsolutePath),
  ]);
}
