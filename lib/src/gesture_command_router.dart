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
 * Behavioral reference: GestureProcessor.kt, Gesture.kt, and ViewerCommand.kt
 * in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_parser.dart';
import 'reviewer_binding_codec.dart';

/// AnkiDroid reviewer commands in the declaration order of `ViewerCommand`.
///
/// The source identifiers and order are retained so duplicate gesture
/// assignments resolve to the same last command as AnkiDroid.
enum ViewerCommand {
  SHOW_ANSWER,
  ANSWER_AGAIN,
  ANSWER_HARD,
  ANSWER_GOOD,
  ANSWER_EASY,
  UNDO,
  REDO,
  EDIT,
  MARK,
  BURY_CARD,
  SUSPEND_CARD,
  DELETE,
  PLAY_MEDIA,
  EXIT,
  BURY_NOTE,
  SUSPEND_NOTE,
  TOGGLE_FLAG_RED,
  TOGGLE_FLAG_ORANGE,
  TOGGLE_FLAG_GREEN,
  TOGGLE_FLAG_BLUE,
  TOGGLE_FLAG_PINK,
  TOGGLE_FLAG_TURQUOISE,
  TOGGLE_FLAG_PURPLE,
  UNSET_FLAG,
  PAGE_UP,
  PAGE_DOWN,
  TAG,
  CARD_INFO,
  PREVIOUS_CARD_INFO,
  RECORD_VOICE,
  SAVE_VOICE,
  REPLAY_VOICE,
  TOGGLE_WHITEBOARD,
  TOGGLE_ERASER,
  CLEAR_WHITEBOARD,
  CHANGE_WHITEBOARD_PEN_COLOR,
  SHOW_HINT,
  SHOW_ALL_HINTS,
  ADD_NOTE,
  RESCHEDULE_NOTE,
  TOGGLE_AUTO_ADVANCE,
  USER_ACTION_1,
  USER_ACTION_2,
  USER_ACTION_3,
  USER_ACTION_4,
  USER_ACTION_5,
  USER_ACTION_6,
  USER_ACTION_7,
  USER_ACTION_8,
  USER_ACTION_9,
}

/// Executes a command selected for a parsed reviewer gesture.
typedef GestureCommandExecutor = bool Function(
  ViewerCommand command,
  Gesture? fromGesture,
);

/// Routes already-parsed gestures using bindings resolved by the host.
///
/// [bindingsByCommand] contains only gesture bindings from the host's binding
/// adapter; preference parsing and non-gesture bindings stay outside this
/// model. Bindings are collected in [ViewerCommand] order, so later commands
/// overwrite earlier commands when they use the same gesture. [isEnabled]
/// gates [isBound], matching AnkiDroid, but does not gate [route].
class GestureCommandRouter {
  /// Builds a router from host-supplied serialized command preference values.
  ///
  /// Missing values stay empty rather than applying `ViewerCommand` keyboard
  /// defaults. Parsed non-gesture bindings are retained by the codec but do not
  /// participate in gesture routing. Card-side suffixes are not an execution
  /// filter in AnkiDroid's `GestureProcessor`.
  factory GestureCommandRouter.fromPreferenceValues({
    required bool isEnabled,
    required bool cornerTouchEnabled,
    required Map<ViewerCommand, String?> serializedBindingsByCommand,
    GestureCommandExecutor? executeCommand,
  }) {
    const codec = ReviewerBindingCodec();
    final bindingsByCommand = <ViewerCommand, Iterable<Gesture>>{};
    for (final command in ViewerCommand.values) {
      bindingsByCommand[command] = codec
          .decode(serializedBindingsByCommand[command])
          .where((binding) => binding.gesture != null)
          .map((binding) => binding.gesture!)
          .toList(growable: false);
    }
    return GestureCommandRouter(
      isEnabled: isEnabled,
      cornerTouchEnabled: cornerTouchEnabled,
      bindingsByCommand: bindingsByCommand,
      executeCommand: executeCommand,
    );
  }

  GestureCommandRouter({
    required this.isEnabled,
    required bool cornerTouchEnabled,
    required Map<ViewerCommand, Iterable<Gesture>> bindingsByCommand,
    this.executeCommand,
  }) : _commandsByGesture = _resolveBindings(
          bindingsByCommand,
          cornerTouchEnabled: cornerTouchEnabled,
        );

  /// Whether callers should consider reviewer gestures enabled.
  ///
  /// AnkiDroid uses this only when reporting whether a gesture is bound.
  final bool isEnabled;

  /// Optional reviewer command executor. A missing executor returns `null`
  /// for a mapped gesture, as the source's nullable processor does.
  final GestureCommandExecutor? executeCommand;

  final Map<Gesture, ViewerCommand> _commandsByGesture;

  /// Whether any supplied gesture has a resolved command while enabled.
  bool isBound(Iterable<Gesture> gestures) =>
      isEnabled && gestures.any(_commandsByGesture.containsKey);

  /// Routes [gesture] to its command.
  ///
  /// A null or unmapped gesture returns `false`. A mapped command returns
  /// `null` when there is no executor, otherwise the executor's result is
  /// returned. This intentionally does not check [isEnabled].
  bool? route(Gesture? gesture) {
    if (gesture == null) return false;
    final command = _commandsByGesture[gesture];
    if (command == null) return false;
    return executeCommand?.call(command, gesture);
  }

  static Map<Gesture, ViewerCommand> _resolveBindings(
    Map<ViewerCommand, Iterable<Gesture>> bindingsByCommand, {
    required bool cornerTouchEnabled,
  }) {
    final commandsByGesture = <Gesture, ViewerCommand>{};
    for (final command in ViewerCommand.values) {
      for (final gesture in bindingsByCommand[command] ?? const <Gesture>[]) {
        if (!_isHandledByGestureProcessor(gesture)) continue;
        if (!cornerTouchEnabled && _cornerTaps.contains(gesture)) continue;
        commandsByGesture[gesture] = command;
      }
    }
    return Map.unmodifiable(commandsByGesture);
  }

  static bool _isHandledByGestureProcessor(Gesture gesture) =>
      switch (gesture) {
        Gesture.twoFingerTap ||
        Gesture.threeFingerTap ||
        Gesture.fourFingerTap =>
          false,
        _ => true,
      };

  static const _cornerTaps = <Gesture>{
    Gesture.tapTopLeft,
    Gesture.tapTopRight,
    Gesture.tapCenter,
    Gesture.tapBottomLeft,
    Gesture.tapBottomRight,
  };
}
