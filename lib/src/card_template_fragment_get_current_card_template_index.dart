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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Reads the current card-template index from required host fragment arguments.
///
/// [requireArguments] represents the source `Fragment.requireArguments()` call;
/// [readCardIndex] represents `Bundle.getInt(CARD_INDEX)` on the returned
/// host-owned Bundle. Each is called once, in source order. The Android Bundle,
/// Fragment, and key stay host-side. The exact index and callback failures are
/// returned or propagated unchanged.
int cardTemplateFragmentGetCurrentCardTemplateIndex<TArguments>({
  required TArguments Function() requireArguments,
  required int Function(TArguments arguments) readCardIndex,
}) {
  final arguments = requireArguments();
  return readCardIndex(arguments);
}
