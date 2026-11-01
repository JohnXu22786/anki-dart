/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from FragmentManager.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host adapter for the Fragment lookup and transaction operations used by
/// [removeFragmentFromContainer].
///
/// Android's `FragmentManager` owns lookup, transaction creation, fragment
/// lifecycle, and commit behavior. This interface exposes only the calls whose
/// ordering is preserved by the portable helper.
abstract interface class FragmentManagerAccess<TFragment> {
  TFragment? findFragmentById(int containerViewId);

  FragmentTransactionAccess<TFragment> beginTransaction();
}

/// Host adapter for Android's `FragmentTransaction` calls used by
/// [removeFragmentFromContainer].
abstract interface class FragmentTransactionAccess<TFragment> {
  FragmentTransactionAccess<TFragment> remove(TFragment fragment);

  /// Returns the host commit result, which [removeFragmentFromContainer] ignores.
  Object? commit();
}

/// Removes the fragment attached to [containerViewId] through host callbacks.
///
/// The helper looks up the fragment once. If no fragment is found, it throws an
/// [ArgumentError] with the Kotlin `requireNotNull` message before beginning a
/// transaction. Otherwise it begins one transaction, removes the same fragment,
/// and commits once in source order. The commit result is ignored, matching the
/// source extension's `Unit` return. Callback failures propagate unchanged and
/// prevent later callbacks.
///
/// The host remains responsible for Android `FragmentManager`, `Fragment`,
/// `FragmentTransaction`, lifecycle, and actual commit effects.
void removeFragmentFromContainer<TFragment>(
  FragmentManagerAccess<TFragment> manager,
  int containerViewId,
) {
  final fragment = manager.findFragmentById(containerViewId);
  if (fragment == null) {
    throw ArgumentError('could not find fragment');
  }
  manager.beginTransaction().remove(fragment).commit();
}
