/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CombinedException.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The portable message and ordered exception values of AnkiDroid's
/// `CombinedException`.
///
/// This is a projection, not a Dart or JVM exception. The host owns exception
/// identity and supplies message and Java simple-class-name projections.
final class CombinedExceptionProjection<T> {
  CombinedExceptionProjection._(this.exceptions, this.message);

  /// Creates a projection using the source constructor's message precedence.
  ///
  /// A non-null [messageOverride] is used unchanged and suppresses all other
  /// callbacks. Otherwise [messageFormatter] formats each exception in order
  /// with its zero-based index. Without either option, each [messageOf] result
  /// is used, falling back to [simpleNameOf] only when that result is null.
  /// The selected strings are joined with one newline. Callback failures
  /// propagate unchanged and stop projection.
  static CombinedExceptionProjection<T> create<T>({
    required Iterable<T> exceptions,
    String? messageOverride,
    String Function(int index, T exception)? messageFormatter,
    required String? Function(T exception) messageOf,
    required String Function(T exception) simpleNameOf,
  }) {
    final exceptionList = List<T>.unmodifiable(exceptions);
    final String message;
    if (messageOverride != null) {
      message = messageOverride;
    } else if (messageFormatter != null) {
      message = exceptionList.indexed
          .map((entry) => messageFormatter(entry.$1, entry.$2))
          .join('\n');
    } else {
      message = exceptionList
          .map((exception) => messageOf(exception) ?? simpleNameOf(exception))
          .join('\n');
    }
    return CombinedExceptionProjection<T>._(exceptionList, message);
  }

  /// Adapts `CombinedException.from(values)` for `(label, exception)` pairs.
  ///
  /// Returns null for an empty input. Otherwise it preserves exception order
  /// and joins labels, including empty labels, with one newline.
  static CombinedExceptionProjection<T>? from<T>(
    Iterable<(String label, T exception)> values,
  ) {
    final valueList = values.toList(growable: false);
    if (valueList.isEmpty) return null;
    return CombinedExceptionProjection<T>._(
      List<T>.unmodifiable(valueList.map((value) => value.$2)),
      valueList.map((value) => value.$1).join('\n'),
    );
  }

  /// Exception values in their original source order.
  final List<T> exceptions;

  /// The combined message projected from the constructor inputs.
  final String message;
}
