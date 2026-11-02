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
 * Source-derived cases from FlagToDisplayTest.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test('selects the display flag for every flag and boolean combination', () {
    for (final actualFlag in PreviewerFlag.values) {
      for (final isOnAppBar in [false, true]) {
        for (final isFullscreen in [false, true]) {
          final expected = isOnAppBar && !isFullscreen
              ? PreviewerFlag.none
              : actualFlag;

          expect(
            flagToDisplay(
              actualFlag: actualFlag,
              noneFlag: PreviewerFlag.none,
              isOnAppBar: isOnAppBar,
              isFullscreen: isFullscreen,
            ),
            same(expected),
            reason:
                'flag=$actualFlag, isOnAppBar=$isOnAppBar, '
                'isFullscreen=$isFullscreen',
          );
        }
      }
    }
  });
}
