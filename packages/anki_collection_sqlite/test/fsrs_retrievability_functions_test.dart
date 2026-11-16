// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/collection_sqlite_storage.dart';
import 'package:anki_collection_sqlite/src/fsrs_retrievability_functions.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('FSRS retrievability uses stored review time and f32 state', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerFsrsRetrievabilityFunctions(database);

    final value =
        database.select(
              'SELECT extract_fsrs_retrievability(?, 100, 10, 110, 0, 87400)',
              ['{"s":10,"d":5,"lrt":1000}'],
            ).single[0]
            as double;
    expect(value, closeTo(0.9884739518, 1e-7));
  });

  test('learning due uses seconds and interval fallback uses days', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerFsrsRetrievabilityFunctions(database);

    final learning =
        database.select(
              'SELECT extract_fsrs_retrievability(?, 500000, 3600, 0, 0, 500000)',
              ['{"s":10,"d":5}'],
            ).single[0]
            as double;
    expect(learning, closeTo(0.9995116591, 1e-7));

    final relativeFallback =
        database.select(
              'SELECT extract_fsrs_relative_retrievability(?, 100, 10, 110, 0, 0)',
              ['{}'],
            ).single[0]
            as double;
    expect(relativeFallback, closeTo(-2.0001, 2e-7));
  });

  test('relative retrievability scales by desired retention', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerFsrsRetrievabilityFunctions(database);

    final value =
        database.select(
              'SELECT extract_fsrs_relative_retrievability(?, 100, 10, 110, 0, 87400)',
              ['{"s":10,"d":5,"dr":0.9,"lrt":1000}'],
            ).single[0]
            as double;
    expect(value, closeTo(-0.10000027, 1e-6));
  });

  test('FSRS functions preserve null and malformed-data behavior', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerFsrsRetrievabilityFunctions(database);

    expect(
      database.select(
        'SELECT extract_fsrs_retrievability(?, 100, 10, 110, 0, 87400)',
        [null],
      ).single[0],
      isNull,
    );
    expect(
      database.select(
        'SELECT extract_fsrs_retrievability(?, 100, 10, 110, 0, 87400)',
        ['{"s":10,"d":5,"s":9}'],
      ).single[0],
      isNull,
    );
    expect(
      database.select(
        'SELECT extract_fsrs_retrievability(?, 100, 10.5, 110, 0, 87400)',
        ['{"s":10,"d":5}'],
      ).single[0],
      isNull,
    );
  });

  test(
    'storage registers both retrievability functions on each connection',
    () async {
      final database = sqlite3.openInMemory();
      final storage = await CollectionSqliteStorage.open(
        driver: CollectionSqliteDriver(openDatabase: (_) => database),
        location: ':memory:',
      );
      addTearDown(storage.close);

      expect(
        database.select(
          'SELECT extract_fsrs_retrievability(?, 100, 10, 110, 0, 87400) IS NULL',
          ['{"s":10,"d":5}'],
        ).single[0],
        0,
      );
      expect(
        database.select(
          'SELECT extract_fsrs_relative_retrievability(?, 100, 10, 110, 0, 87400) IS NOT NULL',
          ['{}'],
        ).single[0],
        1,
      );
    },
  );
}
