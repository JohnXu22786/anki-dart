// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:test/test.dart';

void main() {
  group('collection schema compatibility', () {
    test('recognizes only source-supported schema versions', () {
      expect(collectionSchemaMinimumVersion, 11);
      expect(collectionSchemaStartingVersion, 11);
      expect(collectionSchemaMaximumVersion, 18);
      expect(
        [11, 14, 15, 16, 17, 18].map(collectionSchemaVersionStatus),
        everyElement(CollectionSchemaVersionStatus.supported),
      );
      expect(
        collectionSchemaVersionStatus(10),
        CollectionSchemaVersionStatus.fileTooOld,
      );
      expect(
        collectionSchemaVersionStatus(12),
        CollectionSchemaVersionStatus.fileTooNew,
      );
      expect(
        collectionSchemaVersionStatus(13),
        CollectionSchemaVersionStatus.fileTooNew,
      );
      expect(
        collectionSchemaVersionStatus(19),
        CollectionSchemaVersionStatus.fileTooNew,
      );
      expect(
        collectionSchemaVersionStatus(-1),
        CollectionSchemaVersionStatus.sourceConversionError,
      );
      expect(
        collectionSchemaVersionStatus(256),
        CollectionSchemaVersionStatus.sourceConversionError,
      );
    });

    test('builds the pinned ordered upgrade and downgrade operation plans', () {
      expect(
        collectionSchemaUpgradeSteps.map(
          (step) => '${step.fromVersion}->${step.toVersion}',
        ),
        ['11->14', '14->15', '15->16', '16->17', '17->18'],
      );
      expect(
        collectionSchemaUpgradeSteps.map(
          (step) => step.operations.map((op) => op.name).toList(),
        ),
        [
          [
            'schema14_upgrade.sql',
            'upgradeDeckConfTo14',
            'upgradeTagsTo14',
            'upgradeConfigTo14',
          ],
          [
            'schema15_upgrade.sql',
            'upgradeNotetypesTo15',
            'upgradeDecksTo15',
            'upgradeDeckConfTo15',
          ],
          ['upgradeDeckConfTo16', 'update col set ver = 16'],
          ['upgradeTagsTo17', 'update col set ver = 17'],
          ['schema18_upgrade.sql'],
        ],
      );
      expect(
        collectionSchemaUpgradeSteps[1].operations[2].requiresServerMode,
        isTrue,
      );
      expect(
        collectionSchemaUpgradeSteps[2].operations.first.requiresServerMode,
        isTrue,
      );
      expect(collectionSchemaDowngradeTo11.operations.map((op) => op.name), [
        'schema18_downgrade.sql',
        'downgradeDeckConfFrom16',
        'downgradeDecksFrom15',
        'downgradeNotetypesFrom15',
        'downgradeConfigFrom14',
        'downgradeTagsFrom14',
        'schema11_downgrade.sql',
      ]);
      expect(
        collectionSchemaUpgradeStepsFor(11).map((step) => step.toVersion),
        [14, 15, 16, 17, 18],
      );
      expect(
        collectionSchemaUpgradeStepsFor(15).map((step) => step.toVersion),
        [16, 17, 18],
      );
      expect(collectionSchemaUpgradeStepsFor(18), isEmpty);
      expect(
        () => collectionSchemaUpgradeStepsFor(12),
        throwsA(isA<CollectionSchemaVersionException>()),
      );
    });
  });

  test('SQL catalog matches pinned fixture bytes and SHA-256 manifest', () {
    final manifest = File('SOURCE.sha256').readAsLinesSync();
    final expected = <String, String>{};
    for (final line in manifest) {
      final match = RegExp(r'^([0-9a-f]{64})  (.+)$').firstMatch(line);
      expect(match, isNotNull, reason: 'invalid SOURCE.sha256 entry: $line');
      expected[match!.group(2)!] = match.group(1)!;
    }
    expect(expected.keys, containsAll(collectionSchemaSqlSourcePaths));

    final sqlByPath = collectionSchemaSqlByPath;
    expect(sqlByPath['rslib/src/storage/schema11.sql'], collectionSchema11Sql);
    for (final entry in sqlByPath.entries) {
      final bytes = File(
        'test/fixtures/upstream/${entry.key.split('/').last}',
      ).readAsBytesSync();
      expect(
        sha256.convert(bytes).toString(),
        expected[entry.key],
        reason: entry.key,
      );
      expect(
        base64.encode(bytes),
        base64.encode(utf8.encode(entry.value)),
        reason: entry.key,
      );
    }
  });
}
