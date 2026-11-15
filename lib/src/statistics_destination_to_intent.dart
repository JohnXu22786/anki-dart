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
 * Source-derived from StatisticsDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host operation for creating the Statistics fragment activity Intent.
///
/// The host supplies Android Context and the `Statistics::class` token and
/// delegates to `SingleFragmentActivity.getIntent`.
class StatisticsDestinationIntentCallbacks<TContext, TFragment, TIntent> {
  const StatisticsDestinationIntentCallbacks({
    required this.getStatisticsIntent,
  });

  final TIntent Function(TContext context, TFragment statisticsFragment)
  getStatisticsIntent;
}

/// The source singleton destination for the Statistics screen.
final class StatisticsDestination {
  const StatisticsDestination._();

  /// The single Statistics destination source trigger.
  static const instance = StatisticsDestination._();

  /// Delegates to the host's statistics Intent builder and returns its result.
  ///
  /// [statisticsFragment] is the host's `Statistics::class` token. Context,
  /// fragment class, `SingleFragmentActivity`, and Android Intent behavior
  /// remain host-side. Callback failures propagate unchanged.
  TIntent toIntent<TContext, TFragment, TIntent>({
    required TContext context,
    required TFragment statisticsFragment,
    required StatisticsDestinationIntentCallbacks<TContext, TFragment, TIntent>
    callbacks,
  }) => callbacks.getStatisticsIntent(context, statisticsFragment);
}
