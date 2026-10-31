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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentInsertField', () {
    test('inserts at a collapsed cursor and replaces an ordinary range', () {
      final replacements = <(int, int, String, int, int)>[];
      void replace(
        int start,
        int end,
        String field,
        int fieldStart,
        int fieldEnd,
      ) {
        replacements.add((start, end, field, fieldStart, fieldEnd));
      }

      cardTemplateFragmentInsertField(
        fieldToInsert: '{{Front}}',
        readSelectionStart: () => 3,
        readSelectionEnd: () => 3,
        replaceText: replace,
      );
      cardTemplateFragmentInsertField(
        fieldToInsert: '{{Back}}',
        readSelectionStart: () => 2,
        readSelectionEnd: () => 7,
        replaceText: replace,
      );

      expect(replacements, [
        (3, 3, '{{Front}}', 0, 9),
        (2, 7, '{{Back}}', 0, 8),
      ]);
    });

    test('normalizes a reversed selection', () {
      (int, int, String, int, int)? replacement;
      cardTemplateFragmentInsertField(
        fieldToInsert: 'x',
        readSelectionStart: () => 8,
        readSelectionEnd: () => 4,
        replaceText: (start, end, field, fieldStart, fieldEnd) {
          replacement = (start, end, field, fieldStart, fieldEnd);
        },
      );

      expect(replacement, (4, 8, 'x', 0, 1));
    });

    test('floors negative selection sentinels only to zero', () {
      (int, int, String, int, int)? replacement;
      cardTemplateFragmentInsertField(
        fieldToInsert: 'field',
        readSelectionStart: () => -1,
        readSelectionEnd: () => 14,
        replaceText: (start, end, field, fieldStart, fieldEnd) {
          replacement = (start, end, field, fieldStart, fieldEnd);
        },
      );

      expect(replacement, (0, 14, 'field', 0, 5));
    });

    test('uses UTF-16 field length and reads before one replacement', () {
      final events = <String>[];
      final field = '😀';
      cardTemplateFragmentInsertField(
        fieldToInsert: field,
        readSelectionStart: () {
          events.add('start');
          return 5;
        },
        readSelectionEnd: () {
          events.add('end');
          return 2;
        },
        replaceText: (start, end, value, fieldStart, fieldEnd) {
          events.add('replace');
          expect((start, end), (2, 5));
          expect(value, same(field));
          expect((fieldStart, fieldEnd), (0, 2));
        },
      );

      expect(events, ['start', 'end', 'replace']);
    });

    test(
      'propagates selection and replacement failures and stops later work',
      () {
        final startFailure = StateError('start read');
        final startEvents = <String>[];
        expect(
          () => cardTemplateFragmentInsertField(
            fieldToInsert: 'x',
            readSelectionStart: () {
              startEvents.add('start');
              throw startFailure;
            },
            readSelectionEnd: () {
              startEvents.add('end');
              return 1;
            },
            replaceText: (start, end, field, fieldStart, fieldEnd) {
              startEvents.add('replace');
            },
          ),
          throwsA(same(startFailure)),
        );
        expect(startEvents, ['start']);

        final endFailure = StateError('end read');
        final endEvents = <String>[];
        expect(
          () => cardTemplateFragmentInsertField(
            fieldToInsert: 'x',
            readSelectionStart: () {
              endEvents.add('start');
              return 1;
            },
            readSelectionEnd: () {
              endEvents.add('end');
              throw endFailure;
            },
            replaceText: (start, end, field, fieldStart, fieldEnd) {
              endEvents.add('replace');
            },
          ),
          throwsA(same(endFailure)),
        );
        expect(endEvents, ['start', 'end']);

        final replaceFailure = StateError('replace');
        final replaceEvents = <String>[];
        expect(
          () => cardTemplateFragmentInsertField(
            fieldToInsert: 'x',
            readSelectionStart: () {
              replaceEvents.add('start');
              return 1;
            },
            readSelectionEnd: () {
              replaceEvents.add('end');
              return 2;
            },
            replaceText: (start, end, field, fieldStart, fieldEnd) {
              replaceEvents.add('replace');
              throw replaceFailure;
            },
          ),
          throwsA(same(replaceFailure)),
        );
        expect(replaceEvents, ['start', 'end', 'replace']);
      },
    );
  });
}
