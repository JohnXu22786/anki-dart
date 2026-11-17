/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_app/collection_card_browser_controller.dart';
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
}
