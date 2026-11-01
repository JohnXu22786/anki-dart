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
 * Source-derived from StudyOptionsDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host operation for creating the Study Options activity Intent.
///
/// The host supplies Android Context and the `StudyOptionsActivity` class token
/// and constructs the Intent.
class StudyOptionsDestinationIntentCallbacks<TContext, TActivity, TIntent> {
  const StudyOptionsDestinationIntentCallbacks({required this.createIntent});

  final TIntent Function(TContext context, TActivity studyOptionsActivity)
  createIntent;
}

/// The source singleton destination for the Study Options screen.
final class StudyOptionsDestination {
  const StudyOptionsDestination._();

  /// The single Study Options destination source trigger.
  static const instance = StudyOptionsDestination._();

  /// Delegates Intent creation to the host and returns its exact result.
  ///
  /// [studyOptionsActivity] is the host's `StudyOptionsActivity::class.java`
  /// token. Context, the activity class, and Android Intent behavior remain
  /// host-side. Callback failures propagate unchanged.
  TIntent toIntent<TContext, TActivity, TIntent>({
    required TContext context,
    required TActivity studyOptionsActivity,
    required StudyOptionsDestinationIntentCallbacks<
      TContext,
      TActivity,
      TIntent
    >
    callbacks,
  }) => callbacks.createIntent(context, studyOptionsActivity);
}
