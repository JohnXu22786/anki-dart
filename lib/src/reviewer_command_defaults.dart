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
 * Behavioral reference: ViewerCommand.kt, Binding.kt, and ReviewerBinding.kt
 * in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_command_router.dart';
import 'reviewer_binding_codec.dart';

/// A source default binding descriptor with reviewer card-side metadata.
sealed class ReviewerDefaultBinding {
  const ReviewerDefaultBinding({required this.side});

  final ReviewerCardSide side;
}

/// One source default key-code binding, kept symbolic until host resolution.
final class ReviewerDefaultKeyCode extends ReviewerDefaultBinding {
  const ReviewerDefaultKeyCode(
    this.androidKeyCodeName, {
    required super.side,
    this.modifierKeys = ReviewerModifierKeys.none,
  });

  /// The Android `KeyEvent` constant name, such as `KEYCODE_NUMPAD_1`.
  final String androidKeyCodeName;

  final ReviewerModifierKeys modifierKeys;
}

/// One source default Unicode binding, represented as its UTF-16 code unit.
final class ReviewerDefaultUnicode extends ReviewerDefaultBinding {
  const ReviewerDefaultUnicode(this.codeUnit, {required super.side});

  final int codeUnit;
}

/// Pure `ViewerCommand.defaultValue` definitions from AnkiDroid 2.25.3.
///
/// Android key-code constants stay symbolic in [byCommand]. The host supplies
/// their numeric values to [resolve], so this package does not depend on the
/// Android SDK. Callers should use these defaults only when no preference value
/// is configured; an explicitly configured empty or invalid preference is a
/// separate host/codec decision.
abstract final class ReviewerDefaultBindings {
  static const byCommand = <ViewerCommand, List<ReviewerDefaultBinding>>{
    ViewerCommand.SHOW_ANSWER: [],
    ViewerCommand.ANSWER_AGAIN: [
      ReviewerDefaultKeyCode(
        'KEYCODE_BUTTON_Y',
        side: ReviewerCardSide.answer,
      ),
      ReviewerDefaultKeyCode('KEYCODE_1', side: ReviewerCardSide.answer),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_1',
        side: ReviewerCardSide.answer,
      ),
    ],
    ViewerCommand.ANSWER_HARD: [
      ReviewerDefaultKeyCode(
        'KEYCODE_BUTTON_X',
        side: ReviewerCardSide.answer,
      ),
      ReviewerDefaultKeyCode('KEYCODE_2', side: ReviewerCardSide.answer),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_2',
        side: ReviewerCardSide.answer,
      ),
    ],
    ViewerCommand.ANSWER_GOOD: [
      ReviewerDefaultKeyCode(
        'KEYCODE_BUTTON_B',
        side: ReviewerCardSide.answer,
      ),
      ReviewerDefaultKeyCode('KEYCODE_3', side: ReviewerCardSide.answer),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_3',
        side: ReviewerCardSide.answer,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_DPAD_CENTER',
        side: ReviewerCardSide.answer,
      ),
      ReviewerDefaultKeyCode('KEYCODE_SPACE', side: ReviewerCardSide.answer),
      ReviewerDefaultKeyCode('KEYCODE_ENTER', side: ReviewerCardSide.answer),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_ENTER',
        side: ReviewerCardSide.answer,
      ),
    ],
    ViewerCommand.ANSWER_EASY: [
      ReviewerDefaultKeyCode(
        'KEYCODE_BUTTON_A',
        side: ReviewerCardSide.answer,
      ),
      ReviewerDefaultKeyCode('KEYCODE_4', side: ReviewerCardSide.answer),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_4',
        side: ReviewerCardSide.answer,
      ),
    ],
    ViewerCommand.UNDO: [
      ReviewerDefaultKeyCode(
        'KEYCODE_Z',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.REDO: [
      ReviewerDefaultKeyCode(
        'KEYCODE_Z',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys(shift: true, ctrl: true),
      ),
    ],
    ViewerCommand.EDIT: [
      ReviewerDefaultKeyCode('KEYCODE_E', side: ReviewerCardSide.both),
    ],
    ViewerCommand.MARK: [
      ReviewerDefaultUnicode(0x2a, side: ReviewerCardSide.both),
    ],
    ViewerCommand.BURY_CARD: [
      ReviewerDefaultUnicode(0x2d, side: ReviewerCardSide.both),
    ],
    ViewerCommand.SUSPEND_CARD: [
      ReviewerDefaultUnicode(0x40, side: ReviewerCardSide.both),
    ],
    ViewerCommand.DELETE: [],
    ViewerCommand.PLAY_MEDIA: [
      ReviewerDefaultKeyCode('KEYCODE_R', side: ReviewerCardSide.both),
      ReviewerDefaultKeyCode('KEYCODE_F5', side: ReviewerCardSide.both),
    ],
    ViewerCommand.EXIT: [],
    ViewerCommand.BURY_NOTE: [
      ReviewerDefaultUnicode(0x3d, side: ReviewerCardSide.both),
    ],
    ViewerCommand.SUSPEND_NOTE: [
      ReviewerDefaultUnicode(0x21, side: ReviewerCardSide.both),
    ],
    ViewerCommand.TOGGLE_FLAG_RED: [
      ReviewerDefaultKeyCode(
        'KEYCODE_1',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_1',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.TOGGLE_FLAG_ORANGE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_2',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_2',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.TOGGLE_FLAG_GREEN: [
      ReviewerDefaultKeyCode(
        'KEYCODE_3',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_3',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.TOGGLE_FLAG_BLUE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_4',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_4',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.TOGGLE_FLAG_PINK: [
      ReviewerDefaultKeyCode(
        'KEYCODE_5',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_5',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.TOGGLE_FLAG_TURQUOISE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_6',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_6',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.TOGGLE_FLAG_PURPLE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_7',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
      ReviewerDefaultKeyCode(
        'KEYCODE_NUMPAD_7',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.control,
      ),
    ],
    ViewerCommand.UNSET_FLAG: [],
    ViewerCommand.PAGE_UP: [],
    ViewerCommand.PAGE_DOWN: [],
    ViewerCommand.TAG: [],
    ViewerCommand.CARD_INFO: [],
    ViewerCommand.PREVIOUS_CARD_INFO: [
      ReviewerDefaultKeyCode(
        'KEYCODE_I',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys(ctrl: true, alt: true),
      ),
    ],
    ViewerCommand.RECORD_VOICE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_V',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.shiftOnly,
      ),
    ],
    ViewerCommand.SAVE_VOICE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_S',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.shiftOnly,
      ),
    ],
    ViewerCommand.REPLAY_VOICE: [
      ReviewerDefaultKeyCode('KEYCODE_V', side: ReviewerCardSide.both),
    ],
    ViewerCommand.TOGGLE_WHITEBOARD: [],
    ViewerCommand.TOGGLE_ERASER: [],
    ViewerCommand.CLEAR_WHITEBOARD: [],
    ViewerCommand.CHANGE_WHITEBOARD_PEN_COLOR: [],
    ViewerCommand.SHOW_HINT: [
      ReviewerDefaultKeyCode('KEYCODE_H', side: ReviewerCardSide.both),
    ],
    ViewerCommand.SHOW_ALL_HINTS: [
      ReviewerDefaultKeyCode('KEYCODE_G', side: ReviewerCardSide.both),
    ],
    ViewerCommand.ADD_NOTE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_A',
        side: ReviewerCardSide.both,
      ),
    ],
    ViewerCommand.RESCHEDULE_NOTE: [],
    ViewerCommand.TOGGLE_AUTO_ADVANCE: [
      ReviewerDefaultKeyCode(
        'KEYCODE_A',
        side: ReviewerCardSide.both,
        modifierKeys: ReviewerModifierKeys.shiftOnly,
      ),
    ],
    ViewerCommand.USER_ACTION_1: [],
    ViewerCommand.USER_ACTION_2: [],
    ViewerCommand.USER_ACTION_3: [],
    ViewerCommand.USER_ACTION_4: [],
    ViewerCommand.USER_ACTION_5: [],
    ViewerCommand.USER_ACTION_6: [],
    ViewerCommand.USER_ACTION_7: [],
    ViewerCommand.USER_ACTION_8: [],
    ViewerCommand.USER_ACTION_9: [],
  };

  /// Resolves one command's defaults into the existing typed binding values.
  ///
  /// Throws [StateError] when the host omits a key name used by the source
  /// table. Numeric values and duplicates are retained exactly as supplied.
  static List<ReviewerBindingValue> resolve(
    ViewerCommand command, {
    required Map<String, int> androidKeyCodes,
  }) {
    final resolved = <ReviewerBindingValue>[];
    for (final spec in byCommand[command]!) {
      switch (spec) {
        case ReviewerDefaultKeyCode():
          final keyCode = androidKeyCodes[spec.androidKeyCodeName];
          if (keyCode == null) {
            throw StateError(
              'Missing Android key-code mapping for ${spec.androidKeyCodeName}',
            );
          }
          resolved.add(
            ReviewerBindingValue.forKeyCode(
              keyCode,
              modifierKeys: spec.modifierKeys,
              side: spec.side,
            ),
          );
        case ReviewerDefaultUnicode():
          resolved.add(
            ReviewerBindingValue.forUnicodeCharacter(
              spec.codeUnit,
              side: spec.side,
            ),
          );
      }
    }
    return List.unmodifiable(resolved);
  }
}
