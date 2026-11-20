/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// The public callback names intentionally differ from their private fields.
// ignore_for_file: prefer_initializing_formals

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
  // Spell out public API names separately from the private implementation
  // fields, so call sites can see the accepted parameter names directly.
  CollectionRuntime({
    required Future<String> Function(ProfileId) locationForProfile,
    Future<CollectionSqliteDriver> Function()? createDriver,
    Future<CollectionSqliteDriver> Function(ProfileId)? createDriverForProfile,
    CollectionOptionsForProfile? optionsForProfile,
  }) : assert(createDriver != null || createDriverForProfile != null),
       assert(createDriver == null || createDriverForProfile == null),
       _locationForProfile = locationForProfile,
       _createDriver = createDriverForProfile ?? ((_) => createDriver!()),
       _optionsForProfile = optionsForProfile ?? _defaultOptions;

  final Future<String> Function(ProfileId) _locationForProfile;
  final Future<CollectionSqliteDriver> Function(ProfileId) _createDriver;
  final CollectionOptionsForProfile _optionsForProfile;
  ProfileId? _selectedProfile;
  ProfileId? _openProfile;
  CollectionSqliteStorage? _storage;
  bool _initialized = false;
  bool _closeNeedsRetry = false;
  Future<void> _operationQueue = Future<void>.value();

  /// The open SQLite adapter, for collection repositories and services.
  CollectionSqliteStorage? get storage => _storage;

  /// Whether the active profile's schema and first-create callbacks completed.
  bool get isInitialized => _initialized;

  /// Opens the collection belonging to [profileId], reusing the current
  /// connection when it is already open for that profile. Once a profile has
  /// been selected, other profiles must be selected through AppServices first.
  Future<CollectionSqliteStorage> open(ProfileId profileId) =>
      _serializeOperation(() => _open(profileId));

  /// Opens the profile collection and creates or migrates its schema in one
  /// transaction before startup treats the collection as ready.
  Future<CollectionOpenResult> openOrCreate(
    ProfileId profileId, {
    required CollectionOpenCallbacks Function(CollectionSqliteStorage storage)
    callbacks,
  }) => _serializeOperation(() async {
    _initialized = false;
    final storage = await _open(profileId);
    final result = await openOrCreateCollection(
      storage,
      callbacks(storage),
      serverMode: false,
    );
    _initialized = true;
    return result;
  });

  /// Flushes and closes the active collection connection, preserving its file.
  Future<void> close() => _serializeOperation(_closeActive);

  /// Closes the old collection, persists the selection, and blocks stale
  /// profile opens as one serialized lifecycle operation.
  Future<void> switchProfile(
    ProfileId targetProfileId,
    Future<void> Function() persistSelection,
  ) => _serializeOperation(() async {
    if (_openProfile != null &&
        (_openProfile != targetProfileId || _closeNeedsRetry)) {
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

  Future<CollectionSqliteStorage> _open(ProfileId profileId) async {
    if (_selectedProfile != null && _selectedProfile != profileId) {
      throw StateError('Collection profile is not the active profile.');
    }
    if (_openProfile == profileId && _storage != null && !_closeNeedsRetry) {
      return _storage!;
    }
    await _closeActive();
    final location = await _locationForProfile(profileId);
    final driver = await _createDriver(profileId);
    final storage = await CollectionSqliteStorage.open(
      driver: driver,
      location: location,
      options: _optionsForProfile(profileId),
    );
    _selectedProfile ??= profileId;
    _openProfile = profileId;
    _storage = storage;
    return storage;
  }

  Future<void> _closeActive() async {
    final storage = _storage;
    if (storage == null) return;
    try {
      await storage.close();
    } catch (_) {
      _closeNeedsRetry = true;
      rethrow;
    }
    _storage = null;
    _openProfile = null;
    _initialized = false;
    _closeNeedsRetry = false;
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

/// Stable, profile-isolated IndexedDB database name for collection media.
String collectionMediaDatabaseName(ProfileId profileId) =>
    'anki.collection.media.v1.${collectionProfileKey(profileId)}';
