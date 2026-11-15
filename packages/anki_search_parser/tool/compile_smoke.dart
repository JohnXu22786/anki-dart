// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';

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
}
