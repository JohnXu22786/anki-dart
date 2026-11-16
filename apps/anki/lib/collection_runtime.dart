/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/profile_onboarding.dart';

import 'collection_runtime_platform_stub.dart'
    if (dart.library.io) 'collection_runtime_platform_native.dart'
    if (dart.library.js_interop) 'collection_runtime_platform_web.dart'
    as platform;

/// Owns the open collection connection for the currently selected profile.
///
/// Profile paths derive from immutable IDs, so renaming a profile does not
/// move or replace its existing collection. Profile selection and connection
/// lifecycle remain serialized through this runtime.
final class CollectionRuntime {
  CollectionRuntime({
    required this._locationForProfile,
    required this._createDriver,
    CollectionOptionsForProfile? optionsForProfile,
  }) : _optionsForProfile = optionsForProfile ?? _defaultOptions;

  final Future<String> Function(ProfileId) _locationForProfile;
  final Future<CollectionSqliteDriver> Function() _createDriver;
  final CollectionOptionsForProfile _optionsForProfile;
  ProfileId? _selectedProfile;
  ProfileId? _openProfile;
  CollectionSqliteStorage? _storage;
  Future<void> _operationQueue = Future<void>.value();

  /// The open SQLite adapter, for collection repositories and services.
  CollectionSqliteStorage? get storage => _storage;

  /// Opens the collection belonging to [profileId], reusing the current
  /// connection when it is already open for that profile. Once a profile has
  /// been selected, other profiles must be selected through AppServices first.
  Future<CollectionSqliteStorage> open(ProfileId profileId) =>
      _serializeOperation(() async {
        if (_selectedProfile != null && _selectedProfile != profileId) {
          throw StateError('Collection profile is not the active profile.');
        }
        if (_openProfile == profileId && _storage != null) return _storage!;
        await _closeActive();
        final location = await _locationForProfile(profileId);
        final driver = await _createDriver();
        final storage = await CollectionSqliteStorage.open(
          driver: driver,
          location: location,
          options: _optionsForProfile(profileId),
        );
        _selectedProfile ??= profileId;
        _openProfile = profileId;
        _storage = storage;
        return storage;
      });

  /// Flushes and closes the active collection connection, preserving its file.
  Future<void> close() => _serializeOperation(_closeActive);

  /// Closes the old collection, persists the selection, and blocks stale
  /// profile opens as one serialized lifecycle operation.
  Future<void> switchProfile(
    ProfileId targetProfileId,
    Future<void> Function() persistSelection,
  ) => _serializeOperation(() async {
    if (_openProfile != null && _openProfile != targetProfileId) {
      await _closeActive();
    }
    await persistSelection();
    _selectedProfile = targetProfileId;
  });

  Future<T> _serializeOperation<T>(Future<T> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  Future<void> _closeActive() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.close();
    _storage = null;
    _openProfile = null;
  }
}

typedef CollectionOptionsForProfile = CollectionSqliteOptions Function(
  ProfileId profileId,
);

CollectionSqliteOptions _defaultOptions(ProfileId _) =>
    const CollectionSqliteOptions();

/// Builds the target-specific collection runtime behind conditional imports.
Future<CollectionRuntime> createPlatformCollectionRuntime() =>
    platform.createPlatformCollectionRuntime();

/// Profile IDs are arbitrary persisted strings; encode rather than using them
/// as path components so separators and platform-reserved characters cannot
/// escape the profile collection directory.
String collectionProfileKey(ProfileId profileId) =>
    base64Url.encode(utf8.encode(profileId.value)).replaceAll('=', '');
