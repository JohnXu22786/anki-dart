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
 *
 * Source-derived orchestration cases for `TypeAnswer.updateInfo`.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planTypeAnswerInfoUpdate', () {
    test('no marker returns after the three source-ordered resets', () {
      final plan = planTypeAnswerInfoUpdate(
        question: 'No typing declaration',
        cardOrdinal: 4,
        fields: const [],
        noteValues: const {},
        localizedUnknownFieldWarning: 'Unknown field',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );

      expect(
        plan.effects,
        const [
          TypeAnswerInfoSetCombining(true),
          TypeAnswerInfoSetNoSuggest(false),
          TypeAnswerInfoSetCorrectAnswer(null),
        ],
      );
      expect(plan.failure, isNull);
    });

    test('first marker and first field preserve every update order', () {
      final languageHint = Object();
      const firstField = TypeAnswerFieldMetadata(
        name: 'Back',
        font: 'First font',
        fontSize: 19,
        languageHint: null,
      );
      final selectedField = TypeAnswerFieldMetadata(
        name: 'Back',
        font: 'Selected font',
        fontSize: 23,
        languageHint: languageHint,
      );
      const laterField = TypeAnswerFieldMetadata(
        name: 'Other',
        font: 'Other font',
        fontSize: 30,
        languageHint: null,
      );

      final plan = planTypeAnswerInfoUpdate(
        question: '[[type:nosuggest:nc:cloze:Back]] then [[type:Other]]',
        cardOrdinal: 0,
        fields: [firstField, selectedField, laterField],
        noteValues: const {
          'Back': ' before {{c1::answer :: hint}} after ',
          'Other': 'later answer',
        },
        localizedUnknownFieldWarning: 'Unknown field',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );

      expect(
        plan.effects,
        [
          const TypeAnswerInfoSetCombining(true),
          const TypeAnswerInfoSetNoSuggest(false),
          const TypeAnswerInfoSetCorrectAnswer(null),
          const TypeAnswerInfoSetCombining(false),
          const TypeAnswerInfoSetNoSuggest(true),
          const TypeAnswerInfoSetCorrectAnswer(
            ' before {{c1::answer :: hint}} after ',
          ),
          const TypeAnswerInfoSetCorrectAnswer('answer '),
          const TypeAnswerInfoSetFont('First font'),
          const TypeAnswerInfoSetFontSize(19),
          const TypeAnswerInfoSetLanguageHint(null),
          const TypeAnswerInfoSetWarning(null),
        ],
      );
      expect(plan.failure, isNull);

      final zeroIndexCloze = planTypeAnswerInfoUpdate(
        question: '[[type:cloze:Back]]',
        cardOrdinal: -1,
        fields: const [firstField],
        noteValues: const {'Back': '{{c1::not selected}}'},
        localizedUnknownFieldWarning: 'Unknown field',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );
      expect(
        zeroIndexCloze.effects
            .whereType<TypeAnswerInfoSetCorrectAnswer>()
            .map((effect) => effect.value),
        [null, '{{c1::not selected}}'],
      );
    });

    test('unmatched field sets warning without changing prior metadata', () {
      final ordinary = planTypeAnswerInfoUpdate(
        question: '[[type:Missing]]',
        cardOrdinal: 2,
        fields: const [],
        noteValues: const {},
        localizedUnknownFieldWarning: 'Unknown Missing',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );
      final cloze = planTypeAnswerInfoUpdate(
        question: '[[type:cloze:Missing]]',
        cardOrdinal: 2,
        fields: const [],
        noteValues: const {},
        localizedUnknownFieldWarning: 'Unknown Missing',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );
      final zeroIndexCloze = planTypeAnswerInfoUpdate(
        question: '[[type:cloze:Missing]]',
        cardOrdinal: -1,
        fields: const [],
        noteValues: const {},
        localizedUnknownFieldWarning: 'Unknown Missing',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );

      expect(ordinary.effects.last,
          const TypeAnswerInfoSetWarning('Unknown Missing'));
      expect(cloze.effects.last,
          const TypeAnswerInfoSetWarning('Empty cloze front'));
      expect(zeroIndexCloze.effects.last,
          const TypeAnswerInfoSetWarning('Unknown Missing'));
      for (final plan in [ordinary, cloze, zeroIndexCloze]) {
        expect(
          plan.effects.whereType<TypeAnswerInfoSetFont>(),
          isEmpty,
        );
        expect(
          plan.effects.whereType<TypeAnswerInfoSetFontSize>(),
          isEmpty,
        );
        expect(
          plan.effects.whereType<TypeAnswerInfoSetLanguageHint>(),
          isEmpty,
        );
      }
    });

    test('empty answer updates metadata then preserves prior warning', () {
      const field = TypeAnswerFieldMetadata(
        name: 'Back',
        font: 'Field font',
        fontSize: 16,
        languageHint: 'en-US',
      );
      final plan = planTypeAnswerInfoUpdate(
        question: '[[type:Back]]',
        cardOrdinal: 1,
        fields: const [field],
        noteValues: const {'Back': ''},
        localizedUnknownFieldWarning: 'Unknown Back',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );

      expect(
        plan.effects,
        const [
          TypeAnswerInfoSetCombining(true),
          TypeAnswerInfoSetNoSuggest(false),
          TypeAnswerInfoSetCorrectAnswer(null),
          TypeAnswerInfoSetCombining(true),
          TypeAnswerInfoSetNoSuggest(false),
          TypeAnswerInfoSetCorrectAnswer(''),
          TypeAnswerInfoSetFont('Field font'),
          TypeAnswerInfoSetFontSize(16),
          TypeAnswerInfoSetLanguageHint('en-US'),
          TypeAnswerInfoSetCorrectAnswer(null),
        ],
      );
      expect(plan.effects.whereType<TypeAnswerInfoSetWarning>(), isEmpty);
    });

    test('missing note field reports failure after earlier source effects', () {
      final plan = planTypeAnswerInfoUpdate(
        question: '[[type:nc:nosuggest:Back]]',
        cardOrdinal: 0,
        fields: const [
          TypeAnswerFieldMetadata(
            name: 'Back',
            font: 'Font',
            fontSize: 18,
            languageHint: null,
          ),
        ],
        noteValues: const {},
        localizedUnknownFieldWarning: 'Unknown Back',
        localizedEmptyClozeFrontWarning: 'Empty cloze front',
      );

      expect(
        plan.effects,
        const [
          TypeAnswerInfoSetCombining(true),
          TypeAnswerInfoSetNoSuggest(false),
          TypeAnswerInfoSetCorrectAnswer(null),
          TypeAnswerInfoSetCombining(false),
          TypeAnswerInfoSetNoSuggest(true),
        ],
      );
      expect(plan.failure!.fieldName, 'Back');
      expect(plan.failure!.message, "No field named 'Back' found");
    });
  });
}
