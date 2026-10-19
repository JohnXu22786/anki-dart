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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerBinding.kt, MappableBinding.kt, and
 * ViewerCommand.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewerBindingPreferenceResolver', () {
    test('absent preference resolves ordered command defaults', () {
      final bindings = ReviewerBindingPreferenceResolver.resolve(
        ViewerCommand.ANSWER_GOOD,
        androidKeyCodes: const {
          'KEYCODE_BUTTON_B': 1003,
          'KEYCODE_3': 10,
          'KEYCODE_NUMPAD_3': 147,
          'KEYCODE_DPAD_CENTER': 23,
          'KEYCODE_SPACE': 62,
          'KEYCODE_ENTER': 66,
          'KEYCODE_NUMPAD_ENTER': 160,
        },
      );

      expect(
        bindings.map(
          (binding) => (binding.binding as ReviewerKeyCodeBinding).keyCode,
        ),
        [1003, 10, 147, 23, 62, 66, 160],
      );
      expect(
        bindings.every((binding) => binding.side == ReviewerCardSide.answer),
        isTrue,
      );
    });

    test('present custom preference replaces the command defaults', () {
      final bindings = ReviewerBindingPreferenceResolver.resolve(
        ViewerCommand.ANSWER_GOOD,
        preferenceValue: '1/r⍝TAP_TOP1',
      );

      expect(bindings, hasLength(1));
      expect(bindings.single.gesture, Gesture.tapTop);
      expect(bindings.single.side, ReviewerCardSide.answer);
    });

    test('present empty and empty-version values do not use defaults', () {
      for (final preferenceValue in ['', '1/']) {
        expect(
          ReviewerBindingPreferenceResolver.resolve(
            ViewerCommand.ANSWER_GOOD,
            preferenceValue: preferenceValue,
          ),
          isEmpty,
        );
      }
    });

    test('unknown preference version does not use defaults', () {
      expect(
        ReviewerBindingPreferenceResolver.resolve(
          ViewerCommand.ANSWER_GOOD,
          preferenceValue: '2/r⍝TAP_TOP1',
        ),
        isEmpty,
      );
    });

    test('malformed configured entry remains an unknown binding', () {
      final bindings = ReviewerBindingPreferenceResolver.resolve(
        ViewerCommand.ANSWER_GOOD,
        preferenceValue: '1/r⌨not-a-number0',
      );

      expect(bindings, hasLength(1));
      expect(bindings.single.kind, ReviewerBindingKind.unknown);
    });

    test('configured values do not require a key-code resolver', () {
      final bindings = ReviewerBindingPreferenceResolver.resolve(
        ViewerCommand.ANSWER_GOOD,
        preferenceValue: '1/r⌨711',
      );

      expect(bindings.single.binding, isA<ReviewerKeyCodeBinding>());
      expect(
        (bindings.single.binding as ReviewerKeyCodeBinding).keyCode,
        71,
      );
    });
  });
}
