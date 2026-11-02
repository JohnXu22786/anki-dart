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
 * Source-derived Reviewer page-navigation directive cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer page-navigation directive', () {
    test('PAGE_UP maps to the page-up directive', () {
      expect(
        reviewerPageNavigationDirective(ViewerCommand.PAGE_UP),
        ReviewerPageNavigationDirective.pageUp,
      );
    });

    test('PAGE_DOWN maps to the page-down directive', () {
      expect(
        reviewerPageNavigationDirective(ViewerCommand.PAGE_DOWN),
        ReviewerPageNavigationDirective.pageDown,
      );
    });

    test('unrelated commands have no page-navigation directive', () {
      expect(
        reviewerPageNavigationDirective(ViewerCommand.REPLAY_VOICE),
        isNull,
      );
    });
  });
}
