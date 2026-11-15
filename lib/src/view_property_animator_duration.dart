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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ViewPropertyAnimator.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Applies the `ViewPropertyAnimator.setDuration(Duration)` extension.
///
/// [duration] is an opaque host representation of Kotlin's `Duration`, not a
/// Dart [Duration]. [toLongMilliseconds] must preserve Kotlin's
/// `Duration.toLong(DurationUnit.MILLISECONDS)` conversion, including its
/// finite and infinite representations. The host owns the Android animator.
/// Conversion runs once before [setDuration] runs once; either failure
/// propagates unchanged and stops the remaining work.
TAnimator setViewPropertyAnimatorDuration<TAnimator>(
  Object duration, {
  required int Function(Object duration) toLongMilliseconds,
  required TAnimator Function(int durationMilliseconds) setDuration,
}) {
  final durationMilliseconds = toLongMilliseconds(duration);
  return setDuration(durationMilliseconds);
}
