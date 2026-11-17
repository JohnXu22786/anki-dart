// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CommonDatabase database;
  late CollectionSqliteSearchExecutor executor;

  setUp(() {
    database = sqlite3.openInMemory();
    executor = CollectionSqliteSearchExecutor(database);
  });

  tearDown(() => database.close());

  test(
    'preparation batches and query share the connection and preserve row order',
    () async {
      database.execute('CREATE TABLE cards (id INTEGER NOT NULL, value TEXT)');
      database.execute(
        "INSERT INTO cards VALUES (10, 'ten'), (2, 'two'), (7, 'seven')",
      );

      await executor.executeBatch('''
      DROP TABLE IF EXISTS sort_order;
      CREATE TEMP TABLE sort_order (pos INTEGER PRIMARY KEY, id INTEGER NOT NULL);
      INSERT INTO sort_order VALUES (0, 7), (1, 10), (2, 2);
    ''');
      final ids = await executor.queryIds(
        'SELECT cards.id FROM cards JOIN sort_order USING (id) '
        'WHERE cards.value != ? ORDER BY sort_order.pos',
        ['ignored'],
      );

      expect(ids, [BigInt.from(7), BigInt.from(10), BigInt.from(2)]);
    },
  );

  test(
    'storage executes a compiled search plan on its collection connection',
    () async {
      final collectionDatabase = sqlite3.openInMemory();
      final storage = await CollectionSqliteStorage.open(
        driver: CollectionSqliteDriver(openDatabase: (_) => collectionDatabase),
        location: 'memory',
      );
      collectionDatabase.execute('CREATE TABLE cards (id INTEGER NOT NULL)');
      collectionDatabase.execute('INSERT INTO cards VALUES (8), (3)');

      final ids = await storage.executeSearchPlan(
        const CompiledSearchSqlWithSort(
          search: CompiledSearchSql(
            sql:
                'SELECT cards.id FROM cards JOIN sort_order USING (id) '
                'ORDER BY sort_order.pos',
            arguments: [],
            requiredTable: RequiredTable.cards,
          ),
          preparationSql: [
            'CREATE TEMP TABLE sort_order (pos INTEGER, id INTEGER); '
                'INSERT INTO sort_order VALUES (0, 8), (1, 3);',
          ],
        ),
      );

      expect(ids, [BigInt.from(8), BigInt.from(3)]);
      await storage.close();
    },
  );

  test('maps signed 64-bit integer bounds without narrowing', () async {
    final ids = await executor.queryIds(
      'SELECT CAST(value AS INTEGER) FROM '
      '(SELECT ? AS value UNION ALL SELECT ?)',
      ['-9223372036854775808', '9223372036854775807'],
    );

    expect(ids, [
      BigInt.parse('-9223372036854775808'),
      BigInt.parse('9223372036854775807'),
    ]);
  });

  test('rejects non-integer search results', () async {
    await expectLater(
      executor.queryIds("SELECT 'not-an-id'", const []),
      throwsFormatException,
    );
    await expectLater(
      executor.queryIds('SELECT 1.5', const []),
      throwsFormatException,
    );
  });

  test(
    'rejects an adapter result outside the Core signed 64-bit ID range',
    () async {
      final invalid = CollectionSqliteSearchExecutor(
        _SingleValueDatabase(BigInt.parse('9223372036854775808')),
      );

      await expectLater(
        invalid.queryIds('SELECT id', const []),
        throwsRangeError,
      );
    },
  );
}

final class _SingleValueDatabase implements CommonDatabase {
  _SingleValueDatabase(this.value);

  final BigInt value;

  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) =>
      ResultSet(
        ['id'],
        null,
        [
          <Object?>[value],
        ],
      );

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
