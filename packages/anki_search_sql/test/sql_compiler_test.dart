// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:test/test.dart';

void main() {
  test('source query SELECT shape and required-table optimization', () {
    final parsedCardIds = compileSearchSql(GroupNode(parse('cid:3,4')));
    expect(parsedCardIds.sql, 'select c.id from cards c where (c.id in (3,4))');

    expect(
      compileSearchSql(GroupNode(parse('nid:١'))).sql,
      'select c.id from cards c where (c.nid in (١))',
    );

    final cardIds = Search(CardIds('3,4'));
    final cards = compileSearchSql(GroupNode([cardIds]));
    expect(cards.sql, 'select c.id from cards c where (c.id in (3,4))');
    expect(cards.arguments, isEmpty);
    expect(cards.requiredTable, RequiredTable.cards);

    final notes = compileSearchSql(
      GroupNode([Search(NoteIds('3,4'))]),
      resultType: SearchResultType.notes,
    );
    expect(notes.sql, 'select n.id from notes n where (n.id in (3,4))');
    expect(notes.arguments, isEmpty);
    expect(notes.requiredTable, RequiredTable.notes);

    expect(
      compileSearchSql(
        GroupNode([
          Search(CardIds('3')),
          BooleanNode(NodeKind.and),
          Search(NotetypeIdSearch(Int64.parseInt('7'))),
        ]),
        resultType: SearchResultType.notes,
      ).sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(c.id in (3) and n.mid = 7)',
    );
  });

  test(
    'source predicates, boolean grouping, ID spellings, and unsupported nodes',
    () {
      final maxId = '9223372036854775807';
      expect(
        compileSearchSql(
          GroupNode([
            Search(CardIds('0000000000000000000000000000000000000000003')),
            BooleanNode(NodeKind.or),
            NegatedNode(Search(Flag(2))),
          ]),
        ).sql,
        'select c.id from cards c where (c.id in '
        '(0000000000000000000000000000000000000000003) or not (c.flags & 7) == 2)',
      );
      expect(
        compileSearchSql(GroupNode([Search(NoteIds(maxId))])).sql,
        'select c.id from cards c where (c.nid in ($maxId))',
      );
      expect(
        compileSearchSql(
          GroupNode([Search(DeckIdsWithoutChildren('5,6'))]),
        ).sql,
        'select c.id from cards c where '
        '((c.did in (5,6) or (c.odid != 0 and c.odid in (5,6))))',
      );
      expect(
        compileSearchSql(
          GroupNode([
            Search(DeckIdsWithoutChildren('5,6')),
            BooleanNode(NodeKind.and),
            Search(CardIds('9')),
          ]),
        ).sql,
        'select c.id from cards c where '
        '((c.did in (5,6) or (c.odid != 0 and c.odid in (5,6))) and c.id in (9))',
      );
      expect(
        compileSearchSql(
          GroupNode([NegatedNode(Search(DeckIdsWithoutChildren('5,6')))]),
        ).sql,
        'select c.id from cards c where '
        '(not (c.did in (5,6) or (c.odid != 0 and c.odid in (5,6))))',
      );
      expect(
        compileSearchSql(
          GroupNode([Search(WholeCollection())]),
          resultType: SearchResultType.notes,
        ).sql,
        'select n.id from notes n where (true)',
      );
      expect(
        () => compileSearchSql(GroupNode([Search(TextSearch('unsupported'))])),
        throwsA(isA<UnsupportedSearchSqlNodeException>()),
      );
      for (final value in [-1, 8]) {
        expect(
          () => compileSearchSql(GroupNode([Search(Flag(value))])),
          throwsRangeError,
          reason: 'flag:$value',
        );
      }
      for (final node in <SearchNode>[
        const CardIds('1) or true --'),
        const NoteIds('1) or true --'),
        const DeckIdsWithoutChildren('1) or true --'),
      ]) {
        expect(
          () => compileSearchSql(GroupNode([Search(node)])),
          throwsArgumentError,
          reason: node.runtimeType.toString(),
        );
      }
    },
  );

  test('literal notetype and template names follow Core text semantics', () {
    final notetype = compileSearchSql(
      GroupNode([Search(Notetype('Cafe\u0301\\*'))]),
    );
    expect(
      notetype.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name = ?))',
    );
    expect(notetype.arguments, ['Café*']);
    expect(notetype.requiredTable, RequiredTable.cardsAndNotes);

    final newline = compileSearchSql(
      GroupNode([Search(Notetype('Line\\\nBreak'))]),
    );
    expect(newline.arguments, ['Line\\\nBreak']);

    final template = compileSearchSql(
      GroupNode([Search(CardTemplate(TemplateName('Fron\\*t')))]),
      resultType: SearchResultType.notes,
    );
    expect(
      template.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '((n.mid,c.ord) in '
      '(select ntid,ord from templates where name = ?))',
    );
    expect(template.arguments, ['Fron*t']);
    expect(template.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('glob names emit anchored regexes with Core wildcard escaping', () {
    final notetype = compileSearchSql(
      GroupNode([Search(Notetype('Cafe\u0301*\\_*'))]),
    );
    expect(
      notetype.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name regexp ?))',
    );
    expect(notetype.arguments, [r'(?i)^Café.*_.*$']);

    final template = compileSearchSql(
      GroupNode([Search(CardTemplate(TemplateName(r'A.\**_')))]),
    );
    expect(
      template.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '((n.mid,c.ord) in '
      '(select ntid,ord from templates where name regexp ?))',
    );
    expect(template.arguments, [r'(?i)^A\.\*.*.$']);
  });

  test('ordinal templates use cards and notes without SQL arguments', () {
    final compiled = compileSearchSql(
      GroupNode([Search(CardTemplate(TemplateOrdinal(2)))]),
    );
    expect(
      compiled.sql,
      'select c.id from cards c, notes n where c.nid=n.id and (c.ord = 2)',
    );
    expect(compiled.arguments, isEmpty);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('nested predicates combine tables and preserve argument order', () {
    final compiled = compileSearchSql(
      GroupNode([
        Search(Notetype('Basic*')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(CardTemplate(TemplateName('Front*'))),
          BooleanNode(NodeKind.or),
          Search(CardTemplate(TemplateName('Back*'))),
        ]),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(
      compiled.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name regexp ?) and '
      '((n.mid,c.ord) in '
      '(select ntid,ord from templates where name regexp ?) or '
      '(n.mid,c.ord) in '
      '(select ntid,ord from templates where name regexp ?)))',
    );
    expect(compiled.arguments, [
      r'(?i)^Basic.*$',
      r'(?i)^Front.*$',
      r'(?i)^Back.*$',
    ]);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('tag modes use Core SQL clauses and matching transformations', () {
    final normal = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'foo_bar*', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(
      normal.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(n.tags regexp ?)',
    );
    expect(normal.arguments, [r'(?i).* foo\Sbar\S*(::| ).*']);
    expect(normal.requiredTable, RequiredTable.cardsAndNotes);

    final regex = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: r'^foo.*$', mode: FieldSearchMode.regex)),
      ]),
    );
    expect(
      regex.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(regexp_tags(?1, n.tags))',
    );
    expect(regex.arguments, [r'(?i)^foo.*$']);

    final noCombining = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'Café', mode: FieldSearchMode.noCombining)),
      ]),
    );
    expect(
      noCombining.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(coalesce(process_text(n.tags, 1), n.tags) regexp ?)',
    );
    expect(noCombining.arguments, [r'(?i).* Cafe(::| ).*']);
  });

  test('tag special values and escaped wildcards match Core semantics', () {
    for (final tag in ['none', '*']) {
      final compiled = compileSearchSql(
        GroupNode([Search(Tag(tag: tag, mode: FieldSearchMode.normal))]),
      );
      expect(compiled.sql, contains(tag == 'none' ? 'n.tags = \'\'' : 'true'));
      expect(compiled.arguments, isEmpty);
    }

    final space = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'two words', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(space.sql, endsWith('(false)'));
    expect(space.arguments, isEmpty);

    final escaped = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: r'Foo\*_*', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(escaped.arguments, [r'(?i).* Foo\*\S\S*(::| ).*']);

    final escapedOnly = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: r'Foo\*', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(escapedOnly.arguments, [r'(?i).* Foo\*(::| ).*']);
    expect(escapedOnly.sql, endsWith('(n.tags regexp ?)'));
  });

  test('tag arguments retain ordering through nested boolean predicates', () {
    final compiled = compileSearchSql(
      GroupNode([
        Search(Notetype('Basic*')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(const Tag(tag: 'Café*', mode: FieldSearchMode.noCombining)),
          BooleanNode(NodeKind.or),
          Search(const Tag(tag: r'^math::.*$', mode: FieldSearchMode.regex)),
        ]),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(
      compiled.sql,
      'select n.id from notes n where '
      '(n.mid in (select id from notetypes where name regexp ?) and '
      '(coalesce(process_text(n.tags, 1), n.tags) regexp ? or '
      'regexp_tags(?3, n.tags)))',
    );
    expect(compiled.arguments, [
      r'(?i)^Basic.*$',
      r'(?i).* Cafe\S*(::| ).*',
      r'(?i)^math::.*$',
    ]);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });
}
