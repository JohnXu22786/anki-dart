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
 * Source-derived from LauncherDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host callbacks for creating and configuring a launcher destination Intent.
///
/// The host supplies Android Context, target class, action, category, and Intent
/// behavior.
class LauncherDestinationIntentCallbacks<
  TContext,
  TIntent,
  TTarget,
  TAction,
  TCategory
> {
  const LauncherDestinationIntentCallbacks({
    required this.createIntent,
    required this.setAction,
    required this.addCategory,
  });

  final TIntent Function(TContext context, TTarget target) createIntent;
  final void Function(TIntent intent, TAction action) setAction;
  final void Function(TIntent intent, TCategory category) addCategory;
}

/// The source singleton trigger for creating the host's launcher Intent.
final class LauncherDestination {
  const LauncherDestination._();

  /// The single launcher destination source trigger.
  static const instance = LauncherDestination._();

  /// Creates one host Intent, sets [action], adds [category], and returns it.
  ///
  /// [target], [action], and [category] are host-supplied tokens corresponding
  /// to `IntentHandler::class.java`, `Intent.ACTION_MAIN`, and
  /// `Intent.CATEGORY_LAUNCHER`. Android Intent semantics, flags, and component
  /// behavior remain host-side. Callback failures propagate unchanged and stop
  /// later operations.
  TIntent toIntent<TContext, TIntent, TTarget, TAction, TCategory>({
    required TContext context,
    required TTarget target,
    required TAction action,
    required TCategory category,
    required LauncherDestinationIntentCallbacks<
      TContext,
      TIntent,
      TTarget,
      TAction,
      TCategory
    >
    callbacks,
  }) {
    final intent = callbacks.createIntent(context, target);
    callbacks.setAction(intent, action);
    callbacks.addCategory(intent, category);
    return intent;
  }
}
