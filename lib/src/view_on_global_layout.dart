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
 * Source-derived from View.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host operations used by [onGlobalLayout].
///
/// Android `View`, `ViewTreeObserver`, lifecycle state, listener, and observer
/// objects remain host-owned and are represented by opaque type parameters.
abstract interface class ViewOnGlobalLayoutAccess<
  TView,
  TLifecycleOwner,
  TLifecycleState,
  TGlobalLayoutListener,
  TViewTreeObserver,
  TLifecycleObserver
> {
  TLifecycleState readLifecycleCurrentState(TLifecycleOwner lifecycleOwner);

  bool isDestroyedState(TLifecycleState state);

  TGlobalLayoutListener createGlobalLayoutListener(void Function() action);

  TViewTreeObserver readViewTreeObserver(TView view);

  void addGlobalLayoutListener(
    TViewTreeObserver observer,
    TGlobalLayoutListener listener,
  );

  TLifecycleObserver createDefaultLifecycleObserver(
    void Function(TLifecycleOwner owner) onDestroy,
  );

  void addLifecycleObserver(
    TLifecycleOwner lifecycleOwner,
    TLifecycleObserver observer,
  );

  bool isViewTreeObserverAlive(TViewTreeObserver observer);

  void removeGlobalLayoutListener(
    TViewTreeObserver observer,
    TGlobalLayoutListener listener,
  );
}

/// Runs [action] on each global layout until [lifecycleOwner] is destroyed.
///
/// The host supplies the Android view and lifecycle operations. The lifecycle
/// state is read once; a destroyed owner returns before listener creation. For
/// an active owner, the current view-tree observer receives one listener before
/// a lifecycle observer is created and registered. On destruction, the host's
/// current view-tree observer is read then and the exact listener is removed
/// only when that observer is alive. Callback failures propagate unchanged and
/// stop later operations. Android views, tree observers and lifecycle remain
/// host-side.
void onGlobalLayout<
  TView,
  TLifecycleOwner,
  TLifecycleState,
  TGlobalLayoutListener,
  TViewTreeObserver,
  TLifecycleObserver
>(
  TView view,
  TLifecycleOwner lifecycleOwner,
  void Function() action,
  ViewOnGlobalLayoutAccess<
    TView,
    TLifecycleOwner,
    TLifecycleState,
    TGlobalLayoutListener,
    TViewTreeObserver,
    TLifecycleObserver
  >
  access,
) {
  final state = access.readLifecycleCurrentState(lifecycleOwner);
  if (access.isDestroyedState(state)) return;

  final listener = access.createGlobalLayoutListener(action);
  final observer = access.readViewTreeObserver(view);
  access.addGlobalLayoutListener(observer, listener);
  final lifecycleObserver = access.createDefaultLifecycleObserver((_) {
    final currentObserver = access.readViewTreeObserver(view);
    if (access.isViewTreeObserverAlive(currentObserver)) {
      access.removeGlobalLayoutListener(currentObserver, listener);
    }
  });
  access.addLifecycleObserver(lifecycleOwner, lifecycleObserver);
}
