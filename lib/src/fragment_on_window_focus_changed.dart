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
 * Source-derived from Fragment.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Registers a focus-change listener and removes it when the view is destroyed.
///
/// The host supplies Android Fragment, View, ViewTreeObserver, and lifecycle
/// operations through callbacks and opaque tokens. Setup follows the source
/// order: create the listener, require the current view, register it on that
/// view's current observer, then resolve the view lifecycle owner and register
/// one lifecycle observer. The destroy callback reads the fragment's current
/// view and observer at callback time, and removes the exact listener only if
/// that observer exists and is alive. Failures propagate unchanged and stop
/// subsequent operations; setup does not roll back a listener already added.
void onWindowFocusChanged<
  TFragment,
  TView,
  TViewTreeObserver,
  TLifecycleOwner,
  TLifecycle,
  TFocusListener,
  TLifecycleObserver
>({
  required TFragment fragment,
  required void Function(bool hasFocus) action,
  required TFocusListener Function(void Function(bool hasFocus) action)
  createWindowFocusChangeListener,
  required TView Function(TFragment fragment) requireView,
  required TViewTreeObserver Function(TView view) readViewTreeObserver,
  required void Function(TViewTreeObserver observer, TFocusListener listener)
  addWindowFocusChangeListener,
  required TLifecycleOwner Function(TFragment fragment) readViewLifecycleOwner,
  required TLifecycle Function(TLifecycleOwner owner) readLifecycle,
  required TLifecycleObserver Function(
    void Function(TLifecycleOwner owner) onDestroy,
  )
  createDefaultLifecycleObserver,
  required void Function(TLifecycle lifecycle, TLifecycleObserver observer)
  addLifecycleObserver,
  required TView? Function(TFragment fragment) readCurrentView,
  required TViewTreeObserver? Function(TView view) readCurrentViewTreeObserver,
  required bool Function(TViewTreeObserver observer) isViewTreeObserverAlive,
  required void Function(TViewTreeObserver observer, TFocusListener listener)
  removeWindowFocusChangeListener,
}) {
  final listener = createWindowFocusChangeListener(action);
  final view = requireView(fragment);
  final observer = readViewTreeObserver(view);
  addWindowFocusChangeListener(observer, listener);
  final owner = readViewLifecycleOwner(fragment);
  final lifecycle = readLifecycle(owner);
  final lifecycleObserver = createDefaultLifecycleObserver((_) {
    final currentView = readCurrentView(fragment);
    if (currentView == null) return;
    final currentObserver = readCurrentViewTreeObserver(currentView);
    if (currentObserver == null) return;
    if (isViewTreeObserverAlive(currentObserver)) {
      removeWindowFocusChangeListener(currentObserver, listener);
    }
  });
  addLifecycleObserver(lifecycle, lifecycleObserver);
}
