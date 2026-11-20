/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';
import 'dart:io';

import 'package:anki_app/app.dart';
import 'package:anki_app/collection_runtime_platform_native.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_native.dart';
import 'package:anki_dart/profile_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

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
    var retryOpenCount = 0;
    final retryRuntime = CollectionRuntime(
      locationForProfile: (_) async => 'retry.anki2',
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (_) {
          retryOpenCount++;
          return sqlite3.openInMemory();
        },
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
    final reopenedStorage = await retryRuntime.open(firstProfile);
    expect(reopenedStorage, isNot(same(retryStorage)));
    expect(retryOpenCount, 2);
    expect(retryRuntime.storage, same(reopenedStorage));
    await retryRuntime.close();
    expect(retryRuntime.storage, isNull);
    expect(retryFlushCount, 5);

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
    'profile media drivers are stable, isolated, and released on switch',
    () async {
      final createdFor = <ProfileId>[];
      final media = <ProfileId, _TrackedMedia>{};
      final runtime = CollectionRuntime(
        locationForProfile: (profile) async =>
            'collections/${collectionProfileKey(profile)}.anki2',
        createDriverForProfile: (profile) async {
          createdFor.add(profile);
          final store = _TrackedMedia();
          media[profile] = store;
          return CollectionSqliteDriver(
            openDatabase: (_) => sqlite3.openInMemory(),
            mediaStorage: store,
          );
        },
      );
      const first = ProfileId('first/profile');
      const second = ProfileId('second');
      expect(
        collectionMediaDatabaseName(first),
        collectionMediaDatabaseName(first),
      );
      expect(
        collectionMediaDatabaseName(first),
        isNot(collectionMediaDatabaseName(second)),
      );

      final firstStorage = await runtime.open(first);
      expect(await runtime.open(first), same(firstStorage));
      expect(createdFor, [first]);
      final firstStore = media[first]!;
      await runtime.switchProfile(second, () async {});
      expect(firstStore.closeCount, 1);
      final secondStorage = await runtime.open(second);
      expect(secondStorage, isNot(same(firstStorage)));
      expect(media[second], isNot(same(firstStore)));
      await runtime.close();
      expect(media[second]!.closeCount, 1);
    },
  );

  test('media close failures surface and retry before reopening', () async {
    final media = _TrackedMedia()..failNextClose = true;
    var driverCount = 0;
    final runtime = CollectionRuntime(
      locationForProfile: (_) async => 'retry-media.anki2',
      createDriverForProfile: (_) async {
        driverCount++;
        return CollectionSqliteDriver(
          openDatabase: (_) => sqlite3.openInMemory(),
          mediaStorage: media,
        );
      },
    );
    final profile = ProfileId.defaultId;
    final firstStorage = await runtime.open(profile);
    await expectLater(runtime.close(), throwsA(same(media.closeError)));
    expect(runtime.storage, same(firstStorage));
    final reopened = await runtime.open(profile);
    expect(reopened, isNot(same(firstStorage)));
    expect(media.closeCount, 2);
    expect(driverCount, 2);
    await runtime.close();
  });

  test('failed collection opening releases its profile media handle', () async {
    final media = _TrackedMedia();
    final runtime = CollectionRuntime(
      locationForProfile: (_) async => 'failed-open.anki2',
      createDriverForProfile: (_) async => CollectionSqliteDriver(
        openDatabase: (_) => throw StateError('database initialization failed'),
        mediaStorage: media,
      ),
    );
    await expectLater(
      runtime.open(ProfileId.defaultId),
      throwsA(isA<StateError>()),
    );
    expect(media.closeCount, 1);
    expect(runtime.storage, isNull);
  });

  test(
    'native media directory is stable, isolated, and retained on reopen',
    () async {
      final root = await Directory.systemTemp.createTemp('anki-profile-media-');
      try {
        const firstProfile = ProfileId('native/first');
        const secondProfile = ProfileId('native/second');
        final firstDirectory = nativeCollectionMediaDirectoryForProfile(
          root,
          firstProfile,
        );
        expect(
          nativeCollectionMediaDirectoryForProfile(root, firstProfile).path,
          firstDirectory.path,
        );
        final secondDirectory = nativeCollectionMediaDirectoryForProfile(
          root,
          secondProfile,
        );
        expect(secondDirectory.path, isNot(firstDirectory.path));
        await firstDirectory.create(recursive: true);
        await File('${firstDirectory.path}${Platform.pathSeparator}stored.bin')
            .writeAsBytes([3, 1, 4]);
        await DirectoryCollectionMediaStorage(firstDirectory).close();
        final reopened = DirectoryCollectionMediaStorage(firstDirectory);
        final media = await reopened.read('stored.bin');
        expect(await media!.expand((chunk) => chunk).toList(), [3, 1, 4]);
        await reopened.close();
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

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

final class _TrackedMedia implements CollectionMediaStorage {
  int closeCount = 0;
  bool failNextClose = false;
  final closeError = StateError('media close failed');

  @override
  Future<void> close() async {
    closeCount++;
    if (failNextClose) {
      failNextClose = false;
      throw closeError;
    }
  }

  @override
  Future<Iterable<String>> list() async => const [];

  @override
  Future<Stream<List<int>>?> read(String filename) async => null;
}
