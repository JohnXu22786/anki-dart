/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';

/// Startup and profile boundaries implemented by the platform/backend host.
///
/// Storage selection, persistence, collection opening, and profile switching
/// lifecycle remain behind these injected interfaces.
final class AppServices {
  const AppServices({required this.startup, required this.profiles});

  final StartupService startup;
  final ProfileRepository profiles;
}

abstract interface class StartupService {
  /// Returns true when storage has not yet been configured by the user.
  Future<bool> isFirstRun();

  /// Completes storage setup and backend startup in source-defined order.
  Future<void> completeOnboarding();
}

abstract interface class ProfileRepository {
  Future<ProfileSnapshot> load();
  Future<void> create(ProfileName name);
  Future<void> rename(ProfileId id, ProfileName name);
  Future<void> switchTo(ProfileId id);
}

final class ProfileSnapshot {
  ProfileSnapshot({required Iterable<ProfileItem> items, required this.active})
    : items = List.unmodifiable(items);

  final List<ProfileItem> items;
  final ProfileItem active;
}

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
  Future<void> create(ProfileName name) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> rename(ProfileId id, ProfileName name) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> switchTo(ProfileId id) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );
}
