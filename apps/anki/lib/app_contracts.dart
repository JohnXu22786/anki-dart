/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';

abstract interface class StartupService {
  /// Returns true when storage has not yet been configured by the user.
  Future<bool> isFirstRun();

  /// Completes storage setup and backend startup in source-defined order.
  Future<void> completeOnboarding();
}

/// Persistence and host lifecycle operations consumed by the Dart profile rules.
abstract interface class ProfileRepository {
  Future<ProfileSnapshot> load();
  Future<void> create(ProfileId id, ProfileName name, {bool isActive = false});
  Future<void> rename(ProfileId id, ProfileName name);
  Future<void> persistActiveProfile(ProfileId id);

  Iterable<Future<ProfileSwitchBlockReason?> Function()>
  get profileSwitchChecks;
}

final class ProfileSnapshot {
  ProfileSnapshot({required Iterable<ProfileItem> items, this.active})
    : items = List.unmodifiable(items);

  final List<ProfileItem> items;
  final ProfileItem? active;
}
