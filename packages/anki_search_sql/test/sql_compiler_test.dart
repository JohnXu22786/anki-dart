// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:anki_search_sql/anki_search_sql.dart';
import 'package:test/test.dart';

void main() {
  test('source query SELECT shape and required-table optimization', () {
    final parsedCardIds = compileSearchSql(GroupNode(parse('cid:3,4')));
    expect(parsedCardIds.sql, 'select c.id from cards c where (c.id in (3,4))');

    expect(
      compileSearchSql(GroupNode(parse('nid:١'))).sql,
      'select c.id from cards c where (c.nid in (١))',
    );

    final cardIds = Search(CardIds('3,4'));
    final cards = compileSearchSql(GroupNode([cardIds]));
    expect(cards.sql, 'select c.id from cards c where (c.id in (3,4))');
    expect(cards.arguments, isEmpty);
    expect(cards.requiredTable, RequiredTable.cards);

    final notes = compileSearchSql(
      GroupNode([Search(NoteIds('3,4'))]),
      resultType: SearchResultType.notes,
    );
    expect(notes.sql, 'select n.id from notes n where (n.id in (3,4))');
    expect(notes.arguments, isEmpty);
    expect(notes.requiredTable, RequiredTable.notes);

    expect(
      compileSearchSql(
        GroupNode([
          Search(CardIds('3')),
          BooleanNode(NodeKind.and),
          Search(NotetypeIdSearch(Int64.parseInt('7'))),
        ]),
        resultType: SearchResultType.notes,
      ).sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(c.id in (3) and n.mid = 7)',
    );
  });

  test(
    'source predicates, boolean grouping, ID spellings, and unsupported nodes',
    () {
      final maxId = '9223372036854775807';
      expect(
        compileSearchSql(
          GroupNode([
            Search(CardIds('0000000000000000000000000000000000000000003')),
            BooleanNode(NodeKind.or),
            NegatedNode(Search(Flag(2))),
          ]),
        ).sql,
        'select c.id from cards c where (c.id in '
        '(0000000000000000000000000000000000000000003) or not (c.flags & 7) == 2)',
      );
      expect(
        compileSearchSql(GroupNode([Search(NoteIds(maxId))])).sql,
        'select c.id from cards c where (c.nid in ($maxId))',
      );
      expect(
        compileSearchSql(
          GroupNode([Search(DeckIdsWithoutChildren('5,6'))]),
        ).sql,
        'select c.id from cards c where '
        '((c.did in (5,6) or (c.odid != 0 and c.odid in (5,6))))',
      );
      expect(
        compileSearchSql(
          GroupNode([
            Search(DeckIdsWithoutChildren('5,6')),
            BooleanNode(NodeKind.and),
            Search(CardIds('9')),
          ]),
        ).sql,
        'select c.id from cards c where '
        '((c.did in (5,6) or (c.odid != 0 and c.odid in (5,6))) and c.id in (9))',
      );
      expect(
        compileSearchSql(
          GroupNode([NegatedNode(Search(DeckIdsWithoutChildren('5,6')))]),
        ).sql,
        'select c.id from cards c where '
        '(not (c.did in (5,6) or (c.odid != 0 and c.odid in (5,6))))',
      );
      expect(
        compileSearchSql(
          GroupNode([Search(WholeCollection())]),
          resultType: SearchResultType.notes,
        ).sql,
        'select n.id from notes n where (true)',
      );
      expect(
        () => compileSearchSql(GroupNode([Search(TextSearch('unsupported'))])),
        throwsA(isA<UnsupportedSearchSqlNodeException>()),
      );
      for (final value in [-1, 8]) {
        expect(
          () => compileSearchSql(GroupNode([Search(Flag(value))])),
          throwsRangeError,
          reason: 'flag:$value',
        );
      }
      for (final node in <SearchNode>[
        const CardIds('1) or true --'),
        const NoteIds('1) or true --'),
        const DeckIdsWithoutChildren('1) or true --'),
      ]) {
        expect(
          () => compileSearchSql(GroupNode([Search(node)])),
          throwsArgumentError,
          reason: node.runtimeType.toString(),
        );
      }
    },
  );

  test('literal notetype and template names follow Core text semantics', () {
    final notetype = compileSearchSql(
      GroupNode([Search(Notetype('Cafe\u0301\\*'))]),
    );
    expect(
      notetype.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name = ?))',
    );
    expect(notetype.arguments, ['Café*']);
    expect(notetype.requiredTable, RequiredTable.cardsAndNotes);

    final newline = compileSearchSql(
      GroupNode([Search(Notetype('Line\\\nBreak'))]),
    );
    expect(newline.arguments, ['Line\\\nBreak']);

    final template = compileSearchSql(
      GroupNode([Search(CardTemplate(TemplateName('Fron\\*t')))]),
      resultType: SearchResultType.notes,
    );
    expect(
      template.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '((n.mid,c.ord) in '
      '(select ntid,ord from templates where name = ?))',
    );
    expect(template.arguments, ['Fron*t']);
    expect(template.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('glob names emit anchored regexes with Core wildcard escaping', () {
    final notetype = compileSearchSql(
      GroupNode([Search(Notetype('Cafe\u0301*\\_*'))]),
    );
    expect(
      notetype.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name regexp ?))',
    );
    expect(notetype.arguments, [r'(?i)^Café.*_.*$']);

    final template = compileSearchSql(
      GroupNode([Search(CardTemplate(TemplateName(r'A.\**_')))]),
    );
    expect(
      template.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '((n.mid,c.ord) in '
      '(select ntid,ord from templates where name regexp ?))',
    );
    expect(template.arguments, [r'(?i)^A\.\*.*.$']);
  });

  test('ordinal templates use cards and notes without SQL arguments', () {
    final compiled = compileSearchSql(
      GroupNode([Search(CardTemplate(TemplateOrdinal(2)))]),
    );
    expect(
      compiled.sql,
      'select c.id from cards c, notes n where c.nid=n.id and (c.ord = 2)',
    );
    expect(compiled.arguments, isEmpty);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('nested predicates combine tables and preserve argument order', () {
    final compiled = compileSearchSql(
      GroupNode([
        Search(Notetype('Basic*')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(CardTemplate(TemplateName('Front*'))),
          BooleanNode(NodeKind.or),
          Search(CardTemplate(TemplateName('Back*'))),
        ]),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(
      compiled.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name regexp ?) and '
      '((n.mid,c.ord) in '
      '(select ntid,ord from templates where name regexp ?) or '
      '(n.mid,c.ord) in '
      '(select ntid,ord from templates where name regexp ?)))',
    );
    expect(compiled.arguments, [
      r'(?i)^Basic.*$',
      r'(?i)^Front.*$',
      r'(?i)^Back.*$',
    ]);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('tag modes use Core SQL clauses and matching transformations', () {
    final normal = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'foo_bar*', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(
      normal.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(n.tags regexp ?)',
    );
    expect(normal.arguments, [r'(?i).* foo\Sbar\S*(::| ).*']);
    expect(normal.requiredTable, RequiredTable.cardsAndNotes);

    final regex = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: r'^foo.*$', mode: FieldSearchMode.regex)),
      ]),
    );
    expect(
      regex.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(regexp_tags(?1, n.tags))',
    );
    expect(regex.arguments, [r'(?i)^foo.*$']);

    final noCombining = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'Café', mode: FieldSearchMode.noCombining)),
      ]),
    );
    expect(
      noCombining.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '(coalesce(process_text(n.tags, 1), n.tags) regexp ?)',
    );
    expect(noCombining.arguments, [r'(?i).* Cafe(::| ).*']);
  });

  test('tag special values and escaped wildcards match Core semantics', () {
    for (final tag in ['none', '*']) {
      final compiled = compileSearchSql(
        GroupNode([Search(Tag(tag: tag, mode: FieldSearchMode.normal))]),
      );
      expect(compiled.sql, contains(tag == 'none' ? 'n.tags = \'\'' : 'true'));
      expect(compiled.arguments, isEmpty);
    }

    final space = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'two words', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(space.sql, endsWith('(false)'));
    expect(space.arguments, isEmpty);

    final escaped = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: r'Foo\*_*', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(escaped.arguments, [r'(?i).* Foo\*\S\S*(::| ).*']);

    final escapedOnly = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: r'Foo\*', mode: FieldSearchMode.normal)),
      ]),
    );
    expect(escapedOnly.arguments, [r'(?i).* Foo\*(::| ).*']);
    expect(escapedOnly.sql, endsWith('(n.tags regexp ?)'));
  });

  test('tag arguments retain ordering through nested boolean predicates', () {
    final compiled = compileSearchSql(
      GroupNode([
        Search(Notetype('Basic*')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(const Tag(tag: 'Café*', mode: FieldSearchMode.noCombining)),
          BooleanNode(NodeKind.or),
          Search(const Tag(tag: r'^math::.*$', mode: FieldSearchMode.regex)),
        ]),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(
      compiled.sql,
      'select n.id from notes n where '
      '(n.mid in (select id from notetypes where name regexp ?) and '
      '(coalesce(process_text(n.tags, 1), n.tags) regexp ? or '
      'regexp_tags(?3, n.tags)))',
    );
    expect(compiled.arguments, [
      r'(?i)^Basic.*$',
      r'(?i).* Cafe\S*(::| ).*',
      r'(?i)^math::.*$',
    ]);
    expect(compiled.requiredTable, RequiredTable.notes);
  });

  test('state predicates match pinned card type and queue values', () {
    final cases = <(StateKind, String)>[
      (StateKind.newCard, 'c.type = 0'),
      (StateKind.review, 'c.type in (2, 3)'),
      (StateKind.learning, 'c.type in (1, 3)'),
      (StateKind.buried, 'c.queue in (-2,-3)'),
      (StateKind.userBuried, 'c.queue = -3'),
      (StateKind.schedBuried, 'c.queue = -2'),
      (StateKind.suspended, 'c.queue = -1'),
    ];

    for (final (kind, predicate) in cases) {
      final compiled = compileSearchSql(GroupNode([Search(State(kind))]));
      expect(compiled.sql, 'select c.id from cards c where ($predicate)');
      expect(compiled.requiredTable, RequiredTable.cards);
      expect(compiled.arguments, isEmpty);
    }

    final notes = compileSearchSql(
      GroupNode([Search(State(StateKind.newCard))]),
      resultType: SearchResultType.notes,
    );
    expect(
      notes.sql,
      'select distinct n.id from cards c, notes n where '
      'c.nid=n.id and (c.type = 0)',
    );
    expect(notes.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('due state uses explicit timing and pinned cutoff boundaries', () {
    final compiled = compileSearchSql(
      GroupNode([Search(State(StateKind.due))]),
      timing: SearchSqlTiming(
        daysElapsed: 42,
        now: BigInt.from(1700000000),
        learnAheadSecs: 30,
      ),
    );
    expect(
      compiled.sql,
      'select c.id from cards c where '
      '(((c.queue in (2,3) and c.due <= 42) or '
      '(c.queue in (1,4) and c.due <= 1700000030)))',
    );
    expect(compiled.arguments, isEmpty);

    expect(
      () => compileSearchSql(GroupNode([Search(State(StateKind.due))])),
      throwsArgumentError,
    );
  });

  test('state predicates compose with existing predicates and arguments', () {
    final compiled = compileSearchSql(
      GroupNode([
        Search(Notetype('Basic*')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(State(StateKind.due)),
          BooleanNode(NodeKind.or),
          Search(const Tag(tag: r'^math$', mode: FieldSearchMode.regex)),
        ]),
      ]),
      resultType: SearchResultType.notes,
      timing: SearchSqlTiming(
        daysElapsed: 8,
        now: BigInt.from(100),
        learnAheadSecs: 5,
      ),
    );
    expect(
      compiled.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name regexp ?) and '
      '(((c.queue in (2,3) and c.due <= 8) or '
      '(c.queue in (1,4) and c.due <= 105)) or regexp_tags(?2, n.tags)))',
    );
    expect(compiled.arguments, [r'(?i)^Basic.*$', r'(?i)^math$']);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('due timing rejects values outside Core ranges and cutoff overflow', () {
    final validNow = BigInt.from(1700000000);
    for (final timing in <SearchSqlTiming>[
      SearchSqlTiming(daysElapsed: -1, now: validNow, learnAheadSecs: 0),
      SearchSqlTiming(
        daysElapsed: 4294967296,
        now: validNow,
        learnAheadSecs: 0,
      ),
      SearchSqlTiming(daysElapsed: 0, now: validNow, learnAheadSecs: -1),
      SearchSqlTiming(
        daysElapsed: 0,
        now: validNow,
        learnAheadSecs: 4294967296,
      ),
      SearchSqlTiming(
        daysElapsed: 0,
        now: BigInt.parse('9223372036854775807'),
        learnAheadSecs: 1,
      ),
      SearchSqlTiming(
        daysElapsed: 0,
        now: BigInt.parse('9223372036854775808'),
        learnAheadSecs: 0,
      ),
      SearchSqlTiming(
        daysElapsed: 0,
        now: BigInt.parse('-9223372036854775809'),
        learnAheadSecs: 0,
      ),
    ]) {
      expect(
        () => compileSearchSql(
          GroupNode([Search(State(StateKind.due))]),
          timing: timing,
        ),
        throwsRangeError,
      );
    }
  });

  test('added and edited day predicates use next-day cutoff units', () {
    final timing = SearchSqlTiming(
      daysElapsed: 0,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(1700000000),
    );
    final added = compileSearchSql(
      GroupNode([Search(const AddedInDays(2))]),
      timing: timing,
    );
    expect(added.sql, 'select c.id from cards c where (c.id > 1699827200000)');
    expect(added.requiredTable, RequiredTable.cards);
    expect(added.arguments, isEmpty);

    final addedToNotes = compileSearchSql(
      GroupNode([Search(const AddedInDays(2))]),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      addedToNotes.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(c.id > 1699827200000)',
    );
    expect(addedToNotes.requiredTable, RequiredTable.cardsAndNotes);

    final edited = compileSearchSql(
      GroupNode([Search(const EditedInDays(2))]),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(edited.sql, 'select n.id from notes n where (n.mod > 1699827200)');
    expect(edited.requiredTable, RequiredTable.notes);
    expect(edited.arguments, isEmpty);

    final maxDays = compileSearchSql(
      GroupNode([Search(const AddedInDays(4294967295))]),
      timing: timing,
    );
    expect(
      maxDays.sql,
      'select c.id from cards c where (c.id > -371083474288000000)',
    );
  });

  test(
    'introduced day predicate excludes manual reschedules in correlated SQL',
    () {
      final compiled = compileSearchSql(
        GroupNode([Search(const IntroducedInDays(5))]),
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
          nextDayAt: BigInt.from(1700000000),
        ),
      );
      expect(
        compiled.sql,
        'select c.id from cards c where '
        '(((SELECT coalesce(min(id) > 1699568000000, false) FROM revlog '
        'WHERE cid = c.id AND ease != 0) AND c.id IN '
        '(SELECT cid FROM revlog WHERE id > 1699568000000)))',
      );
      expect(compiled.requiredTable, RequiredTable.cards);
      expect(compiled.arguments, isEmpty);
    },
  );

  test('day predicates compose and validate u32 and signed 64-bit cutoffs', () {
    final timing = SearchSqlTiming(
      daysElapsed: 0,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(1700000000),
    );
    final nested = compileSearchSql(
      GroupNode([
        Search(Notetype('Basic*')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(const AddedInDays(0)),
          BooleanNode(NodeKind.or),
          Search(const EditedInDays(1)),
        ]),
        BooleanNode(NodeKind.and),
        Search(Notetype('Cloze*')),
      ]),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      nested.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name regexp ?) and '
      '(c.id > 1700000000000 or n.mod > 1699913600) and '
      'n.mid in (select id from notetypes where name regexp ?))',
    );
    expect(nested.arguments, [r'(?i)^Basic.*$', r'(?i)^Cloze.*$']);
    expect(nested.requiredTable, RequiredTable.cardsAndNotes);

    for (final days in [-1, 4294967296]) {
      for (final node in <SearchNode>[
        AddedInDays(days),
        EditedInDays(days),
        IntroducedInDays(days),
      ]) {
        expect(
          () => compileSearchSql(GroupNode([Search(node)]), timing: timing),
          throwsRangeError,
          reason: '${node.runtimeType}:$days',
        );
      }
    }
    expect(
      () => compileSearchSql(
        GroupNode([Search(const AddedInDays(1))]),
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => compileSearchSql(GroupNode([Search(const EditedInDays(1))])),
      throwsArgumentError,
    );
    expect(
      () => compileSearchSql(
        GroupNode([Search(const EditedInDays(0))]),
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
          nextDayAt: BigInt.parse('9223372036854775808'),
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => compileSearchSql(
        GroupNode([Search(const AddedInDays(0))]),
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
          nextDayAt: BigInt.parse('9223372036854775807'),
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => compileSearchSql(
        GroupNode([Search(const EditedInDays(1))]),
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
          nextDayAt: BigInt.parse('-9223372036854775808'),
        ),
      ),
      throwsRangeError,
    );
  });

  test('custom-data existence and properties require cards', () {
    final exists = compileSearchSql(
      GroupNode([Search(const CustomData('retention'))]),
    );
    expect(
      exists.sql,
      'select c.id from cards c where '
      '(extract_custom_data(c.data, ?) is not null)',
    );
    expect(exists.arguments, ['retention']);
    expect(exists.requiredTable, RequiredTable.cards);

    final noteResults = compileSearchSql(
      GroupNode([Search(const CustomData('retention'))]),
      resultType: SearchResultType.notes,
    );
    expect(
      noteResults.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(extract_custom_data(c.data, ?) is not null)',
    );
    expect(noteResults.arguments, ['retention']);
    expect(noteResults.requiredTable, RequiredTable.cardsAndNotes);
  });

  test(
    'custom-data properties use Core operators and bind key/value arguments',
    () {
      const operators = ['<=', '>=', '!=', '=', '<', '>'];
      for (final operator in operators) {
        final number = compileSearchSql(
          GroupNode([
            Search(
              Property(
                operator: operator,
                kind: const CustomDataNumberProperty(key: "a'!", value: 2.5),
              ),
            ),
          ]),
        );
        expect(
          number.sql,
          'select c.id from cards c where '
          '(cast(extract_custom_data(c.data, ?) as float) $operator 2.5)',
        );
        expect(number.arguments, ["a'!"]);
        expect(number.requiredTable, RequiredTable.cards);

        final string = compileSearchSql(
          GroupNode([
            Search(
              Property(
                operator: operator,
                kind: const CustomDataStringProperty(
                  key: "k';--",
                  value: "v' OR 1=1 --",
                ),
              ),
            ),
          ]),
        );
        expect(
          string.sql,
          'select c.id from cards c where '
          '(extract_custom_data(c.data, ?) $operator ?)',
        );
        expect(string.arguments, ["k';--", "v' OR 1=1 --"]);
        expect(string.requiredTable, RequiredTable.cards);
      }
    },
  );

  test('custom-data properties compose and preserve float32 spellings', () {
    final compiled = compileSearchSql(
      GroupNode([
        Search(const Notetype('Basic')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(
            const Property(
              operator: '>=',
              kind: CustomDataNumberProperty(key: 'ease', value: 0.1),
            ),
          ),
          BooleanNode(NodeKind.or),
          Search(
            const Property(
              operator: '=',
              kind: CustomDataStringProperty(key: 'label', value: 'again'),
            ),
          ),
        ]),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(
      compiled.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.mid in (select id from notetypes where name = ?) and '
      '(cast(extract_custom_data(c.data, ?) as float) >= 0.1 or '
      'extract_custom_data(c.data, ?) = ?))',
    );
    expect(compiled.arguments, ['Basic', 'ease', 'label', 'again']);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);

    for (final valueAndSql in <(String, String)>[
      ('NaN', 'NaN'),
      ('+inf', 'inf'),
      ('-inf', '-inf'),
      ('1e-45', '0.${'0' * 44}1'),
      ('3.4028235e38', '340282350000000000000000000000000000000'),
      ('3.5e38', 'inf'),
    ]) {
      final (value, sqlValue) = valueAndSql;
      final number = compileSearchSql(GroupNode(parse('prop:cdn:x=$value')));
      expect(number.sql, endsWith('as float) = $sqlValue)'));
      expect(number.arguments, ['x']);
    }

    expect(
      () => compileSearchSql(
        GroupNode([
          Search(
            const Property(
              operator: 'or true --',
              kind: CustomDataStringProperty(key: 'x', value: 'y'),
            ),
          ),
        ]),
      ),
      throwsArgumentError,
    );

    final finite = compileSearchSql(GroupNode(parse('prop:cdn:x=0.1')));
    expect(finite.sql, endsWith('as float) = 0.1)'));
    expect(finite.arguments, ['x']);
  });
}
