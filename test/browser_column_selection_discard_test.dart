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
 * Source-derived from AnkiDroid 2.25.3 BrowserColumnSelectionFragment.kt and
 * DiscardChangesDialog.kt; the pinned test tree has no direct Back-flow test.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser column-selection Back plan', () {
    test('disabled discard callback lets default Back handling proceed', () {
      final plan = planBrowserColumnSelectionBack(
        discardChangesCallbackEnabled: false,
      );

      expect(
        plan.decision,
        BrowserColumnSelectionBackDecision.allowDefaultBack,
      );
    });

    test('enabled discard callback requests confirmation', () {
      final plan = planBrowserColumnSelectionBack(
        discardChangesCallbackEnabled: true,
      );

      expect(
        plan.decision,
        BrowserColumnSelectionBackDecision.showDiscardConfirmation,
      );
    });

    test('confirmed discard disables the guard before redispatching Back', () {
      final plan = planBrowserColumnSelectionBack(
        discardChangesCallbackEnabled: true,
      );

      expect(plan.completeConfirmation(confirmed: true), [
        BrowserColumnSelectionDiscardEffect.disableDiscardGuard,
        BrowserColumnSelectionDiscardEffect.redispatchBack,
      ]);
    });

    test('cancelled discard does not disable the guard or redispatch Back', () {
      final plan = planBrowserColumnSelectionBack(
        discardChangesCallbackEnabled: true,
      );

      expect(plan.completeConfirmation(confirmed: false), isEmpty);
    });
  });
}
