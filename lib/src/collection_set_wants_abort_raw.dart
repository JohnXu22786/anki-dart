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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Forwards `Collection.setWantsAbortRaw(input)` to the host backend unchanged.
///
/// The host retains abort behavior, serialization, and backend protocol.
/// Callback failures propagate unchanged.
Uint8List collectionSetWantsAbortRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) setWantsAbortRaw,
}) => setWantsAbortRaw(input);
