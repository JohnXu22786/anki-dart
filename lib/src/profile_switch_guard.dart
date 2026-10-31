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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ProfileSwitchGuard.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';
import 'dart:collection';

import 'profile_id.dart';

/// Safety conditions that can prevent a profile switch.
enum ProfileSwitchBlockReason {
  BACKUP_IN_PROGRESS,
  MEDIA_SYNC_IN_PROGRESS,
  COLLECTION_BUSY,
}

/// The outcome of running the profile-switch safety checks.
sealed class ProfileSwitchGuardResult {
  const ProfileSwitchGuardResult();
}

/// Indicates that all active blockers were absent or explicitly skipped.
final class ProfileSwitchGuardSuccess extends ProfileSwitchGuardResult {
  const ProfileSwitchGuardSuccess();
}

/// Indicates that the switch is blocked by one or more active reasons.
final class ProfileSwitchGuardBlocked extends ProfileSwitchGuardResult {
  ProfileSwitchGuardBlocked(Iterable<ProfileSwitchBlockReason> reasons)
    : reasons = Set.unmodifiable(LinkedHashSet.of(reasons));

  /// Unique active reasons, in the order they were first encountered.
  final Set<ProfileSwitchBlockReason> reasons;
}

/// Runs ordered profile-switch safety checks before asking the host to switch.
///
/// Every [checks] callback is awaited sequentially. The host retains profile
/// persistence, lifecycle, and the actual switch operation. Exceptions from a
/// check or from [switchActiveProfile] propagate unchanged.
Future<ProfileSwitchGuardResult> invokeProfileSwitchGuard({
  required ProfileId targetProfileId,
  required Iterable<FutureOr<ProfileSwitchBlockReason?> Function()> checks,
  required FutureOr<void> Function(ProfileId) switchActiveProfile,
  Set<ProfileSwitchBlockReason> skipReasons = const {},
}) async {
  final activeReasons = LinkedHashSet<ProfileSwitchBlockReason>();

  for (final check in checks) {
    final reason = await check();
    if (reason != null && !skipReasons.contains(reason)) {
      activeReasons.add(reason);
    }
  }

  if (activeReasons.isNotEmpty) {
    return ProfileSwitchGuardBlocked(activeReasons);
  }

  await switchActiveProfile(targetProfileId);
  return const ProfileSwitchGuardSuccess();
}
