// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'upstream_sql.g.dart';

export 'upstream_sql.g.dart' show collectionSchema11Sql;

/// Earliest collection schema this pinned Anki Core version can open.
const int collectionSchemaMinimumVersion = 11;

/// Schema used to create a new collection before applying upgrades.
const int collectionSchemaStartingVersion = 11;

/// Latest collection schema this pinned Anki Core version can open.
const int collectionSchemaMaximumVersion = 18;

/// Compatibility outcome used by Anki Core's open path.
enum CollectionSchemaVersionStatus {
  supported,
  fileTooOld,
  fileTooNew,
  sourceConversionError,
}

/// Maps a stored schema version to Anki Core's file compatibility result.
CollectionSchemaVersionStatus collectionSchemaVersionStatus(int version) {
  if (version < 0 || version > 255) {
    return CollectionSchemaVersionStatus.sourceConversionError;
  }
  if (version < collectionSchemaMinimumVersion) {
    return CollectionSchemaVersionStatus.fileTooOld;
  }
  if (version > collectionSchemaMaximumVersion ||
      version == 12 ||
      version == 13) {
    return CollectionSchemaVersionStatus.fileTooNew;
  }
  return CollectionSchemaVersionStatus.supported;
}

/// Thrown when a schema plan is requested for a version the source rejects.
final class CollectionSchemaVersionException implements Exception {
  const CollectionSchemaVersionException(this.version, this.status);

  final int version;
  final CollectionSchemaVersionStatus status;

  @override
  String toString() => 'Collection schema version $version is ${status.name}';
}

/// One ordered SQL batch or source-side transformation in a migration.
sealed class CollectionSchemaOperation {
  const CollectionSchemaOperation(this.name);

  /// The exact source SQL filename, source method name, or version update.
  final String name;

  /// Whether the source callback receives the server-mode setting.
  bool get requiresServerMode => false;
}

/// SQL to be passed unchanged to the host database executor.
final class CollectionSchemaSqlOperation extends CollectionSchemaOperation {
  const CollectionSchemaSqlOperation(super.name, this.sql);

  final String sql;
}

/// A transformation implemented by Anki Core outside its SQL files.
///
/// The host storage adapter must implement this named callback. Its position in
/// the containing step is significant and preserves the upstream call order.
final class CollectionSchemaCallbackOperation
    extends CollectionSchemaOperation {
  const CollectionSchemaCallbackOperation(
    super.name, {
    this.requiresServerMode = false,
  });

  @override
  final bool requiresServerMode;
}

/// Consecutive schema-version upgrade operations from Anki Core.
final class CollectionSchemaUpgradeStep {
  const CollectionSchemaUpgradeStep(
    this.fromVersion,
    this.toVersion,
    this.operations,
  );

  final int fromVersion;
  final int toVersion;
  final List<CollectionSchemaOperation> operations;
}

const CollectionSchemaSqlOperation _schema14 = CollectionSchemaSqlOperation(
  'schema14_upgrade.sql',
  collectionSchemaSchema14UpgradeSql,
);
const CollectionSchemaSqlOperation _schema15 = CollectionSchemaSqlOperation(
  'schema15_upgrade.sql',
  collectionSchemaSchema15UpgradeSql,
);
const CollectionSchemaSqlOperation _schema18Upgrade =
    CollectionSchemaSqlOperation(
      'schema18_upgrade.sql',
      collectionSchemaSchema18UpgradeSql,
    );
const CollectionSchemaSqlOperation _schema18Downgrade =
    CollectionSchemaSqlOperation(
      'schema18_downgrade.sql',
      collectionSchemaSchema18DowngradeSql,
    );
const CollectionSchemaSqlOperation _schema11Downgrade =
    CollectionSchemaSqlOperation(
      'schema11_downgrade.sql',
      collectionSchemaSchema11DowngradeSql,
    );

/// The complete ordered upgrade catalog. The first step applies to schema 11;
/// schemas 12 and 13 are rejected before this plan can be selected.
const List<CollectionSchemaUpgradeStep> collectionSchemaUpgradeSteps = [
  CollectionSchemaUpgradeStep(11, 14, [
    _schema14,
    CollectionSchemaCallbackOperation('upgradeDeckConfTo14'),
    CollectionSchemaCallbackOperation('upgradeTagsTo14'),
    CollectionSchemaCallbackOperation('upgradeConfigTo14'),
  ]),
  CollectionSchemaUpgradeStep(14, 15, [
    _schema15,
    CollectionSchemaCallbackOperation('upgradeNotetypesTo15'),
    CollectionSchemaCallbackOperation(
      'upgradeDecksTo15',
      requiresServerMode: true,
    ),
    CollectionSchemaCallbackOperation('upgradeDeckConfTo15'),
  ]),
  CollectionSchemaUpgradeStep(15, 16, [
    CollectionSchemaCallbackOperation(
      'upgradeDeckConfTo16',
      requiresServerMode: true,
    ),
    CollectionSchemaSqlOperation(
      'update col set ver = 16',
      'update col set ver = 16',
    ),
  ]),
  CollectionSchemaUpgradeStep(16, 17, [
    CollectionSchemaCallbackOperation('upgradeTagsTo17'),
    CollectionSchemaSqlOperation(
      'update col set ver = 17',
      'update col set ver = 17',
    ),
  ]),
  CollectionSchemaUpgradeStep(17, 18, [_schema18Upgrade]),
];

/// Selects source upgrade steps needed by a supported collection version.
List<CollectionSchemaUpgradeStep> collectionSchemaUpgradeStepsFor(int version) {
  final status = collectionSchemaVersionStatus(version);
  if (status != CollectionSchemaVersionStatus.supported) {
    throw CollectionSchemaVersionException(version, status);
  }
  return List.unmodifiable(
    collectionSchemaUpgradeSteps.where((step) => step.toVersion > version),
  );
}

/// Ordered 18-to-11 downgrade. The source only exposes this downgrade target.
const CollectionSchemaUpgradeStep collectionSchemaDowngradeTo11 =
    CollectionSchemaUpgradeStep(18, 11, [
      _schema18Downgrade,
      CollectionSchemaCallbackOperation('downgradeDeckConfFrom16'),
      CollectionSchemaCallbackOperation('downgradeDecksFrom15'),
      CollectionSchemaCallbackOperation('downgradeNotetypesFrom15'),
      CollectionSchemaCallbackOperation('downgradeConfigFrom14'),
      CollectionSchemaCallbackOperation('downgradeTagsFrom14'),
      _schema11Downgrade,
    ]);

/// Upstream paths whose byte content is embedded as executable SQL.
const List<String> collectionSchemaSqlSourcePaths = [
  'rslib/src/storage/schema11.sql',
  'rslib/src/storage/upgrades/schema11_downgrade.sql',
  'rslib/src/storage/upgrades/schema14_upgrade.sql',
  'rslib/src/storage/upgrades/schema15_upgrade.sql',
  'rslib/src/storage/upgrades/schema17_upgrade.sql',
  'rslib/src/storage/upgrades/schema18_downgrade.sql',
  'rslib/src/storage/upgrades/schema18_upgrade.sql',
];

/// Upstream SQL files keyed by their source paths, for auditing and tooling.
final Map<String, String> collectionSchemaSqlByPath = Map.unmodifiable({
  'rslib/src/storage/schema11.sql': collectionSchema11Sql,
  'rslib/src/storage/upgrades/schema11_downgrade.sql':
      collectionSchemaSchema11DowngradeSql,
  'rslib/src/storage/upgrades/schema14_upgrade.sql':
      collectionSchemaSchema14UpgradeSql,
  'rslib/src/storage/upgrades/schema15_upgrade.sql':
      collectionSchemaSchema15UpgradeSql,
  'rslib/src/storage/upgrades/schema17_upgrade.sql':
      collectionSchemaSchema17UpgradeSql,
  'rslib/src/storage/upgrades/schema18_downgrade.sql':
      collectionSchemaSchema18DowngradeSql,
  'rslib/src/storage/upgrades/schema18_upgrade.sql':
      collectionSchemaSchema18UpgradeSql,
});
