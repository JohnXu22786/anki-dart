/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Behavioral reference: MutableStateFlow.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Mutable state supplied by a host, such as a `MutableStateFlow` adapter.
///
/// The host owns flow emissions, conflation, dispatch, and lifecycle behavior.
abstract interface class MutableValue<T> {
  T get value;

  set value(T value);
}

/// A direct value delegate for a host-provided mutable value.
///
/// Dart does not support Kotlin's `by` property syntax. Call [getValue] and
/// [setValue] explicitly from the host property or access layer instead. The
/// receiver and property parameters mirror Kotlin's delegate methods and are
/// intentionally ignored.
final class StateFlowVarDelegate<T> {
  StateFlowVarDelegate(this._flow);

  final MutableValue<T> _flow;

  /// Returns the host's current value; [thisRef] and [property] are ignored.
  T getValue(Object? thisRef, Object? property) => _flow.value;

  /// Writes [value] once to the host; [thisRef] and [property] are ignored.
  void setValue(Object? thisRef, Object? property, T value) {
    _flow.value = value;
  }
}

/// Creates a new delegate retaining this exact host object.
extension MutableValueAsVar<T> on MutableValue<T> {
  StateFlowVarDelegate<T> asVar() => StateFlowVarDelegate<T>(this);
}
