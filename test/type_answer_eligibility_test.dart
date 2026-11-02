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
 * Source-derived checks for `TypeAnswer.validForEditText` and
 * `TypeAnswer.autoFocusEditText`.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test('validity requires no input tag and a non-null answer', () {
    for (final useInputTag in [false, true]) {
      for (final correctAnswer in <String?>[null, '', 'answer']) {
        expect(
          typeAnswerValidForEditText(
            useInputTag: useInputTag,
            correctAnswer: correctAnswer,
          ),
          !useInputTag && correctAnswer != null,
          reason: 'useInputTag=$useInputTag, correctAnswer=$correctAnswer',
        );
      }
    }

    expect(
      typeAnswerValidForEditText(useInputTag: false, correctAnswer: ''),
      isTrue,
      reason: 'the source tests non-null, not nonempty, correct answers',
    );
  });

  test('autofocus additionally requires the autoFocus option', () {
    for (final useInputTag in [false, true]) {
      for (final correctAnswer in <String?>[null, '', 'answer']) {
        for (final autoFocus in [false, true]) {
          expect(
            typeAnswerAutoFocusEditText(
              useInputTag: useInputTag,
              correctAnswer: correctAnswer,
              autoFocus: autoFocus,
            ),
            !useInputTag && correctAnswer != null && autoFocus,
            reason:
                'useInputTag=$useInputTag, correctAnswer=$correctAnswer, autoFocus=$autoFocus',
          );
        }
      }
    }
  });
}
