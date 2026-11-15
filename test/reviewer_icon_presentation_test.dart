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
 * Source-derived Reviewer icon presentation cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer mark icon presentation', () {
    test('toolbar mark action suppresses the separate icon update', () {
      expect(
        reviewerMarkIconVisibilityUpdate(
          isMarkShownInToolbar: true,
          isMarked: true,
        ),
        ReviewerIconVisibilityUpdate.noUpdate,
      );
    });

    test('otherwise follows marked and unmarked state', () {
      expect(
        reviewerMarkIconVisibilityUpdate(
          isMarkShownInToolbar: false,
          isMarked: true,
        ),
        ReviewerIconVisibilityUpdate.show,
      );
      expect(
        reviewerMarkIconVisibilityUpdate(
          isMarkShownInToolbar: false,
          isMarked: false,
        ),
        ReviewerIconVisibilityUpdate.hide,
      );
    });
  });

  group('Reviewer flag icon presentation', () {
    test('toolbar flag action suppresses the separate icon update', () {
      final result = reviewerFlagIconPresentation(
        isFlagShownInToolbar: true,
        flag: PreviewerFlag.red,
        noneFlag: PreviewerFlag.none,
      );
      expect(result.visibilityUpdate, ReviewerIconVisibilityUpdate.noUpdate);
      expect(result.iconFlag, isNull);
    });

    test('NONE hides the separate icon when toolbar flag is absent', () {
      final result = reviewerFlagIconPresentation(
        isFlagShownInToolbar: false,
        flag: PreviewerFlag.none,
        noneFlag: PreviewerFlag.none,
      );
      expect(result.visibilityUpdate, ReviewerIconVisibilityUpdate.hide);
      expect(result.iconFlag, isNull);
    });

    test('non-NONE flag is passed through with a show update', () {
      final result = reviewerFlagIconPresentation(
        isFlagShownInToolbar: false,
        flag: PreviewerFlag.turquoise,
        noneFlag: PreviewerFlag.none,
      );
      expect(result.visibilityUpdate, ReviewerIconVisibilityUpdate.show);
      expect(result.iconFlag, PreviewerFlag.turquoise);
    });
  });
}
