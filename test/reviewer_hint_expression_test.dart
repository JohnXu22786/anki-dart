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
 * Source-derived Reviewer hint-expression cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer hint expressions', () {
    test('show hint uses the exact source expression without semicolon', () {
      expect(
        reviewerHintExpression(ViewerCommand.SHOW_HINT),
        'ankidroid.showHint()',
      );
    });

    test(
      'show all hints uses the exact source expression without semicolon',
      () {
        expect(
          reviewerHintExpression(ViewerCommand.SHOW_ALL_HINTS),
          'ankidroid.showAllHints()',
        );
      },
    );

    test('unrelated commands have no hint expression', () {
      expect(reviewerHintExpression(ViewerCommand.TOGGLE_WHITEBOARD), isNull);
    });
  });
}
