/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';
import 'dart:convert';

import 'package:anki_dart/profile_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_services.dart';
import 'collection_runtime.dart';

/// Minimal string storage boundary for the shared startup/profile runtime.
///
/// Applications and tests can inject their own implementation. The default
/// implementation uses shared_preferences on every Flutter app target.
abstract interface class AppKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class SharedPreferencesKeyValueStore implements AppKeyValueStore {
  SharedPreferencesKeyValueStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

/// Persisted app startup and profile state over one versioned storage record.
///
/// Keeping the startup flag, ordered profiles, and active profile together
/// prevents a partially updated set of independent keys from selecting stale
/// profile state after a restart.
final class SharedProfileRuntime implements StartupService, ProfileRepository {
  SharedProfileRuntime(
    this._store, {
    Iterable<Future<ProfileSwitchBlockReason?> Function()> profileSwitchChecks =
        const [],
  }) : _profileSwitchChecks = List.unmodifiable(profileSwitchChecks);

  static const storageKey = 'anki.shared.runtime.v1';
  static const _schemaVersion = 1;

  final AppKeyValueStore _store;
  final List<Future<ProfileSwitchBlockReason?> Function()> _profileSwitchChecks;
  Future<void> _mutationQueue = Future<void>.value();

  @override
  Iterable<Future<ProfileSwitchBlockReason?> Function()>
  get profileSwitchChecks => _profileSwitchChecks;

  @override
  Future<bool> isFirstRun() async => !(await _readState()).onboardingComplete;

  @override
  Future<void> completeOnboarding() => _serializeMutation(() async {
    final state = await _readState();
    if (state.onboardingComplete) return;
    await _writeState(state.copyWith(onboardingComplete: true));
  });

  @override
  Future<ProfileSnapshot> load() async {
    final state = await _readState();
    final items = state.profiles
        .map((profile) => ProfileItem(id: profile.id, name: profile.name))
        .toList(growable: false);
    final activeId = state.activeProfileId;
    final active = activeId == null
        ? null
        : items.where((profile) => profile.id == activeId).first;
    return ProfileSnapshot(items: items, active: active);
  }

  @override
  Future<void> create(
    ProfileId id,
    ProfileName name, {
    bool isActive = false,
  }) => _serializeMutation(() async {
    final state = await _readState();
    if (state.profiles.any((profile) => profile.id == id)) {
      throw StateError('Profile ID already exists: ${id.value}');
    }
    final profiles = [
      ...state.profiles,
      _StoredProfile(id: id, name: name.value),
    ];
    await _writeState(
      state.copyWith(
        profiles: profiles,
        activeProfileId: isActive ? id : state.activeProfileId,
      ),
    );
  });

  @override
  Future<void> rename(ProfileId id, ProfileName name) =>
      _serializeMutation(() async {
        final state = await _readState();
        final index = state.profiles.indexWhere((profile) => profile.id == id);
        if (index < 0) throw StateError('Unknown profile ID: ${id.value}');
        final profiles = [...state.profiles];
        profiles[index] = _StoredProfile(id: id, name: name.value);
        await _writeState(state.copyWith(profiles: profiles));
      });

  @override
  Future<void> persistActiveProfile(ProfileId id) =>
      _serializeMutation(() async {
        final state = await _readState();
        if (!state.profiles.any((profile) => profile.id == id)) {
          throw StateError('Unknown profile ID: ${id.value}');
        }
        await _writeState(state.copyWith(activeProfileId: id));
      });

  Future<void> _serializeMutation(Future<void> Function() mutation) {
    final result = _mutationQueue.then((_) => mutation());
    // Keep the queue usable after a failed write while returning that failure
    // to the caller of this mutation.
    _mutationQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  Future<_RuntimeState> _readState() async {
    final encoded = await _store.read(storageKey);
    if (encoded == null) return const _RuntimeState.empty();

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      rethrow;
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != _schemaVersion ||
        decoded['onboardingComplete'] is! bool ||
        decoded['profiles'] is! List ||
        (decoded['activeProfileId'] != null &&
            decoded['activeProfileId'] is! String)) {
      throw const FormatException('Stored profile data has an invalid shape.');
    }

    final profiles = <_StoredProfile>[];
    final ids = <String>{};
    for (final Object? value in decoded['profiles'] as List<Object?>) {
      if (value is! Map<String, dynamic> ||
          value['id'] is! String ||
          value['name'] is! String) {
        throw const FormatException('Stored profile entry is invalid.');
      }
      final id = value['id'] as String;
      if (!ids.add(id)) {
        throw FormatException('Stored profile ID is duplicated: $id');
      }
      profiles.add(
        _StoredProfile(id: ProfileId(id), name: value['name'] as String),
      );
    }
    final activeValue = decoded['activeProfileId'] as String?;
    if (activeValue != null && !ids.contains(activeValue)) {
      throw FormatException(
        'Stored active profile does not exist: $activeValue',
      );
    }
    return _RuntimeState(
      onboardingComplete: decoded['onboardingComplete'] as bool,
      profiles: profiles,
      activeProfileId: activeValue == null ? null : ProfileId(activeValue),
    );
  }

  Future<void> _writeState(_RuntimeState state) async {
    final encoded = jsonEncode({
      'version': _schemaVersion,
      'onboardingComplete': state.onboardingComplete,
      'profiles': [
        for (final profile in state.profiles)
          {'id': profile.id.value, 'name': profile.name},
      ],
      'activeProfileId': state.activeProfileId?.value,
    });
    await _store.write(storageKey, encoded);
  }
}

/// Composes the shared persistent runtime used by all Flutter app targets.
Future<AppServices> createDefaultAppServices() async {
  final runtime = SharedProfileRuntime(
    SharedPreferencesKeyValueStore(SharedPreferencesAsync()),
  );
  return AppServices(
    startup: runtime,
    profiles: runtime,
    collections: await createPlatformCollectionRuntime(),
  );
}

final class _StoredProfile {
  const _StoredProfile({required this.id, required this.name});

  final ProfileId id;
  final String name;
}

final class _RuntimeState {
  const _RuntimeState({
    this.onboardingComplete = false,
    this.profiles = const [],
    this.activeProfileId,
  });

  const _RuntimeState.empty() : this();

  final bool onboardingComplete;
  final List<_StoredProfile> profiles;
  final ProfileId? activeProfileId;

  _RuntimeState copyWith({
    bool? onboardingComplete,
    List<_StoredProfile>? profiles,
    ProfileId? activeProfileId,
  }) => _RuntimeState(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    profiles: profiles ?? this.profiles,
    activeProfileId: activeProfileId ?? this.activeProfileId,
  );
}
