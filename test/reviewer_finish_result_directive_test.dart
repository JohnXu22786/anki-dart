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
 * Source-derived Reviewer finish-result directive cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer finish-result directive', () {
    test('EXIT maps to the host finish-result directive', () {
      expect(
        reviewerFinishResultDirective(ViewerCommand.EXIT),
        ReviewerFinishResultDirective.exit,
      );
    });

    test('EXIT directive carries RESULT_DEFAULT value 50', () {
      expect(ReviewerFinishResultDirective.exit.resultCode, 50);
    });

    test('unrelated commands have no finish-result directive', () {
      expect(reviewerFinishResultDirective(ViewerCommand.SHOW_ANSWER), isNull);
    });
  });
}
