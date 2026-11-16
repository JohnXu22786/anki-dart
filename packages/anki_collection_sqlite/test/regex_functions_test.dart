// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/regex_functions.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('Core regex matching supports the generated global flag prefixes', () {
    expect(coreRegexHasMatch(r'(?i)needle', 'hay NEEDLE'), isTrue);
    expect(coreRegexHasMatch(r'(?is)^a.b$', 'a\nb'), isTrue);
    expect(coreRegexHasMatch(r'\p{L}+', 'éclair'), isTrue);
    expect(coreRegexHasMatch(r'\d+', '١٢٣'), isTrue);
    expect(coreRegexHasMatch(r'\w+', 'éclair'), isTrue);
    expect(coreRegexHasMatch(r'\s', '\u00a0'), isTrue);
    expect(coreRegexHasMatch(r'\bword\b', 'a word!'), isTrue);
    expect(coreRegexHasMatch(r'\W', '☃'), isTrue);
    expect(coreRegexHasMatch(r'\Astart\z', 'start'), isTrue);
    expect(coreRegexHasMatch(r'\b{start}word', 'a word'), isTrue);
    expect(coreRegexHasMatch(r'\b{start}word', 'sword'), isFalse);
    expect(coreRegexHasMatch(r'word\b{end}', 'word!'), isTrue);
    expect(coreRegexHasMatch(r'\p{Greek}+', 'αβ'), isTrue);
    expect(coreRegexHasMatch(r'(?P<word>needle)', 'hay needle'), isTrue);
    expect(coreRegexHasMatch(r'[\W]+', '☃'), isTrue);
    expect(coreRegexHasMatch(r'[a\W]+', 'a☃'), isTrue);
    expect(coreRegexHasMatch(r'(?i)a+(?-i)b+', 'AAAbbb'), isTrue);
    expect(coreRegexHasMatch(r'(?i)a+(?-i)b+', 'AAABBB'), isFalse);
    expect(coreRegexHasMatch(r'foo(?i:bar)', 'fooBAR'), isTrue);
    expect(coreRegexHasMatch(r'(?m)^foo$', 'x\nfoo\ny'), isTrue);
    expect(coreRegexHasMatch(r'(?s)a.b', 'a\nb'), isTrue);
    expect(coreRegexHasMatch(r'(?s:.)', '\n'), isTrue);
    expect(coreRegexHasMatch(r'(?i)[a-z]', 'A'), isTrue);
    expect(coreRegexHasMatch(r'(?i)[α]', 'Α'), isTrue);
    expect(coreRegexHasMatch(r'(?i)\p{Lu}', 'a'), isTrue);
    expect(coreRegexHasMatch(r'(?i)\p{Lu}', '漢'), isFalse);
    expect(coreRegexHasMatch(r'(?i)[\p{Lu}]', 'a'), isTrue);
    expect(coreRegexHasMatch(r'(?i)[\x{e0}-\x{e9}]', 'É'), isTrue);
    expect(coreRegexHasMatch(r'(?i)é', 'É'), isTrue);
    expect(coreRegexHasMatch(r'(?i)\x{e9}', 'É'), isTrue);
    expect(coreRegexHasMatch(r'(?i)\p{Greek}+', 'ΑΒ'), isTrue);
    expect(coreRegexHasMatch(r'(?i)\b{start}word', ' word'), isTrue);
    expect(coreRegexHasMatch(r'(?i)Σ', 'ς'), isTrue);
    expect(coreRegexHasMatch(r'(?i)(?P<word>É)', 'é'), isTrue);
    expect(coreRegexHasMatch(r'(?i-m)needle', 'NEEDLE'), isTrue);
    expect(coreRegexHasMatch(r'(?x)a b # ignored comment', 'ab'), isTrue);
    expect(coreRegexHasMatch(r'(?x)[a b]', ' '), isFalse);
    expect(coreRegexHasMatch(r'\pN+', '123'), isTrue);
    expect(coreRegexHasMatch(r'\p{XID_Start}+', 'abc'), isTrue);
    expect(coreRegexHasMatch(r'\p{gc=Lu}', 'A'), isTrue);
    expect(coreRegexHasMatch(r'\p{sc=Grek}', 'α'), isTrue);
    expect(coreRegexHasMatch(r'\p{digit}', '7'), isTrue);
    expect(coreRegexHasMatch(r'\p{greek}', 'α'), isTrue);
    expect(coreRegexHasMatch(r'\p{Alpha}', 'α'), isTrue);
    expect(coreRegexHasMatch(r'(?-u:\w+)', 'abc'), isTrue);
    expect(coreRegexHasMatch(r'(?-u:\w+)', 'αβ'), isFalse);
    expect(coreRegexHasMatch(r'(?-u:[\S])', '\u00a0'), isTrue);
    expect(coreRegexHasMatch(r'(?-u:[\D])', 'A'), isTrue);
    expect(coreRegexHasMatch(r'(?-u:[\W])', '²'), isTrue);
    expect(coreRegexHasMatch(r'(?-u:[\S])', ' '), isFalse);
    expect(coreRegexHasMatch(r'\a', '\x07'), isTrue);
    expect(coreRegexHasMatch(r'\x41', 'A'), isTrue);
    expect(coreRegexHasMatch(r'[\x41]', 'A'), isTrue);
    expect(coreRegexHasMatch(r'[\x{1F600}]', '😀'), isTrue);
    expect(coreRegexHasMatch(r'\w', '²'), isFalse);
    expect(coreRegexHasMatch(r'\b²\b', ' ² '), isFalse);
    expect(coreRegexHasMatch(r'\w', '٣'), isTrue);
    expect(coreRegexHasMatch(r'\w', 'Ⅷ'), isTrue);
    expect(coreRegexHasMatch(r'\PN+', 'abc'), isTrue);
    expect(coreRegexHasMatch(r'\P{Greek}+', 'abc'), isTrue);
    expect(coreRegexHasMatch(r'\b{start-half}word', ' word'), isTrue);
    expect(coreRegexHasMatch(r'\b{end-half}word', 'word'), isFalse);
    expect(coreRegexHasMatch(r'[\p{Greek}&&\p{L}]+', 'αβ'), isTrue);
    expect(coreRegexHasMatch(r'[\p{Greek}--[α]]+', 'β'), isTrue);
    expect(coreRegexHasMatch(r'[\p{Greek}--[α]]+', 'α'), isFalse);
    expect(coreRegexHasMatch(r'[a-g~~b-h]', 'a'), isTrue);
    expect(coreRegexHasMatch(r'[a-g~~b-h]', 'h'), isTrue);
    expect(coreRegexHasMatch(r'[a-g~~b-h]', 'c'), isFalse);
    expect(coreRegexHasMatch(r'[\W&&a]', 'a'), isFalse);
    expect(coreRegexHasMatch(r'[\\W]', r'\'), isTrue);
    expect(coreRegexHasMatch(r'[\\W]', 'W'), isTrue);
    expect(coreRegexHasMatch(r'[\\W]', 'a'), isFalse);
    expect(coreRegexHasMatch(r'[a[b]]', 'a'), isTrue);
    expect(coreRegexHasMatch(r'[a[b]]', 'b'), isTrue);
    expect(coreRegexHasMatch(r'[a[b]]', 'c'), isFalse);
    expect(coreRegexHasMatch(r'[\W&&\p{Greek}]', 'α'), isFalse);
    expect(coreRegexHasMatch(r'[\p{Greek}&&\p{L}]', '1'), isFalse);
    expect(coreRegexHasMatch(r'(?m)a$', 'a\r\n'), isFalse);
    expect(coreRegexHasMatch(r'(?mR)a$', 'a\r\n'), isTrue);
    expect(coreRegexHasMatch(r'(?mR)^b', 'a\r\nb'), isTrue);
    expect(coreRegexHasMatch(r'(?mR)^\n', '\r\n'), isFalse);
    expect(coreRegexHasMatch(r'(?mR)$foo', 'x\r\nfoo'), isFalse);
    expect(coreRegexHasMatch(r'(?mR).', '\r'), isFalse);
    expect(coreRegexHasMatch('.', '\r'), isTrue);
    expect(coreRegexHasMatch('.', '\u2028'), isTrue);
    expect(coreRegexHasMatch(r'\(?i:foo\)', 'i:foo)'), isTrue);
    expect(coreRegexHasMatch('needle', 'hay'), isFalse);
  });

  test('regexp_fields splits fields and optionally filters field ordinals', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerRegexFunctions(database);

    expect(
      database.select(r"SELECT regexp_fields('^c$', ?)", [
        'a\x1fb\x1fc',
      ]).single[0],
      1,
    );
    expect(
      database.select(r"SELECT regexp_fields('^c$', ?, 2)", [
        'a\x1fb\x1fc',
      ]).single[0],
      1,
    );
    expect(
      database.select(r"SELECT regexp_fields('^c$', ?, 2, 2)", [
        'a\x1fb\x1fc',
      ]).single[0],
      1,
    );
    expect(
      database.select(r"SELECT regexp_fields('^c$', ?, 1)", [
        'a\x1fb\x1fc',
      ]).single[0],
      0,
    );
    expect(
      database.select(r"SELECT regexp_fields('^b$', ?, 0, 1)", [
        'a\x1fb\x1fc',
      ]).single[0],
      1,
    );
    expect(
      database.select(r"SELECT regexp_fields('^$', ?)", ['a\x1f']).single[0],
      1,
    );
    expect(
      database.select(r"SELECT regexp_fields('^c$', ?, 8)", [
        'a\x1fb\x1fc',
      ]).single[0],
      0,
    );
  });

  test('regexp and regexp_tags match the Core SQL calling convention', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerRegexFunctions(database);

    expect(
      database.select("SELECT regexp('needle', 'hay needle')").single[0],
      1,
    );
    expect(database.select(r"SELECT regexp_tags('^b$', 'a  b')").single[0], 1);
    expect(database.select(r"SELECT regexp_tags('^$', 'a  b')").single[0], 1);
    expect(
      database
          .select(r"SELECT regexp_tags('a\tb', 'a' || char(9) || 'b')")
          .single[0],
      1,
    );
    expect(database.select(r"SELECT regexp_tags('^z$', 'a b')").single[0], 0);
  });

  test('invalid patterns, unsupported syntax, and invalid SQL types error', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerRegexFunctions(database);

    expect(
      () => database.select("SELECT regexp('[', 'text')"),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.select("SELECT regexp('(?=a)', 'a')"),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.select("SELECT regexp(1, 'a')"),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.select('SELECT regexp_tags(1, \'tags\')'),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.select("SELECT regexp_fields('a', 1)"),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.select("SELECT regexp_fields('a', 'a', -1)"),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.select('SELECT regexp_fields()'),
      throwsA(isA<SqliteException>()),
    );
  });
}
