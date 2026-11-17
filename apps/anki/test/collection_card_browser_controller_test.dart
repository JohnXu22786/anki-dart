/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_dart/anki_dart.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core sort-field HTML conversion preserves filenames and spacing', () {
    expect(
      browserHtmlToTextLine(
        ' before<br><div><b>bold</b> &amp; <img title=">" src="pic.png"> '
        '[sound:voice.mp3] [[type:Answer]] ',
        preserveMediaFilenames: true,
      ),
      'before  bold &  pic.png  voice.mp3',
    );
    expect(
      browserHtmlToTextLine(
        '<script>hidden</script><!-- hidden --><p>visible&nbsp;text</p>',
        preserveMediaFilenames: true,
      ),
      'visible text',
    );
    expect(
      browserHtmlToTextLine(
        '<p>one</p><p>two</p>',
        preserveMediaFilenames: true,
      ),
      'onetwo',
      reason: 'only Core persistent spacers are inserted for this column',
    );
    expect(
      browserHtmlToTextLine('left\u00a0right', preserveMediaFilenames: true),
      'left\u00a0right',
      reason: 'a literal NBSP stays intact when no entity decoding occurs',
    );
    expect(
      browserHtmlToTextLine(
        '<b>text</b> &bogus; &amp;',
        preserveMediaFilenames: true,
      ),
      'text &bogus; &amp;',
      reason: 'Core preserves the original text if any entity is invalid',
    );
    for (final literal in ['AT&T', 'trailing &', 'R&D;']) {
      expect(
        browserHtmlToTextLine(literal, preserveMediaFilenames: true),
        literal,
        reason: 'Core keeps the original string when decoding fails',
      );
    }
    for (final invalidEntity in [
      '&#X41;',
      '&#xD800;',
      '&#x110000;',
      '&NotEqualTilde;',
    ]) {
      expect(
        browserHtmlToTextLine(invalidEntity, preserveMediaFilenames: true),
        invalidEntity,
        reason: 'not accepted by htmlescape 0.3.1',
      );
    }
    expect(
      browserHtmlToTextLine(
        '&#65; &#x41; &euro; &nbsp;',
        preserveMediaFilenames: true,
      ),
      'A A €',
      reason: 'Core accepts decimal, lowercase-x hex, and its named table',
    );
  });

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

  test('restored structured filters join the parsed query before the deck', () {
    final root = collectionCardBrowserSearchNodeForRequest(
      const BrowserSearchRequest(
        query: 'tag:a OR tag:b',
        filters: BrowserSearchFilters(
          flags: [1, 3],
          tags: ['biology', 'cell'],
          cardStateCodes: [0, 4],
        ),
      ),
      Int64(7),
    ) as GroupNode;

    final selectedDeck =
        (root.nodes.last as Search).value as DeckIdWithChildren;
    expect(selectedDeck.id, Int64(7));
    expect(root.nodes[root.nodes.length - 2], const BooleanNode(NodeKind.and));
    final requestNode = root.nodes.first as GroupNode;
    expect(
      requestNode.nodes.whereType<BooleanNode>().map((node) => node.kind),
      [NodeKind.and, NodeKind.and, NodeKind.and],
    );
    final filterGroups = requestNode.nodes.whereType<GroupNode>().toList();
    expect(filterGroups, hasLength(4));
    expect(
      filterGroups.first.nodes.whereType<BooleanNode>().single.kind,
      NodeKind.or,
    );
    expect(
      filterGroups[1].nodes
          .whereType<Search>()
          .map((search) => (search.value as Flag).value)
          .toList(),
      [1, 3],
    );
    expect(
      filterGroups[2].nodes
          .whereType<Search>()
          .map((search) => (search.value as Tag).tag)
          .toList(),
      ['biology', 'cell'],
    );
    expect(
      filterGroups[3].nodes
          .whereType<Search>()
          .map((search) => (search.value as State).kind)
          .toList(),
      [StateKind.newCard, StateKind.suspended],
    );
  });
}
