// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:test/test.dart';

void main() {
  test('browser sort keys and default directions match Core columns', () {
    const keys = {
      '': SearchSqlSortColumn.custom,
      'answer': SearchSqlSortColumn.answer,
      'cardMod': SearchSqlSortColumn.cardMod,
      'template': SearchSqlSortColumn.template,
      'deck': SearchSqlSortColumn.deck,
      'cardDue': SearchSqlSortColumn.due,
      'cardEase': SearchSqlSortColumn.ease,
      'cardLapses': SearchSqlSortColumn.lapses,
      'cardIvl': SearchSqlSortColumn.interval,
      'noteCrt': SearchSqlSortColumn.noteCreation,
      'noteMod': SearchSqlSortColumn.noteMod,
      'note': SearchSqlSortColumn.notetype,
      'originalPosition': SearchSqlSortColumn.originalPosition,
      'question': SearchSqlSortColumn.question,
      'cardReps': SearchSqlSortColumn.reps,
      'noteFld': SearchSqlSortColumn.sortField,
      'noteTags': SearchSqlSortColumn.tags,
      'stability': SearchSqlSortColumn.stability,
      'difficulty': SearchSqlSortColumn.difficulty,
      'retrievability': SearchSqlSortColumn.retrievability,
    };
    for (final entry in keys.entries) {
      expect(SearchSqlSortColumn.fromKey(entry.key), entry.value);
      expect(entry.value.key, entry.key);
    }
    expect(SearchSqlSortColumn.fromKey('unknown'), SearchSqlSortColumn.custom);
    expect(
      SearchSqlSortColumn.due.defaultDirection(SearchResultType.cards),
      SearchSqlSortDirection.descending,
    );
    expect(
      SearchSqlSortColumn.sortField.defaultDirection(SearchResultType.notes),
      SearchSqlSortDirection.ascending,
    );
    expect(
      SearchSqlSortColumn.stability.defaultDirection(SearchResultType.notes),
      SearchSqlSortDirection.none,
    );
    expect(
      SearchSqlSortColumn.stability.defaultDirection(SearchResultType.cards),
      SearchSqlSortDirection.descending,
    );
  });

  test('card sort clauses, required tables, and reverse match Core', () {
    final timing = SearchSqlTiming(
      daysElapsed: 42,
      now: BigInt.from(1700000000),
      learnAheadSecs: 30,
      nextDayAt: BigInt.from(1700003600),
    );
    final due = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
      timing: timing,
      sortOrder: const SearchSqlSortOrder.builtin(SearchSqlSortColumn.due),
    );
    expect(
      due.search.sql,
      'select c.id from cards c where (true) order by '
      '(case when c.due > 1000000000 or c.type = 0 then due else '
      '(due - 42) * 86400 + 1700000000 end) asc',
    );
    expect(due.preparationSql, isEmpty);

    final reverseDue = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
      timing: timing,
      sortOrder: const SearchSqlSortOrder.builtin(
        SearchSqlSortColumn.due,
        reverse: true,
      ),
    );
    expect(
      reverseDue.search.sql,
      'select c.id from cards c where (true) order by '
      '(case when c.due > 1000000000 or c.type = 0 then due else '
      '(due - 42) * 86400 + 1700000000 end) desc',
    );

    final field = compileSearchSqlWithSort(
      GroupNode([Search(CardIds('1'))]),
      sortOrder: const SearchSqlSortOrder.builtin(
        SearchSqlSortColumn.sortField,
      ),
    );
    expect(field.search.requiredTable, RequiredTable.cardsAndNotes);
    expect(
      field.search.sql,
      endsWith('order by n.sfld collate nocase asc, c.ord asc'),
    );

    final retrieval = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
      timing: timing,
      sortOrder: const SearchSqlSortOrder.builtin(
        SearchSqlSortColumn.retrievability,
      ),
    );
    expect(
      retrieval.search.sql,
      contains(
        'extract_fsrs_retrievability(c.data, case when c.odue !=0 then '
        'c.odue else c.due end, c.ivl, 42, 1700003600, 1700000000) asc',
      ),
    );
  });

  test('every supported card sort column emits the Core order clause', () {
    final timing = SearchSqlTiming(
      daysElapsed: 17,
      now: BigInt.from(1700000000),
      learnAheadSecs: 30,
      nextDayAt: BigInt.from(1700003600),
    );
    const expectedOrders = {
      SearchSqlSortColumn.cardMod: 'c.mod asc',
      SearchSqlSortColumn.template:
          'coalesce((select pos from sort_order where ntid = n.mid and ord = c.ord),(select pos from sort_order where ntid = n.mid and ord = 0)) asc, ord asc',
      SearchSqlSortColumn.deck:
          '(select pos from sort_order where did = c.did) asc',
      SearchSqlSortColumn.due:
          '(case when c.due > 1000000000 or c.type = 0 then due else (due - 17) * 86400 + 1700000000 end) asc',
      SearchSqlSortColumn.ease: 'c.type = 0 asc, c.factor asc',
      SearchSqlSortColumn.interval: 'c.ivl asc',
      SearchSqlSortColumn.lapses: 'c.lapses asc',
      SearchSqlSortColumn.noteCreation: 'n.id asc, c.ord asc',
      SearchSqlSortColumn.noteMod: 'n.mod asc, c.ord asc',
      SearchSqlSortColumn.notetype:
          '(select pos from sort_order where ntid = n.mid) asc',
      SearchSqlSortColumn.originalPosition:
          '(select pos from sort_order where nid = c.nid) asc',
      SearchSqlSortColumn.reps: 'c.reps asc',
      SearchSqlSortColumn.sortField: 'n.sfld collate nocase asc, c.ord asc',
      SearchSqlSortColumn.tags: 'n.tags asc',
      SearchSqlSortColumn.stability: "extract_fsrs_variable(c.data, 's') asc",
      SearchSqlSortColumn.difficulty: "extract_fsrs_variable(c.data, 'd') asc",
      SearchSqlSortColumn.retrievability:
          'extract_fsrs_retrievability(c.data, case when c.odue !=0 then c.odue else c.due end, c.ivl, 17, 1700003600, 1700000000) asc',
    };
    for (final entry in expectedOrders.entries) {
      final compiled = compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        timing: timing,
        sortOrder: SearchSqlSortOrder.builtin(entry.key),
      );
      expect(compiled.search.sql, endsWith('order by ${entry.value}'));
    }
  });

  test('every supported note sort column emits the Core order clause', () {
    final timing = SearchSqlTiming(
      daysElapsed: 17,
      now: BigInt.from(1700000000),
      learnAheadSecs: 30,
      nextDayAt: BigInt.from(1700003600),
    );
    const idOrder = '(select pos from sort_order where nid = n.id) asc';
    const expectedOrders = {
      SearchSqlSortColumn.cardMod: idOrder,
      SearchSqlSortColumn.template: idOrder,
      SearchSqlSortColumn.deck: idOrder,
      SearchSqlSortColumn.due: idOrder,
      SearchSqlSortColumn.ease: idOrder,
      SearchSqlSortColumn.interval: idOrder,
      SearchSqlSortColumn.lapses: idOrder,
      SearchSqlSortColumn.noteCreation: 'n.id asc',
      SearchSqlSortColumn.noteMod: 'n.mod asc',
      SearchSqlSortColumn.notetype:
          '(select pos from sort_order where ntid = n.mid) asc',
      SearchSqlSortColumn.originalPosition: idOrder,
      SearchSqlSortColumn.reps: idOrder,
      SearchSqlSortColumn.sortField: 'n.sfld collate nocase asc',
      SearchSqlSortColumn.tags: 'n.tags asc',
    };
    for (final entry in expectedOrders.entries) {
      final compiled = compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        resultType: SearchResultType.notes,
        timing: timing,
        sortOrder: SearchSqlSortOrder.builtin(entry.key),
      );
      expect(compiled.search.sql, endsWith('order by ${entry.value}'));
    }
  });

  test('sort preparation SQL and note-specific clauses match Core', () {
    const columnsWithPreparation = {
      SearchSqlSortColumn.template: 'FROM templates',
      SearchSqlSortColumn.deck: 'FROM decks',
      SearchSqlSortColumn.notetype: 'FROM notetypes',
      SearchSqlSortColumn.originalPosition: 'extract_original_position(data)',
    };
    for (final entry in columnsWithPreparation.entries) {
      final compiled = compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        sortOrder: SearchSqlSortOrder.builtin(entry.key),
      );
      expect(compiled.preparationSql, hasLength(1));
      expect(compiled.preparationSql.single, contains(entry.value));
    }

    const notePreparations = {
      SearchSqlSortColumn.cardMod: 'ORDER BY MAX(mod)',
      SearchSqlSortColumn.template: 'ORDER BY COUNT(*)',
      SearchSqlSortColumn.deck: 'row_number() OVER(',
      SearchSqlSortColumn.ease: 'ORDER BY AVG(factor)',
      SearchSqlSortColumn.interval: 'ORDER BY AVG(ivl)',
      SearchSqlSortColumn.lapses: 'ORDER BY SUM(lapses)',
      SearchSqlSortColumn.notetype: 'FROM notetypes',
      SearchSqlSortColumn.originalPosition: 'extract_original_position(data)',
      SearchSqlSortColumn.reps: 'ORDER BY SUM(reps)',
    };
    for (final entry in notePreparations.entries) {
      final compiled = compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        resultType: SearchResultType.notes,
        sortOrder: SearchSqlSortOrder.builtin(entry.key),
      );
      expect(compiled.preparationSql, hasLength(1));
      expect(compiled.preparationSql.single, contains(entry.value));
    }

    final noteDue = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
      resultType: SearchResultType.notes,
      timing: SearchSqlTiming(
        daysElapsed: 7,
        now: BigInt.from(1700000000),
        learnAheadSecs: 30,
      ),
      sortOrder: const SearchSqlSortOrder.builtin(SearchSqlSortColumn.due),
    );
    expect(noteDue.search.requiredTable, RequiredTable.notes);
    expect(noteDue.preparationSql.single, contains('WHERE (\n    odid = 0'));
    expect(
      noteDue.preparationSql.single,
      contains('ORDER BY MIN(CASE WHEN due > 1000000000 OR type = 0 THEN due'),
    );
    expect(
      noteDue.search.sql,
      endsWith('order by (select pos from sort_order where nid = n.id) asc'),
    );

    final cardMod = compileSearchSqlWithSort(
      GroupNode([Search(WholeCollection())]),
      resultType: SearchResultType.notes,
      sortOrder: const SearchSqlSortOrder.builtin(SearchSqlSortColumn.cardMod),
    );
    expect(cardMod.preparationSql.single, contains('ORDER BY MAX(mod)'));
  });

  test('custom clauses pass through and unsupported built-ins fail', () {
    final custom = compileSearchSqlWithSort(
      GroupNode([Search(CardIds('1'))]),
      sortOrder: const SearchSqlSortOrder.custom('n.tags desc, c.id'),
    );
    expect(custom.search.requiredTable, RequiredTable.cardsAndNotes);
    expect(custom.search.sql, endsWith('order by n.tags desc, c.id'));
    expect(custom.preparationSql, isEmpty);

    expect(
      () => compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        sortOrder: const SearchSqlSortOrder.builtin(
          SearchSqlSortColumn.question,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        resultType: SearchResultType.notes,
        sortOrder: const SearchSqlSortOrder.builtin(
          SearchSqlSortColumn.stability,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => compileSearchSqlWithSort(
        GroupNode([Search(WholeCollection())]),
        sortOrder: const SearchSqlSortOrder.builtin(SearchSqlSortColumn.due),
      ),
      throwsArgumentError,
    );
  });
}
