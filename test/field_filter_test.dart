/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('FilterContext', () {
    test('copy and Kotlin data-class value behavior', () {
      const original = FilterContext(isClozeNoteType: true);
      final changed = original.copyWith(producesHtml: true, isTerminal: true);
      const equivalent = FilterContext(
        isClozeNoteType: true,
        producesHtml: true,
        isTerminal: true,
      );

      expect(original.producesHtml, isFalse);
      expect(changed, equivalent);
      expect(changed.hashCode, equivalent.hashCode);
      expect(
        changed.toString(),
        'FilterContext(isClozeNoteType=true, producesHtml=true, '
        'stripsAnkiPronunciationSyntax=false, isTerminal=true, '
        'producesTypeMarker=false)',
      );
    });
  });

  group('FieldFilter defaults and built-ins', () {
    test('default contract only rejects terminal contexts', () {
      const filter = _TestFilter('custom');
      const context = FilterContext(isClozeNoteType: false);
      const terminal = FilterContext(isClozeNoteType: false, isTerminal: true);

      expect(filter.canApplyTo(context), isTrue);
      expect(filter.canApplyTo(terminal), isFalse);
      expect(filter.updateContext(context), same(context));
      expect(filter.render(), 'custom');
      expect(filter.isValid, isTrue);
    });

    test('built-in names, gates, and context transitions match source', () {
      const base = FilterContext(isClozeNoteType: false);
      const cloze = FilterContext(isClozeNoteType: true);
      const html = FilterContext(isClozeNoteType: true, producesHtml: true);
      const terminal = FilterContext(isClozeNoteType: true, isTerminal: true);
      const typed = FilterContext(
        isClozeNoteType: false,
        isTerminal: true,
        producesTypeMarker: true,
      );
      const pronunciation = FilterContext(
        isClozeNoteType: true,
        stripsAnkiPronunciationSyntax: true,
      );

      expect(
        [
          FieldFilters.text.name,
          FieldFilters.cloze.name,
          FieldFilters.clozeOnly.name,
          FieldFilters.hint.name,
          FieldFilters.type.name,
          FieldFilters.typeNonCombining.name,
          FieldFilters.noSuggest.name,
          FieldFilters.furigana.name,
          FieldFilters.kana.name,
          FieldFilters.kanji.name,
        ],
        [
          'text',
          'cloze',
          'cloze-only',
          'hint',
          'type',
          'type:nc',
          'nosuggest',
          'furigana',
          'kana',
          'kanji',
        ],
      );

      expect(FieldFilters.text.canApplyTo(base), isTrue);
      expect(FieldFilters.text.canApplyTo(html), isFalse);
      expect(FieldFilters.cloze.canApplyTo(base), isFalse);
      expect(FieldFilters.clozeOnly.canApplyTo(base), isFalse);
      expect(FieldFilters.clozeOnly.canApplyTo(cloze), isTrue);
      expect(FieldFilters.hint.updateContext(base).producesHtml, isTrue);
      expect(FieldFilters.type.updateContext(base), typed);
      expect(FieldFilters.typeNonCombining.updateContext(base), typed);
      expect(FieldFilters.noSuggest.canApplyTo(typed), isTrue);
      expect(FieldFilters.noSuggest.canApplyTo(terminal), isFalse);
      expect(FieldFilters.noSuggest.updateContext(typed), same(typed));
      for (final filter in [
        FieldFilters.furigana,
        FieldFilters.kana,
        FieldFilters.kanji,
      ]) {
        expect(filter.canApplyTo(pronunciation), isFalse, reason: filter.name);
        expect(filter.canApplyTo(terminal), isFalse, reason: filter.name);
        expect(
          filter.updateContext(base).stripsAnkiPronunciationSyntax,
          isTrue,
        );
      }
      expect(FieldFilters.furigana.updateContext(base).producesHtml, isTrue);
      expect(FieldFilters.kana.updateContext(base).producesHtml, isFalse);
      expect(FieldFilters.text.canApplyTo(terminal), isFalse);
    });
  });

  group('NoSuggestFilter.apply', () {
    const noSuggest = FieldFilters.noSuggest;

    test(
      'applies only for exact filter name when type markers are present',
      () {
        const source = 'before [[type:first]] middle [[type:second]] after';

        expect(
          noSuggest.apply(source, 'Front', 'nosuggest'),
          'before [[type:nosuggest:first]] middle '
          '[[type:nosuggest:second]] after',
        );
        expect(noSuggest.apply(source, 'Front', 'NoSuggest'), source);
        expect(
          noSuggest.apply('plain text', 'Front', 'nosuggest'),
          'plain text',
        );
      },
    );

    test('does not double-transform existing no-suggest markers', () {
      const source = '[[type:nosuggest:first]] and [[type:second]]';

      expect(noSuggest.apply(source, 'Front', 'nosuggest'), source);
    });
  });
}

final class _TestFilter extends FieldFilter {
  const _TestFilter(this.name);

  @override
  final String name;
}
