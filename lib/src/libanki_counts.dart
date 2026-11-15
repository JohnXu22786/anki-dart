/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from Counts.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The three scheduler queues represented by [Counts], in upstream order.
enum CountsQueue { NEW, LRN, REV }

/// Mutable counts for AnkiDroid's new, learning, and review queues.
///
/// Dart cannot use Kotlin's property name `new`, so [newCount] carries that
/// value. Dart also has no nested enum declarations, so [CountsQueue] is the
/// top-level equivalent of Kotlin's `Counts.Queue`.
final class Counts {
  Counts([int newCount = 0, int lrn = 0, int rev = 0])
    : _newCount = _asInt32(newCount),
      _lrn = _asInt32(lrn),
      _rev = _asInt32(rev);

  /// The count of new cards (`Counts.new` in the Kotlin source).
  int _newCount;

  int get newCount => _newCount;
  set newCount(int value) => _newCount = _asInt32(value);

  int _lrn;

  /// The count of learning cards.
  int get lrn => _lrn;
  set lrn(int value) => _lrn = _asInt32(value);

  int _rev;

  /// The count of review cards.
  int get rev => _rev;
  set rev(int value) => _rev = _asInt32(value);

  /// Adds [value] to [newCount] using JVM signed Int32 overflow.
  void addNew(int value) => newCount = _addInt32(newCount, value);

  /// Adds [value] to the learning count using JVM signed Int32 overflow.
  void addLrn(int value) => lrn = _addInt32(lrn, value);

  /// Adds [value] to the review count using JVM signed Int32 overflow.
  void addRev(int value) => rev = _addInt32(rev, value);

  /// Returns the sum using JVM signed Int32 overflow.
  int count() => _addInt32(_addInt32(newCount, lrn), rev);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is Counts &&
          newCount == other.newCount &&
          rev == other.rev &&
          lrn == other.lrn);

  @override
  int get hashCode =>
      _addInt32(_addInt32(_addInt32(31, newCount) * 31, rev) * 31, lrn);

  @override
  String toString() => '[$newCount, $lrn, $rev]';
}

int _addInt32(int left, int right) => _asInt32(left + right);

int _asInt32(int value) => value.toSigned(32);
