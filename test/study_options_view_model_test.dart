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
 * Source-derived from StudyOptionsViewModelTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Study Options projections', () {
    test('buried counts subtract scheduler counts from due-tree counts', () {
      final withTree = DeckStudyData.fromCounts(
        newCardsToday: 2,
        lrnCardsToday: 3,
        revCardsToday: 4,
        totalNewCards: 7,
        numberOfCardsInDeck: 9,
        dueTree: const DeckDueTreeCounts(
          newCount: 5,
          learnCount: 6,
          reviewCount: 8,
        ),
      );
      expect(withTree.buriedNew, 3);
      expect(withTree.buriedLearning, 3);
      expect(withTree.buriedReview, 4);

      final withoutTree = DeckStudyData.fromCounts(
        newCardsToday: 2,
        lrnCardsToday: 3,
        revCardsToday: 4,
        totalNewCards: 7,
        numberOfCardsInDeck: 9,
      );
      expect(withoutTree.buriedNew, 0);
      expect(withoutTree.buriedLearning, 0);
      expect(withoutTree.buriedReview, 0);

      final negativeDifference = DeckStudyData.fromCounts(
        newCardsToday: 5,
        lrnCardsToday: 1,
        revCardsToday: 0,
        totalNewCards: 7,
        numberOfCardsInDeck: 9,
        dueTree: const DeckDueTreeCounts(
          newCount: 2,
          learnCount: 0,
          reviewCount: 0,
        ),
      );
      expect(negativeDifference.buriedNew, -3);
      expect(negativeDifference.buriedLearning, -1);
    });

    test('hasBuriedCards requires a positive buried count', () {
      DeckStudyData data({
        int newCount = 0,
        int learnCount = 0,
        int reviewCount = 0,
      }) => DeckStudyData(
        newCardsToday: 0,
        lrnCardsToday: 0,
        revCardsToday: 0,
        buriedNew: newCount,
        buriedLearning: learnCount,
        buriedReview: reviewCount,
        totalNewCards: 0,
        numberOfCardsInDeck: 0,
      );

      expect(data().hasBuriedCards, isFalse);
      expect(
        data(newCount: -1, learnCount: 0, reviewCount: 0).hasBuriedCards,
        isFalse,
      );
      expect(data(reviewCount: 1).hasBuriedCards, isTrue);
    });

    test('state precedence distinguishes empty regular and filtered decks', () {
      DeckStudyData data({int cards = 0, int newDue = 0}) => DeckStudyData(
        newCardsToday: newDue,
        lrnCardsToday: 0,
        revCardsToday: 0,
        buriedNew: 0,
        buriedLearning: 0,
        buriedReview: 0,
        totalNewCards: 0,
        numberOfCardsInDeck: cards,
      );

      expect(
        projectStudyOptionsState(
          deckName: 'Empty',
          deckDescription: null,
          isDynamic: false,
          data: data(),
        ),
        isA<StudyOptionsEmpty>(),
      );
      expect(
        projectStudyOptionsState(
          deckName: 'Filtered',
          deckDescription: null,
          isDynamic: true,
          data: data(),
        ),
        isA<StudyOptionsCongrats>(),
      );
      expect(
        projectStudyOptionsState(
          deckName: 'Done',
          deckDescription: null,
          isDynamic: false,
          data: data(cards: 1),
        ),
        isA<StudyOptionsCongrats>(),
      );
      final sameEmptyData = data();
      final empty = StudyOptionsEmpty(deckName: 'Empty', data: sameEmptyData);
      expect(empty, StudyOptionsEmpty(deckName: 'Empty', data: sameEmptyData));
      expect(
        empty.hashCode,
        StudyOptionsEmpty(deckName: 'Empty', data: sameEmptyData).hashCode,
      );

      final sameStudyData = data(cards: 1, newDue: 1);
      final study = StudyOptions(
        deckName: 'Due',
        deckDescription: 'description',
        isDynamic: false,
        data: sameStudyData,
      );
      expect(
        study,
        StudyOptions(
          deckName: 'Due',
          deckDescription: 'description',
          isDynamic: false,
          data: sameStudyData,
        ),
      );
      expect(const StudyOptionsLoading(), const StudyOptionsLoading());

      final congrats = StudyOptionsCongrats(
        deckName: 'Done',
        isDynamic: false,
        data: sameEmptyData,
      );
      expect(
        congrats,
        StudyOptionsCongrats(
          deckName: 'Done',
          isDynamic: false,
          data: sameEmptyData,
        ),
      );
      expect(
        congrats.hashCode,
        StudyOptionsCongrats(
          deckName: 'Done',
          isDynamic: false,
          data: sameEmptyData,
        ).hashCode,
      );

      expect(
        projectStudyOptionsState(
          deckName: 'Due',
          deckDescription: 'description',
          isDynamic: false,
          data: data(cards: 1, newDue: 1),
        ),
        isA<StudyOptions>(),
      );
    });

    test('data and deck name helpers return null only while loading', () {
      const loading = StudyOptionsLoading();
      expect(loading.dataOrNull(), isNull);
      expect(loading.deckNameOrNull(), isNull);

      final data = DeckStudyData(
        newCardsToday: 1,
        lrnCardsToday: 0,
        revCardsToday: 0,
        buriedNew: 0,
        buriedLearning: 0,
        buriedReview: 0,
        totalNewCards: 1,
        numberOfCardsInDeck: 1,
      );
      final states = <StudyOptionsState>[
        StudyOptions(
          deckName: 'Study',
          deckDescription: null,
          isDynamic: false,
          data: data,
        ),
        StudyOptionsCongrats(
          deckName: 'Congrats',
          isDynamic: false,
          data: data,
        ),
        StudyOptionsEmpty(deckName: 'Empty', data: data),
      ];
      for (final state in states) {
        expect(state.dataOrNull(), same(data));
        expect(state.deckNameOrNull(), isNotNull);
      }
      expect(states.map((state) => state.deckNameOrNull()), [
        'Study',
        'Congrats',
        'Empty',
      ]);
    });
  });
}
