// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/process_text.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('NFKD no-combining behavior matches source fixtures', () {
    expect(processSearchText('Über Cafe\u0301', 1), 'Uber Cafe');
    expect(
      processSearchText('€ÆÐØÞßæðøþĐđĦħıĸŁłŊŋŒœŦŧƏǝɑ', 1),
      'EAEDOTHsaedothDdHhikLlNnOEoeTtEea',
    );
    expect(processSearchText('e\u0301', 0), 'e\u0301');
  });

  test('cloze stripping matches Core lazy capture and removes hints', () {
    const text =
        'The {{c1::moon::🌛}} {{c2::orbits::this hint has "::" in it}} the {{c3::🌏}}.';
    expect(processSearchText(text, 2), 'The moon orbits the 🌏.');
    expect(processSearchText('{{c١::arabic digit}}', 2), 'arabic digit');
    expect(
      processSearchText('before\n{{c1,2::line\nvalue::hint}} after', 2),
      'before\nline\nvalue after',
    );
    expect(processSearchText('{{c1::open', 2), '{{c1::open');
  });

  test(
    'flags apply cloze stripping before no-combining and truncate to low byte',
    () {
      expect(processSearchText('Über {{c1::café::hint}}', 3), 'Uber cafe');
      expect(processSearchText('{{c1::moon::hint}}', 258), 'moon');
      expect(processSearchText('Über', 257), 'Uber');
      expect(processSearchText('Über', -256), 'Über');
      expect(
        processSearchText(
          'Über {{c1::café::hint}}',
          BigInt.parse('9223372036854775807'),
        ),
        'Uber cafe',
      );
    },
  );

  test(
    'registered SQLite function returns Core text and rejects invalid types',
    () {
      final database = sqlite3.openInMemory();
      addTearDown(database.close);
      registerProcessTextFunction(database);

      expect(
        database
            .select("SELECT process_text('Über {{c1::café::hint}}', 3)")
            .single[0],
        'Uber cafe',
      );
      expect(database.select("SELECT process_text('x', 258)").single[0], 'x');
      expect(
        database.select('SELECT process_text(?, ?)', [
          'Über {{c1::café::hint}}',
          BigInt.parse('9223372036854775807'),
        ]).single[0],
        'Uber cafe',
      );
      expect(
        () => database.select('SELECT process_text(NULL, 1)'),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => database.select("SELECT process_text('x', '1')"),
        throwsA(isA<SqliteException>()),
      );
    },
  );
}
