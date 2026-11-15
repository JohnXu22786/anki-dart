/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from BackendDeckOptions.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Host backend callbacks used by the raw deck-options wrappers.
final class BackendDeckOptionsRawCallbacks {
  const BackendDeckOptionsRawCallbacks({
    required this.getDeckConfigsForUpdateRaw,
    required this.updateDeckConfigsRaw,
  });

  final Uint8List Function(Uint8List input) getDeckConfigsForUpdateRaw;
  final Uint8List Function(Uint8List input) updateDeckConfigsRaw;
}

/// Raw deck-options calls that preserve the source's byte pass-through behavior.
///
/// The host provides backend transport and protobuf handling. Each method passes
/// its input to the matching host callback and returns that callback's result;
/// callback failures propagate unchanged.
final class BackendDeckOptionsRaw {
  const BackendDeckOptionsRaw(this.callbacks);

  final BackendDeckOptionsRawCallbacks callbacks;

  Uint8List getDeckConfigsForUpdateRaw(Uint8List input) =>
      callbacks.getDeckConfigsForUpdateRaw(input);

  Uint8List updateDeckConfigsRaw(Uint8List input) =>
      callbacks.updateDeckConfigsRaw(input);
}
