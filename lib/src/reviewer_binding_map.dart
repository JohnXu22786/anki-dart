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
 * and ViewerCommand.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_command_router.dart';
import 'gesture_parser.dart';
import 'reviewer_binding_codec.dart';

/// One binding registration retained by the source `BindingMap`.
///
/// The original reviewer wrapper, including its card side, is retained so a
/// caller can apply side-specific behavior after lookup.
final class ReviewerCommandBinding {
  const ReviewerCommandBinding(this.command, this.binding);

  final ViewerCommand command;
  final ReviewerBindingValue binding;
}

/// Headless construction and lookup for the reviewer specialization of
/// AnkiDroid's `BindingMap`.
///
/// Bindings for a key or gesture are accumulated in action order and then in
/// each action's binding order. Unlike [GestureCommandRouter], a later
/// registration does not overwrite an earlier one. Lookup keys use the
/// underlying `Binding`, so the reviewer card side is preserved in the result
/// but does not filter a lookup. Axis entries are retained separately in
/// source order; interpreting MotionEvents and executing commands are outside
/// this model.
final class ReviewerBindingMap {
  ReviewerBindingMap({
    required Map<ViewerCommand, Iterable<ReviewerBindingValue>>
        bindingsByCommand,
    Iterable<ViewerCommand>? actions,
  }) {
    final keys = <ReviewerBindingContent, List<ReviewerCommandBinding>>{};
    final gestures = <Gesture, List<ReviewerCommandBinding>>{};
    final axes = <ReviewerCommandBinding>[];

    for (final command in actions ?? ViewerCommand.values) {
      for (final binding
          in bindingsByCommand[command] ?? const <ReviewerBindingValue>[]) {
        final mapped = ReviewerCommandBinding(command, binding);
        switch (binding.binding) {
          case ReviewerGestureBinding(:final gesture):
            gestures.putIfAbsent(gesture, () => []).add(mapped);
          case ReviewerKeyCodeBinding() || ReviewerUnicodeCharacterBinding():
            keys.putIfAbsent(binding.binding, () => []).add(mapped);
          case ReviewerAxisButtonBinding():
            axes.add(mapped);
          case ReviewerUnknownBinding():
            break;
        }
      }
    }

    _keyMap = _freezeMap(keys);
    _gestureMap = _freezeMap(gestures);
    axisRegistrations = List.unmodifiable(axes);
  }

  late final Map<ReviewerBindingContent, List<ReviewerCommandBinding>> _keyMap;
  late final Map<Gesture, List<ReviewerCommandBinding>> _gestureMap;

  /// Axis bindings in the action and binding order used during construction.
  /// MotionEvent matching is not implemented here.
  late final List<ReviewerCommandBinding> axisRegistrations;

  /// Registrations for [gesture] in source construction order.
  List<ReviewerCommandBinding> bindingsForGesture(Gesture gesture) =>
      _gestureMap[gesture] ?? const [];

  /// Whether [gesture] has a registration, independent of any command handler.
  bool isGestureBound(Gesture gesture) => _gestureMap.containsKey(gesture);

  /// Registrations for a typed key binding, without card-side filtering.
  /// Non-key bindings return an empty list.
  List<ReviewerCommandBinding> bindingsForKey(
    ReviewerBindingContent binding,
  ) =>
      binding.isKey ? _keyMap[binding] ?? const [] : const [];

  static Map<K, List<V>> _freezeMap<K, V>(Map<K, List<V>> values) =>
      Map.unmodifiable({
        for (final entry in values.entries)
          entry.key: List<V>.unmodifiable(entry.value),
      });
}
