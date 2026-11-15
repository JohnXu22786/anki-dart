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
  group('cardTemplateEditorCurrentTemplate', () {
    test('reads the index first and returns the exact template identity', () {
      final events = <String>[];
      final template = Object();

      final result = cardTemplateEditorCurrentTemplate<Object>(
        readCurrentIndex: () {
          events.add('index');
          return 4;
        },
        readCurrentTemplate: (index) {
          events.add('template:$index');
          return template;
        },
        isJsonException: (_) => false,
        warn: (_, __, ___) => events.add('warn'),
      );

      expect(result, same(template));
      expect(events, ['index', 'template:4']);
    });

    test('lets index-read failures escape without warning', () {
      final failure = StateError('index read failed');
      final events = <String>[];

      expect(
        () => cardTemplateEditorCurrentTemplate<Object>(
          readCurrentIndex: () {
            events.add('index');
            throw failure;
          },
          readCurrentTemplate: (_) {
            events.add('template');
            return Object();
          },
          isJsonException: (_) => true,
          warn: (_, __, ___) => events.add('warn'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['index']);
    });

    test('warns once for the classified JSON failure then returns null', () {
      final failure = Exception('backend JSON failure');
      final events = <String>[];

      final result = cardTemplateEditorCurrentTemplate<Object>(
        readCurrentIndex: () {
          events.add('index');
          return 6;
        },
        readCurrentTemplate: (index) {
          events.add('template:$index');
          throw failure;
        },
        isJsonException: (error) {
          events.add('classify:${identical(error, failure)}');
          return true;
        },
        warn: (error, message, index) =>
            events.add('warn:${identical(error, failure)}:$message:$index'),
      );

      expect(result, isNull);
      expect(events, [
        'index',
        'template:6',
        'classify:true',
        'warn:true:CardTemplateEditor::getCurrentTemplate - unexpectedly unable to fetch template? %d:6',
      ]);
    });

    test('propagates an unclassified Exception unchanged without warning', () {
      final failure = FormatException('not a JSON exception');
      final warnings = <Object>[];

      expect(
        () => cardTemplateEditorCurrentTemplate<Object>(
          readCurrentIndex: () => 2,
          readCurrentTemplate: (_) => throw failure,
          isJsonException: (_) => false,
          warn: (error, _, __) => warnings.add(error),
        ),
        throwsA(same(failure)),
      );
      expect(warnings, isEmpty);
    });

    test('propagates an Error unchanged without warning', () {
      final failure = AssertionError('host assertion failed');
      final warnings = <Object>[];

      expect(
        () => cardTemplateEditorCurrentTemplate<Object>(
          readCurrentIndex: () => 2,
          readCurrentTemplate: (_) => throw failure,
          isJsonException: (_) => false,
          warn: (error, _, __) => warnings.add(error),
        ),
        throwsA(same(failure)),
      );
      expect(warnings, isEmpty);
    });

    test('returns a null indexed value without treating it as an error', () {
      var warnings = 0;

      final result = cardTemplateEditorCurrentTemplate<Object>(
        readCurrentIndex: () => 8,
        readCurrentTemplate: (_) => null,
        isJsonException: (_) => false,
        warn: (_, __, ___) => warnings++,
      );

      expect(result, isNull);
      expect(warnings, 0);
    });
  });
}
