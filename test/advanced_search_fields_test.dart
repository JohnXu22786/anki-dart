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
 * Source-derived from AdvancedSearchFieldsTab.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('advancedSearchFieldsOptions', () {
    test('preserves source order, exact labels, examples, and node text', () {
      final options = advancedSearchFieldsOptions;

      expect(options.keys.map((key) => key.value), [
        'field',
        'field_exact_match',
        'field_empty',
        'field_non_empty',
        'field_either_empty',
      ]);
      expect(options.values.map((option) => option.title), [
        'Search a named field',
        'Search a named field (exact text match)',
        'Notes with an empty field',
        'Notes with a non-empty field',
        'Notes with a field (empty or non-empty)',
      ]);
      expect(options.values.map((option) => option.example), [
        'field:*text*',
        'field:text',
        'field:',
        'field:_*',
        'field:*',
      ]);

      final projected = <String>[];
      var buildNodeCalls = 0;
      var serializeCalls = 0;
      final serialized = [
        for (final option in options.values)
          option.buildSearchString<String>(
            fieldName: 'Front',
            buildFieldNode: (fieldName, text) {
              buildNodeCalls++;
              projected.add('$fieldName:$text');
              return text;
            },
            buildHostSearchString: (fieldNode) {
              serializeCalls++;
              return 'serialized:$fieldNode';
            },
          ),
      ];

      expect(projected, [
        'Front:!!BEFORE!!text!!AFTER!!',
        'Front:text',
        'Front:',
        'Front:!!BEFORE!!!!AFTER!!',
        'Front:!!BEFORE!!!!AFTER!!',
      ]);
      expect(buildNodeCalls, 5);
      expect(serializeCalls, 5);
      expect(serialized, [
        'serialized:*text*',
        'serialized:text',
        'serialized:',
        'serialized:_*',
        'serialized:*',
      ]);
    });

    test(
      'builds before serialization once and preserves callback failures',
      () {
        final events = <String>[];
        final option = advancedSearchFieldsOptions[const ResultType('field')]!;
        final result = option.buildSearchString<String>(
          fieldName: ' front ',
          buildFieldNode: (fieldName, text) {
            events.add('node:$fieldName:$text');
            return text;
          },
          buildHostSearchString: (fieldNode) {
            events.add('serialize:$fieldNode');
            return 'field:$fieldNode';
          },
        );

        expect(result, 'field:*text*');
        expect(events, [
          'node: front :!!BEFORE!!text!!AFTER!!',
          'serialize:!!BEFORE!!text!!AFTER!!',
        ]);

        final nodeFailure = StateError('field node failed');
        expect(
          () => option.buildSearchString<String>(
            fieldName: 'Front',
            buildFieldNode: (_, _) => throw nodeFailure,
            buildHostSearchString: (_) => 'unreachable',
          ),
          throwsA(same(nodeFailure)),
        );

        final serializerFailure = StateError('field serialization failed');
        expect(
          () => option.buildSearchString<String>(
            fieldName: 'Front',
            buildFieldNode: (_, text) => text,
            buildHostSearchString: (_) => throw serializerFailure,
          ),
          throwsA(same(serializerFailure)),
        );
      },
    );

    test('replaces every marker occurrence, including input collisions', () {
      final option = advancedSearchFieldsOptions[const ResultType('field')]!;
      String? projectedText;

      final result = option.buildSearchString<String>(
        fieldName: 'Front',
        buildFieldNode: (_, text) {
          projectedText = text;
          return text;
        },
        buildHostSearchString: (fieldNode) => '$fieldNode|!!BEFORE!!|!!AFTER!!',
      );

      expect(projectedText, '!!BEFORE!!text!!AFTER!!');
      expect(result, '*text*|*|*');
    });
  });
}
