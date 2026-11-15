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
 * Source-derived from DeckPickerViewModel.kt:150–171 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Deck Picker initial-state projection', () {
    test('preserves a null tree and requires default-only plus no cards', () {
      expect(
        projectDeckPickerInitialState(null, collectionHasNoCards: true),
        isNull,
      );

      final defaultOnlyTree = DeckNode.syntheticRoot(
        children: [DeckNode(did: 1, fullDeckName: 'Default', depth: 0)],
      );
      expect(
        projectDeckPickerInitialState(
          defaultOnlyTree,
          collectionHasNoCards: true,
        ),
        isTrue,
      );
      expect(
        projectDeckPickerInitialState(
          defaultOnlyTree,
          collectionHasNoCards: false,
        ),
        isFalse,
      );

      expect(
        projectDeckPickerInitialState(
          DeckNode.syntheticRoot(),
          collectionHasNoCards: true,
        ),
        isFalse,
      );
      expect(
        projectDeckPickerInitialState(
          DeckNode.syntheticRoot(
            children: [
              DeckNode(did: 1, fullDeckName: 'Default', depth: 0),
              DeckNode(did: 2, fullDeckName: 'Other', depth: 0),
            ],
          ),
          collectionHasNoCards: true,
        ),
        isFalse,
      );
    });

    test('projects cards due only when initial state is exactly false', () {
      final tree = DeckNode.syntheticRoot(
        children: [
          DeckNode(
            did: 2,
            fullDeckName: 'Other',
            depth: 0,
            newCount: 3,
            revCount: 4,
            lrnCount: 5,
          ),
        ],
      );
      expect(projectDeckPickerCardsDue(null, isInInitialState: false), isNull);
      expect(projectDeckPickerCardsDue(tree, isInInitialState: null), isNull);
      expect(projectDeckPickerCardsDue(tree, isInInitialState: true), isNull);
      expect(projectDeckPickerCardsDue(tree, isInInitialState: false), 12);
      expect(
        projectDeckPickerCardsDue(
          DeckNode.syntheticRoot(),
          isInInitialState: false,
        ),
        0,
      );
    });

    test(
      'projects divider visibility from nullable initial state and no-cards',
      () {
        expect(
          projectDeckPickerResizingDividerVisible(
            isInInitialState: null,
            collectionHasNoCards: false,
          ),
          isTrue,
        );
        expect(
          projectDeckPickerResizingDividerVisible(
            isInInitialState: null,
            collectionHasNoCards: true,
          ),
          isFalse,
        );
        expect(
          projectDeckPickerResizingDividerVisible(
            isInInitialState: true,
            collectionHasNoCards: false,
          ),
          isFalse,
        );
        expect(
          projectDeckPickerResizingDividerVisible(
            isInInitialState: false,
            collectionHasNoCards: false,
          ),
          isTrue,
        );
      },
    );
  });
}
