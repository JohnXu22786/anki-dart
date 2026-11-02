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
 * Source-derived Reviewer opExecuted cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer opExecuted effect plan', () {
    test('requests labels first and stops for the source handler', () {
      expect(
        planReviewerOpExecutedEffects(
          isSelfHandler: true,
          hasStudyQueueChanges: true,
          hasNoteTextChanges: true,
          hasCardChanges: true,
          showingAnswer: true,
        ),
        [ReviewerOpExecutedEffect.updateUndoAndRedoLabels],
      );
    });

    test('study queue updates take priority over other changed areas', () {
      expect(
        planReviewerOpExecutedEffects(
          isSelfHandler: false,
          hasStudyQueueChanges: true,
          hasNoteTextChanges: true,
          hasCardChanges: true,
          showingAnswer: false,
        ),
        [
          ReviewerOpExecutedEffect.updateUndoAndRedoLabels,
          ReviewerOpExecutedEffect.updateCurrentCard,
        ],
      );
    });

    test('note text changes reload before tags, mark, and selected side', () {
      final commonEffects = [
        ReviewerOpExecutedEffect.updateUndoAndRedoLabels,
        ReviewerOpExecutedEffect.loadCurrentCard,
        ReviewerOpExecutedEffect.loadCardAvTags,
        ReviewerOpExecutedEffect.updateMarkIcon,
      ];

      expect(
        planReviewerOpExecutedEffects(
          isSelfHandler: false,
          hasStudyQueueChanges: false,
          hasNoteTextChanges: true,
          hasCardChanges: true,
          showingAnswer: true,
        ),
        [...commonEffects, ReviewerOpExecutedEffect.showAnswer],
      );
      expect(
        planReviewerOpExecutedEffects(
          isSelfHandler: false,
          hasStudyQueueChanges: false,
          hasNoteTextChanges: true,
          hasCardChanges: true,
          showingAnswer: false,
        ),
        [...commonEffects, ReviewerOpExecutedEffect.showQuestion],
      );
    });

    test(
      'card changes reload before flag update and unrelated changes stop',
      () {
        expect(
          planReviewerOpExecutedEffects(
            isSelfHandler: false,
            hasStudyQueueChanges: false,
            hasNoteTextChanges: false,
            hasCardChanges: true,
            showingAnswer: false,
          ),
          [
            ReviewerOpExecutedEffect.updateUndoAndRedoLabels,
            ReviewerOpExecutedEffect.loadCurrentCard,
            ReviewerOpExecutedEffect.updateFlagIcon,
          ],
        );
        expect(
          planReviewerOpExecutedEffects(
            isSelfHandler: false,
            hasStudyQueueChanges: false,
            hasNoteTextChanges: false,
            hasCardChanges: false,
            showingAnswer: false,
          ),
          [ReviewerOpExecutedEffect.updateUndoAndRedoLabels],
        );
      },
    );
  });
}
