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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Template Editor discard confirmation', () {
    test('waits for the host callback and applies effects in source order', () {
      final events = <String>[];
      void Function()? registeredConfirmation;
      final dialogHandle = Object();

      final result = cardTemplateEditorShowDiscardChangesDialog<Object, Object>(
        showDialog: (onConfirmed) {
          registeredConfirmation = onConfirmed;
          events.add('showDialog');
          return dialogHandle;
        },
        logConfirmation: (message) => events.add('log:$message'),
        clearTempNoteTypeFiles: () => events.add('clearTempNoteTypeFiles'),
        setTempNoteType: (value) => events.add('tempNoteType=$value'),
        finish: () => events.add('finish'),
      );

      expect(result, same(dialogHandle));
      expect(registeredConfirmation, isNotNull);
      expect(events, ['showDialog']);

      registeredConfirmation!();

      expect(events, [
        'showDialog',
        'log:TemplateEditor:: OK button pressed to confirm discard changes',
        'clearTempNoteTypeFiles',
        'tempNoteType=null',
        'finish',
      ]);
    });

    test('a callback failure propagates and stops all later effects', () {
      const logEvent =
          'log:TemplateEditor:: OK button pressed to confirm discard changes';
      final stages = <({String name, List<String> expected})>[
        (name: 'log', expected: [logEvent]),
        (
          name: 'clearTempNoteTypeFiles',
          expected: [logEvent, 'clearTempNoteTypeFiles'],
        ),
        (
          name: 'setTempNoteType',
          expected: [
            logEvent,
            'clearTempNoteTypeFiles',
            'setTempNoteType:null',
          ],
        ),
        (
          name: 'finish',
          expected: [
            logEvent,
            'clearTempNoteTypeFiles',
            'setTempNoteType:null',
            'finish',
          ],
        ),
      ];

      for (final stage in stages) {
        final events = <String>[];
        final exception = StateError('${stage.name} failed');
        void Function()? registeredConfirmation;
        expect(
          () => cardTemplateEditorShowDiscardChangesDialog<Object, Object>(
            showDialog: (onConfirmed) {
              registeredConfirmation = onConfirmed;
              return Object();
            },
            logConfirmation: (message) {
              events.add('log:$message');
              if (stage.name == 'log') throw exception;
            },
            clearTempNoteTypeFiles: () {
              events.add('clearTempNoteTypeFiles');
              if (stage.name == 'clearTempNoteTypeFiles') throw exception;
            },
            setTempNoteType: (value) {
              events.add('setTempNoteType:$value');
              if (stage.name == 'setTempNoteType') throw exception;
            },
            finish: () {
              events.add('finish');
              if (stage.name == 'finish') throw exception;
            },
          ),
          returnsNormally,
        );
        expect(registeredConfirmation, isNotNull);
        expect(
          () => registeredConfirmation!(),
          throwsA(same(exception)),
          reason: stage.name,
        );
        expect(events, stage.expected, reason: stage.name);
      }
    });
  });
}
