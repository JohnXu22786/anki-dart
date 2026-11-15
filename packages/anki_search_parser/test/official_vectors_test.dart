// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

SearchNode value(String query) => (parse(query).single as Search).value;

void expectError(String query, SearchErrorCode code) {
  expect(
    () => parse(query),
    throwsA(isA<SearchParseException>()
        .having((error) => error.code, 'code', code)),
    reason: query,
  );
}

void main() {
  test('pinned parser success vectors preserve exact AST values', () {
    expect(value(''), isA<WholeCollection>());
    expect(parse('  t   t2  '), [
      const Search(TextSearch('t')),
      const BooleanNode(NodeKind.and),
      const Search(TextSearch('t2')),
    ]);
    expect(parse('(  t   t2  )'), [
      const GroupNode([
        Search(TextSearch('t')),
        BooleanNode(NodeKind.and),
        Search(TextSearch('t2')),
      ]),
    ]);
    expect(parse('hello  -(world and "foo:bar baz") OR test'), [
      const Search(TextSearch('hello')),
      const BooleanNode(NodeKind.and),
      const NegatedNode(GroupNode([
        Search(TextSearch('world')),
        BooleanNode(NodeKind.and),
        Search(SingleFieldSearch(
            field: 'foo', text: 'bar baz', mode: FieldSearchMode.normal)),
      ])),
      const BooleanNode(NodeKind.or),
      const Search(TextSearch('test')),
    ]);
    expect(
        value('foo:re:bar'),
        const SingleFieldSearch(
            field: 'foo', text: 'bar', mode: FieldSearchMode.regex));
    expect(
        value('foo:nc:bar'),
        const SingleFieldSearch(
            field: 'foo', text: 'bar', mode: FieldSearchMode.noCombining));
    expect(parse(r'"field:va\"lue"'), parse(r'field:"va\"lue"'));
    expect(parse(r'"field:va\"lue"'), parse(r'field:va\"lue'));
    expect(value(r'\:\(\)\-'), const TextSearch(':()-'));
    expect(value(r'\\\*\_'), const TextSearch(r'\\\*\_'));
    expect(parse(r'"\)\("'), parse(r'")("'));
    expect(parse('field:val:ue'), parse(r'field:val\:ue'));
    expect(parse(r'"field:val:ue"'), parse(r'field:val\:ue'));
    expect(parse(r'field:"val:ue"'), parse(r'field:val\:ue'));
    expect(parse('-'), parse(r'\-'));
    expect(parse('A-'), parse(r'A\-'));
    expect(parse(r'"-A"'), parse(r'\-A'));
    expect(parse('-A'), isNot(parse(r'\-A')));
    expect((value('"re:\\btest\\%"') as RegexSearch).pattern, r'\btest\%');
    expect((value(r're:te\"st') as RegexSearch).pattern, 'te"st');
    expect(parse('a"b"(c)'), parse('a b (c)'));

    expect(
        value('added:3'), isA<AddedInDays>().having((n) => n.days, 'days', 3));
    expect((value('card:front') as CardTemplate).kind,
        isA<TemplateName>().having((n) => n.value, 'name', 'front'));
    expect((value('card:3') as CardTemplate).kind,
        isA<TemplateOrdinal>().having((n) => n.value, 'ordinal', 2));
    expect((value('card:0') as CardTemplate).kind,
        isA<TemplateOrdinal>().having((n) => n.value, 'ordinal', 0));
    expect(value('deck:default'),
        isA<Deck>().having((n) => n.name, 'name', 'default'));
    expect(value('deck:"default one"'),
        isA<Deck>().having((n) => n.name, 'name', 'default one'));
    expect(value('preset:default'),
        isA<Preset>().having((n) => n.name, 'name', 'default'));
    expect(value('note:basic'),
        isA<Notetype>().having((n) => n.name, 'name', 'basic'));
    expect(value('DECK:default'),
        isA<Deck>().having((n) => n.name, 'name', 'default'));
    expect(
        value('deC\u212A:foo'),
        isA<SingleFieldSearch>()
            .having((n) => n.field, 'field', 'deC\u212A')
            .having((n) => n.text, 'text', 'foo'));
    expect(
        value('tag:hard'),
        isA<Tag>()
            .having((n) => n.tag, 'tag', 'hard')
            .having((n) => n.mode, 'mode', FieldSearchMode.normal));
    expect(
        value(r'tag:re:\\'),
        isA<Tag>()
            .having((n) => n.tag, 'tag', r'\\')
            .having((n) => n.mode, 'mode', FieldSearchMode.regex));
    expect(value('nid:1237123712,2,3'),
        isA<NoteIds>().having((n) => n.ids, 'ids', '1237123712,2,3'));
    expect(value('is:due'),
        isA<State>().having((n) => n.kind, 'state', StateKind.due));
    expect(value('flag:3'), isA<Flag>().having((n) => n.value, 'flag', 3));
    expect(
        value('prop:ivl>3'),
        isA<Property>().having((n) => n.operator, 'operator', '>').having(
            (n) => n.kind,
            'kind',
            isA<IntervalProperty>().having((p) => p.value, 'interval', 3)));
    expect(value('prop:cds:abc=foo'), isA<Property>());
    expect(value('"prop:cds:abc=foo bar"'), isA<Property>());
    expect(value('has-cd:r'),
        isA<CustomData>().having((n) => n.value, 'value', 'r'));
    expect(
        value('foo:re:bar'),
        const SingleFieldSearch(
            field: 'foo', text: 'bar', mode: FieldSearchMode.regex));
    expect(
        value('foo:nc:bar'),
        const SingleFieldSearch(
            field: 'foo', text: 'bar', mode: FieldSearchMode.noCombining));

    final propEase = value('prop:ease<=3.3') as Property;
    expect(propEase.operator, '<=');
    expect((propEase.kind as EaseProperty).value, closeTo(3.3, 0.000001));
    final propCdn = value('prop:cdn:abc<=1') as Property;
    expect(propCdn.operator, '<=');
    expect(
        propCdn.kind,
        isA<CustomDataNumberProperty>()
            .having((kind) => kind.key, 'key', 'abc')
            .having((kind) => kind.value, 'value', 1));
    final propCds = value('prop:cds:abc=foo') as Property;
    expect(propCds.operator, '=');
    expect(
        propCds.kind,
        isA<CustomDataStringProperty>()
            .having((kind) => kind.key, 'key', 'abc')
            .having((kind) => kind.value, 'value', 'foo'));
    expect(
        (value('"prop:cds:abc=foo bar"') as Property).kind,
        isA<CustomDataStringProperty>()
            .having((kind) => kind.key, 'key', 'abc')
            .having((kind) => kind.value, 'value', 'foo bar'));
  });

  test('pinned parser malformed query vectors retain distinct errors', () {
    for (final query in ['foo and', 'and foo', 'and']) {
      expectError(query, SearchErrorCode.misplacedAnd);
    }
    for (final query in ['foo or', 'or foo', 'or']) {
      expectError(query, SearchErrorCode.misplacedOr);
    }
    for (final query in ['()', '( )', '(foo () bar)']) {
      expectError(query, SearchErrorCode.emptyGroup);
    }
    for (final query in [')', 'foo ) bar', '(foo) bar)']) {
      expectError(query, SearchErrorCode.unopenedGroup);
    }
    for (final query in ['(', 'foo ( bar', '(foo (bar)']) {
      expectError(query, SearchErrorCode.unclosedGroup);
    }
    for (final query in ['""', 'foo:""']) {
      expectError(query, SearchErrorCode.emptyQuote);
    }
    for (final query in [' " ', '" foo', r'"\', 'foo:"bar', r'foo:"bar\']) {
      expectError(query, SearchErrorCode.unclosedQuote);
    }
    for (final query in [':', ':foo', r':"foo"']) {
      expectError(query, SearchErrorCode.missingKey);
    }
    for (final query in [r'\', r'\%', r'foo\', r'\foo', r'\ ', r'"\ "']) {
      expectError(query, SearchErrorCode.unknownEscape);
    }
    for (final query in [
      'nid:1_2,3',
      'nid:1,2,x',
      'nid:,2,3',
      'nid:1,2,',
      'cid:1_2,3',
      'cid:1,2,x',
      'cid:,2,3',
      'cid:1,2,',
    ]) {
      expectError(query, SearchErrorCode.other);
    }
    for (final query in ['is:foo', 'is:DUE', 'is:New', 'is:', '"is:learn "']) {
      expectError(query, SearchErrorCode.invalidState);
    }
    for (final query in [
      '"flag: "',
      'flag:-0',
      'flag:',
      'flag:8',
      'flag:1.1'
    ]) {
      expectError(query, SearchErrorCode.invalidFlag);
    }
    for (final key in ['added', 'edited', 'rated', 'resched']) {
      for (final invalid in ['1.1', '-1', '', 'foo']) {
        expectError(
            '$key:$invalid', SearchErrorCode.invalidPositiveWholeNumber);
      }
    }
    for (final invalid in ['1:', '2:-1', '3:1.1', '0:foo']) {
      expectError('rated:$invalid', SearchErrorCode.invalidAnswerButton);
    }
    for (final query in ['dupe:', 'dupe:1.1', 'dupe:foo']) {
      expectError(query, SearchErrorCode.invalidWholeNumber);
    }
    for (final query in [
      'prop:',
      'prop:=1',
      'prop:DUE<5',
      'prop:cdn=5',
      'prop:cdn:=5',
      'prop:cds=s',
      'prop:cds:=s'
    ]) {
      expectError(query, SearchErrorCode.invalidPropProperty);
    }
    for (final query in ['prop:lapses', 'prop:pos~1', 'prop:reps10']) {
      expectError(query, SearchErrorCode.invalidPropOperator);
    }
    for (final key in ['ivl', 'reps', 'lapses', 'pos']) {
      for (final suffix in ['>', '=0.5', '!=-1', '<foo']) {
        expectError(
            'prop:$key$suffix', SearchErrorCode.invalidPositiveWholeNumber);
      }
    }
    for (final query in ['prop:due>', 'prop:due=0.5']) {
      expectError(query, SearchErrorCode.invalidWholeNumber);
    }
    for (final query in ['prop:ease>', 'prop:ease!=one', 'prop:ease<1,3']) {
      expectError(query, SearchErrorCode.invalidNumber);
    }
    expectError('rated:1:2:3', SearchErrorCode.invalidAnswerButton);
    expectError('prop:rated=-1:2:3', SearchErrorCode.invalidAnswerButton);
  });

  test('integer widths and JavaScript-safe 64-bit ID representation', () {
    expect((value('mid:9223372036854775807') as NotetypeIdSearch).id.toString(),
        '9223372036854775807');
    expect((value('dupe:9223372036854775807,txt') as Duplicates).notetypeId,
        Int64.parseInt('9223372036854775807'));
    expectError('mid:9223372036854775808', SearchErrorCode.invalidWholeNumber);
    expectError('added:4294967296', SearchErrorCode.invalidPositiveWholeNumber);
    expectError('prop:due=2147483648', SearchErrorCode.invalidWholeNumber);
    expect(value('card:65536'), isA<CardTemplate>());
    expect(((value('card:65536') as CardTemplate).kind as TemplateName).value,
        '65536');
    expect(((value('card:0x10') as CardTemplate).kind as TemplateName).value,
        '0x10');
    expectError('mid:0x10', SearchErrorCode.invalidWholeNumber);
    expectError('prop:due=0x10', SearchErrorCode.invalidWholeNumber);
    expectError('rated:1:0x2', SearchErrorCode.invalidAnswerButton);
    expect((value('prop:ease=0.1') as Property).kind, isA<EaseProperty>());
  });

  test('field mode conversion uses the checked-in generated protocol enum', () {
    for (final mode in FieldSearchMode.values) {
      expect(FieldSearchModeProto.fromProto(mode.toProto()), mode);
    }
  });

  test('parser errors retain the source context slice', () {
    final cases = <String, String>{
      'added:nope': 'added:',
      'flag:8': '8',
      'is:invalid': 'invalid',
      'prop:ivl>nope': 'ivl>nope',
      'prop:=1': '=1',
      'rated:1:5': '1:5',
      'nid:1,x': '1,x',
      'dupe:1': '1',
      r'foo\': r'foo\',
      r'\%': r'\%',
    };
    for (final entry in cases.entries) {
      expect(
        () => parse(entry.key),
        throwsA(isA<SearchParseException>()
            .having((error) => error.remaining, 'remaining', entry.value)),
        reason: entry.key,
      );
    }
  });
}
