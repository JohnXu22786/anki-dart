/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Note.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Adapts `Note.clone()` while leaving the host Note object and shallow-clone
/// operation in place. Only [isCloneNotSupportedException] failures from
/// [shallowClone] are wrapped by [runtimeException], which receives the exact
/// caught object. The host Note cast happens after that exception boundary.
T libankiNoteClone<T>({
  required Object Function() shallowClone,
  required T Function(Object clone) castToNote,
  required bool Function(Object error) isCloneNotSupportedException,
  required Object Function(Object cause) runtimeException,
}) {
  final Object clone;
  try {
    clone = shallowClone();
  } catch (error) {
    if (!isCloneNotSupportedException(error)) rethrow;
    throw runtimeException(error);
  }
  return castToNote(clone);
}

/// Adapts `Note.equals(other)` using host runtime-class and ID access.
/// Reference identity, null handling, and source callback order are preserved.
bool libankiNoteEquals(
  Object self,
  Object? other, {
  required bool Function(Object self, Object other) sameRuntimeClass,
  required BigInt Function(Object note) noteId,
}) {
  if (identical(self, other)) return true;
  if (other == null || !sameRuntimeClass(self, other)) return false;
  return noteId(self) == noteId(other);
}

/// Returns the signed JVM 32-bit hash of a signed-Long ID supplied as [BigInt].
///
/// The public parameter uses [BigInt] so IDs above JavaScript's safe integer
/// limit retain all bits before the source's 32-bit fold.
int libankiNoteHashCode(BigInt id) {
  final mask64 = BigInt.parse('18446744073709551615');
  final mask32 = BigInt.from(0xffffffff);
  final unsignedLong = id & mask64;
  final folded = (unsignedLong ^ (unsignedLong >> 32)) & mask32;
  return folded.toSigned(32).toInt();
}
