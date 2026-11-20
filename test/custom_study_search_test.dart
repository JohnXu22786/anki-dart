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
  test(
    'custom study search scopes by deck and combines selected predicates',
    () {
      expect(
        buildCustomStudySearch(
          deckName: 'Biology::Cell',
          state: CustomStudyCardState.ReviewCardsRandom,
          includedTags: ['hard', 'exam'],
          excludedTags: ['leech'],
        ),
        'deck:Biology::Cell is:review (tag:hard OR tag:exam) -tag:leech',
      );
    },
  );

  test('tag wildcards are escaped so selected names stay exact', () {
    expect(
      buildCustomStudySearch(
        deckName: 'Default',
        state: CustomStudyCardState.AllCardsRandom,
        includedTags: ['exam*'],
        excludedTags: ['leech_tag'],
      ),
      r'deck:Default (tag:exam\*) -tag:leech\_tag',
    );
  });

  test('all cards omits state and included tags use OR', () {
    expect(
      buildCustomStudySearch(
        deckName: 'Default',
        state: CustomStudyCardState.AllCardsRandom,
        includedTags: [],
        excludedTags: ['a', 'b'],
      ),
      'deck:Default -tag:a -tag:b',
    );
  });

  test('rejects invalid count and more than 100 selected tags', () {
    expect(() => validateCustomStudyInput(cardLimit: 0), throwsArgumentError);
    expect(
      () => validateCustomStudyInput(cardLimit: 1 << 31),
      throwsRangeError,
    );
    expect(
      () => validateCustomStudyInput(
        cardLimit: 1,
        includedTags: List.filled(51, 'x'),
        excludedTags: List.filled(50, 'y'),
      ),
      throwsArgumentError,
    );
  });
}
