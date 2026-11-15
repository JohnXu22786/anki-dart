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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectBrowserRepositionPresentation', () {
    test('no eligible cards requests the source message dialog', () {
      final directive = projectBrowserRepositionPresentation(
        const BrowserRepositionNoEligibleCards(),
      );

      expect(directive, isA<BrowserRepositionErrorDialog>());
      final dialog = directive as BrowserRepositionErrorDialog;
      expect(dialog.titleResource, BrowserRepositionResourceId.vagueError);
      expect(
        dialog.messageResource,
        BrowserRepositionResourceId.repositionCardNotNewError,
      );
      expect(dialog.reload, isFalse);
    });

    test('missing top bound requests the source generic-error snackbar', () {
      final directive = projectBrowserRepositionPresentation(
        const BrowserRepositionPresentationData(
          queueTop: null,
          queueBottom: 4,
          random: true,
          shift: true,
        ),
      );

      expect(directive, isA<BrowserRepositionErrorSnackbar>());
      expect(
        (directive as BrowserRepositionErrorSnackbar).messageResource,
        BrowserRepositionResourceId.somethingWrong,
      );
    });

    test('missing bottom bound requests the source generic-error snackbar', () {
      final directive = projectBrowserRepositionPresentation(
        const BrowserRepositionPresentationData(
          queueTop: 2,
          queueBottom: null,
          random: false,
          shift: false,
        ),
      );

      expect(directive, isA<BrowserRepositionErrorSnackbar>());
      expect(
        (directive as BrowserRepositionErrorSnackbar).messageResource,
        BrowserRepositionResourceId.somethingWrong,
      );
    });

    test('present bounds preserve all reposition dialog values', () {
      final directive = projectBrowserRepositionPresentation(
        const BrowserRepositionPresentationData(
          queueTop: 9,
          queueBottom: 3,
          random: true,
          shift: false,
        ),
      );

      expect(directive, isA<BrowserRepositionDialog>());
      final dialog = directive as BrowserRepositionDialog;
      expect(dialog.queueTop, 9);
      expect(dialog.queueBottom, 3);
      expect(dialog.random, isTrue);
      expect(dialog.shift, isFalse);
    });
  });
}
