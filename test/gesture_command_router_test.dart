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
 * Behavioral reference: GestureProcessor.kt, ViewerCommand.kt, and
 * GestureProcessorTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GestureCommandRouter', () {
    test('preserves ViewerCommand source order and later duplicate wins', () {
      expect(
        ViewerCommand.values.map((command) => command.name),
        [
          'SHOW_ANSWER',
          'ANSWER_AGAIN',
          'ANSWER_HARD',
          'ANSWER_GOOD',
          'ANSWER_EASY',
          'UNDO',
          'REDO',
          'EDIT',
          'MARK',
          'BURY_CARD',
          'SUSPEND_CARD',
          'DELETE',
          'PLAY_MEDIA',
          'EXIT',
          'BURY_NOTE',
          'SUSPEND_NOTE',
          'TOGGLE_FLAG_RED',
          'TOGGLE_FLAG_ORANGE',
          'TOGGLE_FLAG_GREEN',
          'TOGGLE_FLAG_BLUE',
          'TOGGLE_FLAG_PINK',
          'TOGGLE_FLAG_TURQUOISE',
          'TOGGLE_FLAG_PURPLE',
          'UNSET_FLAG',
          'PAGE_UP',
          'PAGE_DOWN',
          'TAG',
          'CARD_INFO',
          'PREVIOUS_CARD_INFO',
          'RECORD_VOICE',
          'SAVE_VOICE',
          'REPLAY_VOICE',
          'TOGGLE_WHITEBOARD',
          'TOGGLE_ERASER',
          'CLEAR_WHITEBOARD',
          'CHANGE_WHITEBOARD_PEN_COLOR',
          'SHOW_HINT',
          'SHOW_ALL_HINTS',
          'ADD_NOTE',
          'RESCHEDULE_NOTE',
          'TOGGLE_AUTO_ADVANCE',
          'USER_ACTION_1',
          'USER_ACTION_2',
          'USER_ACTION_3',
          'USER_ACTION_4',
          'USER_ACTION_5',
          'USER_ACTION_6',
          'USER_ACTION_7',
          'USER_ACTION_8',
          'USER_ACTION_9',
        ],
      );

      final router = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: true,
        bindingsByCommand: {
          // Deliberately reverse insertion order: source enum order wins.
          ViewerCommand.ANSWER_GOOD: [Gesture.tapCenter],
          ViewerCommand.SHOW_ANSWER: [Gesture.tapCenter],
        },
        executeCommand: (command, _) => command == ViewerCommand.ANSWER_GOOD,
      );

      expect(router.route(Gesture.tapCenter), isTrue);
    });

    test('matches GestureProcessor center-tap command dispatch', () {
      final executed = <ViewerCommand>[];
      final router = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: true,
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [Gesture.tapCenter],
        },
        executeCommand: (command, _) {
          executed.add(command);
          return true;
        },
      );

      expect(router.route(Gesture.tapCenter), isTrue);
      expect(executed, [ViewerCommand.SHOW_ANSWER]);
    });

    test('only includes corner tap bindings when corner touch is enabled', () {
      const bindings = {
        ViewerCommand.SHOW_ANSWER: [Gesture.tapCenter],
        ViewerCommand.ANSWER_GOOD: [Gesture.tapLeft],
      };
      final withoutCorners = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: false,
        bindingsByCommand: bindings,
        executeCommand: (_, __) => true,
      );
      final withCorners = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: true,
        bindingsByCommand: bindings,
        executeCommand: (_, __) => true,
      );

      expect(withoutCorners.route(Gesture.tapCenter), isFalse);
      expect(withoutCorners.isBound([Gesture.tapCenter]), isFalse);
      expect(withoutCorners.route(Gesture.tapLeft), isTrue);
      expect(withCorners.route(Gesture.tapCenter), isTrue);
    });

    test('keeps the three multi-finger gestures unmapped', () {
      final router = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: true,
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [
            Gesture.twoFingerTap,
            Gesture.threeFingerTap,
            Gesture.fourFingerTap,
          ],
        },
        executeCommand: (_, __) => true,
      );

      expect(
        router.route(Gesture.twoFingerTap),
        isFalse,
      );
      expect(router.route(Gesture.threeFingerTap), isFalse);
      expect(router.route(Gesture.fourFingerTap), isFalse);
      expect(
        router.isBound([
          Gesture.twoFingerTap,
          Gesture.threeFingerTap,
          Gesture.fourFingerTap,
        ]),
        isFalse,
      );
    });

    test('isEnabled gates isBound but not execution', () {
      var executionCount = 0;
      final router = GestureCommandRouter(
        isEnabled: false,
        cornerTouchEnabled: false,
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [Gesture.tapLeft],
        },
        executeCommand: (_, __) {
          executionCount++;
          return true;
        },
      );

      expect(router.isBound([Gesture.tapLeft]), isFalse);
      expect(router.route(Gesture.tapLeft), isTrue);
      expect(executionCount, 1);
    });

    test('returns false for absent gestures and null without an executor', () {
      final unmapped = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: false,
        bindingsByCommand: const {},
        executeCommand: (_, __) => true,
      );
      final noExecutor = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: false,
        bindingsByCommand: {
          ViewerCommand.SHOW_ANSWER: [Gesture.tapLeft],
        },
      );

      expect(unmapped.route(null), isFalse);
      expect(unmapped.route(Gesture.tapLeft), isFalse);
      expect(noExecutor.route(null), isFalse);
      expect(noExecutor.route(Gesture.tapLeft), isNull);
    });

    test('forwards the command and gesture and returns executor result', () {
      final calls = <(ViewerCommand, Gesture?)>[];
      final router = GestureCommandRouter(
        isEnabled: true,
        cornerTouchEnabled: false,
        bindingsByCommand: {
          ViewerCommand.ANSWER_AGAIN: [Gesture.swipeUp],
        },
        executeCommand: (command, gesture) {
          calls.add((command, gesture));
          return false;
        },
      );

      expect(router.route(Gesture.swipeUp), isFalse);
      expect(calls, [(ViewerCommand.ANSWER_AGAIN, Gesture.swipeUp)]);
    });
  });
}
