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
 * Behavioral reference: Binding.kt, BindingMap.kt, and MappableBinding.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'reviewer_binding_codec.dart';
import 'reviewer_binding_map.dart';

/// Host-decoded keyboard values needed by AnkiDroid's reviewer key dispatch.
///
/// [unicodeCharForShiftAndNumLockMask] must be the result of Android's
/// `getUnicodeChar(metaState & (META_SHIFT_ON | META_NUM_LOCK_ON))`. A platform
/// adapter supplies this value; this model does not decode Android events or
/// keyboard layouts.
final class ReviewerKeyEventProjection {
  const ReviewerKeyEventProjection({
    required this.keyCode,
    required this.repeatCount,
    required this.shiftPressed,
    required this.ctrlPressed,
    required this.altPressed,
    required this.unicodeCharForShiftAndNumLockMask,
  });

  final int keyCode;
  final int repeatCount;
  final bool shiftPressed;
  final bool ctrlPressed;
  final bool altPressed;
  final int unicodeCharForShiftAndNumLockMask;
}

/// A callback for one command/binding registration selected by a key event.
typedef ReviewerKeyEventProcessor = bool Function(
  ReviewerCommandBinding registration,
);

/// Applies the source key candidate and processor order to a [bindingMap].
///
/// Repeated key-downs are ignored. For other events, a nonzero key code is
/// tried before a nonzero precomputed Unicode result. Unicode is truncated to
/// one UTF-16 code unit like Kotlin `Int.toChar()`. The optional processor
/// mirrors `BindingMap` without a processor: no registration is handled.
bool dispatchReviewerKeyEvent({
  required ReviewerBindingMap bindingMap,
  required ReviewerKeyEventProjection event,
  ReviewerKeyEventProcessor? processor,
}) {
  if (event.repeatCount > 0) return false;

  final modifiers = ReviewerModifierKeys(
    shift: event.shiftPressed,
    ctrl: event.ctrlPressed,
    alt: event.altPressed,
  );
  final candidates = <ReviewerBindingContent>[];
  if (event.keyCode != 0) {
    candidates.add(
      ReviewerKeyCodeBinding(
        keyCode: event.keyCode,
        modifierKeys: modifiers,
      ),
    );
  }

  final unicodeResult = event.unicodeCharForShiftAndNumLockMask;
  if (unicodeResult != 0) {
    final unicodeCodeUnit = unicodeResult & 0xFFFF;
    final unicodeBinding = ReviewerBindingValue.forUnicodeCharacter(
      unicodeCodeUnit,
      modifierKeys: modifiers,
    ).binding;
    // The source factory returns Unknown for its `|` list separator; its
    // cast to KeyBinding fails and possibleKeyBindings drops that candidate.
    if (unicodeBinding is ReviewerUnicodeCharacterBinding) {
      candidates.add(unicodeBinding);
    }
  }

  for (final candidate in candidates) {
    for (final registration in bindingMap.bindingsForKey(candidate)) {
      if (processor?.call(registration) == true) return true;
    }
  }
  return false;
}
