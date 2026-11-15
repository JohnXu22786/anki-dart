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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapts TypeAnswerModifiersTest.kt and source-derived parser edge cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TypeAnswerModifiers.parse', () {
    test('parses a bare field with source defaults', () {
      expect(
        TypeAnswerModifiers.parse('Back'),
        const TypeAnswerModifiers(
          fieldName: 'Back',
          combining: true,
          cloze: false,
          noSuggest: false,
        ),
      );
    });

    test('parses nc only', () {
      expect(
        TypeAnswerModifiers.parse('nc:Back'),
        const TypeAnswerModifiers(
          fieldName: 'Back',
          combining: false,
          cloze: false,
          noSuggest: false,
        ),
      );
    });

    test('parses cloze only', () {
      expect(
        TypeAnswerModifiers.parse('cloze:Text'),
        const TypeAnswerModifiers(
          fieldName: 'Text',
          combining: true,
          cloze: true,
          noSuggest: false,
        ),
      );
    });

    test('parses nosuggest only', () {
      expect(
        TypeAnswerModifiers.parse('nosuggest:Back'),
        const TypeAnswerModifiers(
          fieldName: 'Back',
          combining: true,
          cloze: false,
          noSuggest: true,
        ),
      );
    });

    test('parses nosuggest with nc', () {
      expect(
        TypeAnswerModifiers.parse('nosuggest:nc:Back'),
        const TypeAnswerModifiers(
          fieldName: 'Back',
          combining: false,
          cloze: false,
          noSuggest: true,
        ),
      );
    });

    test('parses nosuggest with cloze', () {
      expect(
        TypeAnswerModifiers.parse('nosuggest:cloze:Text'),
        const TypeAnswerModifiers(
          fieldName: 'Text',
          combining: true,
          cloze: true,
          noSuggest: true,
        ),
      );
    });

    test('parses nc and nosuggest in either order', () {
      const expected = TypeAnswerModifiers(
        fieldName: 'Back',
        combining: false,
        cloze: false,
        noSuggest: true,
      );

      expect(TypeAnswerModifiers.parse('nosuggest:nc:Back'), expected);
      expect(TypeAnswerModifiers.parse('nc:nosuggest:Back'), expected);
    });

    test('parses cloze then nc', () {
      expect(
        TypeAnswerModifiers.parse('cloze:nc:Text'),
        const TypeAnswerModifiers(
          fieldName: 'Text',
          combining: false,
          cloze: true,
          noSuggest: false,
        ),
      );
    });

    test('parses nc then cloze', () {
      expect(
        TypeAnswerModifiers.parse('nc:cloze:Text'),
        const TypeAnswerModifiers(
          fieldName: 'Text',
          combining: false,
          cloze: true,
          noSuggest: false,
        ),
      );
    });

    test('accepts an empty field with defaults', () {
      expect(
        TypeAnswerModifiers.parse(''),
        const TypeAnswerModifiers(
          fieldName: '',
          combining: true,
          cloze: false,
          noSuggest: false,
        ),
      );
    });

    test('stops at an unknown prefix and preserves the remainder', () {
      expect(
        TypeAnswerModifiers.parse('nc: Unknown:nosuggest:Tail'),
        const TypeAnswerModifiers(
          fieldName: ' Unknown:nosuggest:Tail',
          combining: false,
          cloze: false,
          noSuggest: false,
        ),
      );
      expect(
        TypeAnswerModifiers.parse('unknown:nc:Back'),
        const TypeAnswerModifiers(
          fieldName: 'unknown:nc:Back',
          combining: true,
          cloze: false,
          noSuggest: false,
        ),
      );
    });

    test('prefix matching is case sensitive and does not trim', () {
      expect(
        TypeAnswerModifiers.parse('NC:Back'),
        const TypeAnswerModifiers(
          fieldName: 'NC:Back',
          combining: true,
          cloze: false,
          noSuggest: false,
        ),
      );
      expect(
        TypeAnswerModifiers.parse(' nc:Back'),
        const TypeAnswerModifiers(
          fieldName: ' nc:Back',
          combining: true,
          cloze: false,
          noSuggest: false,
        ),
      );
    });
  });

  group('TypeAnswerModifiers equality', () {
    test('compares and hashes structurally across all four values', () {
      const value = TypeAnswerModifiers(
        fieldName: 'Back',
        combining: false,
        cloze: true,
        noSuggest: true,
      );
      const same = TypeAnswerModifiers(
        fieldName: 'Back',
        combining: false,
        cloze: true,
        noSuggest: true,
      );

      expect(value, same);
      expect(value.hashCode, same.hashCode);
      expect(
        value,
        isNot(
          const TypeAnswerModifiers(
            fieldName: 'Other',
            combining: false,
            cloze: true,
            noSuggest: true,
          ),
        ),
      );
      expect(
        value,
        isNot(
          const TypeAnswerModifiers(
            fieldName: 'Back',
            combining: true,
            cloze: true,
            noSuggest: true,
          ),
        ),
      );
      expect(
        value,
        isNot(
          const TypeAnswerModifiers(
            fieldName: 'Back',
            combining: false,
            cloze: false,
            noSuggest: true,
          ),
        ),
      );
      expect(
        value,
        isNot(
          const TypeAnswerModifiers(
            fieldName: 'Back',
            combining: false,
            cloze: true,
            noSuggest: false,
          ),
        ),
      );
    });
  });
}
