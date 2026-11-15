/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

const _warningMessage =
    'Exception loading template in CardTemplateFragment. Probably stale fragment.';

final class _HostCardTemplate {
  const _HostCardTemplate(this.front, this.back, this.style);

  final String front;
  final String back;
  final String style;
}

void main() {
  group('cardTemplateFragmentCurrentTemplate', () {
    test('returns the host value with source reads and fields in order', () {
      final events = <String>[];
      final warnings = <Exception>[];
      final warningMessages = <String>[];
      late final _HostCardTemplate template;

      final result = cardTemplateFragmentCurrentTemplate<_HostCardTemplate>(
        readAndProjectCurrentTemplate: () {
          events.add('read tempNoteType');
          Object? readTempNoteType() => Object();
          final tempNoteType = readTempNoteType();
          events.add('assert tempNoteType');
          final checkedTempNoteType = tempNoteType!;
          events.add('read ord');
          const ordinal = 5;
          events.add('getTemplate:${checkedTempNoteType.runtimeType}:$ordinal');
          events.add('read qfmt');
          const front = '  front\n';
          events.add('read afmt');
          const back = 'back\r';
          events.add('read css');
          const style = 'css{}';
          events.add('construct:front,back,style');
          return template = _HostCardTemplate(front, back, style);
        },
        warn: (exception, message) {
          warnings.add(exception);
          warningMessages.add(message);
        },
      );

      expect(result, same(template));
      final card = result!;
      expect(card.front, '  front\n');
      expect(card.back, 'back\r');
      expect(card.style, 'css{}');
      expect(events, [
        'read tempNoteType',
        'assert tempNoteType',
        'read ord',
        'getTemplate:Object:5',
        'read qfmt',
        'read afmt',
        'read css',
        'construct:front,back,style',
      ]);
      expect(warnings, isEmpty);
      expect(warningMessages, isEmpty);
    });

    test(
      'warns once with the same Exception and returns null at every stage',
      () {
        const stages = [
          'read tempNoteType',
          'assert tempNoteType',
          'read ord',
          'getTemplate',
          'read qfmt',
          'read afmt',
          'read css',
          'construct',
        ];

        for (final failedStage in stages) {
          final failure = Exception('$failedStage failed');
          final events = <String>[];

          final result = cardTemplateFragmentCurrentTemplate<Object>(
            readAndProjectCurrentTemplate: () {
              for (final stage in stages) {
                events.add(stage);
                if (stage == failedStage) throw failure;
              }
              return Object();
            },
            warn: (exception, message) {
              expect(message, _warningMessage, reason: failedStage);
              events.add('warn:${identical(exception, failure)}');
            },
          );

          expect(result, isNull, reason: failedStage);
          expect(events.last, 'warn:true', reason: failedStage);
          expect(events.where((event) => event == 'warn:true'), hasLength(1));
          expect(events.takeWhile((event) => !event.startsWith('warn:')), [
            ...stages.take(stages.indexOf(failedStage) + 1),
          ]);
        }
      },
    );

    test(
      'propagates an Error from the host source sequence without warning',
      () {
        final failure = AssertionError('host source error');
        var warnings = 0;

        expect(
          () => cardTemplateFragmentCurrentTemplate<Object>(
            readAndProjectCurrentTemplate: () => throw failure,
            warn: (_, __) => warnings++,
          ),
          throwsA(same(failure)),
        );
        expect(warnings, 0);
      },
    );

    test('propagates warning callback failures unchanged', () {
      final sourceFailure = Exception('source failed');
      final warningFailure = StateError('warning callback failed');

      expect(
        () => cardTemplateFragmentCurrentTemplate<Object>(
          readAndProjectCurrentTemplate: () => throw sourceFailure,
          warn: (_, __) => throw warningFailure,
        ),
        throwsA(same(warningFailure)),
      );
    });
  });
}
