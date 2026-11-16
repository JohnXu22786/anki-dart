/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';

import 'package:anki_app/app.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/profile_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('profile open reuses, switches, and flushes its connection', () async {
    final locations = <String>[];
    var flushCount = 0;
    final runtime = CollectionRuntime(
      locationForProfile: (profile) async {
        final location = 'collections/${collectionProfileKey(profile)}.anki2';
        locations.add(location);
        return location;
      },
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
        flush: () => flushCount++,
      ),
    );
    const firstProfile = ProfileId.defaultId;
    const secondProfile = ProfileId('p_1234');

    final first = await runtime.open(firstProfile);
    expect(await runtime.open(firstProfile), same(first));
    expect(locations, hasLength(1));

    await runtime.switchProfile(secondProfile, () async {});
    final second = await runtime.open(secondProfile);
    expect(second, isNot(same(first)));
    expect(runtime.storage, same(second));
    expect(locations.toSet(), hasLength(2));
    expect(flushCount, 3);

    await runtime.close();
    expect(runtime.storage, isNull);
    expect(flushCount, 4);

    var failCloseFlush = false;
    var retryFlushCount = 0;
    final retryError = StateError('close flush failed');
    final retryDatabase = sqlite3.openInMemory();
    final retryRuntime = CollectionRuntime(
      locationForProfile: (_) async => 'retry.anki2',
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (_) => retryDatabase,
        flush: () {
          retryFlushCount++;
          if (failCloseFlush) throw retryError;
        },
      ),
    );
    final retryStorage = await retryRuntime.open(firstProfile);
    failCloseFlush = true;
    await expectLater(retryRuntime.close(), throwsA(same(retryError)));
    expect(retryRuntime.storage, same(retryStorage));
    failCloseFlush = false;
    await retryRuntime.close();
    expect(retryRuntime.storage, isNull);
    expect(retryFlushCount, 3);
    expect(() => retryDatabase.select('SELECT 1'), throwsA(anything));

    final allowOpen = Completer<void>();
    final openingDatabase = sqlite3.openInMemory();
    final pendingRuntime = CollectionRuntime(
      locationForProfile: (_) async {
        await allowOpen.future;
        return 'pending.anki2';
      },
      createDriver: () async =>
          CollectionSqliteDriver(openDatabase: (_) => openingDatabase),
    );
    final openFuture = pendingRuntime.open(firstProfile);
    var closed = false;
    final closeFuture = pendingRuntime.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    allowOpen.complete();
    await openFuture;
    await closeFuture;
    expect(pendingRuntime.storage, isNull);
    expect(() => openingDatabase.select('SELECT 1'), throwsA(anything));
  });

  test(
    'open and flush errors are preserved and leave no active connection',
    () async {
      final openingError = StateError('open failed');
      final runtime = CollectionRuntime(
        locationForProfile: (_) async => 'collection.anki2',
        createDriver: () async =>
            CollectionSqliteDriver(openDatabase: (_) => throw openingError),
      );

      await expectLater(
        runtime.open(ProfileId.defaultId),
        throwsA(same(openingError)),
      );
      expect(runtime.storage, isNull);

      final flushError = StateError('flush failed');
      final flushRuntime = CollectionRuntime(
        locationForProfile: (_) async => 'collection.anki2',
        createDriver: () async => CollectionSqliteDriver(
          openDatabase: (_) => sqlite3.openInMemory(),
          flush: () => throw flushError,
        ),
      );
      await expectLater(
        flushRuntime.open(ProfileId.defaultId),
        throwsA(same(flushError)),
      );
      expect(flushRuntime.storage, isNull);
    },
  );

  test('successful profile switching closes the previous collection', () async {
    var flushCount = 0;
    final runtime = CollectionRuntime(
      locationForProfile: (profile) async => profile.value,
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
        flush: () => flushCount++,
      ),
    );
    final store = _MemoryStore();
    final preferences = SharedProfileRuntime(store);
    final firstName =
        (ProfileName.validate('Default') as ProfileNameValid).name;
    final secondName = (ProfileName.validate('Other') as ProfileNameValid).name;
    await preferences.create(ProfileId.defaultId, firstName, isActive: true);
    await preferences.create(const ProfileId('other'), secondName);
    final services = AppServices(
      startup: preferences,
      profiles: preferences,
      collections: runtime,
    );

    await runtime.open(ProfileId.defaultId);
    final allowPersistence = Completer<void>();
    final persistenceStarted = Completer<void>();
    store.writeGate = allowPersistence;
    store.writeStarted = persistenceStarted;
    final switchFuture = services.profileManager.switchActiveProfile(
      const ProfileId('other'),
    );
    await persistenceStarted.future;
    final staleOpen = runtime.open(ProfileId.defaultId);
    allowPersistence.complete();
    final result = await switchFuture;
    await expectLater(staleOpen, throwsA(isA<StateError>()));

    expect(result, isA<ProfileSwitchGuardSuccess>());
    expect((await preferences.load()).active?.id, const ProfileId('other'));
    expect(runtime.storage, isNull);
    expect(flushCount, 2);
  });
}

final class _MemoryStore implements AppKeyValueStore {
  final values = <String, String>{};
  Completer<void>? writeGate;
  Completer<void>? writeStarted;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writeStarted?.complete();
    await writeGate?.future;
    values[key] = value;
  }
}
