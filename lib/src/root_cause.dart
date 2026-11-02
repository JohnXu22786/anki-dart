/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (c) 2026 Ashish Yadav <mailtoashish693@gmail.com>
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Throwable.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host read of a throwable's nullable cause.
typedef ThrowableCauseRead = Object? Function(Object throwable);

/// Returns the deepest cause, preserving `Throwable.getRootCause()` reads.
///
/// The source reads `cause` separately for its null check, identity check, and
/// assignment. Only a direct self-cycle is guarded; a longer cycle is not.
Object getRootCause(Object throwable, {required ThrowableCauseRead cause}) {
  var result = throwable;
  while (true) {
    if (cause(result) == null) return result;
    if (identical(cause(result), result)) return result;
    result =
        cause(result) ??
        (throw StateError('Throwable cause changed to null while reading'));
  }
}
