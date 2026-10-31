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
 */

/// Host-resolved deck metadata needed to project a Reviewer deck-options target.
class ReviewerDeckOptionsDeckInfo {
  const ReviewerDeckOptionsDeckInfo({
    required this.name,
    this.isFiltered = false,
  });

  final String? name;
  final bool isFiltered;
}

/// A named deck that can be offered as a Reviewer deck-options target.
class ReviewerDeckOptionsTarget {
  const ReviewerDeckOptionsTarget({
    required this.deckId,
    required this.name,
    required this.isFiltered,
  });

  final int deckId;
  final String name;
  final bool isFiltered;
}

/// Projects source-ordered candidate IDs through host-resolved deck metadata.
///
/// Every candidate ID must have an entry in [deckInfoById]. Missing deck names
/// are omitted. Duplicate candidate IDs are preserved, and targets with the
/// same filtered status retain their source order.
List<ReviewerDeckOptionsTarget> projectReviewerDeckOptionsTargets({
  required int currentDeckId,
  required int originalDeckId,
  required int cardDeckId,
  required Map<int, ReviewerDeckOptionsDeckInfo> deckInfoById,
}) {
  final candidateIds = <int>[currentDeckId];
  if (originalDeckId != 0 && originalDeckId != currentDeckId) {
    candidateIds.add(originalDeckId);
  }
  if (cardDeckId != currentDeckId) {
    candidateIds.add(cardDeckId);
  }

  final indexedTargets = <({int index, ReviewerDeckOptionsTarget target})>[];
  for (var index = 0; index < candidateIds.length; index++) {
    final deckId = candidateIds[index];
    final deckInfo = deckInfoById[deckId]!;
    final name = deckInfo.name;
    if (name != null) {
      indexedTargets.add((
        index: index,
        target: ReviewerDeckOptionsTarget(
          deckId: deckId,
          name: name,
          isFiltered: deckInfo.isFiltered,
        ),
      ));
    }
  }

  indexedTargets.sort((left, right) {
    final leftFiltered = left.target.isFiltered ? 1 : 0;
    final rightFiltered = right.target.isFiltered ? 1 : 0;
    final filteredOrder = leftFiltered.compareTo(rightFiltered);
    return filteredOrder != 0
        ? filteredOrder
        : left.index.compareTo(right.index);
  });
  return indexedTargets.map((entry) => entry.target).toList();
}
