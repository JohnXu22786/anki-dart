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
 * Source-derived from DeckPickerViewModel.kt:413–428 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Pure result of checking whether the legacy scheduler upgrade prompt is due.
class DeckPickerSchedulerUpgradePromptProjection {
  const DeckPickerSchedulerUpgradePromptProjection({
    required this.currentSchedulerVersion,
    required this.shouldShowPrompt,
    required this.nextSchedulerUpgradeDialogShownForVersion,
  });

  /// Scheduler version read from config, defaulting to 1 when it was not Long.
  final int currentSchedulerVersion;

  /// Whether the host should emit the legacy scheduler upgrade prompt.
  final bool shouldShowPrompt;

  /// Exact value for the host's next `schedulerUpgradeDialogShownForVersion`.
  final int nextSchedulerUpgradeDialogShownForVersion;
}

/// Projects the source gate without reading config/preferences or emitting flows.
///
/// The host supplies the typed Long-or-null scheduler config read and the
/// previously shown version, then applies the returned stored version and emits
/// the prompt when requested. A null previous version compares unequal to 1.
DeckPickerSchedulerUpgradePromptProjection
projectDeckPickerSchedulerUpgradePrompt({
  required int? schedulerVersion,
  required int? schedulerUpgradeDialogShownForVersion,
}) {
  final currentSchedulerVersion = schedulerVersion ?? 1;
  final shouldShowPrompt =
      currentSchedulerVersion == 1 &&
      schedulerUpgradeDialogShownForVersion != 1;

  return DeckPickerSchedulerUpgradePromptProjection(
    currentSchedulerVersion: currentSchedulerVersion,
    shouldShowPrompt: shouldShowPrompt,
    nextSchedulerUpgradeDialogShownForVersion: shouldShowPrompt
        ? 1
        : currentSchedulerVersion,
  );
}
