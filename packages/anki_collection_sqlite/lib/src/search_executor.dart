// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:sqlite3/common.dart';

/// Executes Anki search plans against an existing cross-platform SQLite
/// connection. Preparation and result queries use the same database handle.
final class CollectionSqliteSearchExecutor implements SearchSqlQueryExecutor {
  const CollectionSqliteSearchExecutor(this.database);

  final CommonDatabase database;

  @override
  Future<void> executeBatch(String sql) async {
    database.execute(sql);
  }

  @override
  Future<List<BigInt>> queryIds(String sql, List<String> arguments) async {
    final rows = database.select(sql, arguments);
    return List<BigInt>.unmodifiable(
      rows.map((row) => _signedI64(row.columnAt(0))),
    );
  }
}

final BigInt _minI64 = BigInt.parse('-9223372036854775808');
final BigInt _maxI64 = BigInt.parse('9223372036854775807');

BigInt _signedI64(Object? value) {
  final integer = switch (value) {
    BigInt() => value,
    int() => BigInt.from(value),
    _ => throw FormatException('SQLite search ID must be an integer: $value'),
  };
  if (integer < _minI64 || integer > _maxI64) {
    throw RangeError('Search ID $integer does not fit signed Core i64');
  }
  return integer;
}
