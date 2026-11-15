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
 * SPDX-FileCopyrightText: 2025 Rakshita Chauhan <chauhanrakshita64@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from TabLayout.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host-side projection of the callbacks in Material's tab-selected listener.
///
/// The Android listener and tab remain host-owned. Hosts adapt this interface
/// to their listener API and pass tab values through as opaque [TTab] tokens.
abstract interface class OnTabSelectedListener<TTab> {
  /// Invokes the selection action for [tab].
  void onTabSelected(TTab tab);

  /// Called when [tab] is unselected; the source helper performs no action.
  void onTabUnselected(TTab tab);

  /// Called when [tab] is reselected; the source helper performs no action.
  void onTabReselected(TTab tab);
}

final class _DoOnTabSelectedListener<TTab>
    implements OnTabSelectedListener<TTab> {
  _DoOnTabSelectedListener(this._action);

  final void Function(TTab tab) _action;

  @override
  void onTabSelected(TTab tab) => _action(tab);

  @override
  void onTabUnselected(TTab tab) {}

  @override
  void onTabReselected(TTab tab) {}
}

/// Registers a listener that runs [action] only when a tab is selected.
///
/// One listener is created, passed to [addOnTabSelectedListener] before this
/// function returns, and then returned unchanged so the host can later remove
/// it. Registration and action failures propagate unchanged. Android Material
/// types and listener registration remain host-side.
OnTabSelectedListener<TTab> doOnTabSelected<TTab>({
  required void Function(TTab tab) action,
  required void Function(OnTabSelectedListener<TTab> listener)
  addOnTabSelectedListener,
}) {
  final listener = _DoOnTabSelectedListener<TTab>(action);
  addOnTabSelectedListener(listener);
  return listener;
}
