// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/unicase_collation.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('unicase collation applies pinned Unicode folding in SQLite', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerUnicaseCollation(database);

    expect(database.select("SELECT 'Ä' = 'ä' COLLATE unicase").single[0], 1);
    expect(
      database.select("SELECT 'Straße' = 'STRASSE' COLLATE unicase").single[0],
      1,
    );
    expect(database.select("SELECT '𐐀' = '𐐨' COLLATE unicase").single[0], 1);
    expect(
      database.select("SELECT 'Straße' < 'Straßen' COLLATE unicase").single[0],
      1,
    );
  });

  test('unicase ordering compares Unicode scalar values', () {
    expect(compareUniCase('𐀀', '\ue000'), greaterThan(0));
    expect(compareUniCase('a', 'A'), 0);
    expect(compareUniCase(null, ''), 0);
  });
}
