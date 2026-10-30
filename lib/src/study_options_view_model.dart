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
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: StudyOptionsViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Counts from the scheduler due tree before buried cards are excluded.
class DeckDueTreeCounts {
  const DeckDueTreeCounts({
    required this.newCount,
    required this.learnCount,
    required this.reviewCount,
  });

  final int newCount;
  final int learnCount;
  final int reviewCount;
}

/// Portable deck counts projected by AnkiDroid's Study Options view model.
class DeckStudyData {
  const DeckStudyData({
    required this.newCardsToday,
    required this.lrnCardsToday,
    required this.revCardsToday,
    required this.buriedNew,
    required this.buriedLearning,
    required this.buriedReview,
    required this.totalNewCards,
    required this.numberOfCardsInDeck,
  });

  /// Builds study data from scheduler counts and an optional due tree.
  ///
  /// Buried counts are the due-tree counts minus the scheduler counts. When the
  /// due tree is absent, all buried counts are zero.
  factory DeckStudyData.fromCounts({
    required int newCardsToday,
    required int lrnCardsToday,
    required int revCardsToday,
    required int totalNewCards,
    required int numberOfCardsInDeck,
    DeckDueTreeCounts? dueTree,
  }) => DeckStudyData(
    newCardsToday: newCardsToday,
    lrnCardsToday: lrnCardsToday,
    revCardsToday: revCardsToday,
    buriedNew: dueTree == null ? 0 : dueTree.newCount - newCardsToday,
    buriedLearning: dueTree == null ? 0 : dueTree.learnCount - lrnCardsToday,
    buriedReview: dueTree == null ? 0 : dueTree.reviewCount - revCardsToday,
    totalNewCards: totalNewCards,
    numberOfCardsInDeck: numberOfCardsInDeck,
  );

  final int newCardsToday;
  final int lrnCardsToday;
  final int revCardsToday;
  final int buriedNew;
  final int buriedLearning;
  final int buriedReview;
  final int totalNewCards;
  final int numberOfCardsInDeck;

  /// True if any cards (new, learning, or review) are buried.
  bool get hasBuriedCards =>
      buriedNew > 0 || buriedLearning > 0 || buriedReview > 0;
}

sealed class StudyOptionsState {
  const StudyOptionsState();
}

/// Initial state, before the host supplies collection data.
final class StudyOptionsLoading extends StudyOptionsState {
  const StudyOptionsLoading();

  @override
  bool operator ==(Object other) => other is StudyOptionsLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// State for a deck with cards due for study.
final class StudyOptions extends StudyOptionsState {
  const StudyOptions({
    required this.deckName,
    required this.deckDescription,
    required this.isDynamic,
    required this.data,
  });

  final String deckName;
  final String? deckDescription;
  final bool isDynamic;
  final DeckStudyData data;

  @override
  bool operator ==(Object other) =>
      other is StudyOptions &&
      other.deckName == deckName &&
      other.deckDescription == deckDescription &&
      other.isDynamic == isDynamic &&
      other.data == data;

  @override
  int get hashCode => Object.hash(deckName, deckDescription, isDynamic, data);
}

/// State for a deck with no cards currently due.
final class StudyOptionsCongrats extends StudyOptionsState {
  const StudyOptionsCongrats({
    required this.deckName,
    required this.isDynamic,
    required this.data,
  });

  final String deckName;
  final bool isDynamic;
  final DeckStudyData data;

  @override
  bool operator ==(Object other) =>
      other is StudyOptionsCongrats &&
      other.deckName == deckName &&
      other.isDynamic == isDynamic &&
      other.data == data;

  @override
  int get hashCode => Object.hash(deckName, isDynamic, data);
}

/// State for a non-filtered deck that contains no cards.
final class StudyOptionsEmpty extends StudyOptionsState {
  const StudyOptionsEmpty({required this.deckName, required this.data});

  final String deckName;
  final DeckStudyData data;

  @override
  bool operator ==(Object other) =>
      other is StudyOptionsEmpty &&
      other.deckName == deckName &&
      other.data == data;

  @override
  int get hashCode => Object.hash(deckName, data);
}

/// Projects the source branch order after the host resolves deck and count data.
StudyOptionsState projectStudyOptionsState({
  required String deckName,
  required String? deckDescription,
  required bool isDynamic,
  required DeckStudyData data,
}) {
  final totalDue = data.newCardsToday + data.lrnCardsToday + data.revCardsToday;
  if (data.numberOfCardsInDeck == 0 && !isDynamic) {
    return StudyOptionsEmpty(deckName: deckName, data: data);
  }
  if (totalDue == 0) {
    return StudyOptionsCongrats(
      deckName: deckName,
      isDynamic: isDynamic,
      data: data,
    );
  }
  return StudyOptions(
    deckName: deckName,
    deckDescription: deckDescription,
    isDynamic: isDynamic,
    data: data,
  );
}

extension StudyOptionsStateAccessors on StudyOptionsState {
  /// Returns the data for populated states, or null while loading.
  DeckStudyData? dataOrNull() => switch (this) {
    StudyOptions(data: final data) => data,
    StudyOptionsCongrats(data: final data) => data,
    StudyOptionsEmpty(data: final data) => data,
    StudyOptionsLoading() => null,
  };

  /// Returns the deck name for populated states, or null while loading.
  String? deckNameOrNull() => switch (this) {
    StudyOptions(deckName: final deckName) => deckName,
    StudyOptionsCongrats(deckName: final deckName) => deckName,
    StudyOptionsEmpty(deckName: final deckName) => deckName,
    StudyOptionsLoading() => null,
  };
}
