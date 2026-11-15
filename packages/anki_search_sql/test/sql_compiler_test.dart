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

  test('deck special values and named deck globs follow Core SQL', () {
    for (final (name, sql) in <(String, String)>[
      ('*', 'true'),
      ('filtered', 'c.odid != 0'),
    ]) {
      final compiled = compileSearchSql(GroupNode([Search(Deck(name))]));
      expect(compiled.sql, 'select c.id from cards c where ($sql)');
      expect(compiled.arguments, isEmpty);
      expect(compiled.requiredTable, RequiredTable.cards);
    }

    final glob = compileSearchSql(
      GroupNode([Search(Deck('Parent::Child*_*'))]),
    );
    expect(
      glob.sql,
      'select c.id from cards c where '
      '((c.did in (select id from decks where name regexp ?1) or '
      '(c.odid != 0 and c.odid in (select id from decks where name regexp ?1))))',
    );
    expect(glob.arguments, ['(?i)^Parent\x1fChild.*..*(\$|\x1f)']);
    expect(glob.requiredTable, RequiredTable.cards);

    final escaped = compileSearchSql(
      GroupNode([Search(Deck(r'Parent::A\*\_'))]),
    );
    expect(escaped.arguments, ['(?i)^Parent\x1fA\\*_(\$|\x1f)']);

    final childIncluded = compileSearchSql(GroupNode([Search(Deck('Parent'))]));
    expect(childIncluded.arguments, ['(?i)^Parent(\$|\x1f)']);
  });

  test('deck names normalize native paths component by component', () {
    final compiled = compileSearchSql(
      GroupNode([Search(Deck('  Cafe\u0301  ::  \u0001 : :  '))]),
    );
    expect(compiled.arguments, ['(?i)^Café\x1fblank(\$|\x1f)']);

    final controls = compileSearchSql(
      GroupNode([Search(Deck('  A\u0001B  :: \u0002 '))]),
    );
    expect(controls.arguments, ['(?i)^AB\x1fblank(\$|\x1f)']);

    final unicodeWhitespace = compileSearchSql(
      GroupNode([Search(Deck('\u0085Names\u00a0'))]),
    );
    expect(unicodeWhitespace.arguments, ['(?i)^Names(\$|\x1f)']);
  });

  test('current deck names use explicit input or Default fallback', () {
    final current = compileSearchSql(
      GroupNode([Search(Deck('current'))]),
      currentDeckName: 'Course\x1fToday*',
    );
    expect(current.arguments, ['(?i)^Course\x1fToday\\*(\$|\x1f)']);

    final fallback = compileSearchSql(GroupNode([Search(Deck('current'))]));
    expect(fallback.arguments, ['(?i)^Default(\$|\x1f)']);
  });

  test('deck predicates compose with cards, notes, and other searches', () {
    final cards = compileSearchSql(
      GroupNode([
        Search(Deck('Parent')),
        BooleanNode(NodeKind.and),
        Search(DeckIdsWithoutChildren('7')),
        BooleanNode(NodeKind.and),
        Search(State(StateKind.review)),
        BooleanNode(NodeKind.and),
        NegatedNode(Search(Deck('Hidden'))),
        BooleanNode(NodeKind.and),
        Search(const Property(operator: '>=', kind: StabilityProperty(1.2))),
      ]),
    );
    expect(cards.requiredTable, RequiredTable.cards);
    expect(cards.arguments, ['(?i)^Parent(\$|\x1f)', '(?i)^Hidden(\$|\x1f)']);
    expect(
      cards.sql,
      contains('c.did in (select id from decks where name regexp ?1)'),
    );
    expect(cards.sql, contains('c.did in (7)'));
    expect(cards.sql, contains('c.type in (2, 3)'));
    expect(cards.sql, contains('not (c.did in (select id from decks'));
    expect(cards.sql, contains("extract_fsrs_variable(c.data, 's') >= 1.2"));

    final notes = compileSearchSql(
      GroupNode([
        Search(Deck('Parent')),
        BooleanNode(NodeKind.and),
        Search(Notetype('Basic')),
        BooleanNode(NodeKind.and),
        Search(const Tag(tag: 'math', mode: FieldSearchMode.normal)),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(notes.sql, startsWith('select distinct n.id from cards c, notes n'));
    expect(notes.sql, contains('c.nid=n.id'));
    expect(notes.requiredTable, RequiredTable.cardsAndNotes);
    expect(notes.arguments, [
      '(?i)^Parent(\$|\x1f)',
      'Basic',
      r'(?i).* math(::| ).*',
    ]);
  });

  test('deck IDs with children use explicit ordered host expansions', () {
    final rootId = Int64.parseInt('9223372036854775807');
    final rootKey = BigInt.parse(rootId.toString());
    final compiled = compileSearchSql(
      GroupNode([Search(DeckIdWithChildren(rootId))]),
      deckIdsWithChildren: {
        rootKey: [
          BigInt.parse('9223372036854775807'),
          BigInt.from(8),
          BigInt.from(-9),
        ],
      },
    );

    expect(
      compiled.sql,
      'select c.id from cards c where (c.did in '
      '(9223372036854775807,8,-9))',
    );
    expect(compiled.arguments, isEmpty);
    expect(compiled.requiredTable, RequiredTable.cards);

    final missing = compileSearchSql(
      GroupNode([Search(DeckIdWithChildren(Int64(42)))]),
    );
    expect(missing.sql, 'select c.id from cards c where (false)');

    final empty = compileSearchSql(
      GroupNode([Search(DeckIdWithChildren(Int64(42)))]),
      deckIdsWithChildren: {BigInt.from(42): []},
    );
    expect(empty.sql, 'select c.id from cards c where (c.did in ())');
    expect(empty.arguments, isEmpty);
    expect(empty.sql, isNot(contains('odid')));
  });

  test(
    'deck IDs with children compose with boolean searches and note results',
    () {
      final deckId = Int64(17);
      final expansions = {
        BigInt.from(17): [BigInt.from(17), BigInt.from(19)],
      };
      final cards = compileSearchSql(
        GroupNode([
          Search(DeckIdWithChildren(deckId)),
          BooleanNode(NodeKind.and),
          Search(DeckIdsWithoutChildren('7')),
          BooleanNode(NodeKind.or),
          NegatedNode(Search(State(StateKind.review))),
        ]),
        deckIdsWithChildren: expansions,
      );
      expect(cards.requiredTable, RequiredTable.cards);
      expect(cards.arguments, isEmpty);
      expect(cards.sql, contains('c.did in (17,19)'));
      expect(cards.sql, contains('c.did in (7)'));
      expect(cards.sql, contains('not c.type in (2, 3)'));

      final notes = compileSearchSql(
        GroupNode([Search(DeckIdWithChildren(deckId))]),
        resultType: SearchResultType.notes,
        deckIdsWithChildren: expansions,
      );
      expect(
        notes.sql,
        startsWith('select distinct n.id from cards c, notes n'),
      );
      expect(notes.sql, contains('c.nid=n.id and (c.did in (17,19))'));
      expect(notes.requiredTable, RequiredTable.cardsAndNotes);
      expect(notes.arguments, isEmpty);
    },
  );

  test('preset names resolve only by exact config-name spelling', () {
    const composed = 'Café';
    const decomposed = 'Cafe\u0301';
    final resolved = compileSearchSql(
      GroupNode([Search(Preset(composed))]),
      deckIdsByPreset: {
        composed: [BigInt.from(12)],
        'café': [BigInt.from(13)],
        decomposed: [BigInt.from(14)],
      },
    );
    expect(
      resolved.sql,
      'select c.id from cards c where '
      '((c.did in (12) or c.odid in (12)))',
    );
    expect(resolved.arguments, isEmpty);
    expect(resolved.requiredTable, RequiredTable.cards);

    for (final missingName in ['Café ', 'café', 'Cafe\u0301']) {
      final missing = compileSearchSql(
        GroupNode([Search(Preset(missingName))]),
        deckIdsByPreset: {
          composed: [BigInt.from(12)],
        },
      );
      expect(missing.sql, 'select c.id from cards c where (false)');
      expect(missing.arguments, isEmpty);
    }
  });

  test(
    'preset SQL repeats exact ordered IDs for current and original decks',
    () {
      const presetName = 'Study';
      final ids = [
        BigInt.parse('-9223372036854775808'),
        BigInt.from(9),
        BigInt.parse('9223372036854775807'),
      ];
      final compiled = compileSearchSql(
        GroupNode([Search(const Preset(presetName))]),
        deckIdsByPreset: {presetName: ids},
      );
      const list = '-9223372036854775808,9,9223372036854775807';
      expect(
        compiled.sql,
        'select c.id from cards c where '
        '((c.did in ($list) or c.odid in ($list)))',
      );
      expect(compiled.arguments, isEmpty);

      final empty = compileSearchSql(
        GroupNode([Search(const Preset(presetName))]),
        deckIdsByPreset: {presetName: []},
      );
      expect(
        empty.sql,
        'select c.id from cards c where '
        '((c.did in () or c.odid in ()))',
      );
      expect(empty.sql, isNot(contains('false')));
      expect(empty.arguments, isEmpty);
    },
  );

  test(
    'preset predicates compose and retain cards and notes result shapes',
    () {
      final cards = compileSearchSql(
        GroupNode([
          Search(const Preset('Study')),
          BooleanNode(NodeKind.and),
          Search(Deck('Parent')),
          BooleanNode(NodeKind.and),
          Search(DeckIdsWithoutChildren('7')),
          BooleanNode(NodeKind.and),
          Search(State(StateKind.review)),
          BooleanNode(NodeKind.and),
          Search(const Tag(tag: 'math', mode: FieldSearchMode.normal)),
          BooleanNode(NodeKind.and),
          Search(const Property(operator: '>=', kind: StabilityProperty(1.2))),
        ]),
        deckIdsByPreset: {
          'Study': [BigInt.parse('9007199254740993')],
        },
      );
      expect(cards.requiredTable, RequiredTable.cardsAndNotes);
      expect(cards.sql, contains('c.did in (9007199254740993)'));
      expect(cards.sql, contains('c.odid in (9007199254740993)'));
      expect(cards.sql, contains('c.did in (7)'));
      expect(cards.sql, contains('c.type in (2, 3)'));
      expect(
        cards.sql,
        contains('extract_fsrs_variable(c.data, \'s\') >= 1.2'),
      );
      expect(cards.arguments, ['(?i)^Parent(\$|\x1f)', r'(?i).* math(::| ).*']);

      final notes = compileSearchSql(
        GroupNode([Search(const Preset('Study'))]),
        resultType: SearchResultType.notes,
        deckIdsByPreset: {
          'Study': [BigInt.from(4), BigInt.from(5)],
        },
      );
      expect(
        notes.sql,
        startsWith(
          'select distinct n.id from cards c, notes n where c.nid=n.id and ',
        ),
      );
      expect(notes.sql, endsWith('((c.did in (4,5) or c.odid in (4,5)))'));
      expect(notes.requiredTable, RequiredTable.cardsAndNotes);
      expect(notes.arguments, isEmpty);
    },
  );

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

  test(
    'regex searches use Core field exclusions and preserve regex syntax',
    () {
      final fallback = compileSearchSql(
        GroupNode([Search(const RegexSearch(r'^[a-z]+\d$'))]),
      );
      expect(
        fallback.sql,
        'select c.id from cards c, notes n where c.nid=n.id and '
        '(n.flds regexp ?1)',
      );
      expect(fallback.arguments, [r'(?i)^[a-z]+\d$']);
      expect(fallback.requiredTable, RequiredTable.cardsAndNotes);

      final explicit = compileSearchSql(
        GroupNode([Search(const RegexSearch(r'\w+'))]),
        regexFieldsByNotetype: RegexFieldsByNotetype([
          RegexNotetypeSearchContext(
            notetypeId: BigInt.parse('9007199254740993'),
            totalFieldsInNote: 3,
            includedFieldIndices: [0, 1, 2],
          ),
          RegexNotetypeSearchContext(
            notetypeId: BigInt.from(7),
            totalFieldsInNote: 4,
            includedFieldIndices: [3, 1],
          ),
          RegexNotetypeSearchContext(
            notetypeId: BigInt.from(8),
            totalFieldsInNote: 2,
            includedFieldIndices: [],
          ),
        ]),
      );
      expect(
        explicit.sql,
        'select c.id from cards c, notes n where c.nid=n.id and '
        '(((n.mid = 9007199254740993 and n.flds regexp ?1) or '
        '(n.mid = 7 and regexp_fields(?1, n.flds, 3,1)) or '
        '(n.mid = 8 and regexp_fields(?1, n.flds, ))))',
      );
      expect(explicit.arguments, [r'(?i)\w+']);
    },
  );

  test(
    'regex normalization, argument indices, and note projection are explicit',
    () {
      final pattern = 'Cafe\u0301.*';
      final unnormalized = compileSearchSql(
        GroupNode([
          Search(Notetype('Basic')),
          BooleanNode(NodeKind.and),
          GroupNode([
            Search(const RegexSearch('Cafe\u0301.*')),
            BooleanNode(NodeKind.or),
            NegatedNode(Search(const RegexSearch(r'\bword\b'))),
          ]),
        ]),
        resultType: SearchResultType.notes,
      );
      expect(
        unnormalized.sql,
        'select n.id from notes n where '
        '(n.mid in (select id from notetypes where name = ?) and '
        '(n.flds regexp ?2 or not n.flds regexp ?3))',
      );
      expect(unnormalized.arguments, [
        'Basic',
        '(?i)$pattern',
        r'(?i)\bword\b',
      ]);
      expect(unnormalized.requiredTable, RequiredTable.notes);

      final normalized = compileSearchSql(
        GroupNode([Search(RegexSearch(pattern))]),
        normalizeNoteText: true,
      );
      expect(normalized.arguments, [r'(?i)Café.*']);
    },
  );

  test(
    'unqualified text search matches Core SQL wildcard and note semantics',
    () {
      final plain = compileSearchSql(
        GroupNode([Search(const TextSearch(r'foo*bar\*baz%'))]),
        resultType: SearchResultType.notes,
      );
      expect(
        plain.sql,
        'select n.id from notes n where '
        "((n.sfld like ?1 escape '\\' or n.flds like ?1 escape '\\'))",
      );
      expect(plain.arguments, [r'%foo%bar*baz\%%']);
      expect(plain.requiredTable, RequiredTable.notes);

      final folded = compileSearchSql(
        GroupNode([Search(const TextSearch('Cafe\u0301'))]),
        textSearchContext: const SearchSqlTextContext(
          ignoreAccentsInSearch: true,
        ),
      );
      expect(folded.arguments, ['%Cafe%']);
      expect(
        folded.sql,
        'select c.id from cards c, notes n where c.nid=n.id and '
        "((coalesce(process_text(cast(n.sfld as text), 1), n.sfld) like ?1 escape '\\' or "
        "coalesce(process_text(n.flds, 1), n.flds) like ?1 escape '\\'))",
      );

      final normalized = compileSearchSql(
        GroupNode([Search(const TextSearch('Cafe\u0301'))]),
        normalizeNoteText: true,
      );
      expect(normalized.arguments, ['%Café%']);

      final composed = compileSearchSql(
        GroupNode([
          Search(const Notetype('Basic')),
          BooleanNode(NodeKind.and),
          Search(const TextSearch('front')),
        ]),
        resultType: SearchResultType.notes,
      );
      expect(
        composed.sql,
        'select n.id from notes n where '
        '(n.mid in (select id from notetypes where name = ?) and '
        "(n.sfld like ?2 escape '\\' or n.flds like ?2 escape '\\'))",
      );
      expect(composed.arguments, ['Basic', '%front%']);
    },
  );

  test('no-combining and cloze searches retain Core flags and field map', () {
    final noCombining = compileSearchSql(
      GroupNode([Search(const NoCombining('Café'))]),
    );
    expect(noCombining.arguments, ['%Cafe%']);
    expect(
      noCombining.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      "((coalesce(process_text(cast(n.sfld as text), 1), n.sfld) like ?1 escape '\\' or "
      "coalesce(process_text(n.flds, 1), n.flds) like ?1 escape '\\'))",
    );

    final stripClozes = compileSearchSql(
      GroupNode([Search(const StripClozes('café'))]),
      textSearchContext: SearchSqlTextContext(
        ignoreAccentsInSearch: true,
        clozeNotetypeIds: [BigInt.from(10), BigInt.from(11)],
        fieldsByNotetype: [
          TextNotetypeSearchContext(
            notetypeId: BigInt.from(10),
            totalFieldsInNote: 3,
            sortFieldExcluded: true,
            fieldRangesToSearch: [
              SearchableFieldRange(0, 1),
              SearchableFieldRange(2, 3),
            ],
          ),
        ],
      ),
    );
    expect(stripClozes.arguments, ['%cafe%']);
    expect(
      stripClozes.sql,
      'select c.id from cards c, notes n where c.nid=n.id and '
      '((n.mid = 10 or n.mid = 11) and '
      "((n.mid = 10 and (coalesce(process_text(n.flds, 3), n.flds) like '' || ?1 || '\u001f%\u001f%' escape '\\' or "
      "coalesce(process_text(n.flds, 3), n.flds) like '%\u001f%\u001f' || ?1 || '' escape '\\'))))",
    );

    final sortFieldVisible = compileSearchSql(
      GroupNode([Search(const TextSearch('x'))]),
      resultType: SearchResultType.notes,
      textSearchContext: SearchSqlTextContext(
        fieldsByNotetype: [
          TextNotetypeSearchContext(
            notetypeId: BigInt.from(22),
            totalFieldsInNote: 2,
            sortFieldExcluded: false,
            fieldRangesToSearch: [SearchableFieldRange(1, 2)],
          ),
        ],
      ),
    );
    expect(
      sortFieldVisible.sql,
      'select n.id from notes n where '
      "(((n.mid = 22 and (n.flds like '%\u001f' || ?1 || '' escape '\\' or n.sfld like ?1 escape '\\'))))",
    );

    final noClozeNoteTypes = compileSearchSql(
      GroupNode([Search(const StripClozes('x'))]),
      resultType: SearchResultType.notes,
      textSearchContext: const SearchSqlTextContext(),
    );
    expect(
      noClozeNoteTypes.sql,
      'select n.id from notes n where '
      "(() and (coalesce(process_text(cast(n.sfld as text), 2), n.sfld) like ?1 escape '\\' or coalesce(process_text(n.flds, 2), n.flds) like ?1 escape '\\'))",
    );

    expect(
      () => compileSearchSql(GroupNode([Search(const StripClozes('x'))])),
      throwsArgumentError,
    );
  });

  test('field-qualified searches resolve exact names and Anki globs', () {
    final context = SearchSqlFieldContext([
      SearchSqlNotetypeFields(
        notetypeId: BigInt.parse('9007199254740993'),
        fields: const [
          SearchSqlField(name: 'Name', ordinal: 0),
          SearchSqlField(name: 'Front', ordinal: 1),
          SearchSqlField(name: 'Back', ordinal: 2),
        ],
      ),
      SearchSqlNotetypeFields(
        notetypeId: BigInt.from(8),
        fields: const [
          SearchSqlField(name: 'Fíeld', ordinal: 0),
          SearchSqlField(name: 'Other', ordinal: 1),
        ],
      ),
    ]);

    final exact = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'front',
            text: 'hello*world',
            mode: FieldSearchMode.normal,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: context,
    );
    expect(
      exact.sql,
      'select n.id from notes n where '
      "(((n.mid = 9007199254740993 and (n.flds like '%\u001f' || ?1 || '\u001f%' escape '\\'))))",
    );
    expect(exact.arguments, ['hello%world']);
    final cardProjection = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'Front',
            text: 'x',
            mode: FieldSearchMode.normal,
          ),
        ),
      ]),
      fieldSearchContext: context,
    );
    expect(cardProjection.requiredTable, RequiredTable.cardsAndNotes);
    expect(
      cardProjection.sql,
      startsWith('select c.id from cards c, notes n where c.nid=n.id and '),
    );

    final escapedValue = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'Front',
            text: r'hello\*100%',
            mode: FieldSearchMode.normal,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: context,
    );
    expect(escapedValue.arguments, [r'hello*100\%']);

    final glob = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'F*',
            text: 'x',
            mode: FieldSearchMode.regex,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: context,
    );
    expect(
      glob.sql,
      'select n.id from notes n where '
      '(((n.mid = 8 and regexp_fields(?1, n.flds, 0)) or '
      '(n.mid = 9007199254740993 and regexp_fields(?1, n.flds, 1))))',
    );
    expect(glob.arguments, [r'(?i)x']);

    final unicodeName = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'FÍELD',
            text: '^a+\$',
            mode: FieldSearchMode.regex,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: context,
    );
    expect(
      unicodeName.sql,
      'select n.id from notes n where '
      '(((n.mid = 8 and regexp_fields(?1, n.flds, 0))))',
    );
    expect(unicodeName.arguments, [r'(?i)^a+$']);

    final normalized = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'Front',
            text: 'Cafe\u0301',
            mode: FieldSearchMode.regex,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: context,
      normalizeNoteText: true,
    );
    expect(normalized.arguments, [r'(?i)Café']);

    final numbered = compileSearchSql(
      GroupNode([
        Search(const Notetype('Basic')),
        BooleanNode(NodeKind.and),
        Search(
          const SingleFieldSearch(
            field: 'Front',
            text: 'x',
            mode: FieldSearchMode.regex,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: context,
    );
    expect(numbered.arguments, ['Basic', r'(?i)x']);
    expect(numbered.sql, contains('regexp_fields(?2, n.flds, 1)'));
  });

  test('field search all-field aliases and no-combining follow Core modes', () {
    final fields = SearchSqlFieldContext([
      SearchSqlNotetypeFields(
        notetypeId: BigInt.from(1),
        fields: const [
          SearchSqlField(name: 'Front', ordinal: 0),
          SearchSqlField(name: 'Front Extra', ordinal: 1),
          SearchSqlField(name: 'Back', ordinal: 2),
        ],
      ),
    ]);
    final allFields = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: '_*',
            text: 'foo*bar',
            mode: FieldSearchMode.noCombining,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: fields,
    );
    expect(
      allFields.sql,
      'select n.id from notes n where (regexp_fields(?1, n.flds))',
    );
    expect(allFields.arguments, [r'(?is)^foo.*bar$']);

    final regexAllFields = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: '*_',
            text: r'^foo$',
            mode: FieldSearchMode.regex,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
    );
    expect(
      regexAllFields.sql,
      'select n.id from notes n where (regexp_fields(?1, n.flds))',
    );
    expect(regexAllFields.arguments, [r'(?i)^foo$']);

    final noCombining = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'Front',
            text: 'Café',
            mode: FieldSearchMode.noCombining,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: fields,
    );
    expect(noCombining.arguments, ['Cafe']);
    expect(
      noCombining.sql,
      'select n.id from notes n where '
      "(((n.mid = 1 and (coalesce(process_text(n.flds, 1), n.flds) like '' || ?1 || '\u001f%\u001f%' escape '\\'))))",
    );

    final missing = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'Missing',
            text: 'x',
            mode: FieldSearchMode.normal,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: fields,
    );
    expect(missing.sql, 'select n.id from notes n where (false)');
    expect(missing.arguments, isEmpty);

    expect(
      () => compileSearchSql(
        GroupNode([
          Search(
            const SingleFieldSearch(
              field: 'Front',
              text: 'x',
              mode: FieldSearchMode.normal,
            ),
          ),
        ]),
      ),
      throwsArgumentError,
    );

    final nonempty = compileSearchSql(
      GroupNode([
        Search(
          const SingleFieldSearch(
            field: 'F*',
            text: '*',
            mode: FieldSearchMode.normal,
          ),
        ),
      ]),
      resultType: SearchResultType.notes,
      fieldSearchContext: fields,
    );
    expect(
      nonempty.sql,
      'select n.id from notes n where '
      "(((n.mid = 1 and (n.flds like '' || ?1 || '\u001f%\u001f%' escape '\\' or n.flds like '%\u001f' || ?1 || '\u001f%' escape '\\'))))",
    );
    expect(nonempty.arguments, ['%']);
  });

  test('word-boundary search delegates Core regex matching and text flags', () {
    final basic = compileSearchSql(
      GroupNode([Search(const WordBoundary('foo*bar'))]),
      resultType: SearchResultType.notes,
    );
    expect(basic.sql, 'select n.id from notes n where (n.flds regexp ?1)');
    expect(basic.arguments, [r'(?i)\bfoo.*bar\b']);
    expect(basic.requiredTable, RequiredTable.notes);

    final normalized = compileSearchSql(
      GroupNode([
        Search(const Notetype('Basic')),
        BooleanNode(NodeKind.and),
        Search(const WordBoundary('Cafe\u0301')),
      ]),
      resultType: SearchResultType.notes,
      regexFieldsByNotetype: RegexFieldsByNotetype([
        RegexNotetypeSearchContext(
          notetypeId: BigInt.parse('9007199254740993'),
          totalFieldsInNote: 3,
          includedFieldIndices: [0, 2],
        ),
      ]),
      normalizeNoteText: true,
      textSearchContext: const SearchSqlTextContext(
        ignoreAccentsInSearch: true,
      ),
    );
    expect(
      normalized.sql,
      'select n.id from notes n where '
      '(n.mid in (select id from notetypes where name = ?) and '
      '((n.mid = 9007199254740993 and '
      'regexp_fields(?2, coalesce(process_text(n.flds, 1), n.flds), 0,2))))',
    );
    expect(normalized.arguments, ['Basic', r'(?i)\bCafe\b']);
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

  test('rated search uses signed day cutoffs and answer ease classes', () {
    const nextDayAt = 1700000000;
    final timing = SearchSqlTiming(
      daysElapsed: 0,
      now: BigInt.from(nextDayAt),
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(nextDayAt),
    );

    for (final (query, days, easeSql) in <(String, int, String)>[
      ('rated:2', -2, ' and ease > 0'),
      ('rated:0:1', -1, ' and ease = 1'),
      ('rated:1:4', -1, ' and ease = 4'),
    ]) {
      final target = BigInt.from(nextDayAt + 86400 * days) * BigInt.from(1000);
      final before =
          BigInt.from(nextDayAt + 86400 * (days - 1)) * BigInt.from(1000);
      final compiled = compileSearchSql(
        GroupNode(parse(query)),
        timing: timing,
      );
      expect(
        compiled.sql,
        'select c.id from cards c where (c.id in '
        '(select cid from revlog where id >= $target$easeSql))',
        reason: query,
      );
      expect(compiled.arguments, isEmpty);
      expect(compiled.requiredTable, RequiredTable.cards);
      expect(before < target, isTrue);
    }

    final parsedZero = compileSearchSql(
      GroupNode(parse('rated:0:1')),
      timing: timing,
    );
    final astZero = compileSearchSql(
      GroupNode([Search(const Rated(days: 0, ease: AnswerButton(1)))]),
      timing: timing,
    );
    expect(astZero.sql, parsedZero.sql);
    expect(astZero.requiredTable, RequiredTable.cards);

    final parsedReschedZero = compileSearchSql(
      GroupNode(parse('resched:0')),
      timing: timing,
    );
    final astReschedZero = compileSearchSql(
      GroupNode([Search(const Rated(days: 0, ease: ManualReschedule()))]),
      timing: timing,
    );
    expect(astReschedZero.sql, parsedReschedZero.sql);

    final notes = compileSearchSql(
      GroupNode(parse('rated:3:2')),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      notes.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(c.id in (select cid from revlog where id >= '
      '${(BigInt.from(nextDayAt) - BigInt.from(3 * 86400)) * BigInt.from(1000)} '
      'and ease = 2))',
    );
    expect(notes.requiredTable, RequiredTable.cardsAndNotes);

    expect(
      () => compileSearchSql(GroupNode(parse('rated:1'))),
      throwsArgumentError,
      reason: 'rated predicates require explicit rollover timing',
    );
    expect(
      () => parse('rated:4294967296'),
      throwsA(isA<SearchParseException>()),
    );
    expect(
      () => compileSearchSql(
        GroupNode(parse('rated:4294967295')),
        timing: timing,
      ),
      returnsNormally,
    );
    expect(
      () => compileSearchSql(
        GroupNode(parse('rated:1')),
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
          nextDayAt: BigInt.parse('9223372036854775807'),
        ),
      ),
      throwsRangeError,
    );
  });

  test('rated property operators, signed days, and nesting match Core', () {
    const nextDayAt = 1700000000;
    final timing = SearchSqlTiming(
      daysElapsed: 0,
      now: BigInt.from(nextDayAt),
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(nextDayAt),
    );

    final target = BigInt.from(nextDayAt - 2 * 86400) * BigInt.from(1000);
    final before = BigInt.from(nextDayAt - 3 * 86400) * BigInt.from(1000);
    final cases = <(String, String)>[
      ('prop:rated>-2:1', 'id >= $target and ease = 1'),
      ('prop:rated>=-2:2', 'id >= $before and ease = 2'),
      ('prop:rated<-2:3', 'id < $before and ease = 3'),
      ('prop:rated<=-2:4', 'id < $target and ease = 4'),
      (
        'prop:rated=-2',
        'id between $before and ${target - BigInt.one} and ease > 0',
      ),
      (
        'prop:rated!=-2',
        'id not between $before and ${target - BigInt.one} and ease > 0',
      ),
      (
        'prop:resched=-2',
        'id between $before and ${target - BigInt.one} and ease = 0',
      ),
    ];
    for (final (query, predicate) in cases) {
      final compiled = compileSearchSql(
        GroupNode(parse(query)),
        timing: timing,
      );
      expect(
        compiled.sql,
        'select c.id from cards c where '
        '(c.id in (select cid from revlog where $predicate))',
        reason: query,
      );
      expect(compiled.arguments, isEmpty);
      expect(compiled.requiredTable, RequiredTable.cards);
    }

    final zeroDays = compileSearchSql(
      GroupNode(parse('prop:rated=-0:3')),
      timing: timing,
    );

    final positiveDays = compileSearchSql(
      GroupNode([
        Search(
          const Property(
            operator: '>=',
            kind: RatedProperty(1, AnswerButton(2)),
          ),
        ),
      ]),
      timing: timing,
    );
    expect(
      positiveDays.sql,
      'select c.id from cards c where '
      '(c.id in (select cid from revlog where id >= '
      '${BigInt.from(nextDayAt) * BigInt.from(1000)} and ease = 2))',
    );
    expect(
      zeroDays.sql,
      'select c.id from cards c where '
      '(c.id in (select cid from revlog where id between '
      '${BigInt.from(nextDayAt - 86400) * BigInt.from(1000)} and '
      '${BigInt.from(nextDayAt) * BigInt.from(1000) - BigInt.one} and ease = 3))',
    );

    final nested = compileSearchSql(
      GroupNode([
        Search(CustomData('due')),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(
            const Property(
              operator: '>=',
              kind: RatedProperty(-1, AnswerButton(2)),
            ),
          ),
          BooleanNode(NodeKind.or),
          Search(
            const Property(
              operator: '=',
              kind: RatedProperty(-1, ManualReschedule()),
            ),
          ),
        ]),
      ]),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      nested.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(extract_custom_data(c.data, ?) is not null and '
      '(c.id in (select cid from revlog where id >= '
      '${BigInt.from(nextDayAt - 2 * 86400) * BigInt.from(1000)} and ease = 2) or '
      'c.id in (select cid from revlog where id between '
      '${BigInt.from(nextDayAt - 2 * 86400) * BigInt.from(1000)} and '
      '${BigInt.from(nextDayAt - 86400) * BigInt.from(1000) - BigInt.one} '
      'and ease = 0)))',
    );
    expect(nested.arguments, ['due']);
    expect(nested.requiredTable, RequiredTable.cardsAndNotes);

    expect(() => parse('prop:rated>1'), throwsA(isA<SearchParseException>()));
    expect(
      () => parse('prop:rated>-2147483648:5'),
      throwsA(isA<SearchParseException>()),
    );
    expect(
      () => parse('prop:rated>-2147483649'),
      throwsA(isA<SearchParseException>()),
    );
    expect(
      () => compileSearchSql(
        GroupNode([
          Search(
            const Property(
              operator: '=',
              kind: RatedProperty(2147483648, AnyAnswerButton()),
            ),
          ),
        ]),
        timing: timing,
      ),
      throwsRangeError,
    );
  });

  test('due properties use explicit day timing and Core queue branches', () {
    final timing = SearchSqlTiming(
      daysElapsed: 42,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(1700000000),
    );

    for (final operator in const ['<=', '>=', '!=', '=', '<', '>']) {
      final compiled = compileSearchSql(
        GroupNode(parse('prop:due$operator-2')),
        timing: timing,
      );
      expect(
        compiled.sql,
        'select c.id from cards c where '
        '(((c.queue in (2,3) and (case when c.odue != 0 then c.odue else c.due end) '
        '$operator 40) or (c.queue in (1,4) and '
        '(((case when c.odue != 0 then c.odue else c.due end) - 1700000000) '
        '/ 86400) $operator -2)))',
        reason: operator,
      );
      expect(compiled.arguments, isEmpty);
      expect(compiled.requiredTable, RequiredTable.cards);
    }

    expect(
      () => compileSearchSql(GroupNode(parse('prop:due=0'))),
      throwsArgumentError,
      reason: 'due properties cannot read collection timing implicitly',
    );
    expect(
      () => compileSearchSql(
        GroupNode(parse('prop:due=0')),
        timing: SearchSqlTiming(
          daysElapsed: 42,
          now: BigInt.zero,
          learnAheadSecs: 0,
        ),
      ),
      throwsArgumentError,
      reason: 'learning due comparisons require the explicit rollover cutoff',
    );

    final notes = compileSearchSql(
      GroupNode(parse('prop:due<=0')),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      notes.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(((c.queue in (2,3) and (case when c.odue != 0 then c.odue else c.due end) '
      '<= 42) or (c.queue in (1,4) and '
      '(((case when c.odue != 0 then c.odue else c.due end) - 1700000000) '
      '/ 86400) <= 0)))',
    );
    expect(notes.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('position, interval, reps, and lapses match Core SQL and operators', () {
    const operators = ['<=', '>=', '!=', '=', '<', '>'];
    final properties = <(String, String, String)>[
      (
        'pos',
        'PositionProperty',
        'c.type = 0 and (case when c.odue != 0 then c.odue else c.due end)',
      ),
      ('ivl', 'IntervalProperty', 'ivl'),
      ('reps', 'RepsProperty', 'reps'),
      ('lapses', 'LapsesProperty', 'lapses'),
    ];
    for (final (name, _, left) in properties) {
      for (final operator in operators) {
        final compiled = compileSearchSql(
          GroupNode(parse('prop:$name${operator}4')),
        );
        final predicate = name == 'pos'
            ? '($left $operator 4)'
            : '$left $operator 4';
        expect(
          compiled.sql,
          'select c.id from cards c where ($predicate)',
          reason: '$name $operator',
        );
        expect(compiled.arguments, isEmpty);
        expect(compiled.requiredTable, RequiredTable.cards);
      }
    }

    final noteResults = compileSearchSql(
      GroupNode(parse('prop:pos<9')),
      resultType: SearchResultType.notes,
    );
    expect(
      noteResults.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '((c.type = 0 and (case when c.odue != 0 then c.odue else c.due end) < 9))',
    );
    expect(noteResults.requiredTable, RequiredTable.cardsAndNotes);

    expect(
      () => compileSearchSql(
        GroupNode([
          Search(const Property(operator: '=', kind: PositionProperty(-1))),
        ]),
      ),
      throwsRangeError,
    );
  });

  test('ease properties round as float32 and cast to unsigned 32-bit', () {
    for (final (value, expected) in <(double, String)>[
      (0.1, 'factor = 100'),
      (1.0009999999, 'factor = 1001'),
      (0.0004, 'factor = 0'),
      (-2.5, 'factor = 0'),
      (double.nan, 'factor = 0'),
      (double.infinity, 'factor = 4294967295'),
      (4294968.0, 'factor = 4294967295'),
    ]) {
      final dynamicCompiled = compileSearchSql(
        GroupNode([Search(Property(operator: '=', kind: EaseProperty(value)))]),
      );
      expect(dynamicCompiled.sql, endsWith('$expected)'));
      expect(dynamicCompiled.requiredTable, RequiredTable.cards);
    }

    for (final operator in const ['<=', '>=', '!=', '=', '<', '>']) {
      final compiled = compileSearchSql(
        GroupNode(parse('prop:ease${operator}0.1')),
      );
      expect(compiled.sql, endsWith('factor $operator 100)'));
    }

    expect(
      () => compileSearchSql(
        GroupNode([
          Search(const Property(operator: 'or 1 --', kind: EaseProperty(1))),
        ]),
      ),
      throwsArgumentError,
    );
  });

  test('scalar properties preserve nested boolean composition', () {
    final timing = SearchSqlTiming(
      daysElapsed: 10,
      now: BigInt.zero,
      learnAheadSecs: 0,
      nextDayAt: BigInt.from(1700000000),
    );
    final compiled = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'blue', mode: FieldSearchMode.normal)),
        BooleanNode(NodeKind.and),
        GroupNode([
          Search(const Property(operator: '>=', kind: IntervalProperty(3))),
          BooleanNode(NodeKind.or),
          Search(
            const Property(
              operator: '=',
              kind: CustomDataStringProperty(key: 'label', value: 'again'),
            ),
          ),
          BooleanNode(NodeKind.or),
          Search(
            const Property(
              operator: '>',
              kind: RatedProperty(-1, AnyAnswerButton()),
            ),
          ),
        ]),
      ]),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      compiled.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.tags regexp ? and '
      '(ivl >= 3 or extract_custom_data(c.data, ?) = ? or '
      'c.id in (select cid from revlog where id >= '
      '${BigInt.from(1700000000 - 86400) * BigInt.from(1000)} and ease > 0)))',
    );
    expect(compiled.arguments, ['(?i).* blue(::| ).*', 'label', 'again']);
    expect(compiled.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('FSRS stability and difficulty properties match Core formatting', () {
    const operators = ['<=', '>=', '!=', '=', '<', '>'];
    for (final operator in operators) {
      final stability = compileSearchSql(
        GroupNode(parse('prop:s${operator}1.25')),
      );
      expect(
        stability.sql,
        'select c.id from cards c where '
        '(extract_fsrs_variable(c.data, \'s\') $operator 1.25)',
        reason: 'stability $operator',
      );
      expect(stability.arguments, isEmpty);
      expect(stability.requiredTable, RequiredTable.cards);

      final difficulty = compileSearchSql(
        GroupNode(parse('prop:d${operator}2.5')),
      );
      expect(
        difficulty.sql,
        'select c.id from cards c where '
        '(extract_fsrs_variable(c.data, \'d\') $operator 23.5)',
        reason: 'difficulty $operator',
      );
      expect(difficulty.arguments, isEmpty);
      expect(difficulty.requiredTable, RequiredTable.cards);
    }

    final rounded = compileSearchSql(GroupNode(parse('prop:s=1.23456789')));
    expect(
      rounded.sql,
      'select c.id from cards c where '
      '(extract_fsrs_variable(c.data, \'s\') = 1.2345679)',
    );
    expect(
      compileSearchSql(GroupNode(parse('prop:s=1e-8'))).sql,
      'select c.id from cards c where '
      '(extract_fsrs_variable(c.data, \'s\') = 0.00000001)',
    );
    expect(
      compileSearchSql(GroupNode(parse('prop:s=inf'))).sql,
      'select c.id from cards c where '
      '(extract_fsrs_variable(c.data, \'s\') = inf)',
    );
    expect(
      compileSearchSql(GroupNode(parse('prop:d=nan'))).sql,
      'select c.id from cards c where '
      '(extract_fsrs_variable(c.data, \'d\') = NaN)',
    );
    expect(
      compileSearchSql(GroupNode(parse('prop:d=0.1'))).sql,
      'select c.id from cards c where '
      '(extract_fsrs_variable(c.data, \'d\') = 1.9000001)',
    );
    expect(
      compileSearchSql(GroupNode(parse('prop:s=3.4028235e38'))).sql,
      'select c.id from cards c where '
      '(extract_fsrs_variable(c.data, \'s\') = '
      '340282350000000000000000000000000000000)',
    );

    expect(
      () => compileSearchSql(
        GroupNode([
          Search(
            const Property(operator: 'or 1 --', kind: StabilityProperty(1.0)),
          ),
        ]),
      ),
      throwsArgumentError,
    );
  });

  test('FSRS retrievability uses Core timing and New-card behavior', () {
    final timing = SearchSqlTiming(
      daysElapsed: 42,
      now: BigInt.from(1700000030),
      learnAheadSecs: 30,
      nextDayAt: BigInt.from(1700000000),
    );
    const operators = ['<=', '>=', '!=', '=', '<', '>'];
    for (final operator in operators) {
      final compiled = compileSearchSql(
        GroupNode(parse('prop:r${operator}0.75')),
        timing: timing,
      );
      expect(
        compiled.sql,
        'select c.id from cards c where '
        '(case when c.type = 0 then false else '
        '(extract_fsrs_retrievability(c.data, '
        'case when c.odue !=0 then c.odue else c.due end, c.ivl, '
        '42, 1700000000, 1700000030) $operator 0.75) end)',
        reason: 'retrievability $operator',
      );
      expect(compiled.arguments, isEmpty);
      expect(compiled.requiredTable, RequiredTable.cards);
    }

    final notes = compileSearchSql(
      GroupNode([
        Search(const Tag(tag: 'blue', mode: FieldSearchMode.normal)),
        BooleanNode(NodeKind.and),
        GroupNode([
          NegatedNode(
            Search(
              const Property(operator: '>=', kind: RetrievabilityProperty(0.5)),
            ),
          ),
          BooleanNode(NodeKind.or),
          Search(const Property(operator: '=', kind: IntervalProperty(3))),
        ]),
      ]),
      resultType: SearchResultType.notes,
      timing: timing,
    );
    expect(
      notes.sql,
      'select distinct n.id from cards c, notes n where c.nid=n.id and '
      '(n.tags regexp ? and '
      '(not case when c.type = 0 then false else '
      '(extract_fsrs_retrievability(c.data, '
      'case when c.odue !=0 then c.odue else c.due end, c.ivl, '
      '42, 1700000000, 1700000030) >= 0.5) end or ivl = 3))',
    );
    expect(notes.arguments, ['(?i).* blue(::| ).*']);
    expect(notes.requiredTable, RequiredTable.cardsAndNotes);
  });

  test('FSRS retrievability validates explicit timing and Core ranges', () {
    final query = GroupNode(parse('prop:r>0.5'));
    expect(() => compileSearchSql(query), throwsArgumentError);
    expect(
      () => compileSearchSql(
        query,
        timing: SearchSqlTiming(
          daysElapsed: 0,
          now: BigInt.zero,
          learnAheadSecs: 0,
        ),
      ),
      throwsArgumentError,
    );

    final validNow = BigInt.from(1700000000);
    final validNextDay = BigInt.from(1700000000);
    for (final timing in <SearchSqlTiming>[
      SearchSqlTiming(
        daysElapsed: -1,
        now: validNow,
        learnAheadSecs: 0,
        nextDayAt: validNextDay,
      ),
      SearchSqlTiming(
        daysElapsed: 4294967296,
        now: validNow,
        learnAheadSecs: 0,
        nextDayAt: validNextDay,
      ),
      SearchSqlTiming(
        daysElapsed: 0,
        now: BigInt.parse('9223372036854775808'),
        learnAheadSecs: 0,
        nextDayAt: validNextDay,
      ),
      SearchSqlTiming(
        daysElapsed: 0,
        now: validNow,
        learnAheadSecs: 0,
        nextDayAt: BigInt.parse('-9223372036854775809'),
      ),
    ]) {
      expect(() => compileSearchSql(query, timing: timing), throwsRangeError);
    }
  });
}
