// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';

import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:test/test.dart';

void main() {
  group('collection schema migration runner', () {
    test(
      'selects every supported upgrade range and rejects unsupported ones',
      () async {
        final expected = <int, List<String>>{
          11: ['11->14', '14->15', '15->16', '16->17', '17->18'],
          14: ['14->15', '15->16', '16->17', '17->18'],
          15: ['15->16', '16->17', '17->18'],
          16: ['16->17', '17->18'],
          17: ['17->18'],
          18: [],
        };

        for (final entry in expected.entries) {
          final events = <String>[];
          final database = _RecordingDatabase(events: events);
          await upgradeCollectionSchemaToLatest(
            database,
            _RecordingCallbacks(events),
            fromVersion: entry.key,
            serverMode: false,
          );
          final expectedOperations = collectionSchemaUpgradeSteps
              .where((step) => step.toVersion > entry.key)
              .expand((step) => step.operations)
              .map(_operationEvent)
              .toList();
          expect(
            events.where((event) => event != 'begin' && event != 'commit'),
            expectedOperations,
            reason: 'schema ${entry.key}',
          );
          expect(
            collectionSchemaUpgradeSteps
                .where((step) => step.toVersion > entry.key)
                .map((step) => '${step.fromVersion}->${step.toVersion}')
                .toList(),
            entry.value,
            reason: 'schema ${entry.key}',
          );
        }

        for (final version in [-1, 0, 10, 12, 13, 19, 255, 256]) {
          final database = _RecordingDatabase();
          await expectLater(
            upgradeCollectionSchemaToLatest(
              database,
              _RecordingCallbacks(database.events),
              fromVersion: version,
              serverMode: false,
            ),
            throwsA(isA<CollectionSchemaVersionException>()),
            reason: 'schema $version',
          );
          expect(database.events, isEmpty, reason: 'schema $version');
        }
      },
    );

    test(
      'executes operations in catalog order and forwards server mode',
      () async {
        final events = <String>[];
        final database = _RecordingDatabase(events: events);
        final callbacks = _RecordingCallbacks(events);

        await upgradeCollectionSchemaToLatest(
          database,
          callbacks,
          fromVersion: 11,
          serverMode: true,
        );

        expect(events.first, 'begin');
        expect(events.last, 'commit');
        expect(events.where((event) => !['begin', 'commit'].contains(event)), [
          'sql:schema14_upgrade.sql',
          'callback:upgradeDeckConfTo14:null',
          'callback:upgradeTagsTo14:null',
          'callback:upgradeConfigTo14:null',
          'sql:schema15_upgrade.sql',
          'callback:upgradeNotetypesTo15:null',
          'callback:upgradeDecksTo15:true',
          'callback:upgradeDeckConfTo15:null',
          'callback:upgradeDeckConfTo16:true',
          'sql:update col set ver = 16',
          'callback:upgradeTagsTo17:null',
          'sql:update col set ver = 17',
          'sql:schema18_upgrade.sql',
        ]);
      },
    );

    test('schema 18 upgrade is a no-op without a transaction', () async {
      final database = _RecordingDatabase();

      await upgradeCollectionSchemaToLatest(
        database,
        _RecordingCallbacks(database.events),
        fromVersion: 18,
        serverMode: false,
      );

      expect(database.events, isEmpty);
    });

    test('downgrade to 18 is a no-op and downgrade to 11 is ordered', () async {
      final noOpDatabase = _RecordingDatabase();
      await downgradeCollectionSchema(
        noOpDatabase,
        _RecordingCallbacks(noOpDatabase.events),
        toVersion: 18,
      );
      expect(noOpDatabase.events, isEmpty);

      final database = _RecordingDatabase();
      await downgradeCollectionSchema(
        database,
        _RecordingCallbacks(database.events),
        toVersion: 11,
      );
      expect(database.events, [
        'begin',
        'sql:schema18_downgrade.sql',
        'callback:downgradeDeckConfFrom16:null',
        'callback:downgradeDecksFrom15:null',
        'callback:downgradeNotetypesFrom15:null',
        'callback:downgradeConfigFrom14:null',
        'callback:downgradeTagsFrom14:null',
        'sql:schema11_downgrade.sql',
        'commit',
      ]);
    });

    test(
      'rolls back and preserves failures at transaction and operation boundaries',
      () async {
        final beginFailure = StateError('begin failed');
        final beginDatabase = _RecordingDatabase(
          failAt: 'begin',
          failure: beginFailure,
        );
        await _expectOriginalFailure(beginDatabase, beginFailure, 'begin');

        final sqlFailure = StateError('sql failed');
        final sqlDatabase = _RecordingDatabase(
          failAt: 'sql:schema14_upgrade.sql',
          failure: sqlFailure,
        );
        await _expectOriginalFailure(sqlDatabase, sqlFailure, 'sql');

        final callbackFailure = StateError('callback failed');
        final callbackEvents = <String>[];
        final callbackDatabase = _RecordingDatabase(events: callbackEvents);
        await expectLater(
          upgradeCollectionSchemaToLatest(
            callbackDatabase,
            _RecordingCallbacks(
              callbackEvents,
              failAt: 'upgradeDeckConfTo14',
              failure: callbackFailure,
            ),
            fromVersion: 11,
            serverMode: false,
          ),
          throwsA(same(callbackFailure)),
        );
        expect(callbackEvents.last, 'rollback');

        final commitFailure = StateError('commit failed');
        final commitDatabase = _RecordingDatabase(
          failAt: 'commit',
          failure: commitFailure,
        );
        await _expectOriginalFailure(commitDatabase, commitFailure, 'commit');

        final operationFailure = StateError('operation failed');
        final rollbackFailure = StateError('rollback failed');
        final rollbackDatabase = _RecordingDatabase(
          failAt: 'sql:schema14_upgrade.sql',
          failure: operationFailure,
          rollbackFailure: rollbackFailure,
        );
        await _expectOriginalFailure(rollbackDatabase, operationFailure, 'sql');
        expect(rollbackDatabase.events.last, 'rollback');
      },
    );

    test('accepts synchronous and asynchronous host methods', () async {
      final events = <String>[];
      final database = _RecordingDatabase(events: events, asynchronous: true);
      final callbacks = _RecordingCallbacks(events, asynchronous: true);

      await upgradeCollectionSchemaToLatest(
        database,
        callbacks,
        fromVersion: 17,
        serverMode: false,
      );

      expect(events, ['begin', 'sql:schema18_upgrade.sql', 'commit']);
    });
  });
}

String _operationEvent(CollectionSchemaOperation operation) =>
    switch (operation) {
      CollectionSchemaSqlOperation(:final name) => 'sql:$name',
      CollectionSchemaCallbackOperation(
        :final name,
        :final requiresServerMode,
      ) =>
        'callback:$name:${requiresServerMode ? 'false' : 'null'}',
    };

Future<void> _expectOriginalFailure(
  _RecordingDatabase database,
  Object failure,
  String operation,
) async {
  await expectLater(
    upgradeCollectionSchemaToLatest(
      database,
      _RecordingCallbacks(database.events),
      fromVersion: 11,
      serverMode: false,
    ),
    throwsA(same(failure)),
    reason: operation,
  );
  expect(database.events.last, 'rollback', reason: operation);
}

final class _RecordingDatabase implements CollectionSchemaMigrationDatabase {
  _RecordingDatabase({
    List<String>? events,
    this.failAt,
    this.failure,
    this.rollbackFailure,
    this.asynchronous = false,
  }) : events = events ?? <String>[];

  final List<String> events;
  final String? failAt;
  final Object? failure;
  final Object? rollbackFailure;
  final bool asynchronous;

  @override
  FutureOr<void> beginExclusive() => _record('begin');

  @override
  FutureOr<void> executeBatch(String sql) => _record(
    sql.startsWith('update col') ? 'sql:$sql' : 'sql:${_sqlName(sql)}',
  );

  @override
  FutureOr<void> commit() => _record('commit');

  @override
  FutureOr<void> rollback() {
    events.add('rollback');
    if (rollbackFailure != null) throw rollbackFailure!;
  }

  FutureOr<void> _record(String event) {
    events.add(event);
    if (event == failAt) throw failure!;
    if (asynchronous) return Future<void>.value();
  }

  String _sqlName(String sql) =>
      collectionSchemaSqlByPath.entries
          .where((entry) => entry.value == sql)
          .map((entry) => entry.key.split('/').last)
          .firstOrNull ??
      sql;
}

final class _RecordingCallbacks implements CollectionSchemaMigrationCallbacks {
  _RecordingCallbacks(
    this.events, {
    this.failAt,
    this.failure,
    this.asynchronous = false,
  });

  final List<String> events;
  final String? failAt;
  final Object? failure;
  final bool asynchronous;

  @override
  FutureOr<void> run(String name, {bool? serverMode}) {
    events.add('callback:$name:${serverMode?.toString() ?? 'null'}');
    if (name == failAt) throw failure!;
    if (asynchronous) return Future<void>.value();
  }
}
