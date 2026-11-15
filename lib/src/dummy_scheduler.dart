/*
 * Copyright (c) 2011 Norbert Nagold
 * Copyright (c) 2012 Kostas Spyropoulos
 * Copyright (c) 2013 Houssam Salem
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2012 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2013 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DummyScheduler.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Minimal compatibility adapter for AnkiDroid's unsupported v1/v2 scheduler.
///
/// The collection remains opaque and is retained by reference. The base
/// Scheduler class and its backend integration remain host-side.
final class DummyScheduler<CollectionT, CardT, RatingT> {
  DummyScheduler(CollectionT col) : col = col;

  /// The exact collection value passed to the constructor.
  final CollectionT col;

  /// This scheduler never has a current card.
  CardT? get card => null;

  /// Always reports that the legacy scheduler is unsupported.
  void answerCard(CardT card, RatingT rating) {
    throw Exception('v1/v2 scheduler not supported');
  }
}
