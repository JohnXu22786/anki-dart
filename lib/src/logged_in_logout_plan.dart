/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from LoggedInViewModel.onLogout() in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for the ordered effects in a logged-in logout.
///
/// The host owns preference storage and collection/media access; no credential
/// values enter this callback bundle.
final class LoggedInLogoutCallbacks {
  const LoggedInLogoutCallbacks({
    required this.clearSavedHkey,
    required this.clearUsername,
    required this.clearCurrentSyncUri,
    required this.forceMediaResync,
  });

  final void Function() clearSavedHkey;
  final void Function() clearUsername;
  final void Function() clearCurrentSyncUri;
  final void Function() forceMediaResync;
}

/// Runs the source's logout callback sequence without handling host failures.
final class LoggedInLogoutPlan {
  const LoggedInLogoutPlan(this.callbacks);

  final LoggedInLogoutCallbacks callbacks;

  /// Clears saved hkey, username, and current sync URI before media resync.
  ///
  /// A callback failure propagates immediately. Later callbacks are not run and
  /// earlier host effects are not rolled back.
  void run() {
    callbacks.clearSavedHkey();
    callbacks.clearUsername();
    callbacks.clearCurrentSyncUri();
    callbacks.forceMediaResync();
  }
}

/// Builds the host callback plan for `LoggedInViewModel.onLogout()`.
LoggedInLogoutPlan planLoggedInLogout(LoggedInLogoutCallbacks callbacks) =>
    LoggedInLogoutPlan(callbacks);
