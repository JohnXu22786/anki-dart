// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';

void main() {
  final nodes = parse('mid:9223372036854775807 prop:ivl>3 foo:re:bar');
  final id = (nodes.first as Search).value as NotetypeIdSearch;
  if (id.id.toString() != '9223372036854775807' || nodes.length != 5) {
    throw StateError('Search parser JavaScript smoke test failed');
  }
}
