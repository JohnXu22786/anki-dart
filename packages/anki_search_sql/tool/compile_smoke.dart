// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  const maxId = '9223372036854775807';
  final query = compileSearchSql(GroupNode([Search(NoteIds(maxId))]));
  if (query.sql != 'select c.id from cards c where (c.nid in ($maxId))') {
    throw StateError('Search SQL JavaScript ID precision smoke test failed');
  }
  final notetypeQuery = compileSearchSql(
    GroupNode([Search(NotetypeIdSearch(Int64.parseInt(maxId)))]),
  );
  if (notetypeQuery.sql !=
      'select c.id from cards c, notes n where '
          'c.nid=n.id and (n.mid = $maxId)') {
    throw StateError('Notetype ID JavaScript precision smoke test failed');
  }
  final nameQuery = compileSearchSql(
    GroupNode([
      Search(Notetype('Basic*')),
      BooleanNode(NodeKind.and),
      Search(CardTemplate(TemplateName('Front*'))),
    ]),
  );
  if (nameQuery.arguments.join('|') != r'(?i)^Basic.*$|(?i)^Front.*$') {
    throw StateError('Search name JavaScript compilation smoke test failed');
  }
  final deckQuery = compileSearchSql(
    GroupNode([Search(Deck('Parent::Child*'))]),
  );
  if (deckQuery.arguments.single != '(?i)^Parent\x1fChild.*(\$|\x1f)') {
    throw StateError('Deck name JavaScript regex smoke test failed');
  }
  final currentDeckQuery = compileSearchSql(
    GroupNode([Search(Deck('current'))]),
    currentDeckName: 'Course\x1fToday*',
  );
  if (currentDeckQuery.arguments.single != '(?i)^Course\x1fToday\\*(\$|\x1f)') {
    throw StateError('Current deck JavaScript SQL smoke test failed');
  }
  final fallbackDeckQuery = compileSearchSql(
    GroupNode([Search(Deck('current'))]),
  );
  if (fallbackDeckQuery.arguments.single != '(?i)^Default(\$|\x1f)') {
    throw StateError('Default deck JavaScript SQL smoke test failed');
  }
  final regexQuery = compileSearchSql(
    GroupNode([Search(const RegexSearch(r'^\d+$'))]),
    regexFieldsByNotetype: RegexFieldsByNotetype([
      RegexNotetypeSearchContext(
        notetypeId: BigInt.parse('9007199254740993'),
        totalFieldsInNote: 2,
        includedFieldIndices: [1],
      ),
    ]),
  );
  if (regexQuery.sql !=
          'select c.id from cards c, notes n where c.nid=n.id and '
              '(((n.mid = 9007199254740993 and '
              'regexp_fields(?1, n.flds, 1))))' ||
      regexQuery.arguments.single != r'(?i)^\d+$') {
    throw StateError(
      'Regex JavaScript precision smoke test failed: '
      '${regexQuery.sql}; ${regexQuery.arguments}',
    );
  }
  final textQuery = compileSearchSql(
    GroupNode([Search(const TextSearch('front*back'))]),
    resultType: SearchResultType.notes,
    textSearchContext: SearchSqlTextContext(
      fieldsByNotetype: [
        TextNotetypeSearchContext(
          notetypeId: BigInt.parse('9007199254740993'),
          totalFieldsInNote: 2,
          sortFieldExcluded: true,
          fieldRangesToSearch: const [SearchableFieldRange(0, 1)],
        ),
      ],
    ),
  );
  if (!textQuery.sql.contains('n.mid = 9007199254740993') ||
      textQuery.arguments.single != '%front%back%') {
    throw StateError('Text search precision/JS smoke test failed');
  }
  final largeDeckId = Int64.parseInt('9223372036854775807');
  final largeDeckQuery = compileSearchSql(
    GroupNode([Search(DeckIdWithChildren(largeDeckId))]),
    deckIdsWithChildren: {
      BigInt.parse(largeDeckId.toString()): [
        BigInt.parse('9223372036854775807'),
        BigInt.parse('-9223372036854775808'),
      ],
    },
  );
  if (largeDeckQuery.sql !=
      'select c.id from cards c where '
          '(c.did in (9223372036854775807,-9223372036854775808))') {
    throw StateError('Deck ID JavaScript precision smoke test failed');
  }
  final presetQuery = compileSearchSql(
    GroupNode([Search(const Preset('Study'))]),
    deckIdsByPreset: {
      'Study': [
        BigInt.parse('9007199254740993'),
        BigInt.parse('-9223372036854775808'),
      ],
    },
  );
  if (presetQuery.sql !=
      'select c.id from cards c where '
          '((c.did in (9007199254740993,-9223372036854775808) or '
          'c.odid in (9007199254740993,-9223372036854775808)))') {
    throw StateError(
      'Deck preset JavaScript precision smoke test failed: ${presetQuery.sql}',
    );
  }
  final dueQuery = compileSearchSql(
    GroupNode([Search(State(StateKind.due))]),
    timing: SearchSqlTiming(
      daysElapsed: 42,
      now: BigInt.from(1700000000),
      learnAheadSecs: 30,
    ),
  );
  if (dueQuery.sql !=
      'select c.id from cards c where '
          '(((c.queue in (2,3) and c.due <= 42) or '
          '(c.queue in (1,4) and c.due <= 1700000030)))') {
    throw StateError('Search due state JavaScript smoke test failed');
  }
  final addedQuery = compileSearchSql(
    GroupNode([Search(const AddedInDays(0))]),
    timing: SearchSqlTiming(
      daysElapsed: 0,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.parse('9007199254741'),
    ),
  );
  if (addedQuery.sql !=
      'select c.id from cards c where (c.id > 9007199254741000)') {
    throw StateError('Added-day SQL JavaScript precision smoke test failed');
  }
  final ratedQuery = compileSearchSql(
    GroupNode(parse('prop:rated=-0:3')),
    timing: SearchSqlTiming(
      daysElapsed: 0,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.parse('9007199254741'),
    ),
  );
  if (ratedQuery.sql !=
      'select c.id from cards c where (c.id in '
          '(select cid from revlog where id between 9007199168341000 and '
          '9007199254740999 and ease = 3))') {
    throw StateError('Rated SQL JavaScript precision smoke test failed');
  }
  final customDataQuery = compileSearchSql(
    GroupNode([
      Search(const CustomData("x';--")),
      BooleanNode(NodeKind.and),
      Search(
        const Property(
          operator: '>=',
          kind: CustomDataNumberProperty(key: 'n', value: 0.1),
        ),
      ),
    ]),
  );
  if (customDataQuery.sql !=
          'select c.id from cards c where '
              '(extract_custom_data(c.data, ?) is not null and '
              'cast(extract_custom_data(c.data, ?) as float) >= 0.1)' ||
      customDataQuery.arguments.join('|') != "x';--|n") {
    throw StateError('Custom-data JavaScript SQL smoke test failed');
  }
  final dueProperty = compileSearchSql(
    GroupNode(parse('prop:due<=-2')),
    timing: SearchSqlTiming(
      daysElapsed: 42,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(1700000000),
    ),
  );
  if (dueProperty.sql !=
      'select c.id from cards c where (((c.queue in (2,3) and '
          '(case when c.odue != 0 then c.odue else c.due end) <= 40) or '
          '(c.queue in (1,4) and (((case when c.odue != 0 then c.odue else c.due end) '
          '- 1700000000) / 86400) <= -2)))') {
    throw StateError('Due property JavaScript SQL smoke test failed');
  }
  final easeProperty = compileSearchSql(
    GroupNode(parse('prop:ease=1.0009999999')),
  );
  if (easeProperty.sql != 'select c.id from cards c where (factor = 1001)') {
    throw StateError('Ease property float32 JavaScript smoke test failed');
  }
  final fsrsTiming = SearchSqlTiming(
    daysElapsed: 42,
    now: BigInt.from(1700000030),
    learnAheadSecs: 30,
    nextDayAt: BigInt.from(1700000000),
  );
  final fsrsProperties = compileSearchSql(
    GroupNode(parse('prop:s=1.23456789 prop:d=0.1 prop:r>=0.75')),
    timing: fsrsTiming,
  );
  if (fsrsProperties.sql !=
      'select c.id from cards c where '
          '(extract_fsrs_variable(c.data, \'s\') = 1.2345679 and '
          'extract_fsrs_variable(c.data, \'d\') = 1.9000001 and '
          'case when c.type = 0 then false else '
          '(extract_fsrs_retrievability(c.data, '
          'case when c.odue !=0 then c.odue else c.due end, c.ivl, '
          '42, 1700000000, 1700000030) >= 0.75) end)') {
    throw StateError('FSRS JavaScript SQL smoke test failed');
  }
}
