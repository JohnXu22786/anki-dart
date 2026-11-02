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
 * Behavioral reference: BindingMap.kt, MappableBinding.kt, ReviewerBinding.kt,
 * ViewerCommand.kt, and BindingMapTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewerBindingMap', () {
    test('retains duplicate gesture registrations in action and list order',
        () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.ANSWER_GOOD: [
            ReviewerBindingValue.forGesture(Gesture.tapCenter),
          ],
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forGesture(
              Gesture.tapCenter,
              side: ReviewerCardSide.question,
            ),
            ReviewerBindingValue.forGesture(
              Gesture.tapCenter,
              side: ReviewerCardSide.answer,
            ),
          ],
        },
      );

      final mapped = bindings.bindingsForGesture(Gesture.tapCenter);
      expect(
        mapped.map((entry) => entry.command),
        [
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.ANSWER_GOOD,
        ],
      );
      expect(
        mapped.map((entry) => entry.binding.side),
        [
          ReviewerCardSide.question,
          ReviewerCardSide.answer,
          ReviewerCardSide.both,
        ],
      );
      expect(bindings.isGestureBound(Gesture.tapCenter), isTrue);
      expect(bindings.isGestureBound(Gesture.tapLeft), isFalse);
    });

    test('looks up key bindings without filtering by reviewer card side', () {
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.ANSWER_GOOD: [
            ReviewerBindingValue.forKeyCode(
              88,
              side: ReviewerCardSide.answer,
            ),
          ],
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forKeyCode(
              88,
              side: ReviewerCardSide.question,
            ),
          ],
        },
      );

      final mapped = bindings.bindingsForKey(
        ReviewerKeyCodeBinding(keyCode: 88),
      );
      expect(
        mapped.map((entry) => entry.command),
        [ViewerCommand.SHOW_ANSWER, ViewerCommand.ANSWER_GOOD],
      );
      expect(
        mapped.map((entry) => entry.binding.side),
        [ReviewerCardSide.question, ReviewerCardSide.answer],
      );
      expect(
        bindings.bindingsForKey(
          ReviewerKeyCodeBinding(
            keyCode: 88,
            modifierKeys: const ReviewerModifierKeys(ctrl: true),
          ),
        ),
        isEmpty,
      );
    });

    test('keeps axis registrations separate and skips unknown bindings', () {
      const codec = ReviewerBindingCodec();
      final axis = codec.decode('1/r◯0 0.25 2').single;
      final unknown = codec.decode('1/r?2').single;
      final bindings = ReviewerBindingMap(
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [axis, unknown],
        },
      );

      expect(bindings.axisRegistrations, hasLength(1));
      expect(
          bindings.axisRegistrations.single.command, ViewerCommand.SHOW_ANSWER);
      expect(bindings.axisRegistrations.single.binding, axis);
      expect(bindings.bindingsForKey(axis.binding), isEmpty);
      expect(bindings.bindingsForKey(unknown.binding), isEmpty);
      expect(bindings.bindingsForGesture(Gesture.tapCenter), isEmpty);
      expect(bindings.isGestureBound(Gesture.tapCenter), isFalse);
    });

    test('uses explicit action order and does not supply missing defaults', () {
      final bindings = ReviewerBindingMap(
        actions: [ViewerCommand.ANSWER_GOOD, ViewerCommand.SHOW_ANSWER],
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            ReviewerBindingValue.forGesture(Gesture.tapCenter),
          ],
          ViewerCommand.ANSWER_GOOD: [
            ReviewerBindingValue.forGesture(Gesture.tapCenter),
          ],
        },
      );

      expect(
        bindings
            .bindingsForGesture(Gesture.tapCenter)
            .map((entry) => entry.command),
        [ViewerCommand.ANSWER_GOOD, ViewerCommand.SHOW_ANSWER],
      );
      expect(
        ReviewerBindingMap(bindingsByCommand: const {})
            .bindingsForGesture(Gesture.tapCenter),
        isEmpty,
      );
    });
  });
}
