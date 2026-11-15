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
 * Behavioral reference: WhiteboardPenColor.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Light and dark pen colors selected by the host-resolved theme.
///
/// The host supplies `isNightTheme` because Android's `Themes` remains
/// host-side. This value carries preferences only; drawing and persistence are
/// also host responsibilities.
final class WhiteboardPenColor {
  WhiteboardPenColor(this.lightPenColor, this.darkPenColor);

  final int? lightPenColor;
  final int? darkPenColor;

  /// Returns the preference matching the host-supplied current theme.
  int? fromPreferences({required bool isNightTheme}) =>
      isNightTheme ? darkPenColor : lightPenColor;

  /// A fresh null-valued default, matching the source getter's identity.
  static WhiteboardPenColor get defaultColor => WhiteboardPenColor(null, null);
}
