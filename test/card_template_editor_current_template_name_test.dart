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
  group('cardTemplateEditorCurrentTemplateName', () {
    test('reads by the source ordinal and returns the exact name', () {
      final ordinals = <int>[];
      final warnings = <Exception>[];

      final name = cardTemplateEditorCurrentTemplateName(
        currentOrdinal: 3,
        readTemplateName: (ordinal) {
          ordinals.add(ordinal);
          return '  Exact Name\n';
        },
        warn: warnings.add,
      );

      expect(name, '  Exact Name\n');
      expect(ordinals, [3]);
      expect(warnings, isEmpty);
    });

    test('warns once and returns empty for a host read Exception', () {
      final failure = Exception('template read failed');
      final warnings = <Exception>[];
      var reads = 0;

      final name = cardTemplateEditorCurrentTemplateName(
        currentOrdinal: 0,
        readTemplateName: (_) {
          reads++;
          throw failure;
        },
        warn: warnings.add,
      );

      expect(name, '');
      expect(reads, 1);
      expect(warnings, [same(failure)]);
    });

    test('propagates a non-Exception Error without warning', () {
      final failure = AssertionError('fatal host failure');
      final warnings = <Exception>[];

      expect(
        () => cardTemplateEditorCurrentTemplateName(
          currentOrdinal: 0,
          readTemplateName: (_) => throw failure,
          warn: warnings.add,
        ),
        throwsA(same(failure)),
      );
      expect(warnings, isEmpty);
    });

    test('propagates a warning callback failure unchanged', () {
      final readFailure = Exception('template read failed');
      final warningFailure = StateError('warning callback failed');

      expect(
        () => cardTemplateEditorCurrentTemplateName(
          currentOrdinal: 0,
          readTemplateName: (_) => throw readFailure,
          warn: (_) => throw warningFailure,
        ),
        throwsA(same(warningFailure)),
      );
    });

    test('runs the template read before the host warning/log callback', () {
      final events = <String>[];
      final failure = Exception('template read failed');

      final name = cardTemplateEditorCurrentTemplateName(
        currentOrdinal: 5,
        readTemplateName: (ordinal) {
          events.add('read:$ordinal');
          throw failure;
        },
        warn: (exception) =>
            events.add('warn:${identical(exception, failure)}'),
      );

      expect(name, '');
      expect(events, ['read:5', 'warn:true']);
    });
  });
}
