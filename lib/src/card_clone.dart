/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Adapts `Card.clone()` while leaving the host Card and object cloning in place.
/// [shallowClone] performs the host's shallow clone, and [castToCard] applies
/// the host Card cast. Only [isCloneNotSupportedException] failures are wrapped
/// using [runtimeException], which receives the exact caught cause.
T libankiCardClone<T>({
  required Object Function() shallowClone,
  required T Function(Object clone) castToCard,
  required bool Function(Object error) isCloneNotSupportedException,
  required Object Function(Object cause) runtimeException,
}) {
  try {
    return castToCard(shallowClone());
  } catch (error) {
    if (!isCloneNotSupportedException(error)) rethrow;
    throw runtimeException(error);
  }
}
