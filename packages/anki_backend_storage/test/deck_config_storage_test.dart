// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:ffi';
import 'dart:io';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as proto;
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/open.dart' as sqliteOpen;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  if (Platform.isLinux) {
    sqliteOpen.open.overrideFor(
      sqliteOpen.OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }
  late Database sqlite;
  late DeckConfigStorage storage;

  setUp(() {
    sqlite = sqlite3.openInMemory();
    sqlite.execute('''
CREATE TABLE deck_config (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  config BLOB NOT NULL
)''');
    storage = DeckConfigStorage(_SqliteAdapter(sqlite));
  });

  tearDown(() => sqlite.dispose());

  test('deck configs round-trip protobuf bytes and preserve signed 64-bit IDs',
      () {
    final id = Int64.parseInt('9007199254740993');
    final config = _config(
      id: id,
      name: 'Custom',
      mtimeSecs: Int64.parseInt('9007199254740995'),
      usn: -7,
      inner: proto.DeckConfig_Config(
        newPerDay: 41,
        initialEase: 2.25,
        fsrsParams6: [0.2, 0.5],
      ),
    );
    storage.addOrUpdateDeckConfigWithExistingId(config);

    final decoded = storage.getDeckConfig(id)!;
    expect(decoded.id, id);
    expect(decoded.name, 'Custom');
    expect(decoded.mtimeSecs, config.mtimeSecs);
    expect(decoded.usn, -7);
    expect(decoded.inner.newPerDay, 41);
    expect(decoded.inner.initialEase, 2.25);
    expect(decoded.inner.fsrsParams6[0], closeTo(0.2, 0.000001));
    expect(decoded.inner.fsrsParams6[1], 0.5);
    expect(storage.getDeckConfigIdByName('Custom'), id);
    expect(storage.getDeckConfigIdByName('custom'), id);
    expect(storage.getDeckConfig(Int64(8)), isNull);
    final configMap = storage.getDeckConfigMap();
    expect(configMap.keys, [id]);
    expect(configMap[id]!.name, decoded.name);
  });

  test('all configs apply Core validation but schema-16 read skips it', () {
    final invalid = _config(
      id: Int64(3),
      name: 'Invalid',
      inner: proto.DeckConfig_Config(
        newPerDay: 10000,
        initialEase: 0,
        desiredRetention: double.nan,
        historicalRetention: 1,
      ),
    );
    storage.addOrUpdateDeckConfigWithExistingId(invalid);

    final validated = storage.allDeckConfigs().single.inner;
    expect(validated.newPerDay, DeckConfig.defaults().inner.newPerDay);
    expect(validated.initialEase, DeckConfig.defaults().inner.initialEase);
    expect(
      validated.desiredRetention,
      DeckConfig.defaults().inner.desiredRetention,
    );
    expect(
      validated.historicalRetention,
      DeckConfig.defaults().inner.historicalRetention,
    );
    final raw = storage.allDeckConfigsForSchema16Upgrade().single.inner;
    expect(raw.newPerDay, 10000);
    expect(raw.initialEase, 0);
    expect(raw.desiredRetention.isNaN, isTrue);
    expect(raw.historicalRetention, 1);
  });

  test('add allocates a new ID after a collision and preserves input fields',
      () {
    storage.addOrUpdateDeckConfigWithExistingId(
      _config(id: Int64(4), name: 'First'),
    );
    storage.addOrUpdateDeckConfigWithExistingId(
      _config(id: Int64(9), name: 'Last'),
    );
    final input = _config(id: Int64(4), name: 'Inserted');

    final inserted = storage.addDeckConfig(input);

    expect(inserted.id, Int64(10));
    expect(input.id, Int64(4));
    expect(storage.getDeckConfig(inserted.id)!.name, 'Inserted');
  });

  test('insert-if-unique reports ignored primary-key collisions', () {
    final original = _config(id: Int64(11), name: 'Original');
    expect(storage.addDeckConfigIfUnique(original), isTrue);
    expect(
      storage.addDeckConfigIfUnique(_config(id: Int64(11), name: 'Ignored')),
      isFalse,
    );
    expect(storage.getDeckConfig(Int64(11))!.name, 'Original');
  });

  test('update, replace, remove, and USN clearing match Core row behavior', () {
    storage.addOrUpdateDeckConfigWithExistingId(
      _config(id: Int64(21), name: 'Before', usn: 8),
    );
    storage.updateDeckConfig(_config(id: Int64(21), name: 'After', usn: 9));
    expect(storage.getDeckConfig(Int64(21))!.name, 'After');
    expect(storage.getDeckConfig(Int64(21))!.usn, 9);
    expect(() => storage.updateDeckConfig(_config(id: Int64(22))),
        returnsNormally);

    storage.addOrUpdateDeckConfigWithExistingId(
      _config(id: Int64(21), name: 'Replacement'),
    );
    expect(storage.getDeckConfig(Int64(21))!.name, 'Replacement');
    expect(
      () => storage.addOrUpdateDeckConfigWithExistingId(_config()),
      throwsStateError,
    );
    storage.addOrUpdateDeckConfigWithExistingId(
      _config(id: Int64(25), name: 'Other', usn: -1),
    );
    storage.clearDeckConfigUsns();
    expect(storage.getDeckConfig(Int64(25))!.usn, 0);
    storage.removeDeckConfig(Int64(21));
    storage.removeDeckConfig(Int64(999));
    expect(storage.getDeckConfig(Int64(21)), isNull);
    expect(storage.getDeckConfig(Int64(25)), isNotNull);
  });
}

DeckConfig _config({
  Int64? id,
  String name = '',
  Int64? mtimeSecs,
  int usn = 0,
  proto.DeckConfig_Config? inner,
}) =>
    DeckConfig(
      id: id ?? Int64.ZERO,
      name: name,
      mtimeSecs: mtimeSecs ?? Int64(0),
      usn: usn,
      inner: inner ?? DeckConfig.defaults().inner,
    );

final class _SqliteAdapter implements DeckConfigStorageDatabase {
  const _SqliteAdapter(this.database);

  final Database database;

  @override
  List<Map<String, Object?>> select(String sql,
      [List<Object?> parameters = const []]) {
    final rows = database.select(sql, parameters);
    final names = rows.columnNames;
    return rows
        .map((row) =>
            {for (var i = 0; i < names.length; i++) names[i]: row.columnAt(i)})
        .toList(growable: false);
  }

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    database.execute(sql, parameters);
    return database.updatedRows;
  }
}
