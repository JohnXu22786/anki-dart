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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Forwards `Collection.syncStatus(auth)` to the backend and returns its result.
///
/// The host owns sync status requests and response types. Callback failures
/// propagate unchanged.
TResponse collectionSyncStatus<TAuth, TResponse>(
  TAuth auth, {
  required TResponse Function(TAuth auth) syncStatus,
}) => syncStatus(auth);

/// Forwards `Collection.mediaSyncStatus(auth)` to the backend and returns its
/// result.
///
/// The pinned Collection method does not use [auth] when calling the backend.
/// The host owns sync status requests and response types. Callback failures
/// propagate unchanged.
TResponse collectionMediaSyncStatus<TAuth, TResponse>(
  TAuth auth, {
  required TResponse Function() mediaSyncStatus,
}) => mediaSyncStatus();

/// Returns the exact value returned by `Collection.getPreferences()`' backend
/// callback.
///
/// The host owns Preferences and backend behavior. Callback failures propagate
/// unchanged.
TPreferences collectionGetPreferences<TPreferences>({
  required TPreferences Function() getPreferences,
}) => getPreferences();

/// Forwards [preferences] to `Collection.setPreferences(preferences)` and
/// returns the backend result unchanged.
///
/// The host owns Preferences, OpChanges, and backend behavior. Callback failures
/// propagate unchanged.
TOpChanges collectionSetPreferences<TPreferences, TOpChanges>(
  TPreferences preferences, {
  required TOpChanges Function(TPreferences preferences) setPreferences,
}) => setPreferences(preferences);
