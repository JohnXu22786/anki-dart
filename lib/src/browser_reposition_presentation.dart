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
 * Behavioral reference: CardBrowserFragment.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Android string resources referenced by the reposition presentation branches.
enum BrowserRepositionResourceId {
  vagueError,
  repositionCardNotNewError,
  somethingWrong,
}

/// Host-supplied result values from `prepareToRepositionCards()`.
sealed class BrowserRepositionPresentationInput {
  const BrowserRepositionPresentationInput();
}

/// The source result when the selection contains no repositionable cards.
final class BrowserRepositionNoEligibleCards
    extends BrowserRepositionPresentationInput {
  const BrowserRepositionNoEligibleCards();
}

/// Source `RepositionData` values needed by the fragment's branch choice.
final class BrowserRepositionPresentationData
    extends BrowserRepositionPresentationInput {
  const BrowserRepositionPresentationData({
    required this.queueTop,
    required this.queueBottom,
    required this.random,
    required this.shift,
  });

  final int? queueTop;
  final int? queueBottom;
  final bool random;
  final bool shift;
}

/// Data-only directive for host-side dialog or snackbar construction.
sealed class BrowserRepositionPresentationDirective {
  const BrowserRepositionPresentationDirective();
}

/// Show the source no-repositionable-cards message dialog.
final class BrowserRepositionErrorDialog
    extends BrowserRepositionPresentationDirective {
  const BrowserRepositionErrorDialog({
    required this.titleResource,
    required this.messageResource,
    required this.reload,
  });

  final BrowserRepositionResourceId titleResource;
  final BrowserRepositionResourceId messageResource;
  final bool reload;
}

/// Show the source generic-error snackbar when a queue bound is unavailable.
final class BrowserRepositionErrorSnackbar
    extends BrowserRepositionPresentationDirective {
  const BrowserRepositionErrorSnackbar({required this.messageResource});

  final BrowserRepositionResourceId messageResource;
}

/// Construct the host's reposition dialog with the source values unchanged.
final class BrowserRepositionDialog
    extends BrowserRepositionPresentationDirective {
  const BrowserRepositionDialog({
    required this.queueTop,
    required this.queueBottom,
    required this.random,
    required this.shift,
  });

  final int queueTop;
  final int queueBottom;
  final bool random;
  final bool shift;
}

/// Projects the fragment's result branches without constructing Android UI.
BrowserRepositionPresentationDirective projectBrowserRepositionPresentation(
  BrowserRepositionPresentationInput input,
) {
  if (input is BrowserRepositionNoEligibleCards) {
    return const BrowserRepositionErrorDialog(
      titleResource: BrowserRepositionResourceId.vagueError,
      messageResource: BrowserRepositionResourceId.repositionCardNotNewError,
      reload: false,
    );
  }

  final data = input as BrowserRepositionPresentationData;
  final queueTop = data.queueTop;
  final queueBottom = data.queueBottom;
  if (queueTop == null || queueBottom == null) {
    return const BrowserRepositionErrorSnackbar(
      messageResource: BrowserRepositionResourceId.somethingWrong,
    );
  }

  return BrowserRepositionDialog(
    queueTop: queueTop,
    queueBottom: queueBottom,
    random: data.random,
    shift: data.shift,
  );
}
