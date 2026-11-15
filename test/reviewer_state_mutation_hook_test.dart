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
 * Source-derived Reviewer state-mutation hook decision cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer state-mutation hook decision', () {
    test('empty JavaScript requests completion for a pending signal', () {
      expect(
        reviewerStateMutationHookDecision(
          stateMutationJs: '',
          stateMutationKey: 'unused-key',
          mutationSignalCompleted: false,
        ),
        isA<ReviewerStateMutationHookCompleteSignal>(),
      );
    });

    test('empty JavaScript leaves a completed signal alone', () {
      expect(
        reviewerStateMutationHookDecision(
          stateMutationJs: '',
          stateMutationKey: 'unused-key',
          mutationSignalCompleted: true,
        ),
        isA<ReviewerStateMutationHookNoAction>(),
      );
    });

    test('nonempty JavaScript emits the exact raw source template', () {
      const stateMutationKey = "raw'key";
      const stateMutationJs = 'return states + "raw\\njs";';
      const expectedScript =
          "\n            anki.mutateNextCardStates('raw'key', async (states, customData, ctx) => { return states + \"raw\\njs\"; })\n"
          '                .finally(() => fetch("ankidroid/statesMutated", { method: "POST" }));\n'
          '            ';

      for (final mutationSignalCompleted in [false, true]) {
        final decision = reviewerStateMutationHookDecision(
          stateMutationJs: stateMutationJs,
          stateMutationKey: stateMutationKey,
          mutationSignalCompleted: mutationSignalCompleted,
        );

        expect(decision, isA<ReviewerStateMutationHookEmitScript>());
        expect(
          (decision as ReviewerStateMutationHookEmitScript).script,
          expectedScript,
        );
      }
    });
  });
}
