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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('selectLibAnkiCardTemplate', () {
    test('standard note type uses card ordinal after reading inputs once', () {
      final templates = [Object(), Object(), Object()];
      final calls = <String>[];

      final selected = selectLibAnkiCardTemplate(
        getTemplates: () {
          calls.add('templates');
          return templates;
        },
        isStandard: () {
          calls.add('isStandard');
          return true;
        },
        ordinal: 2,
        getAt: (items, index) {
          calls.add('index:$index');
          expect(items, same(templates));
          return items[index];
        },
      );

      expect(selected, same(templates[2]));
      expect(calls, ['templates', 'isStandard', 'index:2']);
    });

    test('cloze note type selects the first template by identity', () {
      final templates = [Object(), Object()];
      final calls = <String>[];

      final selected = selectLibAnkiCardTemplate(
        getTemplates: () {
          calls.add('templates');
          return templates;
        },
        isStandard: () {
          calls.add('isStandard');
          return false;
        },
        ordinal: 8,
        getAt: (items, index) {
          calls.add('index:$index');
          expect(items, same(templates));
          return items[index];
        },
      );

      expect(selected, same(templates[0]));
      expect(calls, ['templates', 'isStandard', 'index:0']);
    });

    test('callback failures propagate and prevent later operations', () {
      final failure = StateError('template access failed');
      final calls = <String>[];

      expect(
        () => selectLibAnkiCardTemplate(
          getTemplates: () {
            calls.add('templates');
            throw failure;
          },
          isStandard: () {
            calls.add('isStandard');
            return true;
          },
          ordinal: 0,
          getAt: (_, _) {
            calls.add('index');
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['templates']);

      calls.clear();
      expect(
        () => selectLibAnkiCardTemplate(
          getTemplates: () {
            calls.add('templates');
            return <Object>[];
          },
          isStandard: () {
            calls.add('isStandard');
            throw failure;
          },
          ordinal: 0,
          getAt: (_, _) {
            calls.add('index');
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['templates', 'isStandard']);

      calls.clear();
      expect(
        () => selectLibAnkiCardTemplate(
          getTemplates: () {
            calls.add('templates');
            return <Object>[];
          },
          isStandard: () {
            calls.add('isStandard');
            return false;
          },
          ordinal: 8,
          getAt: (_, index) {
            calls.add('index:$index');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['templates', 'isStandard', 'index:0']);
    });
  });
}
