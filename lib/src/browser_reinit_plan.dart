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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The host operations requested by `CardBrowserViewModel.onReinit()`.
enum BrowserReinitEffect { restoreActiveBackendColumns, refreshBackendColumns }

/// Ordered host effect requests for browser reinitialization.
final class BrowserReinitPlan {
  BrowserReinitPlan({required Iterable<BrowserReinitEffect> effects})
    : effects = List.unmodifiable(effects);

  /// Effects for the host to run in order. Refresh is requested after restore.
  final List<BrowserReinitEffect> effects;
}

/// Plans `CardBrowserViewModel.onReinit()`'s initialization guard and effects.
///
/// Before initialization completes, the source returns without side effects.
/// Once initialized, it requests that the host synchronously restore active
/// backend columns and then launch its asynchronous column refresh.
BrowserReinitPlan planBrowserReinit({required bool initCompleted}) {
  if (!initCompleted) {
    return BrowserReinitPlan(effects: const []);
  }

  return BrowserReinitPlan(
    effects: const [
      BrowserReinitEffect.restoreActiveBackendColumns,
      BrowserReinitEffect.refreshBackendColumns,
    ],
  );
}
