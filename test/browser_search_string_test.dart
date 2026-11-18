/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: SearchRequestTest.kt, SearchRequest.kt, SearchFilters.kt,
 * and Collection.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:test/test.dart';

void main() {
  group('browserSearchString', () {
    test('writes empty and trimmed query requests canonically', () {
      expect(
        browserSearchString(const BrowserSearchRequest(query: '')),
        'deck:*',
      );
      expect(
        browserSearchString(
          const BrowserSearchRequest(query: '\u00a0 hello \u00a0'),
        ),
        'hello',
      );
      expect(
        browserSearchString(const BrowserSearchRequest(query: ' \u0085 ')),
        'deck:*',
      );
    });

    test('preserves query and category order with nested boolean groups', () {
      final request = BrowserSearchRequest(
        query: 'hello',
        filters: BrowserSearchFilters(
          decks: [
            BrowserDeckNameId(name: 'Default', id: 1),
            BrowserDeckNameId(name: 'Other', id: 2),
          ],
          flags: [1, 4],
          tags: ['one', 'two'],
          noteTypes: [
            BrowserNoteTypeNameId(name: 'Basic', id: 3),
            BrowserNoteTypeNameId(name: 'Cloze', id: 4),
          ],
          cardStateCodes: [0, 1, 2, 3, 4],
        ),
      );

      expect(
        browserSearchString(request),
        '(hello (deck:Default OR deck:Other) (flag:1 OR flag:4) '
        '(tag:one OR tag:two) (note:Basic OR note:Cloze) '
        '(is:new OR is:learn OR is:review OR is:buried OR is:suspended))',
      );
    });

    test('writes each persisted flag and state code', () {
      expect(
        browserSearchString(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(flags: [0, 1, 2, 3, 4, 5, 6, 7]),
          ),
        ),
        '(flag:0 OR flag:1 OR flag:2 OR flag:3 OR flag:4 OR flag:5 OR flag:6 OR flag:7)',
      );
      expect(
        browserSearchString(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(cardStateCodes: [0, 1, 2, 3, 4]),
          ),
        ),
        '(is:new OR is:learn OR is:review OR is:buried OR is:suspended)',
      );
    });

    test('uses shared escaping and canonical quoting for names', () {
      expect(
        browserSearchString(
          BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(
              decks: [BrowserDeckNameId(name: r'A_B*', id: 1)],
              tags: [r'tag*'],
              noteTypes: [BrowserNoteTypeNameId(name: 'Basic (old)', id: 2)],
            ),
          ),
        ),
        r'(deck:A\_B\* tag:tag\* "note:Basic (old)")',
      );
      expect(
        browserSearchString(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(
              decks: [BrowserDeckNameId(name: '_*', id: 1)],
            ),
          ),
        ),
        'deck:_*',
      );
    });

    test('reports invalid search syntax and persisted semantic codes', () {
      expect(
        () => browserSearchString(const BrowserSearchRequest(query: '(')),
        throwsA(isA<SearchParseException>()),
      );
      expect(
        () => browserSearchString(const BrowserSearchRequest(query: 'and')),
        throwsA(
          isA<SearchParseException>().having(
            (error) => error.code,
            'code',
            SearchErrorCode.misplacedAnd,
          ),
        ),
      );
      expect(
        () => browserSearchString(const BrowserSearchRequest(query: 'or')),
        throwsA(
          isA<SearchParseException>().having(
            (error) => error.code,
            'code',
            SearchErrorCode.misplacedOr,
          ),
        ),
      );
      expect(
        () => browserSearchString(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(flags: [8]),
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => browserSearchString(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(cardStateCodes: [5]),
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
