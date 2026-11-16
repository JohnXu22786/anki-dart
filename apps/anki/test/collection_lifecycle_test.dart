/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:anki_app/app.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/profile_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory directory;
  late _MemoryStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('anki-collection-app-');
    store = _MemoryStore();
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  testWidgets('first run creates a collection and the next launch reopens it', (
    tester,
  ) async {
    var services = _services(directory, store);
    await tester.pumpWidget(AppRouter(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up Anki'));
    await tester.pumpAndSettle();

    expect(find.text('Active profile: Default'), findsOneWidget);
    expect(services.collections.isInitialized, isTrue);
    final firstStorage = services.collections.storage!;
    expect(await firstStorage.queryInt('select ver from col'), 18);
    expect(await firstStorage.queryInt('select count(*) from decks'), 1);
    expect(await firstStorage.queryInt('select count(*) from notetypes'), 6);
    await services.collections.close();

    await tester.pumpWidget(const SizedBox.shrink());
    services = _services(directory, store);
    await tester.pumpWidget(AppRouter(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Active profile: Default'), findsOneWidget);
    expect(
      await services.collections.storage!.queryInt('select ver from col'),
      18,
    );
    expect(
      await services.collections.storage!.queryInt(
        'select count(*) from decks',
      ),
      1,
    );
    expect(
      await services.collections.storage!.queryInt(
        'select count(*) from notetypes',
      ),
      6,
    );
  });

  testWidgets(
    'switch flushes old collection before selection and opens target',
    (tester) async {
      final events = <String>[];
      final profileStore = _MemoryStore(events: events);
      final profiles = SharedProfileRuntime(profileStore);
      await profiles.create(
        const ProfileId('work'),
        (ProfileName.validate('Work') as ProfileNameValid).name,
      );
      await profiles.completeOnboarding();
      final services = _services(directory, profileStore, events: events);
      await tester.pumpWidget(AppRouter(services: services));
      await tester.pumpAndSettle();
      events.clear();

      await tester.tap(find.text('Profiles'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('select-work')));
      await tester.pumpAndSettle();

      final oldFlush = events.indexOf('flush:default');
      final selectionWrite = events.indexOf('persist');
      final targetOpen = events.indexOf('open:work');
      expect(oldFlush, greaterThanOrEqualTo(0));
      expect(selectionWrite, greaterThan(oldFlush));
      expect(targetOpen, greaterThan(selectionWrite));
      expect(
        tester.widget<ListTile>(find.byKey(const Key('select-work'))).selected,
        isTrue,
      );
    },
  );

  testWidgets('creation failures retry and invalid collection bytes survive', (
    tester,
  ) async {
    final events = <String>[];
    var failOpenOnce = true;
    final collections = CollectionRuntime(
      locationForProfile: (id) async {
        return '${directory.path}/${id.value}.anki2';
      },
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (location) {
          events.add('open');
          if (failOpenOnce) {
            failOpenOnce = false;
            throw StateError('transient database open failure');
          }
          return sqlite.sqlite3.open(location);
        },
      ),
    );
    final profiles = SharedProfileRuntime(store);
    final services = AppServices(
      startup: profiles,
      profiles: profiles,
      collections: collections,
    );
    await tester.pumpWidget(AppRouter(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up Anki'));
    await tester.pumpAndSettle();
    expect(find.text('Collection could not be opened'), findsOneWidget);
    expect(collections.storage, isNull);
    expect(collections.isInitialized, isFalse);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Active profile: Default'), findsOneWidget);
    expect(collections.isInitialized, isTrue);
    expect(
      await collections.storage!.queryInt('select count(*) from decks'),
      1,
    );

    await collections.close();
    final path = '${directory.path}/corrupt.anki2';
    final originalBytes = [
      0x6e,
      0x6f,
      0x74,
      0x2d,
      0x73,
      0x71,
      0x6c,
      0x69,
      0x74,
      0x65,
    ];
    await tester.runAsync(() => File(path).writeAsBytes(originalBytes));
    final corruptRuntime = CollectionRuntime(
      locationForProfile: (_) async => path,
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (location) => sqlite.sqlite3.open(location),
      ),
    );
    final corruptServices = AppServices(
      startup: profiles,
      profiles: profiles,
      collections: corruptRuntime,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(AppRouter(services: corruptServices));
    await tester.pumpAndSettle();
    expect(find.text('Collection could not be opened'), findsOneWidget);
    expect(corruptRuntime.isInitialized, isFalse);
    expect(
      await tester.runAsync(() => File(path).readAsBytes()),
      originalBytes,
    );
  });
}

AppServices _services(
  Directory directory,
  _MemoryStore store, {
  List<String>? events,
}) {
  final profiles = SharedProfileRuntime(store);
  return AppServices(
    startup: profiles,
    profiles: profiles,
    collections: CollectionRuntime(
      locationForProfile: (id) async {
        return '${directory.path}/${id.value}.anki2';
      },
      createDriver: () async {
        var openedPath = '';
        return CollectionSqliteDriver(
          openDatabase: (location) {
            openedPath = location;
            events?.add('open:${location.split('/').last.split('.').first}');
            return sqlite.sqlite3.open(location);
          },
          flush: () {
            events?.add('flush:${openedPath.split('/').last.split('.').first}');
          },
        );
      },
    ),
  );
}

final class _MemoryStore implements AppKeyValueStore {
  _MemoryStore({this.events});

  final Map<String, String> values = {};
  final List<String>? events;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
    events?.add('persist');
  }
}
