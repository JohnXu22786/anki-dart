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
}
