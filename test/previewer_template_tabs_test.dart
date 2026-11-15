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
 * Source-derived Template Previewer tab and answer-side decision cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Previewer answer toggle', () {
    test('showing the answer hides it before loading question audio', () {
      expect(previewerToggleShowAnswerEffects(showingAnswer: true), [
        PreviewerTemplateTabEffect.showQuestion,
        PreviewerTemplateTabEffect.loadQuestionSounds,
      ]);
    });

    test(
      'showing the question reveals the answer before loading answer audio',
      () {
        expect(previewerToggleShowAnswerEffects(showingAnswer: false), [
          PreviewerTemplateTabEffect.showAnswer,
          PreviewerTemplateTabEffect.loadAnswerSounds,
        ]);
      },
    );
  });

  group('Previewer template tabs', () {
    test(
      'selects the cloze ordinal at the selected tab and keeps index error',
      () {
        expect(
          previewerSelectedTemplateOrd(
            isCloze: true,
            clozeOrds: [3, 6, 8],
            position: 1,
          ),
          6,
        );
        expect(
          () => previewerSelectedTemplateOrd(
            isCloze: true,
            clozeOrds: [3, 6, 8],
            position: 3,
          ),
          throwsRangeError,
        );
      },
    );

    test('uses the tab position directly for non-cloze notes', () {
      expect(
        previewerSelectedTemplateOrd(
          isCloze: false,
          clozeOrds: null,
          position: 4,
        ),
        4,
      );
    });

    test('maps cloze ordinals back to tab index and preserves missing -1', () {
      expect(
        previewerCurrentTemplateTabIndex(
          isCloze: true,
          clozeOrds: [3, 6, 8],
          currentOrd: 6,
        ),
        1,
      );
      expect(
        previewerCurrentTemplateTabIndex(
          isCloze: true,
          clozeOrds: [3, 6, 8],
          currentOrd: 0,
        ),
        -1,
      );
    });

    test('returns and clamps a safe cloze ordinal for recreation', () {
      expect(previewerSafeClozeOrd(clozeOrds: null, currentOrd: 4), 0);
      expect(previewerSafeClozeOrd(clozeOrds: [], currentOrd: 4), 0);
      expect(previewerSafeClozeOrd(clozeOrds: [3, 6, 8], currentOrd: -2), 0);
      expect(previewerSafeClozeOrd(clozeOrds: [3, 6, 8], currentOrd: 9), 2);
    });
  });
}
