// SPDX-License-Identifier: AGPL-3.0-or-later
import 'sql_compiler.dart';
import 'package:anki_search_parser/anki_search_parser.dart';

enum SearchSqlSortKind { none, builtin, custom }

enum SearchSqlSortColumn {
  custom(''),
  answer('answer'),
  cardMod('cardMod'),
  template('template'),
  deck('deck'),
  due('cardDue'),
  ease('cardEase'),
  lapses('cardLapses'),
  interval('cardIvl'),
  noteCreation('noteCrt'),
  noteMod('noteMod'),
  notetype('note'),
  originalPosition('originalPosition'),
  question('question'),
  reps('cardReps'),
  sortField('noteFld'),
  tags('noteTags'),
  stability('stability'),
  difficulty('difficulty'),
  retrievability('retrievability');

  const SearchSqlSortColumn(this.key);
  final String key;

  static SearchSqlSortColumn fromKey(String key) => values.firstWhere(
    (column) => column.key == key,
    orElse: () => SearchSqlSortColumn.custom,
  );

  SearchSqlSortDirection defaultDirection(SearchResultType resultType) =>
      switch (this) {
        SearchSqlSortColumn.question ||
        SearchSqlSortColumn.answer ||
        SearchSqlSortColumn.custom => SearchSqlSortDirection.none,
        SearchSqlSortColumn.sortField ||
        SearchSqlSortColumn.tags ||
        SearchSqlSortColumn.notetype ||
        SearchSqlSortColumn.deck => SearchSqlSortDirection.ascending,
        SearchSqlSortColumn.stability ||
        SearchSqlSortColumn.difficulty ||
        SearchSqlSortColumn.retrievability =>
          resultType == SearchResultType.notes
              ? SearchSqlSortDirection.none
              : SearchSqlSortDirection.descending,
        _ => SearchSqlSortDirection.descending,
      };
}

enum SearchSqlSortDirection { none, ascending, descending }

/// A Core `SortMode` request.
final class SearchSqlSortOrder {
  const SearchSqlSortOrder.none()
    : kind = SearchSqlSortKind.none,
      column = null,
      reverse = false,
      customClause = null;

  const SearchSqlSortOrder.builtin(
    SearchSqlSortColumn column, {
    this.reverse = false,
  }) : kind = SearchSqlSortKind.builtin,
       column = column,
       customClause = null;

  const SearchSqlSortOrder.custom(this.customClause)
    : kind = SearchSqlSortKind.custom,
      column = null,
      reverse = false;

  final SearchSqlSortKind kind;
  final SearchSqlSortColumn? column;
  final bool reverse;
  final String? customClause;
}

final class CompiledSearchSqlWithSort {
  const CompiledSearchSqlWithSort({
    required this.search,
    required this.preparationSql,
  });

  final CompiledSearchSql search;
  final List<String> preparationSql;
}

/// Compiles Core search and `SortMode` SQL without executing database work.
///
/// Run [CompiledSearchSqlWithSort.preparationSql] on the same connection before
/// [CompiledSearchSqlWithSort.search.sql] when Core requires a temporary
/// `sort_order` table. The caller owns transaction and connection lifetime.
CompiledSearchSqlWithSort compileSearchSqlWithSort(
  Node node, {
  SearchResultType resultType = SearchResultType.cards,
  RequiredTable requiredTables = RequiredTable.cardsOrNotes,
  SearchSqlTiming? timing,
  String? currentDeckName,
  Map<BigInt, List<BigInt>> deckIdsWithChildren = const {},
  Map<String, List<BigInt>> deckIdsByPreset = const {},
  RegexFieldsByNotetype? regexFieldsByNotetype,
  bool normalizeNoteText = false,
  SearchSqlTextContext? textSearchContext,
  SearchSqlFieldContext? fieldSearchContext,
  SearchSqlDuplicatesContext? duplicatesContext,
  SearchSqlSortOrder sortOrder = const SearchSqlSortOrder.none(),
}) {
  final sortTable = _sortRequiredTable(sortOrder);
  final compiled = compileSearchSql(
    node,
    resultType: resultType,
    requiredTables: requiredTables.combine(sortTable),
    timing: timing,
    currentDeckName: currentDeckName,
    deckIdsWithChildren: deckIdsWithChildren,
    deckIdsByPreset: deckIdsByPreset,
    regexFieldsByNotetype: regexFieldsByNotetype,
    normalizeNoteText: normalizeNoteText,
    textSearchContext: textSearchContext,
    fieldSearchContext: fieldSearchContext,
    duplicatesContext: duplicatesContext,
  );

  final itemType = resultType;
  final prep = <String>[];
  final orderClause = switch (sortOrder.kind) {
    SearchSqlSortKind.none => null,
    SearchSqlSortKind.custom => ' order by ${sortOrder.customClause}',
    SearchSqlSortKind.builtin => _builtinOrder(
      sortOrder.column!,
      itemType,
      timing,
      sortOrder.reverse,
      prep,
    ),
  };
  return CompiledSearchSqlWithSort(
    search: CompiledSearchSql(
      sql: compiled.sql + (orderClause ?? ''),
      arguments: compiled.arguments,
      requiredTable: compiled.requiredTable,
    ),
    preparationSql: prep,
  );
}

RequiredTable _sortRequiredTable(SearchSqlSortOrder sort) =>
    switch (sort.kind) {
      SearchSqlSortKind.none => RequiredTable.cardsOrNotes,
      SearchSqlSortKind.builtin => switch (sort.column!) {
        SearchSqlSortColumn.template ||
        SearchSqlSortColumn.noteCreation ||
        SearchSqlSortColumn.noteMod ||
        SearchSqlSortColumn.notetype ||
        SearchSqlSortColumn.sortField ||
        SearchSqlSortColumn.tags => RequiredTable.notes,
        _ => RequiredTable.cardsOrNotes,
      },
      SearchSqlSortKind.custom => switch (sort.customClause!) {
        final clause when clause.contains('n.') && clause.contains('c.') =>
          RequiredTable.cardsAndNotes,
        final clause when clause.contains('n.') => RequiredTable.notes,
        _ => RequiredTable.cards,
      },
    };

String _builtinOrder(
  SearchSqlSortColumn column,
  SearchResultType itemType,
  SearchSqlTiming? timing,
  bool reverse,
  List<String> preparationSql,
) {
  final order = itemType == SearchResultType.cards
      ? _cardOrder(column, timing, preparationSql)
      : _noteOrder(column, timing, preparationSql);
  if (order.isEmpty) {
    throw ArgumentError('Cannot sort $itemType by ${column.key}.');
  }
  final effectiveOrder = reverse
      ? order.toLowerCase().replaceAll(' desc', '').replaceAll(' asc', ' desc')
      : order;
  return ' order by $effectiveOrder';
}

String _cardOrder(
  SearchSqlSortColumn column,
  SearchSqlTiming? timing,
  List<String> preparationSql,
) {
  switch (column) {
    case SearchSqlSortColumn.cardMod:
      return 'c.mod asc';
    case SearchSqlSortColumn.template:
      preparationSql.add(_templateOrder);
      return 'coalesce((select pos from sort_order where ntid = n.mid and ord = c.ord),(select pos from sort_order where ntid = n.mid and ord = 0)) asc, ord asc';
    case SearchSqlSortColumn.deck:
      preparationSql.add(_deckOrder);
      return '(select pos from sort_order where did = c.did) asc';
    case SearchSqlSortColumn.due:
      final t = _requireTiming(timing, nextDay: false);
      return '(case when c.due > 1000000000 or c.type = 0 then due else (due - ${t.daysElapsed}) * 86400 + ${_i64(t.now, 'now')} end) asc';
    case SearchSqlSortColumn.ease:
      return 'c.type = 0 asc, c.factor asc';
    case SearchSqlSortColumn.interval:
      return 'c.ivl asc';
    case SearchSqlSortColumn.lapses:
      return 'c.lapses asc';
    case SearchSqlSortColumn.noteCreation:
      return 'n.id asc, c.ord asc';
    case SearchSqlSortColumn.noteMod:
      return 'n.mod asc, c.ord asc';
    case SearchSqlSortColumn.notetype:
      preparationSql.add(_notetypeOrder);
      return '(select pos from sort_order where ntid = n.mid) asc';
    case SearchSqlSortColumn.originalPosition:
      preparationSql.add(_noteOriginalPositionOrder);
      return '(select pos from sort_order where nid = c.nid) asc';
    case SearchSqlSortColumn.reps:
      return 'c.reps asc';
    case SearchSqlSortColumn.sortField:
      return 'n.sfld collate nocase asc, c.ord asc';
    case SearchSqlSortColumn.tags:
      return 'n.tags asc';
    case SearchSqlSortColumn.stability:
      return "extract_fsrs_variable(c.data, 's') asc";
    case SearchSqlSortColumn.difficulty:
      return "extract_fsrs_variable(c.data, 'd') asc";
    case SearchSqlSortColumn.retrievability:
      final t = _requireTiming(timing, nextDay: true);
      return 'extract_fsrs_retrievability(c.data, case when c.odue !=0 then c.odue else c.due end, c.ivl, ${t.daysElapsed}, ${_i64(t.nextDayAt!, 'nextDayAt')}, ${_i64(t.now, 'now')}) asc';
    case SearchSqlSortColumn.answer ||
        SearchSqlSortColumn.custom ||
        SearchSqlSortColumn.question:
      return '';
  }
}

String _noteOrder(
  SearchSqlSortColumn column,
  SearchSqlTiming? timing,
  List<String> preparationSql,
) {
  switch (column) {
    case SearchSqlSortColumn.cardMod:
      preparationSql.add(_cardModOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.template:
      preparationSql.add(_noteCardsOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.deck:
      preparationSql.add(_noteDecksOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.due:
      preparationSql.add(_noteDueOrder(timing));
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.ease:
      preparationSql.add(_noteEaseOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.interval:
      preparationSql.add(_noteIntervalOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.lapses:
      preparationSql.add(_noteLapsesOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.noteCreation:
      return 'n.id asc';
    case SearchSqlSortColumn.noteMod:
      return 'n.mod asc';
    case SearchSqlSortColumn.notetype:
      preparationSql.add(_notetypeOrder);
      return '(select pos from sort_order where ntid = n.mid) asc';
    case SearchSqlSortColumn.originalPosition:
      preparationSql.add(_noteOriginalPositionOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.reps:
      preparationSql.add(_noteRepsOrder);
      return '(select pos from sort_order where nid = n.id) asc';
    case SearchSqlSortColumn.sortField:
      return 'n.sfld collate nocase asc';
    case SearchSqlSortColumn.tags:
      return 'n.tags asc';
    case SearchSqlSortColumn.answer ||
        SearchSqlSortColumn.custom ||
        SearchSqlSortColumn.question ||
        SearchSqlSortColumn.stability ||
        SearchSqlSortColumn.difficulty ||
        SearchSqlSortColumn.retrievability:
      return '';
  }
}

SearchSqlTiming _requireTiming(
  SearchSqlTiming? timing, {
  required bool nextDay,
}) {
  if (timing == null || (nextDay && timing.nextDayAt == null)) {
    throw ArgumentError('This sort column requires explicit SearchSqlTiming.');
  }
  return timing;
}

String _i64(BigInt value, String name) {
  final min = BigInt.parse('-9223372036854775808');
  final max = BigInt.parse('9223372036854775807');
  if (value < min || value > max) throw RangeError('$name is outside i64');
  return value.toString();
}

String _noteDueOrder(SearchSqlTiming? timing) {
  final t = _requireTiming(timing, nextDay: false);
  return '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
WHERE (
    odid = 0
    AND type != 0
    AND queue > 0
  )
GROUP BY nid ORDER BY MIN(CASE WHEN due > 1000000000 OR type = 0 THEN due ELSE (due - ${t.daysElapsed}) * 86400 + ${_i64(t.now, 'now')} END);''';
}

const _cardModOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
GROUP BY nid
ORDER BY MAX(mod);''';

const _deckOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  did integer NOT NULL UNIQUE
);
INSERT INTO sort_order (did)
SELECT id
FROM decks
ORDER BY name;''';

const _noteCardsOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
GROUP BY nid
ORDER BY COUNT(*);''';

const _noteDecksOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
  JOIN (
    SELECT id,
      row_number() OVER(
        ORDER BY name
      ) AS pos
    FROM decks
  ) decks ON cards.did = decks.id
GROUP BY nid
ORDER BY COUNT(DISTINCT did),
  decks.pos;''';

const _noteEaseOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
WHERE type != 0
GROUP BY nid
ORDER BY AVG(factor);''';

const _noteIntervalOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
WHERE type IN (2, 3)
GROUP BY nid
ORDER BY AVG(ivl);''';

const _noteLapsesOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
GROUP BY nid
ORDER BY SUM(lapses);''';

const _noteOriginalPositionOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
GROUP BY nid
ORDER BY COALESCE(
    extract_original_position(data),
    CASE
      WHEN type == 0 THEN due
      ELSE 0
    END
  );''';

const _noteRepsOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  nid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (nid)
SELECT nid
FROM cards
GROUP BY nid
ORDER BY SUM(reps);''';

const _notetypeOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  ntid integer NOT NULL UNIQUE
);
INSERT INTO sort_order (ntid)
SELECT id
FROM notetypes
ORDER BY name;''';

const _templateOrder = '''DROP TABLE IF EXISTS sort_order;
CREATE TEMPORARY TABLE sort_order (
  pos integer PRIMARY KEY,
  ntid integer NOT NULL,
  ord integer NOT NULL,
  UNIQUE(ntid, ord)
);
INSERT INTO sort_order (ntid, ord)
SELECT ntid,
  ord
FROM templates
ORDER BY name''';
