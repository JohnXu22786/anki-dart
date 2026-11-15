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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Executes the callback order of Reviewer's `updateMarkIcon()`.
///
/// Resolves one current card, then awaits one host collection callback that
/// resolves its note and reads `MARKED_TAG` once, then emits the exact result.
/// Callback failures propagate unchanged and stop later callbacks. Card, note,
/// Collection, tag/service behavior, Flow delivery, and coroutine scheduling
/// remain host-side.
Future<void> executeReviewerUpdateMarkIcon<TCard>({
  required FutureOr<TCard> Function() resolveCurrentCard,
  required FutureOr<bool> Function(TCard card) readMarkedTagForCard,
  required FutureOr<void> Function(bool isMarked) emitMarkIcon,
}) async {
  final card = await resolveCurrentCard();
  final isMarked = await readMarkedTagForCard(card);
  await emitMarkIcon(isMarked);
}

/// Executes the callback order of Reviewer's `updateFlagIcon()`.
///
/// Resolves one current card, reads its current flag once synchronously, then
/// emits that exact flag. Callback failures propagate unchanged and stop later
/// callbacks. Card access, Flow delivery, and coroutine scheduling remain
/// host-side.
Future<void> executeReviewerUpdateFlagIcon<TCard, TFlag>({
  required FutureOr<TCard> Function() resolveCurrentCard,
  required TFlag Function(TCard card) readCardFlag,
  required FutureOr<void> Function(TFlag flag) emitFlagIcon,
}) async {
  final card = await resolveCurrentCard();
  final flag = readCardFlag(card);
  await emitFlagIcon(flag);
}
