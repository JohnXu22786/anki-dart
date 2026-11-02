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
 * Behavioral reference: ViewerCommand.kt and MappableBindingTest.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

const _hostKeyCodes = <String, int>{
  'KEYCODE_BUTTON_Y': 1001,
  'KEYCODE_1': 8,
  'KEYCODE_NUMPAD_1': 145,
  'KEYCODE_BUTTON_X': 1002,
  'KEYCODE_2': 9,
  'KEYCODE_NUMPAD_2': 146,
  'KEYCODE_BUTTON_B': 1003,
  'KEYCODE_3': 10,
  'KEYCODE_NUMPAD_3': 147,
  'KEYCODE_DPAD_CENTER': 23,
  'KEYCODE_SPACE': 62,
  'KEYCODE_ENTER': 66,
  'KEYCODE_NUMPAD_ENTER': 160,
  'KEYCODE_BUTTON_A': 1004,
  'KEYCODE_4': 11,
  'KEYCODE_NUMPAD_4': 148,
  'KEYCODE_E': 33,
  'KEYCODE_R': 46,
  'KEYCODE_F5': 135,
  'KEYCODE_V': 50,
  'KEYCODE_S': 47,
  'KEYCODE_Z': 54,
  'KEYCODE_I': 37,
  'KEYCODE_5': 12,
  'KEYCODE_NUMPAD_5': 149,
  'KEYCODE_6': 13,
  'KEYCODE_NUMPAD_6': 150,
  'KEYCODE_7': 14,
  'KEYCODE_NUMPAD_7': 151,
  'KEYCODE_A': 29,
  'KEYCODE_H': 36,
  'KEYCODE_G': 35,
};

ReviewerBindingValue _resolveOne(
  ViewerCommand command, {
  required Map<String, int> keyCodes,
}) =>
    ReviewerDefaultBindings.resolve(command, androidKeyCodes: keyCodes).single;

void main() {
  group('ReviewerDefaultBindings', () {
    test('defines every command and retains the source empty-default branch',
        () {
      expect(
        ReviewerDefaultBindings.byCommand.keys.toSet(),
        ViewerCommand.values.toSet(),
      );

      final emptyDefaults = ReviewerDefaultBindings.byCommand.entries
          .where((entry) => entry.value.isEmpty)
          .map((entry) => entry.key)
          .toSet();
      expect(
        emptyDefaults,
        {
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.DELETE,
          ViewerCommand.EXIT,
          ViewerCommand.UNSET_FLAG,
          ViewerCommand.PAGE_UP,
          ViewerCommand.PAGE_DOWN,
          ViewerCommand.TAG,
          ViewerCommand.CARD_INFO,
          ViewerCommand.TOGGLE_WHITEBOARD,
          ViewerCommand.TOGGLE_ERASER,
          ViewerCommand.CLEAR_WHITEBOARD,
          ViewerCommand.CHANGE_WHITEBOARD_PEN_COLOR,
          ViewerCommand.RESCHEDULE_NOTE,
          ViewerCommand.USER_ACTION_1,
          ViewerCommand.USER_ACTION_2,
          ViewerCommand.USER_ACTION_3,
          ViewerCommand.USER_ACTION_4,
          ViewerCommand.USER_ACTION_5,
          ViewerCommand.USER_ACTION_6,
          ViewerCommand.USER_ACTION_7,
          ViewerCommand.USER_ACTION_8,
          ViewerCommand.USER_ACTION_9,
        },
      );
      for (final command in emptyDefaults) {
        expect(
          ReviewerDefaultBindings.resolve(
            command,
            androidKeyCodes: _hostKeyCodes,
          ),
          isEmpty,
        );
      }
    });

    test('preserves answer-rating key names, order, and answer-side metadata',
        () {
      const expected = <ViewerCommand, List<int>>{
        ViewerCommand.ANSWER_AGAIN: [1001, 8, 145],
        ViewerCommand.ANSWER_HARD: [1002, 9, 146],
        ViewerCommand.ANSWER_GOOD: [1003, 10, 147, 23, 62, 66, 160],
        ViewerCommand.ANSWER_EASY: [1004, 11, 148],
      };
      for (final entry in expected.entries) {
        final bindings = ReviewerDefaultBindings.resolve(
          entry.key,
          androidKeyCodes: _hostKeyCodes,
        );
        expect(
          bindings.map(
              (binding) => (binding.binding as ReviewerKeyCodeBinding).keyCode),
          entry.value,
          reason: entry.key.name,
        );
        expect(
          bindings.every((binding) => binding.side == ReviewerCardSide.answer),
          isTrue,
          reason: entry.key.name,
        );
      }
    });

    test('keeps Unicode defaults and their app-defined shift matching', () {
      for (final entry in {
        ViewerCommand.MARK: '*',
        ViewerCommand.BURY_CARD: '-',
        ViewerCommand.BURY_NOTE: '=',
        ViewerCommand.SUSPEND_CARD: '@',
        ViewerCommand.SUSPEND_NOTE: '!',
      }.entries) {
        final binding = _resolveOne(entry.key, keyCodes: _hostKeyCodes);
        expect(binding.binding, isA<ReviewerUnicodeCharacterBinding>());
        expect(
          (binding.binding as ReviewerUnicodeCharacterBinding).codeUnit,
          entry.value.codeUnitAt(0),
        );
        expect(binding.side, ReviewerCardSide.both);
        expect(
          (binding.binding as ReviewerUnicodeCharacterBinding)
              .modifierKeys
              .shiftMatches(true),
          isTrue,
        );
        expect(
          (binding.binding as ReviewerUnicodeCharacterBinding)
              .modifierKeys
              .shiftMatches(false),
          isTrue,
        );
      }
    });

    test('preserves modifier flags, side, and same-key distinct commands', () {
      final undo = _resolveOne(ViewerCommand.UNDO, keyCodes: _hostKeyCodes);
      final undoBinding = undo.binding as ReviewerKeyCodeBinding;
      expect(undoBinding.keyCode, 54);
      expect(undoBinding.modifierKeys, const ReviewerModifierKeys(ctrl: true));
      expect(undo.side, ReviewerCardSide.both);

      final redo = _resolveOne(ViewerCommand.REDO, keyCodes: _hostKeyCodes);
      final redoBinding = redo.binding as ReviewerKeyCodeBinding;
      expect(redoBinding.keyCode, 54);
      expect(
        redoBinding.modifierKeys,
        const ReviewerModifierKeys(shift: true, ctrl: true),
      );

      final previousInfo = _resolveOne(
        ViewerCommand.PREVIOUS_CARD_INFO,
        keyCodes: _hostKeyCodes,
      );
      expect(
        (previousInfo.binding as ReviewerKeyCodeBinding).modifierKeys,
        const ReviewerModifierKeys(ctrl: true, alt: true),
      );

      final replayVoice = _resolveOne(
        ViewerCommand.REPLAY_VOICE,
        keyCodes: _hostKeyCodes,
      );
      final recordVoice = _resolveOne(
        ViewerCommand.RECORD_VOICE,
        keyCodes: _hostKeyCodes,
      );
      expect(
        (replayVoice.binding as ReviewerKeyCodeBinding).keyCode,
        (recordVoice.binding as ReviewerKeyCodeBinding).keyCode,
      );
      expect(
        (replayVoice.binding as ReviewerKeyCodeBinding).modifierKeys,
        ReviewerModifierKeys.none,
      );
      expect(
        (recordVoice.binding as ReviewerKeyCodeBinding).modifierKeys,
        ReviewerModifierKeys.shiftOnly,
      );

      final addNote = _resolveOne(
        ViewerCommand.ADD_NOTE,
        keyCodes: _hostKeyCodes,
      );
      final autoAdvance = _resolveOne(
        ViewerCommand.TOGGLE_AUTO_ADVANCE,
        keyCodes: _hostKeyCodes,
      );
      expect(
        (addNote.binding as ReviewerKeyCodeBinding).keyCode,
        (autoAdvance.binding as ReviewerKeyCodeBinding).keyCode,
      );
      expect(
        (addNote.binding as ReviewerKeyCodeBinding).modifierKeys,
        ReviewerModifierKeys.none,
      );
      expect(
        (autoAdvance.binding as ReviewerKeyCodeBinding).modifierKeys,
        ReviewerModifierKeys.shiftOnly,
      );
      expect(addNote.side, ReviewerCardSide.both);
      expect(autoAdvance.side, ReviewerCardSide.both);

      final playMedia = ReviewerDefaultBindings.resolve(
        ViewerCommand.PLAY_MEDIA,
        androidKeyCodes: _hostKeyCodes,
      );
      expect(
        playMedia.map(
            (binding) => (binding.binding as ReviewerKeyCodeBinding).keyCode),
        [46, 135],
      );

      const expected = <ViewerCommand, List<int>>{
        ViewerCommand.TOGGLE_FLAG_RED: [8, 145],
        ViewerCommand.TOGGLE_FLAG_ORANGE: [9, 146],
        ViewerCommand.TOGGLE_FLAG_GREEN: [10, 147],
        ViewerCommand.TOGGLE_FLAG_BLUE: [11, 148],
        ViewerCommand.TOGGLE_FLAG_PINK: [12, 149],
        ViewerCommand.TOGGLE_FLAG_TURQUOISE: [13, 150],
        ViewerCommand.TOGGLE_FLAG_PURPLE: [14, 151],
      };
      for (final entry in expected.entries) {
        final bindings = ReviewerDefaultBindings.resolve(
          entry.key,
          androidKeyCodes: _hostKeyCodes,
        );
        expect(
          bindings.map(
              (binding) => (binding.binding as ReviewerKeyCodeBinding).keyCode),
          entry.value,
          reason: entry.key.name,
        );
        expect(
          bindings.every((binding) =>
              binding.side == ReviewerCardSide.both &&
              (binding.binding as ReviewerKeyCodeBinding).modifierKeys ==
                  ReviewerModifierKeys.control),
          isTrue,
          reason: entry.key.name,
        );
      }
    });

    test('does not deduplicate host-resolved numeric key values', () {
      final bindings = ReviewerDefaultBindings.resolve(
        ViewerCommand.ANSWER_AGAIN,
        androidKeyCodes: {
          ..._hostKeyCodes,
          'KEYCODE_1': 8,
          'KEYCODE_NUMPAD_1': 8,
        },
      );
      expect(
        bindings.map(
            (binding) => (binding.binding as ReviewerKeyCodeBinding).keyCode),
        [1001, 8, 8],
      );
    });

    test('requires every referenced symbolic Android key name', () {
      expect(
        () => ReviewerDefaultBindings.resolve(
          ViewerCommand.EDIT,
          androidKeyCodes: const {},
        ),
        throwsStateError,
      );
    });

    test('matches MappableBinding aggregate positive and negative checks', () {
      final allBindings = [
        for (final command in ViewerCommand.values)
          ...ReviewerDefaultBindings.resolve(
            command,
            androidKeyCodes: _hostKeyCodes,
          ),
      ];

      expect(
        allBindings,
        contains(
          ReviewerBindingValue.forUnicodeCharacter('@'.codeUnitAt(0)),
        ),
      );
      expect(
        allBindings,
        contains(ReviewerBindingValue.forKeyCode(8)),
      );
      expect(
        allBindings,
        isNot(contains(
            ReviewerBindingValue.forUnicodeCharacter('l'.codeUnitAt(0)))),
      );
      expect(
        allBindings,
        isNot(contains(ReviewerBindingValue.forKeyCode(9999))),
      );
    });
  });
}
