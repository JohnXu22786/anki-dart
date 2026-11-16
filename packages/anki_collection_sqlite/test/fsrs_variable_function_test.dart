// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/fsrs_variable_function.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('extracts supported FSRS values with stored f32 precision', () {
    expect(
      extractFsrsVariable('{"s":0.123456789,"d":2.25,"dr":0.9}', 's'),
      0.12345679104328156,
    );
    expect(
      extractFsrsVariable('{"s":0.123456789,"d":2.25,"dr":0.9}', 'd'),
      2.25,
    );
    expect(
      extractFsrsVariable('{"s":0.123456789,"d":2.25,"dr":0.9}', 'dr'),
      0.8999999761581421,
    );
    expect(extractFsrsVariable('[null,0.5,2,0.9]', 's'), 0.5);
    expect(
      extractFsrsVariable('{"s":18014401730707455}', 's'),
      18014400656965632.0,
    );
  });

  test('returns null for absent, malformed, or non-text inputs', () {
    expect(extractFsrsVariable('{"s":"0.5"}', 's'), isNull);
    expect(extractFsrsVariable('{"s":null}', 's'), isNull);
    expect(extractFsrsVariable('{"s":1,"s":2}', 's'), isNull);
    expect(extractFsrsVariable('{"s":1e100}', 's')!.isInfinite, isTrue);
    expect(extractFsrsVariable('{"s":0.5,"cd":42}', 's'), isNull);
    expect(extractFsrsVariable('{bad json', 's'), isNull);
    expect(extractFsrsVariable('', 's'), isNull);
    expect(extractFsrsVariable(null, 's'), isNull);
    expect(extractFsrsVariable('{"s":0.5}', null), isNull);
  });

  test('invalid string key follows Core function error behavior', () {
    expect(
      () => extractFsrsVariable('{"s":0.5}', 'unknown'),
      throwsA(isA<StateError>()),
    );
  });

  test('registered SQL function returns nullable Core f32 values', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerFsrsVariableFunction(database);

    expect(
      database
          .select("SELECT extract_fsrs_variable('{\"s\":0.123456789}', 's')")
          .single[0],
      0.12345679104328156,
    );
    expect(
      database
          .select("SELECT extract_fsrs_variable('{\"s\":null}', 's')")
          .single[0],
      isNull,
    );
    expect(
      () =>
          database.select("SELECT extract_fsrs_variable('{\"s\":0.5}', 'bad')"),
      throwsA(isA<SqliteException>()),
    );
  });
}
