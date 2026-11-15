// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';

import 'collection_schema.dart';

/// Platform-neutral database operations required to execute schema plans.
///
/// Implementations may return immediately or asynchronously. [executeBatch]
/// must execute the supplied SQL unchanged as a batch.
abstract interface class CollectionSchemaMigrationDatabase {
  FutureOr<void> beginExclusive();

  FutureOr<void> executeBatch(String sql);

  FutureOr<void> commit();

  FutureOr<void> rollback();
}

/// Executes one source-named transformation from the migration catalog.
///
/// [serverMode] is supplied only for operations whose catalog entry requires
/// it; all other callbacks are invoked without that argument.
abstract interface class CollectionSchemaMigrationCallbacks {
  FutureOr<void> run(String name, {bool? serverMode});
}

/// Runs catalogued upgrade operations and commits them as one exclusive
/// transaction. Host database and callback methods may be synchronous or
/// asynchronous. A failing begin, operation, or commit triggers a rollback
/// attempt; a rollback failure never replaces the original failure.
Future<void> upgradeCollectionSchemaToLatest(
  CollectionSchemaMigrationDatabase database,
  CollectionSchemaMigrationCallbacks callbacks, {
  required int fromVersion,
  required bool serverMode,
}) async {
  final steps = collectionSchemaUpgradeStepsFor(fromVersion);
  if (steps.isEmpty) return;

  await _executeTransaction(database, () async {
    await executeCollectionSchemaUpgradesInTransaction(
      database,
      callbacks,
      fromVersion: fromVersion,
      serverMode: serverMode,
    );
  });
}

/// Executes the catalogued upgrade operations without starting or committing
/// a transaction. The caller must already have started a transaction and must
/// commit or roll it back. This is intended for host workflows that combine
/// schema upgrades with collection initialization in one atomic transaction.
Future<void> executeCollectionSchemaUpgradesInTransaction(
  CollectionSchemaMigrationDatabase database,
  CollectionSchemaMigrationCallbacks callbacks, {
  required int fromVersion,
  required bool serverMode,
}) async {
  for (final step in collectionSchemaUpgradeStepsFor(fromVersion)) {
    for (final operation in step.operations) {
      await _executeOperation(
        database,
        callbacks,
        operation,
        serverMode: serverMode,
      );
    }
  }
}

/// Runs the source's supported schema downgrade target.
///
/// Target 18 is the source-compatible no-op. Target 11 executes the ordered
/// 18-to-11 catalog in one exclusive transaction. The caller is responsible
/// for selecting this downgrade when appropriate for its collection.
Future<void> downgradeCollectionSchema(
  CollectionSchemaMigrationDatabase database,
  CollectionSchemaMigrationCallbacks callbacks, {
  required int toVersion,
}) async {
  if (toVersion == 18) return;
  if (toVersion != 11) {
    throw ArgumentError.value(toVersion, 'toVersion', 'must be 11 or 18');
  }

  await _executeTransaction(database, () async {
    for (final operation in collectionSchemaDowngradeTo11.operations) {
      await _executeOperation(database, callbacks, operation);
    }
  });
}

Future<void> _executeOperation(
  CollectionSchemaMigrationDatabase database,
  CollectionSchemaMigrationCallbacks callbacks,
  CollectionSchemaOperation operation, {
  bool? serverMode,
}) async {
  switch (operation) {
    case CollectionSchemaSqlOperation(:final sql):
      await Future<void>.sync(() => database.executeBatch(sql));
    case CollectionSchemaCallbackOperation(
      :final name,
      :final requiresServerMode,
    ):
      if (requiresServerMode) {
        await Future<void>.sync(
          () => callbacks.run(name, serverMode: serverMode),
        );
      } else {
        await Future<void>.sync(() => callbacks.run(name));
      }
  }
}

Future<void> _executeTransaction(
  CollectionSchemaMigrationDatabase database,
  Future<void> Function() execute,
) async {
  try {
    await Future<void>.sync(database.beginExclusive);
    await execute();
    await Future<void>.sync(database.commit);
  } catch (error, stackTrace) {
    try {
      await Future<void>.sync(database.rollback);
    } catch (_) {
      // Preserve the failure that caused rollback, including a begin/commit
      // failure whose transaction state may be unknown to the host adapter.
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}
