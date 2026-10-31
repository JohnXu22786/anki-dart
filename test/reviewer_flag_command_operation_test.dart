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
 * Source-derived Reviewer flag command mapping cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer flag command operation', () {
    test('maps each flag toggle command to its matching flag', () {
      final commandsByFlag = {
        ViewerCommand.TOGGLE_FLAG_RED: PreviewerFlag.red,
        ViewerCommand.TOGGLE_FLAG_ORANGE: PreviewerFlag.orange,
        ViewerCommand.TOGGLE_FLAG_GREEN: PreviewerFlag.green,
        ViewerCommand.TOGGLE_FLAG_BLUE: PreviewerFlag.blue,
        ViewerCommand.TOGGLE_FLAG_PINK: PreviewerFlag.pink,
        ViewerCommand.TOGGLE_FLAG_TURQUOISE: PreviewerFlag.turquoise,
        ViewerCommand.TOGGLE_FLAG_PURPLE: PreviewerFlag.purple,
      };

      for (final entry in commandsByFlag.entries) {
        final operation = reviewerFlagCommandOperation(entry.key);

        expect(
          operation,
          isA<ReviewerToggleFlagCommand>(),
          reason: '${entry.key}',
        );
        expect((operation! as ReviewerToggleFlagCommand).flag, entry.value);
      }
    });

    test('maps UNSET_FLAG to setting NONE', () {
      final operation = reviewerFlagCommandOperation(ViewerCommand.UNSET_FLAG);

      expect(operation, isA<ReviewerSetFlagCommand>());
      expect((operation! as ReviewerSetFlagCommand).flag, PreviewerFlag.none);
    });

    test('leaves null and unrelated commands unmapped', () {
      expect(reviewerFlagCommandOperation(null), isNull);
      expect(reviewerFlagCommandOperation(ViewerCommand.ANSWER_GOOD), isNull);
      expect(reviewerFlagCommandOperation(ViewerCommand.SHOW_ANSWER), isNull);
    });
  });
}
