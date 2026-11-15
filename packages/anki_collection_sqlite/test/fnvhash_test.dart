// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/fnvhash.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('fnvhash matches Core signed i64 FNV-1a vectors', () {
    expect(fnvHashSqlArguments([]), BigInt.parse('-3750763034362895579'));
    expect(fnvHashSqlArguments([0]), BigInt.parse('-6284781860667377211'));
    expect(fnvHashSqlArguments([1]), BigInt.parse('-8517097267634966620'));
    expect(fnvHashSqlArguments([-1]), BigInt.parse('-8289690350564177859'));
    expect(fnvHashSqlArguments([1, 2]), BigInt.parse('8581494755304202342'));
    expect(fnvHashSqlArguments([2, 1]), BigInt.parse('513837244993915590'));
    expect(
      fnvHashSqlArguments([BigInt.parse('9223372036854775807')]),
      BigInt.parse('-8289549613075766851'),
    );
    expect(
      fnvHashSqlArguments([BigInt.parse('-9223372036854775808')]),
      BigInt.parse('-6284922598155788219'),
    );
    expect(() => fnvHashSqlArguments([1.0]), throwsArgumentError);
    expect(() => fnvHashSqlArguments([BigInt.one << 63]), throwsArgumentError);
  });

  test('registered fnvhash SQL function preserves order and 64-bit values', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerFnvHashFunction(database);

    expect(database.select('SELECT fnvhash()').single[0], -3750763034362895579);
    expect(
      database.select('SELECT fnvhash(1, 2)').single[0],
      8581494755304202342,
    );
    expect(
      database.select('SELECT fnvhash(2, 1)').single[0],
      513837244993915590,
    );
    expect(
      database.select('SELECT fnvhash(?)', [
        BigInt.parse('9223372036854775807'),
      ]).single[0],
      -8289549613075766851,
    );
    expect(
      () => database.select("SELECT fnvhash('1')"),
      throwsA(isA<SqliteException>()),
    );
  });
}
