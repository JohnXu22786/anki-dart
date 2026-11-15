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
 * Behavioral reference: Ease.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Compatibility values for the four answer buttons used by AnkiDroid.
///
/// The integer [value]s must stay in sync with AnkiDroid's `Ease` API enum.
/// Use `CardAnswer.Rating` for new code.
@Deprecated('Use CardAnswer.Rating')
enum Ease {
  AGAIN(1),
  HARD(2),
  GOOD(3),
  EASY(4);

  const Ease(this.value);

  /// The source API integer associated with this answer button.
  final int value;

  /// Returns the first source entry whose integer matches [value].
  ///
  /// Throws [StateError] when [value] is unsupported, matching the source's
  /// failure rather than substituting a default entry.
  static Ease fromValue(int value) =>
      Ease.values.firstWhere((ease) => value == ease.value);
}
