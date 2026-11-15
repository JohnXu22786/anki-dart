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
}
