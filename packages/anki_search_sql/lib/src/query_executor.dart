// SPDX-License-Identifier: AGPL-3.0-or-later
import 'sort_compiler.dart';

/// The minimal host boundary needed to execute a Core search plan.
///
/// Implementations must use one database connection for preparation batches
/// and the following ID query. Database errors are propagated to the caller.
abstract interface class SearchSqlQueryExecutor {
  /// Executes a potentially multi-statement Core sort preparation batch.
  Future<void> executeBatch(String sql);

  /// Executes an ID query with arguments in the exact order supplied.
  ///
  /// The host is responsible for lossless mapping of database integer IDs to
  /// [BigInt], including on targets where JavaScript numbers cannot represent
  /// every signed 64-bit integer.
  Future<List<BigInt>> queryIds(String sql, List<String> arguments);
}

/// Executes Core's search sequence: sort preparation batches first, then the
/// compiled SELECT, returning the IDs in database result order.
Future<List<BigInt>> executeSearchSqlPlan(
  SearchSqlQueryExecutor executor,
  CompiledSearchSqlWithSort plan,
) async {
  for (final sql in plan.preparationSql) {
    await executor.executeBatch(sql);
  }
  return executor.queryIds(plan.search.sql, plan.search.arguments);
}
