/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected deck constraint applies to every OR query branch', () {
    final query = collectionCardBrowserSearchNode('tag:a OR tag:b', Int64(7));

    expect(query, isA<GroupNode>());
    final nodes = (query as GroupNode).nodes;
    expect(nodes, hasLength(3));
    expect(nodes[0], isA<GroupNode>());
    final queryNodes = (nodes[0] as GroupNode).nodes;
    expect(queryNodes, hasLength(3));
    expect(queryNodes[1], const BooleanNode(NodeKind.or));
    expect(nodes[1], const BooleanNode(NodeKind.and));
    expect(nodes[2], isA<Search>());
  });
}
