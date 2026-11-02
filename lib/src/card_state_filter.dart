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
 * Behavioral reference: CardStateFilter.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Card Browser card-state choices and their Anki search fragments.
///
/// The host retains filter selection, query composition, and search execution.
enum CardStateFilter {
  ALL_CARDS,
  NEW,
  DUE;

  /// The exact search fragment defined by AnkiDroid, including trailing space.
  String get toSearch => switch (this) {
    CardStateFilter.ALL_CARDS => '',
    CardStateFilter.NEW => 'is:new ',
    CardStateFilter.DUE => 'is:due ',
  };
}
