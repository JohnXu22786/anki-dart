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
 * Source-derived from ChangelogDestination.kt and InfoDestination.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Host callback for creating the changelog destination Intent.
///
/// The host supplies Android Context, the Info activity class token, and Intent
/// construction.
class ChangelogDestinationIntentCallbacks<TContext, TInfoActivity, TIntent> {
  const ChangelogDestinationIntentCallbacks({required this.createIntent});

  final TIntent Function(TContext context, TInfoActivity infoActivity)
  createIntent;
}

/// The source singleton destination for the changelog ("What's New") screen.
final class ChangelogDestination {
  const ChangelogDestination._();

  /// The single changelog destination source trigger.
  static const instance = ChangelogDestination._();

  /// Delegates changelog Intent creation to the host and returns its result.
  ///
  /// [infoActivity] is the host's `Info::class.java` token. Android Context,
  /// activity class, Intent construction and behavior remain host-side.
  TIntent toIntent<TContext, TInfoActivity, TIntent>({
    required TContext context,
    required TInfoActivity infoActivity,
    required ChangelogDestinationIntentCallbacks<
      TContext,
      TInfoActivity,
      TIntent
    >
    callbacks,
  }) => callbacks.createIntent(context, infoActivity);
}
