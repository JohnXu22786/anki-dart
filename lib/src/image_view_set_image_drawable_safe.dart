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
 * Source-derived from ImageView.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// The host's generic result from running an action under its OOM guard.
///
/// The host retains responsibility for identifying its platform's
/// out-of-memory failure and invoking [onError] only for that failure.
typedef ImageViewSetImageDrawableSafeOomGuard<
  TOutOfMemoryError extends Object
> =
    bool? Function(
      bool Function() action, {
      void Function(TOutOfMemoryError error)? onError,
    });

/// Adapts AnkiDroid's `ImageView.setImageDrawableSafe` callback sequence.
///
/// The host supplies [setImageDrawable] and its platform-specific
/// [runWithOomCheck] guard. The guard decides which failure is an OOM; this
/// Dart adapter does not classify VM or Android failures. The identical
/// nullable [drawable] is set once inside the guarded action. A null guard
/// result maps to `false`; success returns `true`. Non-OOM failures and
/// [onError] failures propagate unchanged.
bool imageViewSetImageDrawableSafe<TDrawable, TOutOfMemoryError extends Object>(
  TDrawable? drawable, {
  required void Function(TDrawable? drawable) setImageDrawable,
  required ImageViewSetImageDrawableSafeOomGuard<TOutOfMemoryError>
  runWithOomCheck,
  void Function(TOutOfMemoryError error)? onError,
}) =>
    runWithOomCheck(() {
      setImageDrawable(drawable);
      return true;
    }, onError: onError) ??
    false;
