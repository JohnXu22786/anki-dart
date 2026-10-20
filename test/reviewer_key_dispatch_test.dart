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
 * Behavioral reference: Binding.kt, BindingMap.kt, MappableBinding.kt,
 * BindingTest.kt, and BindingMapTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer key event dispatch', () {
    test('ignores repeated key-down events without invoking the processor', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [ReviewerBindingValue.forKeyCode(13)],
        },
      );
      var calls = 0;

      final handled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 13,
          repeatCount: 1,
          shiftPressed: false,
          ctrlPressed: false,
          altPressed: false,
          unicodeCharForShiftAndNumLockMask: 0,
        ),
        processor: (_) {
          calls++;
          return true;
        },
      );

      expect(handled, isFalse);
      expect(calls, 0);
    });

    test('omits zero key and Unicode candidates', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forKeyCode(13),
            ReviewerBindingValue.forUnicodeCharacter(
              0x41,
              modifierKeys: ReviewerModifierKeys.none,
            ),
          ],
        },
      );
      var calls = 0;

      final handled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 0,
          repeatCount: 0,
          shiftPressed: false,
          ctrlPressed: false,
          altPressed: false,
          unicodeCharForShiftAndNumLockMask: 0,
        ),
        processor: (_) {
          calls++;
          return true;
        },
      );

      expect(handled, isFalse);
      expect(calls, 0);
    });

    test('tries the key-code candidate before the Unicode candidate', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forKeyCode(
              13,
              side: ReviewerCardSide.question,
            ),
            ReviewerBindingValue.forUnicodeCharacter(
              0x41,
              modifierKeys: ReviewerModifierKeys.none,
              side: ReviewerCardSide.answer,
            ),
          ],
        },
      );
      final seen = <ReviewerCommandBinding>[];

      final handled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 13,
          repeatCount: 0,
          shiftPressed: false,
          ctrlPressed: false,
          altPressed: false,
          unicodeCharForShiftAndNumLockMask: 0x41,
        ),
        processor: (binding) {
          seen.add(binding);
          return binding.binding.binding is ReviewerUnicodeCharacterBinding;
        },
      );

      expect(handled, isTrue);
      expect(seen.map((binding) => binding.binding.binding), [
        isA<ReviewerKeyCodeBinding>(),
        isA<ReviewerUnicodeCharacterBinding>(),
      ]);
      expect(
        seen.map((binding) => binding.binding.side),
        [ReviewerCardSide.question, ReviewerCardSide.answer],
      );
    });

    test('uses exact Shift, Ctrl, and Alt states for both candidate kinds', () {
      const allModifiers = ReviewerModifierKeys(
        shift: true,
        ctrl: true,
        alt: true,
      );
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forKeyCode(
              13,
              modifierKeys: allModifiers,
            ),
            ReviewerBindingValue.forUnicodeCharacter(
              0x41,
              modifierKeys: allModifiers,
            ),
          ],
        },
      );
      final seen = <ReviewerBindingContent>[];

      final exactModifiersHandled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 13,
          repeatCount: 0,
          shiftPressed: true,
          ctrlPressed: true,
          altPressed: true,
          unicodeCharForShiftAndNumLockMask: 0x41,
        ),
        processor: (registration) {
          seen.add(registration.binding.binding);
          return false;
        },
      );

      expect(exactModifiersHandled, isFalse);
      expect(seen, hasLength(2));

      seen.clear();
      final differentModifiersHandled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 13,
          repeatCount: 0,
          shiftPressed: false,
          ctrlPressed: true,
          altPressed: true,
          unicodeCharForShiftAndNumLockMask: 0x41,
        ),
        processor: (registration) {
          seen.add(registration.binding.binding);
          return true;
        },
      );

      expect(differentModifiersHandled, isFalse);
      expect(seen, isEmpty);
    });

    test('truncates Unicode results to Kotlin Char low 16 bits', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forUnicodeCharacter(
              0x41,
              modifierKeys: ReviewerModifierKeys.none,
            ),
            ReviewerBindingValue.forUnicodeCharacter(
              0xFFFF,
              modifierKeys: ReviewerModifierKeys.none,
            ),
          ],
        },
      );
      final seen = <int>[];

      for (final unicodeResult in [0x10041, -1]) {
        dispatchReviewerKeyEvent(
          bindingMap: bindings,
          event: ReviewerKeyEventProjection(
            keyCode: 0,
            repeatCount: 0,
            shiftPressed: false,
            ctrlPressed: false,
            altPressed: false,
            unicodeCharForShiftAndNumLockMask: unicodeResult,
          ),
          processor: (registration) {
            seen.add(
              (registration.binding.binding as ReviewerUnicodeCharacterBinding)
                  .codeUnit,
            );
            return true;
          },
        );
      }

      expect(seen, [0x41, 0xFFFF]);
    });

    test('keeps a nonzero result whose low 16 bits are zero', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forUnicodeCharacter(
              0,
              modifierKeys: ReviewerModifierKeys.none,
            ),
          ],
        },
      );
      var calls = 0;

      final handled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 0,
          repeatCount: 0,
          shiftPressed: false,
          ctrlPressed: false,
          altPressed: false,
          unicodeCharForShiftAndNumLockMask: 0x10000,
        ),
        processor: (_) {
          calls++;
          return true;
        },
      );

      expect(handled, isTrue);
      expect(calls, 1);
    });

    test('omits the separator Unicode candidate but still tries key code', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forKeyCode(13),
            ReviewerBindingValue.forUnicodeCharacter(
              0x7C,
              modifierKeys: ReviewerModifierKeys.none,
            ),
          ],
        },
      );
      final seen = <ReviewerBindingContent>[];

      final handled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 13,
          repeatCount: 0,
          shiftPressed: false,
          ctrlPressed: false,
          altPressed: false,
          unicodeCharForShiftAndNumLockMask: 0x7C,
        ),
        processor: (registration) {
          seen.add(registration.binding.binding);
          return false;
        },
      );

      expect(handled, isFalse);
      expect(seen, hasLength(1));
      expect(seen.single, isA<ReviewerKeyCodeBinding>());
    });

    test('keeps registration order and stops at the first true processor', () {
      final bindings = ReviewerBindingMap(
        actions: [
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.ANSWER_GOOD,
          ViewerCommand.ANSWER_EASY,
        ],
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forKeyCode(
              13,
              side: ReviewerCardSide.question,
            ),
            ReviewerBindingValue.forKeyCode(
              13,
              side: ReviewerCardSide.answer,
            ),
          ],
          ViewerCommand.ANSWER_GOOD: [
            ReviewerBindingValue.forKeyCode(13),
          ],
          ViewerCommand.ANSWER_EASY: [
            ReviewerBindingValue.forKeyCode(13),
          ],
        },
      );
      final seen = <ReviewerCommandBinding>[];

      final handled = dispatchReviewerKeyEvent(
        bindingMap: bindings,
        event: const ReviewerKeyEventProjection(
          keyCode: 13,
          repeatCount: 0,
          shiftPressed: false,
          ctrlPressed: false,
          altPressed: false,
          unicodeCharForShiftAndNumLockMask: 0,
        ),
        processor: (registration) {
          seen.add(registration);
          return registration.command == ViewerCommand.ANSWER_GOOD;
        },
      );

      expect(handled, isTrue);
      expect(
        seen.map((registration) => registration.command),
        [
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.ANSWER_GOOD,
        ],
      );
      expect(
        seen.map((registration) => registration.binding.side),
        [
          ReviewerCardSide.question,
          ReviewerCardSide.answer,
          ReviewerCardSide.both,
        ],
      );
    });

    test('returns false after rejected or absent processors', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [ReviewerBindingValue.forKeyCode(13)],
        },
      );
      var calls = 0;
      const event = ReviewerKeyEventProjection(
        keyCode: 13,
        repeatCount: 0,
        shiftPressed: false,
        ctrlPressed: false,
        altPressed: false,
        unicodeCharForShiftAndNumLockMask: 0,
      );

      expect(
        dispatchReviewerKeyEvent(
          bindingMap: bindings,
          event: event,
          processor: (_) {
            calls++;
            return false;
          },
        ),
        isFalse,
      );
      expect(calls, 1);
      expect(
        dispatchReviewerKeyEvent(bindingMap: bindings, event: event),
        isFalse,
      );
    });
  });
}
