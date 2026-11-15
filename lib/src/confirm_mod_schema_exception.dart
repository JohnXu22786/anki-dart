/*
 * Copyright (c) 2015 Timothy Rae <perceptualchaos2@gmail.com>
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
 * SPDX-FileCopyrightText: 2015 Timothy Rae <perceptualchaos2@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ConfirmModSchemaException.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Signals that a collection schema change needs full-sync confirmation.
///
/// The host supplies [logger] to [log], keeping platform logging outside this
/// Dart package while preserving the source behavior of logging this exception.
final class ConfirmModSchemaException implements Exception {
  const ConfirmModSchemaException();

  /// Sends this exact exception to the host logger once.
  void log(void Function(Object exception) logger) {
    logger(this);
  }

  @override
  String toString() =>
      'com.ichi2.anki.libanki.exception.ConfirmModSchemaException';
}
