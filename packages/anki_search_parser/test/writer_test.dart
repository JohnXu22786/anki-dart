// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

Search search(SearchNode value) => Search(value);

void main() {
  test('normalization writes canonical syntax and is idempotent', () {
    final vectors = <String, String>{
      '"foo" "b a r"': 'foo "b a r"',
      'field:"foo"': 'field:foo',
      r'\( \)': '"(" ")"',
      r'\-foo': '"-foo"',
      r'\*\:\_': r'\*\:\_',
      r'deck:\:': 'deck::',
      r'1 and 2 or 3': '1 2 OR 3',
      'prop:ease>1.0': 'prop:ease>1',
      'is:buried-manually': 'is:buried-manually',
    };
    for (final entry in vectors.entries) {
      final normalized = normalizeSearch(entry.key);
      expect(normalized, entry.value, reason: entry.key);
      expect(normalizeSearch(normalized), normalized, reason: entry.key);
    }
    expect(() => normalizeSearch('and'), throwsA(isA<SearchParseException>()));
  });

  test('every Node and SearchNode kind serializes with pinned syntax', () {
    final nodes = <Node>[
      const Search(TextSearch('plain')),
      const BooleanNode(NodeKind.and),
      const BooleanNode(NodeKind.or),
      const NegatedNode(Search(TextSearch('x'))),
      const GroupNode([
        Search(TextSearch('a')),
        BooleanNode(NodeKind.and),
        Search(TextSearch('b'))
      ]),
      const Search(SingleFieldSearch(
          field: 'f', text: 're:x', mode: FieldSearchMode.normal)),
      const Search(SingleFieldSearch(
          field: 'f', text: 'x y', mode: FieldSearchMode.regex)),
      const Search(SingleFieldSearch(
          field: 'f', text: 'x', mode: FieldSearchMode.noCombining)),
      const Search(AddedInDays(3)),
      const Search(EditedInDays(4)),
      const Search(IntroducedInDays(5)),
      const Search(CardTemplate(TemplateOrdinal(0))),
      const Search(CardTemplate(TemplateName('two words'))),
      const Search(Deck('two words')),
      const Search(DeckIdsWithoutChildren('1,2')),
      Search(DeckIdWithChildren(Int64(7))),
      Search(NotetypeIdSearch(Int64.parseInt('9223372036854775807'))),
      const Search(Notetype('two words')),
      const Search(Rated(days: 2, ease: AnswerButton(4))),
      const Search(Rated(days: 2, ease: AnyAnswerButton())),
      const Search(Rated(days: 2, ease: ManualReschedule())),
      const Search(Tag(tag: 'x y', mode: FieldSearchMode.normal)),
      Search(Duplicates(notetypeId: Int64(9), text: r'a\b')),
      const Search(State(StateKind.newCard)),
      const Search(State(StateKind.review)),
      const Search(State(StateKind.learning)),
      const Search(State(StateKind.due)),
      const Search(State(StateKind.buried)),
      const Search(State(StateKind.userBuried)),
      const Search(State(StateKind.schedBuried)),
      const Search(State(StateKind.suspended)),
      const Search(Flag(3)),
      const Search(NoteIds('1,2')),
      const Search(CardIds('3,4')),
      const Search(Property(operator: '<=', kind: DueProperty(-2))),
      const Search(Property(operator: '>', kind: IntervalProperty(3))),
      const Search(Property(operator: '=', kind: RepsProperty(4))),
      const Search(Property(operator: '!=', kind: LapsesProperty(5))),
      const Search(Property(operator: '=', kind: EaseProperty(1.0))),
      const Search(Property(operator: '<', kind: PositionProperty(6))),
      const Search(
          Property(operator: '>', kind: RatedProperty(-2, AnswerButton(1)))),
      const Search(
          Property(operator: '=', kind: RatedProperty(0, AnyAnswerButton()))),
      const Search(
          Property(operator: '=', kind: RatedProperty(-1, ManualReschedule()))),
      const Search(Property(operator: '>', kind: StabilityProperty(1.25))),
      const Search(Property(operator: '<', kind: DifficultyProperty(2.5))),
      const Search(Property(operator: '=', kind: RetrievabilityProperty(0.5))),
      const Search(Property(
          operator: '=',
          kind: CustomDataNumberProperty(key: 'abc', value: 2.0))),
      const Search(Property(
          operator: '=',
          kind: CustomDataStringProperty(key: 'abc', value: 'x y'))),
      const Search(WholeCollection()),
      const Search(RegexSearch(r'a\b')),
      const Search(NoCombining('x y')),
      const Search(StripClozes('x y')),
      const Search(WordBoundary('x y')),
      const Search(CustomData('x y')),
      const Search(Preset('two words')),
    ];
    final expected = <String>[
      'plain',
      ' ',
      ' OR ',
      '-x',
      '(a b)',
      r'f:re\:x',
      '"f:re:x y"',
      'f:nc:x',
      'added:3',
      'edited:4',
      'introduced:5',
      'card:1',
      '"card:two words"',
      '"deck:two words"',
      'did:1,2',
      '',
      'mid:9223372036854775807',
      '"note:two words"',
      'rated:2:4',
      'rated:2',
      'resched:2',
      '"tag:x y"',
      r'dupe:9,a\\b',
      'is:new',
      'is:review',
      'is:learn',
      'is:due',
      'is:buried',
      'is:buried-manually',
      'is:buried-sibling',
      'is:suspended',
      'flag:3',
      'nid:1,2',
      'cid:3,4',
      'prop:due<=-2',
      'prop:ivl>3',
      'prop:reps=4',
      'prop:lapses!=5',
      'prop:ease=1',
      'prop:pos<6',
      'prop:rated>-2:1',
      'prop:rated=0',
      'prop:resched=-1',
      'prop:s>1.25',
      'prop:d<2.5',
      'prop:r=0.5',
      'prop:cdn:abc=2',
      '"prop:cds:abc=x y"',
      'deck:*',
      're:a\\b',
      '"nc:x y"',
      '"sc:x y"',
      '"w:x y"',
      '"has-cd:x y"',
      '"preset:two words"',
    ];
    expect(nodes, hasLength(expected.length));
    for (var i = 0; i < nodes.length; i++) {
      expect(writeNode(nodes[i]), expected[i],
          reason: '${nodes[i].runtimeType}');
    }
  });

  test(
      'replacement matches search kind recursively through groups and negations',
      () {
    final original = parse('deck:one OR -(deck:two tag:old)');
    expect(replaceSearchNode(original, search(const Deck('new'))),
        'deck:new OR -(deck:new tag:old)');
    expect(
        replaceSearchNode(parse('tag:a OR (tag:b deck:x)'),
            search(const Tag(tag: 'z', mode: FieldSearchMode.normal))),
        'tag:z OR (tag:z deck:x)');
    expect(
        replaceSearchNode(parse('deck:a tag:b'), search(const Notetype('n'))),
        'deck:a tag:b');
    expect(replaceSearchNode(parse('deck:a'), const BooleanNode(NodeKind.or)),
        'deck:a');
  });

  test('deck query escaping and floating point output match Rust f32 display',
      () {
    expect(deckSearch(r'a*b_c\d'), r'deck:a\*b\_c\\d');
    expect(
        writeNode(
            search(const Property(operator: '=', kind: EaseProperty(0.1)))),
        'prop:ease=0.1');
    expect(
        writeNode(
            search(const Property(operator: '=', kind: EaseProperty(1e-7)))),
        'prop:ease=0.0000001');
    expect(
        writeNode(search(const Property(
            operator: '=', kind: EaseProperty(double.infinity)))),
        'prop:ease=inf');
    expect(
        writeNode(search(
            const Property(operator: '=', kind: EaseProperty(double.nan)))),
        'prop:ease=NaN');
  });
}
