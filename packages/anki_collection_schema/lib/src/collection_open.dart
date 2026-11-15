// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';

import 'collection_schema.dart';
import 'migration_runner.dart';

/// Host-neutral query and transaction operations needed to open a collection.
///
/// Query methods receive the source SQL used by Anki Core. Implementations are
/// responsible for translating driver failures into their normal host errors;
/// the orchestration propagates those failures unchanged.
abstract interface class CollectionOpenDatabase
    implements CollectionSchemaMigrationDatabase {
  FutureOr<bool> queryExists(String sql);

  FutureOr<int> queryInt(String sql);

  FutureOr<String> queryString(String sql);
}

/// Host-side initialization steps that are not pure SQL in Anki Core.
///
/// [initializeCollectionMetadata] updates the initial schema 11 `col` row with
/// its creation timestamp, modification stamp, version, and initial config.
/// The host supplies the source-compatible clock, version 1 creation-date and
/// local timezone calculations, and schema 11 default-config serialization.
/// For server mode, the initial timezone offset is absent; otherwise it is the
/// local minutes-west offset at the collection creation timestamp. Default
/// deck/config/note-type callbacks follow all schema migrations.
abstract interface class CollectionOpenCallbacks
    implements CollectionSchemaMigrationCallbacks {
  FutureOr<void> initializeCollectionMetadata({required bool serverMode});

  FutureOr<void> addDefaultDeckConfig();

  FutureOr<void> addDefaultDeck();

  FutureOr<void> addStockNoteTypes();
}

/// Whether opening found a new collection or upgraded an existing schema.
final class CollectionOpenResult {
  const CollectionOpenResult({required this.created, required this.upgraded});

  final bool created;
  final bool upgraded;

  @override
  bool operator ==(Object other) =>
      other is CollectionOpenResult &&
      other.created == created &&
      other.upgraded == upgraded;

  @override
  int get hashCode => Object.hash(created, upgraded);
}

/// Integrity-check result that was not the SQLite success value `ok`.
final class CollectionIntegrityException implements Exception {
  const CollectionIntegrityException(this.result);

  final String result;

  @override
  String toString() => 'Collection integrity check failed: $result';
}

/// Detects a collection, optionally checks it, and initializes or upgrades it.
///
/// Creation and all schema migrations/default callbacks share one exclusive
/// transaction. Existing current-schema collections are left untouched. The
/// host owns the connection and concrete storage configuration; this function
/// does not open a file, configure SQLite/WAL, or implement transformation and
/// default-data callbacks.
Future<CollectionOpenResult> openOrCreateCollection(
  CollectionOpenDatabase database,
  CollectionOpenCallbacks callbacks, {
  required bool serverMode,
  bool checkIntegrity = false,
}) async {
  final create = !await Future<bool>.sync(
    () => database.queryExists(
      "select null from sqlite_master where type = 'table' and name = 'col'",
    ),
  );
  final version = create
      ? collectionSchemaStartingVersion
      : await Future<int>.sync(() => database.queryInt('select ver from col'));

  final status = collectionSchemaVersionStatus(version);
  if (status != CollectionSchemaVersionStatus.supported) {
    throw CollectionSchemaVersionException(version, status);
  }

  if (checkIntegrity) {
    final integrity = await Future<String>.sync(
      () => database.queryString('pragma integrity_check'),
    );
    if (integrity != 'ok') throw CollectionIntegrityException(integrity);
  }

  final upgrade = version != collectionSchemaMaximumVersion;
  if (!create && !upgrade) {
    return const CollectionOpenResult(created: false, upgraded: false);
  }

  await _openTransaction(database, () async {
    if (create) {
      await Future<void>.sync(
        () => database.executeBatch(collectionSchema11Sql),
      );
      await Future<void>.sync(
        () => callbacks.initializeCollectionMetadata(serverMode: serverMode),
      );
    }

    await executeCollectionSchemaUpgradesInTransaction(
      database,
      callbacks,
      fromVersion: version,
      serverMode: serverMode,
    );

    if (create) {
      await Future<void>.sync(callbacks.addDefaultDeckConfig);
      await Future<void>.sync(callbacks.addDefaultDeck);
      await Future<void>.sync(callbacks.addStockNoteTypes);
    }
  });

  return CollectionOpenResult(created: create, upgraded: upgrade);
}

Future<void> _openTransaction(
  CollectionSchemaMigrationDatabase database,
  Future<void> Function() initialize,
) async {
  try {
    await Future<void>.sync(database.beginExclusive);
    await initialize();
    await Future<void>.sync(database.commit);
  } catch (error, stackTrace) {
    try {
      await Future<void>.sync(database.rollback);
    } catch (_) {
      // Preserve the error that caused rollback, including begin/commit errors.
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}
