// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  test('grouped and flat joins preserve source nesting and empty edges', () {
    expect(
      SearchBuilder.fromValue(StateKind.due)
          .or(StateKind.newCard)
          .and(SearchBuilder.any([const Flag(1), const Flag(2), const Flag(3)]))
          .write(),
      '(is:due OR is:new) (flag:1 OR flag:2 OR flag:3)',
    );
    expect(
      SearchBuilder.fromValue(StateKind.due)
          .or(StateKind.newCard)
          .andFlat(SearchBuilder.any([const Flag(1), const Flag(2)]))
          .write(),
      'is:due OR is:new flag:1 OR flag:2',
    );
    expect(
      SearchBuilder.any([StateKind.due, StateKind.newCard])
          .or(StateKind.learning)
          .or(StateKind.review)
          .write(),
      '((is:due OR is:new) OR is:learn) OR is:review',
    );
    expect(SearchBuilder().isEmpty, isTrue);
    expect(SearchBuilder().length, 0);
    expect(SearchBuilder.all([]).write(), '');
    expect(SearchBuilder.any([StateKind.due]).write(), 'is:due');
    expect(SearchBuilder.any([StateKind.due]).group().write(), 'is:due');
    expect(SearchBuilder().and(StateKind.due).write(), 'is:due');
    expect(SearchBuilder.fromRoot(const GroupNode([])).isEmpty, isTrue);
  });

  test('negation toggles and state shortcuts match source behavior', () {
    final due = const Search(State(StateKind.due));
    expect(due.negated(), const NegatedNode(Search(State(StateKind.due))));
    expect(due.negated().negated(), due);
    expect(SearchBuilder.learningCards().write(), 'is:learn -is:review');
    expect(SearchBuilder.relearningCards().write(), 'is:learn is:review');
  });

  test('constructors escape names and serialize full-width identifiers', () {
    const large = '9223372036854775807';
    expect(
        writeNode(SearchNodeBuilder.fromDeckId(Int64.parseInt(large)).toNode()),
        'did:$large');
    final deckWithChildren =
        SearchNodeBuilder.fromDeckId(Int64(17), withChildren: true).toNode()
            as Search;
    expect(deckWithChildren.value, isA<DeckIdWithChildren>());
    expect((deckWithChildren.value as DeckIdWithChildren).id, Int64(17));
    expect(writeNode(SearchNodeBuilder.fromDeckName(r'a*b_c\d').toNode()),
        r'deck:a\*b\_c\\d');
    expect(writeNode(SearchNodeBuilder.fromDeckName('_*').toNode()), 'deck:_*');
    expect(
        writeNode(SearchNodeBuilder.fromTagName('a_b').toNode()), r'tag:a\_b');
    expect(writeNode(SearchNodeBuilder.fromNotetypeName('a*b').toNode()),
        r'note:a\*b');
    expect(writeNode(SearchNodeBuilder.fromTemplateName('_front').toNode()),
        r'card:\_front');
    expect(
        writeNode(
            SearchNodeBuilder.fromNoteIds([Int64.parseInt(large), Int64(2)])
                .toNode()),
        'nid:$large,2');
    expect(
        writeNode(
            SearchNodeBuilder.fromCardIds([Int64.parseInt(large), Int64(3)])
                .toNode()),
        'cid:$large,3');
    final notetype = Int64.parseInt(large).asNotetypeIdNode() as Search;
    expect(notetype.value, isA<NotetypeIdSearch>());
    expect((notetype.value as NotetypeIdSearch).id.toString(), large);
    expect(writeNode(Int64.parseInt(large).asNoteIdNode()), 'nid:$large');
    expect(writeNode(TemplateOrdinal(0).toNode()), 'card:1');
    expect(writeNode(StateKind.review.toNode()), 'is:review');
    expect(SearchBuilder.fromDecks([Int64(4), Int64(5)]).write(), 'did:4,5');
  });
}
