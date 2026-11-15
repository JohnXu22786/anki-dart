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
 * Source-derived from CustomStudyDialogTest.kt and CustomStudyDialog.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Study selected card state', () {
    test('maps each source selection index to its CramKind in enum order', () {
      expect(
        projectCustomStudySelectedKind(0),
        CustomStudyCramKind.CRAM_KIND_NEW,
      );
      expect(
        projectCustomStudySelectedKind(1),
        CustomStudyCramKind.CRAM_KIND_DUE,
      );
      expect(
        projectCustomStudySelectedKind(2),
        CustomStudyCramKind.CRAM_KIND_REVIEW,
      );
      expect(
        projectCustomStudySelectedKind(3),
        CustomStudyCramKind.CRAM_KIND_ALL,
      );
    });

    test('defaults only the invalid-position selection to new cards', () {
      expect(
        projectCustomStudySelectedKind(-1),
        CustomStudyCramKind.CRAM_KIND_NEW,
      );
    });

    test(
      'preserves the source index failure for other out-of-range values',
      () {
        expect(() => projectCustomStudySelectedKind(4), throwsRangeError);
        expect(() => projectCustomStudySelectedKind(-2), throwsRangeError);
      },
    );
  });
}
