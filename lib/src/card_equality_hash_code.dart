/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Adapts `Card.equals(other)` while leaving the host's Card type and ID access
/// in place. [isCard] identifies host Card values, and [cardId] reads their IDs.
/// Non-Card values use Dart reference identity, matching `Object.equals`.
bool libankiCardEquals(
  Object self,
  Object? other, {
  required bool Function(Object? value) isCard,
  required int Function(Object card) cardId,
}) {
  if (isCard(other)) {
    return cardId(self) == cardId(other!);
  }
  return identical(self, other);
}

/// Folds a signed 64-bit Card ID into the signed 32-bit JVM hash code.
///
/// The low 32 bits of `id >> 32` equal the source's unsigned `id ushr 32`;
/// [_signedInt32] then applies Kotlin's `toInt()` truncation.
int libankiCardHashCode(int id) =>
    _signedInt32((id & 0xffffffff) ^ ((id >> 32) & 0xffffffff));

int _signedInt32(int value) {
  final unsigned = value & 0xffffffff;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
