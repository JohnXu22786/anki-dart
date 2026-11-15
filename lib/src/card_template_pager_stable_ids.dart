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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Initial `baseId`, matching the adapter's Kotlin `var baseId = 0L`.
final BigInt initialTemplatePagerBaseId = BigInt.zero;

/// Returns the stable ID for [position], preserving Kotlin signed-Long wrap.
///
/// `BigInt` keeps the full JVM `Long` range available on both Dart VM and web.
BigInt templatePagerGetItemId({
  required BigInt baseId,
  required int position,
}) => _toInt64(_toInt64(baseId) + BigInt.from(_toInt32(position)));

/// Checks an ID against the current item count using Kotlin signed-Long rules.
///
/// Reads [readBaseId] once before [itemCount], which is also read once. The
/// host retains the adapter, item-count source, and mutable base-ID storage.
bool templatePagerContainsItem({
  required BigInt id,
  required BigInt Function() readBaseId,
  required int Function() itemCount,
}) {
  final baseId = _toInt64(readBaseId());
  final delta = _toInt64(_toInt64(id) - baseId);
  final count = BigInt.from(_toInt32(itemCount()));
  if (delta < count) {
    return delta >= BigInt.zero;
  }
  return false;
}

/// Advances the stable-ID base by the source's wrapped `itemCount + 1`.
///
/// The base callback runs first, then the count callback, then the write
/// callback. Any callback failure propagates and prevents later callbacks.
void templatePagerOrdinalShift({
  required BigInt Function() readBaseId,
  required int Function() itemCount,
  required void Function(BigInt) writeBaseId,
}) {
  final baseId = _toInt64(readBaseId());
  final count = itemCount();
  final shift = BigInt.from(_toInt32(_toInt32(count) + 1));
  writeBaseId(_toInt64(baseId + shift));
}

int _toInt32(int value) => value.toSigned(32);

BigInt _toInt64(BigInt value) => value.toSigned(64);
