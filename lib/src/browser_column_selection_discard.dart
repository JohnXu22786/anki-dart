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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: BrowserColumnSelectionFragment.kt and
 * DiscardChangesDialog.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The host's decision when the user presses Back in the column dialog.
enum BrowserColumnSelectionBackDecision {
  allowDefaultBack,
  showDiscardConfirmation,
}

/// Effects the host performs after the user confirms discarding the changes.
enum BrowserColumnSelectionDiscardEffect { disableDiscardGuard, redispatchBack }

/// Projects the current discard callback state into the source Back decision.
///
/// AnkiDroid updates the callback's enabled state from adapter notifications.
/// The host passes that current state here; the projection does not recompute
/// it from the selected columns. When disabled, the normal dispatcher handles
/// Back. When enabled, the source callback opens the discard dialog.
final class BrowserColumnSelectionBackPlan {
  const BrowserColumnSelectionBackPlan({required this.decision});

  final BrowserColumnSelectionBackDecision decision;

  /// The source's positive-button callback disables its guard before
  /// synchronously redispatching Back. A cancelled dialog invokes no callback.
  List<BrowserColumnSelectionDiscardEffect> completeConfirmation({
    required bool confirmed,
  }) => confirmed
      ? const [
          BrowserColumnSelectionDiscardEffect.disableDiscardGuard,
          BrowserColumnSelectionDiscardEffect.redispatchBack,
        ]
      : const [];
}

/// Plans the host-visible outcome of pressing Back in the column dialog.
///
/// Android's dispatcher, callback lifecycle, dialog, and actual dialog/back
/// delivery remain host responsibilities.
BrowserColumnSelectionBackPlan planBrowserColumnSelectionBack({
  required bool discardChangesCallbackEnabled,
}) => BrowserColumnSelectionBackPlan(
  decision: discardChangesCallbackEnabled
      ? BrowserColumnSelectionBackDecision.showDiscardConfirmation
      : BrowserColumnSelectionBackDecision.allowDefaultBack,
);
