/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';

import 'app_contracts.dart';

/// Shared profile rules and event ordering over an injected persistence host.
final class ProfileManager {
  ProfileManager(
    this._repository, {
    ProfileId Function()? generateProfileId,
    Future<void> Function(
      ProfileId profileId,
      Future<void> Function() persistSelection,
    )?
    profileSwitch,
  }) : _generateProfileId = generateProfileId ?? ProfileId.generate,
       // Keep the public API named `profileSwitch` while storing the hook
       // privately.
       // ignore: prefer_initializing_formals
       _profileSwitch = profileSwitch;

  static const defaultProfileName = 'Default';
  static const maxIdGenerationAttempts = 10;

  final ProfileRepository _repository;
  final ProfileId Function() _generateProfileId;
  final Future<void> Function(ProfileId, Future<void> Function())?
  _profileSwitch;

  /// Loads the active profile, creating and activating Default when none exists.
  Future<ProfileSnapshot> initializeActiveProfile() async {
    var snapshot = await _repository.load();
    final active = snapshot.active;
    if (active == null ||
        !snapshot.items.any((profile) => profile.id == active.id)) {
      await _repository.create(
        ProfileId.defaultId,
        ProfileName.fromTrustedSource(defaultProfileName),
        isActive: true,
      );
      await _repository.persistActiveProfile(ProfileId.defaultId);
      snapshot = await _repository.load();
    }
    if (snapshot.active == null) {
      throw StateError(
        'Profile initialization completed without an active profile.',
      );
    }
    return snapshot;
  }

  /// Generates a unique ID in Dart before asking the host to persist the profile.
  Future<ProfileId> createNewProfile(ProfileName name) async {
    final existing = await _repository.load();
    for (var attempt = 0; attempt < maxIdGenerationAttempts; attempt++) {
      final id = _generateProfileId();
      if (existing.items.any((profile) => profile.id == id)) continue;
      await _repository.create(id, name);
      return id;
    }
    throw StateError(
      'Failed to generate a unique Profile ID after $maxIdGenerationAttempts attempts.',
    );
  }

  Future<void> renameProfile(ProfileId id, ProfileName name) =>
      _repository.rename(id, name);

  /// Runs the ordered Dart safety checks before persisting the active profile.
  Future<ProfileSwitchGuardResult> switchActiveProfile(
    ProfileId id, {
    Set<ProfileSwitchBlockReason> skipReasons = const {},
  }) => invokeProfileSwitchGuard(
    targetProfileId: id,
    checks: _repository.profileSwitchChecks,
    switchActiveProfile: (target) async {
      Future<void> persistSelection() =>
          _repository.persistActiveProfile(target);
      final profileSwitch = _profileSwitch;
      if (profileSwitch == null) {
        await persistSelection();
      } else {
        await profileSwitch(target, persistSelection);
      }
    },
    skipReasons: skipReasons,
  );

  Future<ProfileSnapshot> load() => _repository.load();
}
