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
 * Source-derived checks for `TypeAnswer.updateInfo` field/result behavior.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('resolveTypeAnswerFieldResult', () {
    test('selects the first exact-name field and copies its metadata', () {
      final hint = Object();
      final first = TypeAnswerFieldMetadata(
        name: 'Back',
        font: 'Source Sans',
        fontSize: 17,
        languageHint: hint,
      );
      const second = TypeAnswerFieldMetadata(
        name: 'Back',
        font: 'Later Field',
        fontSize: 30,
        languageHint: 'fr-FR',
      );

      final result = resolveTypeAnswerFieldResult(
        fieldName: 'Back',
        fields: [first, second],
        noteValues: const {'Back': 'answer'},
        clozeIndex: 0,
        localizedUnknownFieldWarning: 'Unknown field: Back',
        localizedEmptyClozeFrontWarning: 'No cloze on the front',
      );

      expect(result.correctAnswer, 'answer');
      expect(identical(result.matchedField, first), isTrue);
      expect(result.matchedField!.font, 'Source Sans');
      expect(result.matchedField!.fontSize, 17);
      expect(identical(result.matchedField!.languageHint, hint), isTrue);
      expect(result.warningUpdate.kind, TypeAnswerWarningUpdateKind.clear);
      expect(result.warningUpdate.value, isNull);
    });

    test('a missing exact-name field leaves metadata and sets unknown warning',
        () {
      final result = resolveTypeAnswerFieldResult(
        fieldName: 'Back',
        fields: const [
          TypeAnswerFieldMetadata(
            name: 'back',
            font: 'font',
            fontSize: 18,
            languageHint: null,
          ),
        ],
        noteValues: const {},
        clozeIndex: 0,
        localizedUnknownFieldWarning: 'Unknown field: Back',
        localizedEmptyClozeFrontWarning: 'No cloze on the front',
      );

      expect(result.correctAnswer, isNull);
      expect(result.matchedField, isNull);
      expect(result.warningUpdate.kind, TypeAnswerWarningUpdateKind.set);
      expect(result.warningUpdate.value, 'Unknown field: Back');
    });

    test('a missing field with a nonzero cloze index sets empty-front warning',
        () {
      final result = resolveTypeAnswerFieldResult(
        fieldName: 'Back',
        fields: const [],
        noteValues: const {},
        clozeIndex: 1,
        localizedUnknownFieldWarning: 'Unknown field: Back',
        localizedEmptyClozeFrontWarning: 'No cloze on the front',
      );

      expect(result.correctAnswer, isNull);
      expect(result.matchedField, isNull);
      expect(result.warningUpdate.kind, TypeAnswerWarningUpdateKind.set);
      expect(result.warningUpdate.value, 'No cloze on the front');
    });

    test('empty note value nulls correct answer but preserves prior warning',
        () {
      const field = TypeAnswerFieldMetadata(
        name: 'Back',
        font: '',
        fontSize: 0,
        languageHint: null,
      );

      final result = resolveTypeAnswerFieldResult(
        fieldName: 'Back',
        fields: const [field],
        noteValues: const {'Back': ''},
        clozeIndex: 0,
        localizedUnknownFieldWarning: 'Unknown field: Back',
        localizedEmptyClozeFrontWarning: 'No cloze on the front',
      );

      expect(result.correctAnswer, isNull);
      expect(identical(result.matchedField, field), isTrue);
      expect(result.matchedField!.font, '');
      expect(result.matchedField!.fontSize, 0);
      expect(result.matchedField!.languageHint, isNull);
      expect(
        result.warningUpdate.kind,
        TypeAnswerWarningUpdateKind.preservePrevious,
      );
      expect(result.warningUpdate.value, isNull);
    });

    test('nonempty cloze answer is narrowed and clears the warning', () {
      const field = TypeAnswerFieldMetadata(
        name: 'Text',
        font: 'font',
        fontSize: 18,
        languageHint: 'ja-JP',
      );

      final result = resolveTypeAnswerFieldResult(
        fieldName: 'Text',
        fields: const [field],
        noteValues: const {'Text': 'before {{c1::answer}} after'},
        clozeIndex: 1,
        localizedUnknownFieldWarning: 'Unknown field: Text',
        localizedEmptyClozeFrontWarning: 'No cloze on the front',
      );

      expect(result.correctAnswer, 'answer');
      expect(identical(result.matchedField, field), isTrue);
      expect(result.warningUpdate.kind, TypeAnswerWarningUpdateKind.clear);
    });

    test('no matching cloze content preserves the warning after field match',
        () {
      const field = TypeAnswerFieldMetadata(
        name: 'Text',
        font: 'font',
        fontSize: 18,
        languageHint: null,
      );

      final result = resolveTypeAnswerFieldResult(
        fieldName: 'Text',
        fields: const [field],
        noteValues: const {'Text': '{{c2::other}}'},
        clozeIndex: 1,
        localizedUnknownFieldWarning: 'Unknown field: Text',
        localizedEmptyClozeFrontWarning: 'No cloze on the front',
      );

      expect(result.correctAnswer, isNull);
      expect(identical(result.matchedField, field), isTrue);
      expect(
        result.warningUpdate.kind,
        TypeAnswerWarningUpdateKind.preservePrevious,
      );
    });

    test(
        'selected field absent from note values preserves source lookup failure',
        () {
      expect(
        () => resolveTypeAnswerFieldResult(
          fieldName: 'Back',
          fields: const [
            TypeAnswerFieldMetadata(
              name: 'Back',
              font: 'font',
              fontSize: 18,
              languageHint: null,
            ),
          ],
          noteValues: const {},
          clozeIndex: 0,
          localizedUnknownFieldWarning: 'Unknown field: Back',
          localizedEmptyClozeFrontWarning: 'No cloze on the front',
        ),
        throwsA(isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains("No field named 'Back' found"),
        )),
      );
    });
  });
}
