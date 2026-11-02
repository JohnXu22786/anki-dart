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
 * Source-derived from PreferencesDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host callbacks for creating the Intent for a preferences destination.
///
/// The host supplies the preferences Activity and fragment class tokens and
/// owns Android Context and Intent behavior.
class PreferencesDestinationIntentCallbacks<TContext, TIntent, TScreen> {
  const PreferencesDestinationIntentCallbacks({
    required this.getRootIntent,
    required this.getScreenIntent,
  });

  final TIntent Function(TContext context) getRootIntent;
  final TIntent Function(TContext context, TScreen screen) getScreenIntent;
}

/// The source settings destinations and their host Intent projections.
sealed class PreferencesDestination {
  const PreferencesDestination();

  /// Opens the top level preferences screen.
  static const PreferencesDestination root = PreferencesDestinationRoot._();

  /// Opens Advanced preferences.
  static const PreferencesDestination advanced =
      PreferencesDestinationAdvanced._();

  /// Opens Accessibility preferences.
  static const PreferencesDestination accessibility =
      PreferencesDestinationAccessibility._();

  /// Delegates to the matching host preferences Intent builder once.
  ///
  /// Root calls [callbacks.getRootIntent] without a screen token. Advanced and
  /// Accessibility call [callbacks.getScreenIntent] with their corresponding
  /// host fragment class token. The exact callback result is returned and
  /// callback failures propagate unchanged. Context, fragment classes, and
  /// Android Intent behavior remain host-side.
  TIntent toIntent<TContext, TIntent, TScreen>({
    required TContext context,
    required TScreen advancedSettingsFragment,
    required TScreen accessibilitySettingsFragment,
    required PreferencesDestinationIntentCallbacks<TContext, TIntent, TScreen>
    callbacks,
  }) {
    switch (this) {
      case PreferencesDestinationRoot():
        return callbacks.getRootIntent(context);
      case PreferencesDestinationAdvanced():
        return callbacks.getScreenIntent(context, advancedSettingsFragment);
      case PreferencesDestinationAccessibility():
        return callbacks.getScreenIntent(
          context,
          accessibilitySettingsFragment,
        );
    }
  }
}

/// The root preferences destination.
final class PreferencesDestinationRoot extends PreferencesDestination {
  const PreferencesDestinationRoot._();
}

/// The Advanced preferences destination.
final class PreferencesDestinationAdvanced extends PreferencesDestination {
  const PreferencesDestinationAdvanced._();
}

/// The Accessibility preferences destination.
final class PreferencesDestinationAccessibility extends PreferencesDestination {
  const PreferencesDestinationAccessibility._();
}
