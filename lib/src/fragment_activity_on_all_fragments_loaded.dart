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
 * Source-derived from FragmentActivity.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Registers a recursive callback that runs [block] whenever all fragment
/// views currently exist.
///
/// The initial manager is read once before callback creation and used for
/// registration. For every view-created event, [superOnFragmentViewCreated]
/// runs first, then the current manager is checked by
/// [allFragmentViewsCreated]. A false check leaves the callback registered. A
/// true check runs [block] and unregisters the same callback in `finally`,
/// resolving the current manager again for that unregistration. Failures before
/// [block] begins skip both it and unregistration; a failure during
/// unregistration follows normal `finally` propagation. No one-shot guard is
/// added, so each qualifying event performs these operations again. Android
/// FragmentActivity, FragmentManager, Fragment, View, Bundle, and lifecycle
/// callback classes remain host-side.
typedef FragmentViewCreated<TFragmentManager, TFragment, TView, TSavedState> =
    void Function(
      TFragmentManager manager,
      TFragment fragment,
      TView view,
      TSavedState? savedState,
    );

void onAllFragmentsLoaded<
  TFragmentManager,
  TFragment,
  TView,
  TSavedState,
  TLifecycleCallbacks
>({
  required TFragmentManager Function() supportFragmentManager,
  required TLifecycleCallbacks Function(
    FragmentViewCreated<TFragmentManager, TFragment, TView, TSavedState>
    onFragmentViewCreated,
  )
  createLifecycleCallbacks,
  required void Function(
    TFragmentManager manager,
    TLifecycleCallbacks callback, {
    required bool recursive,
  })
  registerFragmentLifecycleCallbacks,
  required void Function(TFragmentManager manager, TLifecycleCallbacks callback)
  unregisterFragmentLifecycleCallbacks,
  required void Function(
    TFragmentManager manager,
    TFragment fragment,
    TView view,
    TSavedState? savedState,
  )
  superOnFragmentViewCreated,
  required bool Function(TFragmentManager manager) allFragmentViewsCreated,
  required void Function() block,
}) {
  final initialManager = supportFragmentManager();
  late final TLifecycleCallbacks callback;
  callback = createLifecycleCallbacks((manager, fragment, view, savedState) {
    superOnFragmentViewCreated(manager, fragment, view, savedState);
    if (!allFragmentViewsCreated(supportFragmentManager())) return;
    try {
      block();
    } finally {
      unregisterFragmentLifecycleCallbacks(supportFragmentManager(), callback);
    }
  });
  registerFragmentLifecycleCallbacks(initialManager, callback, recursive: true);
}
