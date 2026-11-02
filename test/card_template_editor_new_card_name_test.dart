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
  group('newCardName', () {
    test('returns the first localized candidate when it is unused', () {
      final formatted = <int>[];

      final result = newCardName(
        templateCount: 2,
        existingNames: ['Card 1', 'Card 2'],
        localizeName: (number) {
          formatted.add(number);
          return 'Card $number';
        },
      );

      expect(result, 'Card 3');
      expect(formatted, [3]);
    });

    test('skips one and multiple exact collisions in order', () {
      final formatted = <int>[];

      final result = newCardName(
        templateCount: 1,
        existingNames: ['Card 2', 'Card 3', 'Card 5'],
        localizeName: (number) {
          formatted.add(number);
          return 'Card $number';
        },
      );

      expect(result, 'Card 4');
      expect(formatted, [2, 3, 4]);
    });

    test('uses exact case-sensitive equality', () {
      final result = newCardName(
        templateCount: 0,
        existingNames: ['card 1'],
        localizeName: (number) => 'Card $number',
      );

      expect(result, 'Card 1');
    });

    test(
      'formats once per candidate and scans names in order until a match',
      () {
        final events = <String>[];
        final names = Iterable<String>.generate(3, (index) {
          events.add('name$index');
          return 'Name $index';
        });

        final result = newCardName(
          templateCount: 0,
          existingNames: names,
          localizeName: (number) {
            events.add('format$number');
            return number == 1 ? 'Name 1' : 'Candidate $number';
          },
        );

        expect(result, 'Candidate 2');
        expect(events, [
          'format1',
          'name0',
          'name1',
          'format2',
          'name0',
          'name1',
          'name2',
        ]);
      },
    );

    test('propagates formatter and iterable exceptions unchanged', () {
      final formatterFailure = StateError('format failed');
      expect(
        () => newCardName(
          templateCount: 0,
          existingNames: const <String>[],
          localizeName: (_) => throw formatterFailure,
        ),
        throwsA(same(formatterFailure)),
      );

      final iterableFailure = StateError('iteration failed');
      Iterable<String> throwingNames() sync* {
        yield 'not a match';
        throw iterableFailure;
      }

      expect(
        () => newCardName(
          templateCount: 0,
          existingNames: throwingNames(),
          localizeName: (_) => 'candidate',
        ),
        throwsA(same(iterableFailure)),
      );
    });

    test('wraps signed 32-bit candidate increments', () {
      const maxInt32 = 0x7fffffff;
      const minInt32 = -0x80000000;
      final initialFormatted = <int>[];
      final initialResult = newCardName(
        templateCount: maxInt32,
        existingNames: const <String>[],
        localizeName: (number) {
          initialFormatted.add(number);
          return 'Name $number';
        },
      );
      expect(initialResult, 'Name $minInt32');
      expect(initialFormatted, [minInt32]);

      final formatted = <int>[];
      final result = newCardName(
        templateCount: maxInt32 - 1,
        existingNames: const ['Name $maxInt32'],
        localizeName: (number) {
          formatted.add(number);
          return 'Name $number';
        },
      );

      expect(result, 'Name $minInt32');
      expect(formatted, [maxInt32, minInt32]);
    });
  });
}
