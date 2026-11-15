// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  final nodes = parse('mid:9223372036854775807 prop:ivl>3 foo:re:bar');
  final id = (nodes.first as Search).value as NotetypeIdSearch;
  final unicodeId = (parse('nid:١').single as Search).value as NoteIds;
  if (id.id.toString() != '9223372036854775807' || nodes.length != 5) {
    throw StateError('Search parser JavaScript smoke test failed');
  }
  if (unicodeId.ids != '١') {
    throw StateError('Unicode ID parser JavaScript smoke test failed');
  }
  if (normalizeSearch('1 and 2 or 3') != '1 2 OR 3') {
    throw StateError(
        'Search writer JavaScript normalization smoke test failed');
  }
  if (deckSearch(r'a*b_c\d') != r'deck:a\*b\_c\\d') {
    throw StateError('Search writer JavaScript escaping smoke test failed');
  }
  const maxId = '9223372036854775807';
  final built = SearchNodeBuilder.fromNoteIds([Int64.parseInt(maxId)]);
  if (writeNode(built.toNode()) != 'nid:$maxId') {
    throw StateError(
      'Search builder JavaScript ID precision smoke test failed',
    );
  }
  if (writeNode(
          const Search(Property(operator: '=', kind: EaseProperty(0.1)))) !=
      'prop:ease=0.1') {
    throw StateError('Search writer JavaScript f32 smoke test failed');
  }
}
