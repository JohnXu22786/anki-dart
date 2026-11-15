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
 * Source-derived Reviewer show-question cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer show-question effects', () {
    test(
      'replaces a completed mutation signal before ordered question effects',
      () {
        expect(
          planReviewerShowQuestionEffects(
            mutationSignalCompleted: true,
            shouldWaitForAudio: false,
          ),
          [
            ReviewerShowQuestionEffect.replaceCompletedMutationSignal,
            ReviewerShowQuestionEffect.showQuestion,
            ReviewerShowQuestionEffect.runStateMutationHook,
            ReviewerShowQuestionEffect.updateMarkIcon,
            ReviewerShowQuestionEffect.updateFlagIcon,
            ReviewerShowQuestionEffect.autoAdvanceOnShowQuestion,
          ],
        );
      },
    );

    test(
      'preserves a pending mutation signal before ordered question effects',
      () {
        expect(
          planReviewerShowQuestionEffects(
            mutationSignalCompleted: false,
            shouldWaitForAudio: false,
          ),
          [
            ReviewerShowQuestionEffect.showQuestion,
            ReviewerShowQuestionEffect.runStateMutationHook,
            ReviewerShowQuestionEffect.updateMarkIcon,
            ReviewerShowQuestionEffect.updateFlagIcon,
            ReviewerShowQuestionEffect.autoAdvanceOnShowQuestion,
          ],
        );
      },
    );

    test('omits question auto-advance while waiting for audio', () {
      expect(
        planReviewerShowQuestionEffects(
          mutationSignalCompleted: false,
          shouldWaitForAudio: true,
        ),
        [
          ReviewerShowQuestionEffect.showQuestion,
          ReviewerShowQuestionEffect.runStateMutationHook,
          ReviewerShowQuestionEffect.updateMarkIcon,
          ReviewerShowQuestionEffect.updateFlagIcon,
        ],
      );
    });
  });
}
