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
 * Source-derived from CardTemplateEditor.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Template Editor keyboard discard gate', () {
    test(
      'null safe-call boundaries mean keyboard-closed and continue the update',
      () {
        final cases = <({String absent, List<String> events})>[
          (
            absent: 'fragment',
            events: ['fragment', 'noteTypeHasChanged', 'setEnabled:true'],
          ),
          (
            absent: 'view',
            events: [
              'fragment',
              'view',
              'noteTypeHasChanged',
              'setEnabled:true',
            ],
          ),
          (
            absent: 'binding',
            events: [
              'fragment',
              'view',
              'binding',
              'noteTypeHasChanged',
              'setEnabled:true',
            ],
          ),
          (
            absent: 'navigation',
            events: [
              'fragment',
              'view',
              'binding',
              'navigation',
              'noteTypeHasChanged',
              'setEnabled:true',
            ],
          ),
        ];

        for (final testCase in cases) {
          final events = <String>[];
          bool? enabled;
          cardTemplateEditorUpdateDiscardChangesCallback(
            callbacks: _callbacks(
              events,
              absent: testCase.absent,
              noteTypeHasChanged: () {
                events.add('noteTypeHasChanged');
                return true;
              },
              setEnabled: (value) {
                events.add('setEnabled:$value');
                enabled = value;
              },
            ),
          );

          expect(events, testCase.events, reason: testCase.absent);
          expect(enabled, isTrue, reason: testCase.absent);
        }
      },
    );

    test('visibility must be exactly false to report an open keyboard', () {
      for (final visibility in <bool?>[true, false, null]) {
        final events = <String>[];
        bool? enabled;
        cardTemplateEditorUpdateDiscardChangesCallback(
          callbacks: _callbacks(
            events,
            visibility: visibility,
            noteTypeHasChanged: () {
              events.add('noteTypeHasChanged');
              return true;
            },
            setEnabled: (value) {
              events.add('setEnabled:$value');
              enabled = value;
            },
          ),
        );

        expect(enabled, visibility == false ? isFalse : isTrue);
        expect(
          events,
          visibility == false
              ? [
                  'fragment',
                  'view',
                  'binding',
                  'navigation',
                  'visibility',
                  'setEnabled:false',
                ]
              : [
                  'fragment',
                  'view',
                  'binding',
                  'navigation',
                  'visibility',
                  'noteTypeHasChanged',
                  'setEnabled:true',
                ],
        );
      }
    });

    test(
      'reads fragment once and preserves callback order and write count',
      () {
        final events = <String>[];
        var fragmentReads = 0;
        var noteTypeReads = 0;
        var enabledWrites = 0;
        cardTemplateEditorUpdateDiscardChangesCallback(
          callbacks: _callbacks(
            events,
            readFragment: () {
              fragmentReads++;
              events.add('fragment');
              return 'fragment';
            },
            visibility: true,
            noteTypeHasChanged: () {
              noteTypeReads++;
              events.add('noteTypeHasChanged');
              return false;
            },
            setEnabled: (value) {
              enabledWrites++;
              events.add('setEnabled:$value');
            },
          ),
        );

        expect(fragmentReads, 1);
        expect(noteTypeReads, 1);
        expect(enabledWrites, 1);
        expect(events, [
          'fragment',
          'view',
          'binding',
          'navigation',
          'visibility',
          'noteTypeHasChanged',
          'setEnabled:false',
        ]);
      },
    );

    test('open keyboard lazily skips note-type check and disables once', () {
      final events = <String>[];
      cardTemplateEditorUpdateDiscardChangesCallback(
        callbacks: _callbacks(
          events,
          visibility: false,
          noteTypeHasChanged: () => fail('must not check note type'),
          setEnabled: (value) => events.add('setEnabled:$value'),
        ),
      );

      expect(events, [
        'fragment',
        'view',
        'binding',
        'navigation',
        'visibility',
        'setEnabled:false',
      ]);
    });

    test(
      'closed keyboard calls note-type check once and writes its result',
      () {
        final events = <String>[];
        var noteTypeReads = 0;
        var enabledWrites = 0;
        cardTemplateEditorUpdateDiscardChangesCallback(
          callbacks: _callbacks(
            events,
            visibility: true,
            noteTypeHasChanged: () {
              noteTypeReads++;
              events.add('noteTypeHasChanged');
              return true;
            },
            setEnabled: (value) {
              enabledWrites++;
              events.add('setEnabled:$value');
            },
          ),
        );

        expect(noteTypeReads, 1);
        expect(enabledWrites, 1);
        expect(events.last, 'setEnabled:true');
      },
    );

    test('callback failures propagate unchanged and stop later effects', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'fragment', reached: ['fragment']),
        (stage: 'view', reached: ['fragment', 'view']),
        (stage: 'binding', reached: ['fragment', 'view', 'binding']),
        (
          stage: 'navigation',
          reached: ['fragment', 'view', 'binding', 'navigation'],
        ),
        (
          stage: 'visibility',
          reached: ['fragment', 'view', 'binding', 'navigation', 'visibility'],
        ),
        (
          stage: 'noteTypeHasChanged',
          reached: [
            'fragment',
            'view',
            'binding',
            'navigation',
            'visibility',
            'noteTypeHasChanged',
          ],
        ),
        (
          stage: 'setEnabled',
          reached: [
            'fragment',
            'view',
            'binding',
            'navigation',
            'visibility',
            'noteTypeHasChanged',
            'setEnabled',
          ],
        ),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => cardTemplateEditorUpdateDiscardChangesCallback(
            callbacks: _callbacks(
              reached,
              invoke: invoke,
              noteTypeHasChanged: () {
                invoke('noteTypeHasChanged');
                return true;
              },
              setEnabled: (_) => invoke('setEnabled'),
            ),
          ),
          throwsA(same(failure)),
          reason: testCase.stage,
        );
        expect(reached, testCase.reached, reason: testCase.stage);
      }
    });
  });
}

CardTemplateEditorKeyboardDiscardCallbacks<String, String, String, String>
_callbacks(
  List<String> events, {
  String? absent,
  bool? visibility = true,
  String? Function()? readFragment,
  required bool Function() noteTypeHasChanged,
  required void Function(bool) setEnabled,
  void Function(String)? invoke,
}) {
  void stage(String name) {
    if (invoke != null) {
      invoke(name);
    } else {
      events.add(name);
    }
  }

  return CardTemplateEditorKeyboardDiscardCallbacks<
    String,
    String,
    String,
    String
  >(
    currentFragment:
        readFragment ??
        () {
          stage('fragment');
          return absent == 'fragment' ? null : 'fragment';
        },
    fragmentView: (_) {
      stage('view');
      return absent == 'view' ? null : 'view';
    },
    viewBinding: (_) {
      stage('binding');
      return absent == 'binding' ? null : 'binding';
    },
    bindingBottomNavigation: (_) {
      stage('navigation');
      return absent == 'navigation' ? null : 'navigation';
    },
    bottomNavigationIsVisible: (_) {
      stage('visibility');
      return visibility;
    },
    noteTypeHasChanged: noteTypeHasChanged,
    setDiscardCallbackEnabled: (value) {
      if (invoke != null) {
        invoke('setEnabled');
      } else {
        setEnabled(value);
      }
    },
  );
}
