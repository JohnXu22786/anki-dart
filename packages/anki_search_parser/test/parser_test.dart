// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:test/test.dart';

void main() {
  test('official parser vectors: grouping, precedence, quoting and escapes',
      () {
    expect(parse(''), [isA<Search>()]);
    expect((parse('')[0] as Search).value, isA<WholeCollection>());
    final spaced = parse('  t   t2  ');
    expect(spaced, hasLength(3));
    expect((spaced[1] as BooleanNode).kind, NodeKind.and);
    final tree = parse('hello  -(world and "foo:bar baz") OR test');
    expect(tree, hasLength(5));
    expect(tree[1], isA<BooleanNode>());
    expect(tree[2], isA<NegatedNode>());
    expect((tree[3] as BooleanNode).kind, NodeKind.or);
    expect(parse('foo:re:bar').single, isA<Search>());
    expect(
        (parse('foo:re:bar').single as Search).value, isA<SingleFieldSearch>());
    expect(
        (parse('foo:nc:bar').single as Search).value, isA<SingleFieldSearch>());
    expect(parse(r'"field:va\"lue"'), parse(r'field:"va\"lue"'));
    expect(parse(r'"field:va\"lue"'), parse(r'field:va\"lue'));
    expect((parse(r'\:\(\)\-').single as Search).value, TextSearch(':()-'));
    expect((parse(r'\\\*\_').single as Search).value, TextSearch(r'\\\*\_'));
    expect(parse(r'"\)\("'), parse(r'")("'));
    expect(parse('field:val:ue'), parse(r'field:val\:ue'));
    expect(parse('"field:val:ue"'), parse(r'field:val\:ue'));
    expect(parse('field:"val:ue"'), parse(r'field:val\:ue'));
    expect(parse('-'), parse(r'\-'));
    expect(parse('A-'), parse(r'A\-'));
    expect(parse('"-A"'), parse(r'\-A'));
    expect(parse('-A'), isNot(parse(r'\-A')));
    expect(
        (parse('"re:\\btest\\%"').single as Search).value, isA<RegexSearch>());
    expect(parse(r're:te\"st').single, isA<Search>());
    expect(parse('a"b"(c)'), parse('a b (c)'));
  });

  test('official keyword and property parser vectors', () {
    final accepted = <String>[
      'added:3',
      'edited:3',
      'introduced:2',
      'card:front',
      'card:3',
      'card:0',
      'deck:default',
      'deck:"default one"',
      'preset:default',
      'note:basic',
      'tag:hard',
      r'tag:re:\\',
      'nid:1237123712,2,3',
      'cid:1,2',
      'did:1,2',
      'is:due',
      'flag:3',
      'resched:3',
      'rated:3',
      'rated:10:2',
      'dupe:123,hello',
      'mid:9223372036854775807',
      'prop:ivl>3',
      'prop:ease<=3.3',
      'prop:cdn:abc<=1',
      'prop:cds:abc=foo',
      '"prop:cds:abc=foo bar"',
      'has-cd:r',
      'foo:re:bar',
      'foo:nc:bar',
      '"re:\\btest\\%"',
      'nc:foo',
      'sc:foo',
      'w:foo',
    ];
    for (final query in accepted) {
      expect(() => parse(query), returnsNormally, reason: query);
    }
    expect(((parse('card:3').single as Search).value as CardTemplate).kind,
        const TypeMatcher<TemplateOrdinal>());
    expect(((parse('added:0').single as Search).value as AddedInDays).days, 1);
    expect(((parse('flag:7').single as Search).value as Flag).value, 7);
    final prop = (parse('prop:cds:abc=foo').single as Search).value as Property;
    expect(prop.operator, '=');
    expect(prop.kind, isA<CustomDataStringProperty>());
  });

  test('official malformed query classes', () {
    final errors = <String, SearchErrorCode>{
      'foo and': SearchErrorCode.misplacedAnd,
      'and foo': SearchErrorCode.misplacedAnd,
      'and': SearchErrorCode.misplacedAnd,
      'foo or': SearchErrorCode.misplacedOr,
      'or foo': SearchErrorCode.misplacedOr,
      'or': SearchErrorCode.misplacedOr,
      '()': SearchErrorCode.emptyGroup,
      '( )': SearchErrorCode.emptyGroup,
      '(foo () bar)': SearchErrorCode.emptyGroup,
      ')': SearchErrorCode.unopenedGroup,
      'foo ) bar': SearchErrorCode.unopenedGroup,
      '(foo) bar)': SearchErrorCode.unopenedGroup,
      '(': SearchErrorCode.unclosedGroup,
      'foo ( bar': SearchErrorCode.unclosedGroup,
      '(foo (bar)': SearchErrorCode.unclosedGroup,
      '""': SearchErrorCode.emptyQuote,
      'foo:""': SearchErrorCode.emptyQuote,
      ' " ': SearchErrorCode.unclosedQuote,
      '" foo': SearchErrorCode.unclosedQuote,
      '"\\': SearchErrorCode.unclosedQuote,
      'foo:"bar': SearchErrorCode.unclosedQuote,
      'foo:"bar\\': SearchErrorCode.unclosedQuote,
      ':': SearchErrorCode.missingKey,
      ':foo': SearchErrorCode.missingKey,
      r'\': SearchErrorCode.unknownEscape,
      r'\%': SearchErrorCode.unknownEscape,
      r'foo\': SearchErrorCode.unknownEscape,
      r'\foo': SearchErrorCode.unknownEscape,
      r'\ ': SearchErrorCode.unknownEscape,
      'flag:': SearchErrorCode.invalidFlag,
      'flag:8': SearchErrorCode.invalidFlag,
      'flag:-0': SearchErrorCode.invalidFlag,
      'is:foo': SearchErrorCode.invalidState,
      'is:DUE': SearchErrorCode.invalidState,
      'prop:': SearchErrorCode.invalidPropProperty,
      'prop:=1': SearchErrorCode.invalidPropProperty,
      'prop:DUE<5': SearchErrorCode.invalidPropProperty,
      'prop:lapses': SearchErrorCode.invalidPropOperator,
      'prop:pos~1': SearchErrorCode.invalidPropOperator,
    };
    for (final entry in errors.entries) {
      expect(
          () => parse(entry.key),
          throwsA(isA<SearchParseException>()
              .having((e) => e.code, 'code', entry.value)),
          reason: entry.key);
    }
    for (final query in [
      'nid:1_2,3',
      'nid:1,2,x',
      'nid:,2,3',
      'nid:1,2,',
      'cid:1_2,3',
      'cid:1,2,x',
      'cid:,2,3',
      'cid:1,2,'
    ]) {
      expect(
          () => parse(query),
          throwsA(isA<SearchParseException>()
              .having((e) => e.code, 'code', SearchErrorCode.other)),
          reason: query);
    }
  });

  test('numeric widths and 64-bit IDs stay exact', () {
    expect(
        ((parse('mid:9223372036854775807').single as Search).value
                as NotetypeIdSearch)
            .id
            .toString(),
        '9223372036854775807');
    expect(
        () => parse('mid:9223372036854775808'),
        throwsA(isA<SearchParseException>().having(
            (e) => e.code, 'code', SearchErrorCode.invalidWholeNumber)));
    expect(
        () => parse('added:4294967296'),
        throwsA(isA<SearchParseException>().having((e) => e.code, 'code',
            SearchErrorCode.invalidPositiveWholeNumber)));
    expect(
        () => parse('prop:due=2147483648'),
        throwsA(isA<SearchParseException>().having(
            (e) => e.code, 'code', SearchErrorCode.invalidWholeNumber)));
    expect(() => parse('card:65536'),
        returnsNormally); // overflow falls back to a template name
    expect(() => parse('prop:cdn:clé=1'), returnsNormally);
    expect(((parse('prop:ease=0.1').single as Search).value as Property).kind,
        const TypeMatcher<EaseProperty>());
  });

  test('field mode conversions match the generated protocol enum', () {
    for (final mode in FieldSearchMode.values) {
      expect(FieldSearchModeProto.fromProto(mode.toProto()), mode);
    }
  });
}
