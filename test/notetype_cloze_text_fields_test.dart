/*
 * Copyright (c) 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Test adapted from NoteTypeTest.testGetAllClozeTexts in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/src/notetype_cloze_text_fields.dart';
import 'package:test/test.dart';

void main() {
  group('getAllClozeTextFields', () {
    test('preserves pinned examples, order, and optional prefixes', () {
      expect(
        getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const [
            '{{type:cloze:Text}} {{type:cloze:Text2}} {{cloze:Text3}}',
          ],
        ),
        ['Text', 'Text2', 'Text3'],
      );
      // The optional prefix reaches the later `cloze:` and consumes the
      // intervening direct marker, matching the source regex's lazy dot-star.
      expect(
        getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const [
            '{{a:b:cloze:first}} {{cloze:second}} {{left:cloze:third}}',
          ],
        ),
        ['first', 'third'],
      );
    });

    test('preserves empty captures, braces, and line break behavior', () {
      expect(
        getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const ['{{cloze:}} {{cloze:a{b}}}'],
        ),
        ['', 'a{b'],
      );
      expect(
        getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const ['{{cloze:first\nsecond}}'],
        ),
        ['first\nsecond'],
      );
      expect(
        getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const [
            '{{prefix:\ncloze:miss}} {{cloze:hit}}',
          ],
        ),
        ['hit'],
      );

      for (final lineTerminator in [
        '\n',
        '\r',
        '\r\n',
        '\u0085',
        '\u2028',
        '\u2029',
      ]) {
        expect(
          getAllClozeTextFields(
            isCloze: true,
            templateQuestionFormats: ['{{prefix$lineTerminator:cloze:miss}}'],
          ),
          isEmpty,
          reason: 'a prefix must not cross a JVM line terminator',
        );
      }
    });

    test('returns no values when the format has no cloze marker', () {
      expect(
        getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const ['{{Front}} {{type:Front}}'],
        ),
        isEmpty,
      );
    });

    test('rejects non-cloze input before reading question formats', () {
      Iterable<String> unreadableFormats() sync* {
        throw StateError('question formats were read');
      }

      expect(
        () => getAllClozeTextFields(
          isCloze: false,
          templateQuestionFormats: unreadableFormats(),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'getAllClozeTextFields called on non-cloze template',
          ),
        ),
      );
    });

    test('requires exactly one question format', () {
      expect(
        () => getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const [],
        ),
        throwsStateError,
      );
      expect(
        () => getAllClozeTextFields(
          isCloze: true,
          templateQuestionFormats: const [
            '{{cloze:first}}',
            '{{cloze:second}}',
          ],
        ),
        throwsStateError,
      );
    });
  });
}
