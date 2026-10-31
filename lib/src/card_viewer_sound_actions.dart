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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardViewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Forwards the requested enabled state to the host media player unchanged.
///
/// The host owns task scheduling and asynchronous error handling.
Future<void> setCardViewerSoundPlayerEnabled({
  required bool isEnabled,
  required FutureOr<void> Function(bool isEnabled) setEnabled,
}) async {
  await setEnabled(isEnabled);
}

/// Resolves and plays a sound link using host card, AV-parser, and player APIs.
///
/// The current card is awaited before the exact [url] is passed to [getAvTag].
/// A null tag is a no-op. Errors propagate to the host's async error handling.
Future<void> playCardViewerSoundFromUrl<Card, Tag>({
  required String url,
  required FutureOr<Card> Function() awaitCurrentCard,
  required FutureOr<Tag?> Function(Card card, String url) getAvTag,
  required FutureOr<void> Function(Tag tag) playOne,
}) async {
  final card = await awaitCurrentCard();
  final tag = await getAvTag(card, url);
  if (tag != null) await playOne(tag);
}
