/*
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
 * Source-derived from CardTemplateFragment.onModelSaved in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentOnModelSaved', () {
    test('runs logging, button enable, clear, and finish in source order', () {
      final events = <String>[];
      final button = Object();

      cardTemplateFragmentOnModelSaved(
        callbacks: _callbacks(
          events,
          button: button,
          enableButton: (actual) {
            expect(actual, same(button));
            events.add('enable button');
          },
        ),
      );

      expect(events, [
        'debug:saveModelAndExitHandler::postExecute called',
        'find confirm button',
        'enable button',
        'clear temporary note type',
        'finish activity',
      ]);
    });

    test('null button skips enabling and still clears and finishes', () {
      final events = <String>[];

      cardTemplateFragmentOnModelSaved(
        callbacks: _callbacks(events, button: null),
      );

      expect(events, [
        'debug:saveModelAndExitHandler::postExecute called',
        'find confirm button',
        'clear temporary note type',
        'finish activity',
      ]);
    });

    test('callback failures propagate and stop later source effects', () {
      final cases = <({String failedAt, List<String> expected})>[
        (
          failedAt: 'find confirm button',
          expected: [
            'debug:saveModelAndExitHandler::postExecute called',
            'find confirm button',
          ],
        ),
        (
          failedAt: 'enable button',
          expected: [
            'debug:saveModelAndExitHandler::postExecute called',
            'find confirm button',
            'enable button',
          ],
        ),
        (
          failedAt: 'clear temporary note type',
          expected: [
            'debug:saveModelAndExitHandler::postExecute called',
            'find confirm button',
            'enable button',
            'clear temporary note type',
          ],
        ),
      ];

      for (final testCase in cases) {
        final events = <String>[];
        final failure = StateError(testCase.failedAt);

        expect(
          () => cardTemplateFragmentOnModelSaved(
            callbacks: _callbacks(
              events,
              button: Object(),
              failAt: testCase.failedAt,
              failure: failure,
            ),
          ),
          throwsA(same(failure)),
          reason: testCase.failedAt,
        );
        expect(events, testCase.expected, reason: testCase.failedAt);
      }
    });
  });
}

CardTemplateFragmentOnModelSavedCallbacks<Object> _callbacks(
  List<String> events, {
  required Object? button,
  String? failAt,
  Object? failure,
  void Function(Object button)? enableButton,
}) {
  void hit(String event) {
    events.add(event);
    if (event == failAt) throw failure!;
  }

  return CardTemplateFragmentOnModelSavedCallbacks<Object>(
    debug: (message) => hit('debug:$message'),
    findConfirmButton: () {
      hit('find confirm button');
      return button;
    },
    enableButton: (button) {
      (enableButton ?? (_) => hit('enable button'))(button);
      if (failAt == 'enable button' && enableButton != null) {
        throw failure!;
      }
    },
    clearTemporaryNoteType: () => hit('clear temporary note type'),
    finishActivity: () => hit('finish activity'),
  );
}
