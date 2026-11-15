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
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd <https://apps.ankiweb.net>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ViewModelProgress.kt and CoroutineHelpers.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// A progress amount with a current value and a maximum, both represented as
/// signed 64-bit-compatible Dart integers.
final class ProgressAmount {
  const ProgressAmount({required this.current, required this.max});

  final int current;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is ProgressAmount && other.current == current && other.max == max;

  @override
  int get hashCode => Object.hash(current, max);
}

/// Formats a [ProgressAmount] for display.
typedef ProgressAmountFormatter = String Function(ProgressAmount amount);

String _formatProgressAmount(ProgressAmount amount) =>
    '${amount.current}/${amount.max}';

/// The UI-visible progress state; scheduling and progress updates remain with
/// the host application.
sealed class ViewModelProgress<M extends Object> {
  const ViewModelProgress();

  /// The singleton idle state.
  static const ViewModelProgressIdle idle = ViewModelProgressIdle.instance;
}

/// The singleton idle progress state.
final class ViewModelProgressIdle extends ViewModelProgress<Never> {
  const ViewModelProgressIdle._();

  static const ViewModelProgressIdle instance = ViewModelProgressIdle._();
}

/// An active progress state with its message, amount and display options.
final class ViewModelProgressActive<M extends Object>
    extends ViewModelProgress<M> {
  const ViewModelProgressActive({
    this.message,
    this.amount,
    this.cancellable = false,
    this.formatAmount = _formatProgressAmount,
    this.separator = ' ',
  });

  final M? message;
  final ProgressAmount? amount;
  final bool cancellable;
  final ProgressAmountFormatter formatAmount;
  final String separator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewModelProgressActive<Object> &&
          other.message == message &&
          other.amount == amount &&
          other.cancellable == cancellable &&
          identical(other.formatAmount, formatAmount) &&
          other.separator == separator);

  @override
  int get hashCode => Object.hash(
    message,
    amount,
    cancellable,
    identityHashCode(formatAmount),
    separator,
  );
}
