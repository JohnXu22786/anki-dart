// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:test/test.dart';

final class _RecordingExecutor implements SearchSqlQueryExecutor {
  final calls = <String>[];
  Object? batchError;
  Object? queryError;
  List<BigInt> result = const [];

  @override
  Future<void> executeBatch(String sql) async {
    calls.add('batch:$sql');
    if (batchError case final error?) throw error;
  }

  @override
  Future<List<BigInt>> queryIds(String sql, List<String> arguments) async {
    calls.add('query:$sql:${arguments.join('|')}');
    if (queryError case final error?) throw error;
    return result;
  }
}

void main() {
  test(
    'Core search runs ordered sort preparation before the ID query',
    () async {
      final executor = _RecordingExecutor()
        ..result = [BigInt.parse('9223372036854775807'), BigInt.from(7)];
      const prepared =
          'DROP TABLE IF EXISTS sort_order; CREATE TEMP TABLE sort_order(x);';
      final plan = CompiledSearchSqlWithSort(
        search: const CompiledSearchSql(
          sql: 'select c.id from cards c where c.id = ? order by c.id',
          arguments: ['42'],
          requiredTable: RequiredTable.cards,
        ),
        preparationSql: [prepared],
      );

      final result = await executeSearchSqlPlan(executor, plan);

      expect(result, executor.result);
      expect(executor.calls, [
        'batch:$prepared',
        'query:select c.id from cards c where c.id = ? order by c.id:42',
      ]);
    },
  );

  test('unordered Core searches query directly without preparation', () async {
    final executor = _RecordingExecutor();
    final plan = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
      resultType: SearchResultType.notes,
    );

    await executeSearchSqlPlan(executor, plan);

    expect(executor.calls, ['query:select n.id from notes n where (true):']);
  });

  test(
    'multiple preparation batches run sequentially with bind order intact',
    () async {
      final executor = _RecordingExecutor();
      final plan = CompiledSearchSqlWithSort(
        search: const CompiledSearchSql(
          sql: 'select n.id from notes n where n.id in (?, ?)',
          arguments: ['11', '22'],
          requiredTable: RequiredTable.notes,
        ),
        preparationSql: ['prepare-one; prepare-two;', 'prepare-three;'],
      );

      await executeSearchSqlPlan(executor, plan);

      expect(executor.calls, [
        'batch:prepare-one; prepare-two;',
        'batch:prepare-three;',
        'query:select n.id from notes n where n.id in (?, ?):11|22',
      ]);
    },
  );

  test(
    'preparation failure prevents query and preserves the host error',
    () async {
      final executor = _RecordingExecutor()..batchError = StateError('prepare');
      final plan = CompiledSearchSqlWithSort(
        search: const CompiledSearchSql(
          sql: 'select c.id from cards c where true',
          arguments: [],
          requiredTable: RequiredTable.cards,
        ),
        preparationSql: ['prepare;'],
      );

      await expectLater(executeSearchSqlPlan(executor, plan), throwsStateError);
      expect(executor.calls, ['batch:prepare;']);
    },
  );

  test('query failure is propagated without wrapping', () async {
    final executor = _RecordingExecutor()..queryError = StateError('query');
    final plan = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
    );

    await expectLater(executeSearchSqlPlan(executor, plan), throwsStateError);
    expect(executor.calls.single, startsWith('query:'));
  });
}
