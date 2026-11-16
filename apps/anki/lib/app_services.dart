/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';

import 'app_contracts.dart';
import 'collection_runtime.dart';
import 'deck_picker_screen.dart';
import 'profile_manager.dart';

export 'app_contracts.dart';

/// Startup and profile boundaries implemented by the platform/backend host.
///
/// Storage selection, persistence, collection opening, and profile switching
/// lifecycle remain behind these injected interfaces.
final class AppServices {
  AppServices({
    required this.startup,
    required this.profiles,
    CollectionRuntime? collections,
    DeckPickerRepository? deckPicker,
    ProfileId Function()? generateProfileId,
  }) : collectionRuntimeConfigured = collections != null,
       collections = collections ?? _unconfiguredCollections,
       deckPicker = deckPicker ?? const UnavailableDeckPickerRepository(),
       profileManager = ProfileManager(
         profiles,
         generateProfileId: generateProfileId,
         profileSwitch: collections?.switchProfile,
       );

  final StartupService startup;
  final ProfileRepository profiles;
  final bool collectionRuntimeConfigured;
  final CollectionRuntime collections;
  final DeckPickerRepository deckPicker;
  final ProfileManager profileManager;
}

final _unconfiguredCollections = CollectionRuntime(
  locationForProfile: (_) => Future.error(
    UnsupportedError('Collection storage adapter is not configured.'),
  ),
  createDriver: () => Future.error(
    UnsupportedError('Collection storage adapter is not configured.'),
  ),
);

/// Default host boundary until platform storage and backend adapters are wired.
final class UnconfiguredAppServices
    implements StartupService, ProfileRepository {
  const UnconfiguredAppServices();

  @override
  Future<bool> isFirstRun() async => true;

  @override
  Future<void> completeOnboarding() => Future.error(
    UnsupportedError('Platform storage adapter is not configured.'),
  );

  @override
  Future<ProfileSnapshot> load() => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> create(
    ProfileId id,
    ProfileName name, {
    bool isActive = false,
  }) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> rename(ProfileId id, ProfileName name) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> persistActiveProfile(ProfileId id) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Iterable<Future<ProfileSwitchBlockReason?> Function()>
  get profileSwitchChecks => const [];
}
