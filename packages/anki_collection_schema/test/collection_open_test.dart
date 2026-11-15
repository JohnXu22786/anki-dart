// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';

import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:test/test.dart';

void main() {
  group('collection open/create orchestration', () {
    test(
      'creates a new collection in source order in one transaction',
      () async {
        final events = <String>[];
        final result = await openOrCreateCollection(
          _Database(events: events, collectionExists: false),
          _Callbacks(events),
          serverMode: false,
        );

        expect(
          result,
          const CollectionOpenResult(created: true, upgraded: true),
        );
        expect(events, [
          'query:exists',
          'begin',
          'sql:schema11.sql',
          'callback:metadata:false',
          'sql:schema14_upgrade.sql',
          'callback:migration:upgradeDeckConfTo14:null',
          'callback:migration:upgradeTagsTo14:null',
          'callback:migration:upgradeConfigTo14:null',
          'sql:schema15_upgrade.sql',
          'callback:migration:upgradeNotetypesTo15:null',
          'callback:migration:upgradeDecksTo15:false',
          'callback:migration:upgradeDeckConfTo15:null',
          'callback:migration:upgradeDeckConfTo16:false',
          'sql:update col set ver = 16',
          'callback:migration:upgradeTagsTo17:null',
          'sql:update col set ver = 17',
          'sql:schema18_upgrade.sql',
          'callback:default-deck-config',
          'callback:default-deck',
          'callback:stock-notetypes',
          'commit',
        ]);
      },
    );

    test('schema 18 opens without a transaction or mutation', () async {
      final events = <String>[];
      final result = await openOrCreateCollection(
        _Database(events: events, collectionExists: true, version: 18),
        _Callbacks(events),
        serverMode: true,
      );

      expect(
        result,
        const CollectionOpenResult(created: false, upgraded: false),
      );
      expect(events, ['query:exists', 'query:int']);
    });

    test('awaits asynchronous host callbacks in source order', () async {
      final events = <String>[];
      await openOrCreateCollection(
        _Database(events: events, collectionExists: false, asynchronous: true),
        _Callbacks(events, asynchronous: true),
        serverMode: true,
      );

      expect(events.first, 'query:exists');
      expect(events[1], 'begin');
      expect(events[2], 'sql:schema11.sql');
      expect(events[3], 'callback:metadata:true');
      expect(events[4], 'sql:schema14_upgrade.sql');
      expect(
        events[events.indexOf('callback:default-deck-config') + 1],
        'callback:default-deck',
      );
      expect(
        events[events.indexOf('callback:default-deck') + 1],
        'callback:stock-notetypes',
      );
      expect(events.last, 'commit');
    });

    test('supported versions run only their remaining upgrade path', () async {
      for (final version in [11, 14, 15, 16, 17, 18]) {
        final events = <String>[];
        final result = await openOrCreateCollection(
          _Database(events: events, collectionExists: true, version: version),
          _Callbacks(events),
          serverMode: true,
        );
        final steps = collectionSchemaUpgradeSteps
            .where((step) => step.toVersion > version)
            .expand((step) => step.operations)
            .map(
              (operation) => switch (operation) {
                CollectionSchemaSqlOperation(:final name) => 'sql:$name',
                CollectionSchemaCallbackOperation(
                  :final name,
                  :final requiresServerMode,
                ) =>
                  'callback:migration:$name:${requiresServerMode ? 'true' : 'null'}',
              },
            );

        expect(result.created, isFalse, reason: 'schema $version');
        expect(result.upgraded, version != 18, reason: 'schema $version');
        expect(
          events.where(
            (event) =>
                event.startsWith('sql:') ||
                event.startsWith('callback:migration:'),
          ),
          steps,
          reason: 'schema $version',
        );
        expect(
          events.where((event) => event == 'begin').length,
          version == 18 ? 0 : 1,
        );
        expect(
          events.where((event) => event == 'commit').length,
          version == 18 ? 0 : 1,
        );
      }
    });

    test(
      'rejects source-incompatible versions before any transaction',
      () async {
        final expected = <int, CollectionSchemaVersionStatus>{
          -1: CollectionSchemaVersionStatus.sourceConversionError,
          0: CollectionSchemaVersionStatus.fileTooOld,
          10: CollectionSchemaVersionStatus.fileTooOld,
          12: CollectionSchemaVersionStatus.fileTooNew,
          13: CollectionSchemaVersionStatus.fileTooNew,
          19: CollectionSchemaVersionStatus.fileTooNew,
          255: CollectionSchemaVersionStatus.fileTooNew,
          256: CollectionSchemaVersionStatus.sourceConversionError,
        };

        for (final entry in expected.entries) {
          final events = <String>[];
          await expectLater(
            openOrCreateCollection(
              _Database(
                events: events,
                collectionExists: true,
                version: entry.key,
              ),
              _Callbacks(events),
              serverMode: false,
            ),
            throwsA(
              isA<CollectionSchemaVersionException>().having(
                (error) => error.status,
                'status',
                entry.value,
              ),
            ),
            reason: 'schema ${entry.key}',
          );
          expect(events, [
            'query:exists',
            'query:int',
          ], reason: 'schema ${entry.key}');
        }
      },
    );

    test(
      'integrity check runs only when requested and rejects corrupt results',
      () async {
        final successEvents = <String>[];
        await openOrCreateCollection(
          _Database(
            events: successEvents,
            collectionExists: true,
            version: 18,
            integrityResult: 'ok',
          ),
          _Callbacks(successEvents),
          serverMode: false,
          checkIntegrity: true,
        );
        expect(successEvents, ['query:exists', 'query:int', 'query:integrity']);

        final failureEvents = <String>[];
        await expectLater(
          openOrCreateCollection(
            _Database(
              events: failureEvents,
              collectionExists: true,
              version: 18,
              integrityResult: 'row 2 missing',
            ),
            _Callbacks(failureEvents),
            serverMode: false,
            checkIntegrity: true,
          ),
          throwsA(isA<CollectionIntegrityException>()),
        );
        expect(failureEvents, ['query:exists', 'query:int', 'query:integrity']);
      },
    );

    test(
      'transaction failures roll back and preserve the original error',
      () async {
        for (final failurePoint in [
          'begin',
          'schema',
          'metadata',
          'default',
          'commit',
        ]) {
          final events = <String>[];
          final failure = StateError('$failurePoint failed');
          final database = _Database(
            events: events,
            collectionExists: false,
            failAt: failurePoint,
            failure: failure,
            rollbackFailure: StateError('rollback failed'),
          );
          await expectLater(
            openOrCreateCollection(
              database,
              _Callbacks(
                events,
                failAt: failurePoint == 'metadata'
                    ? 'metadata'
                    : failurePoint == 'default'
                    ? 'default-deck-config'
                    : null,
                failure: failure,
              ),
              serverMode: false,
            ),
            throwsA(same(failure)),
            reason: failurePoint,
          );
          expect(events.last, 'rollback', reason: failurePoint);
        }

        final migrationEvents = <String>[];
        final migrationFailure = StateError('migration failed');
        await expectLater(
          openOrCreateCollection(
            _Database(events: migrationEvents, collectionExists: false),
            _Callbacks(
              migrationEvents,
              failAt: 'migration:upgradeDeckConfTo14',
              failure: migrationFailure,
            ),
            serverMode: false,
          ),
          throwsA(same(migrationFailure)),
        );
        expect(migrationEvents.last, 'rollback');
      },
    );
  });
}

final class _Database implements CollectionOpenDatabase {
  _Database({
    required this.events,
    required this.collectionExists,
    this.version = 18,
    this.integrityResult = 'ok',
    this.failAt,
    this.failure,
    this.rollbackFailure,
    this.asynchronous = false,
  });

  final List<String> events;
  final bool collectionExists;
  final int version;
  final String integrityResult;
  final String? failAt;
  final Object? failure;
  final Object? rollbackFailure;
  final bool asynchronous;

  @override
  FutureOr<bool> queryExists(String sql) {
    events.add('query:exists');
    return collectionExists;
  }

  @override
  FutureOr<int> queryInt(String sql) {
    events.add('query:int');
    return version;
  }

  @override
  FutureOr<String> queryString(String sql) {
    events.add('query:integrity');
    return integrityResult;
  }

  @override
  FutureOr<void> beginExclusive() => _record('begin');

  @override
  FutureOr<void> executeBatch(String sql) =>
      _record(sql == collectionSchema11Sql ? 'schema' : 'sql:${_sqlName(sql)}');

  @override
  FutureOr<void> commit() => _record('commit');

  @override
  FutureOr<void> rollback() {
    events.add('rollback');
    if (rollbackFailure != null) throw rollbackFailure!;
  }

  FutureOr<void> _record(String event) {
    void record() {
      events.add(event == 'schema' ? 'sql:schema11.sql' : event);
      if (event == failAt) throw failure!;
    }

    if (asynchronous) {
      return Future<void>.delayed(Duration.zero, record);
    }
    record();
  }

  String _sqlName(String sql) =>
      collectionSchemaSqlByPath.entries
          .where((entry) => entry.value == sql)
          .map((entry) => entry.key.split('/').last)
          .firstOrNull ??
      sql;
}

final class _Callbacks implements CollectionOpenCallbacks {
  _Callbacks(
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
  FutureOr<void> initializeCollectionMetadata({required bool serverMode}) =>
      _record('metadata', 'callback:metadata:$serverMode');

  @override
  FutureOr<void> addDefaultDeckConfig() =>
      _record('default-deck-config', 'callback:default-deck-config');

  @override
  FutureOr<void> addDefaultDeck() =>
      _record('default-deck', 'callback:default-deck');

  @override
  FutureOr<void> addStockNoteTypes() =>
      _record('stock-notetypes', 'callback:stock-notetypes');

  @override
  FutureOr<void> run(String name, {bool? serverMode}) => _record(
    'migration:$name',
    'callback:migration:$name:${serverMode?.toString() ?? 'null'}',
  );

  FutureOr<void> _record(String key, String event) {
    void record() {
      events.add(event);
      if (key == failAt) throw failure!;
    }

    if (asynchronous) {
      return Future<void>.delayed(Duration.zero, record);
    }
    record();
  }
}
