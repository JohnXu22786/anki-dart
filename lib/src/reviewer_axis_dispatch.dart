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
 * Behavioral reference: SingleAxisDetector.kt, BindingMap.kt, Binding.kt, and
 * Axis.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'reviewer_binding_codec.dart';
import 'reviewer_binding_map.dart';

/// Supplies one source Float32 axis value for a host-projected motion sample.
///
/// The platform adapter should read the requested value from its motion event.
/// This model does not decode Android `MotionEvent` objects or choose devices.
typedef ReviewerAxisValueProvider = double Function(int axisValue);

/// A callback for one axis registration emitted by the source debounce logic.
///
/// Its result is intentionally ignored while the event is processed, matching
/// `BindingMap.onGenericMotionEvent()`.
typedef ReviewerAxisEventProcessor = bool Function(
  ReviewerCommandBinding registration,
);

/// Applies source axis-button threshold, debounce, and dispatch behavior.
///
/// The dispatcher takes one independent debounce state for each axis
/// registration in [bindingMap]'s construction order. A null [valueForAxis]
/// represents a null source event and returns false without changing state.
/// The host should return the platform's Float32 axis value as a Dart double.
final class ReviewerAxisButtonDispatcher {
  ReviewerAxisButtonDispatcher({required ReviewerBindingMap bindingMap})
      : _detectors = List.unmodifiable([
          for (final registration in bindingMap.axisRegistrations)
            _SingleAxisDetector(registration),
        ]);

  final List<_SingleAxisDetector> _detectors;

  /// Processes one host-projected generic-motion event.
  ///
  /// Every detector is evaluated in registration order. The return value is
  /// true if any registration fired, regardless of whether [processor] exists
  /// or returns true. Passing null for [valueForAxis] preserves the source
  /// null-event behavior and does not rearm detectors.
  bool onGenericMotionEvent({
    required ReviewerAxisValueProvider? valueForAxis,
    ReviewerAxisEventProcessor? processor,
  }) {
    if (valueForAxis == null || _detectors.isEmpty) return false;

    var processed = false;
    for (final detector in _detectors) {
      final registration = detector.getAction(valueForAxis);
      if (registration == null) continue;
      processed = true;
      processor?.call(registration);
    }
    return processed;
  }
}

final class _SingleAxisDetector {
  _SingleAxisDetector(this.registration)
      : _axisBinding =
            registration.binding.binding as ReviewerAxisButtonBinding;

  final ReviewerCommandBinding registration;
  final ReviewerAxisButtonBinding _axisBinding;
  bool _sentAction = false;

  ReviewerCommandBinding? getAction(ReviewerAxisValueProvider valueForAxis) {
    final value = Float32List.fromList([
      valueForAxis(_axisBinding.axisValue),
    ])[0];
    final threshold = _axisBinding.threshold;

    if (threshold > 0) {
      if (value >= threshold) return _debouncedAction;
    } else if (threshold < 0) {
      if (value <= threshold) return _debouncedAction;
    }

    _sentAction = false;
    return null;
  }

  ReviewerCommandBinding? get _debouncedAction {
    if (_sentAction) return null;
    _sentAction = true;
    return registration;
  }
}
