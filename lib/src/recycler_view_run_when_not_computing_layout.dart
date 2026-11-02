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
 * Source-derived from RecyclerView.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The host-supplied action token corresponding to Android's `Runnable`.
abstract interface class RunnableAction {
  void run();
}

/// The host operations used by [runWhenNotComputingLayout].
abstract interface class RecyclerViewRunWhenNotComputingLayoutAccess<
  TAction extends RunnableAction
> {
  bool get isComputingLayout;

  void post(TAction action);
}

/// Runs [action] immediately unless the host RecyclerView is computing layout.
///
/// The host supplies the `isComputingLayout` read and `post` operation. The
/// state is read once; while computing, the identical action token is posted
/// once and is not run here. Otherwise its `run` method is called once. Host
/// callback failures propagate unchanged. Android frame scheduling and action
/// execution remain host-side.
void runWhenNotComputingLayout<TAction extends RunnableAction>(
  RecyclerViewRunWhenNotComputingLayoutAccess<TAction> recyclerView,
  TAction action,
) {
  final isComputingLayout = recyclerView.isComputingLayout;
  if (isComputingLayout) {
    recyclerView.post(action);
  } else {
    action.run();
  }
}
