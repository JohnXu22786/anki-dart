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
}
