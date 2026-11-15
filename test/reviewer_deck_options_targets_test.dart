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
 * Source-derived Reviewer deck-options target cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer deck-options targets', () {
    test('includes current, nonzero original, and noncurrent card decks', () {
      List<int> ids({
        required int current,
        required int original,
        required int card,
      }) => projectReviewerDeckOptionsTargets(
        currentDeckId: current,
        originalDeckId: original,
        cardDeckId: card,
        deckInfoById: {
          current: const ReviewerDeckOptionsDeckInfo(name: 'Current'),
          original: const ReviewerDeckOptionsDeckInfo(name: 'Original'),
          card: const ReviewerDeckOptionsDeckInfo(name: 'Card'),
        },
      ).map((target) => target.deckId).toList();

      expect(ids(current: 10, original: 0, card: 10), [10]);
      expect(ids(current: 10, original: 10, card: 11), [10, 11]);
      expect(ids(current: 10, original: 12, card: 13), [10, 12, 13]);
    });

    test('preserves duplicate original and card deck candidates', () {
      final targets = projectReviewerDeckOptionsTargets(
        currentDeckId: 10,
        originalDeckId: 12,
        cardDeckId: 12,
        deckInfoById: {
          10: const ReviewerDeckOptionsDeckInfo(name: 'Current'),
          12: const ReviewerDeckOptionsDeckInfo(name: 'Other'),
        },
      );

      expect(targets.map((target) => target.deckId), [10, 12, 12]);
    });

    test('omits null names and stably sorts unfiltered targets first', () {
      final targets = projectReviewerDeckOptionsTargets(
        currentDeckId: 1,
        originalDeckId: 2,
        cardDeckId: 3,
        deckInfoById: {
          1: const ReviewerDeckOptionsDeckInfo(
            name: 'Current',
            isFiltered: true,
          ),
          2: const ReviewerDeckOptionsDeckInfo(name: 'Original'),
          3: const ReviewerDeckOptionsDeckInfo(name: 'Card', isFiltered: true),
        },
      );

      expect(targets.map((target) => target.deckId), [2, 1, 3]);

      final missingName = projectReviewerDeckOptionsTargets(
        currentDeckId: 1,
        originalDeckId: 2,
        cardDeckId: 3,
        deckInfoById: {
          1: const ReviewerDeckOptionsDeckInfo(name: 'Current'),
          2: const ReviewerDeckOptionsDeckInfo(name: null),
          3: const ReviewerDeckOptionsDeckInfo(name: 'Card'),
        },
      );

      expect(missingName.map((target) => target.deckId), [1, 3]);
    });
  });
}
