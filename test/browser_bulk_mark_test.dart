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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserBulkMarkToggle', () {
    test('no selected card ids produce no operation or note-state reads', () {
      var inspectedNoteStates = false;
      final noteStates = Iterable<bool>.generate(1, (_) {
        inspectedNoteStates = true;
        throw StateError('no selected cards should skip note state lookup');
      });

      expect(
        planBrowserBulkMarkToggle(
          selectedCardIds: const <int>[],
          noteMarkedStates: noteStates,
        ),
        isNull,
      );
      expect(inspectedNoteStates, isFalse);
    });

    test('all notes already marked selects removal and preserves card ids', () {
      final selectedCardIds = [10, 20, 30];

      expect(
        planBrowserBulkMarkToggle(
          selectedCardIds: selectedCardIds,
          noteMarkedStates: const [true, true],
        ),
        BrowserBulkMarkOperation.removeMarkedTag,
      );
      expect(selectedCardIds, [10, 20, 30]);
    });

    test('unmarked or mixed notes select adding the tag to all notes', () {
      expect(
        planBrowserBulkMarkToggle(
          selectedCardIds: const [10],
          noteMarkedStates: const [false],
        ),
        BrowserBulkMarkOperation.addMarkedTag,
      );
      expect(
        planBrowserBulkMarkToggle(
          selectedCardIds: const [10, 20],
          noteMarkedStates: const [true, false],
        ),
        BrowserBulkMarkOperation.addMarkedTag,
      );
    });

    test('nonempty card selection with no resolved notes follows all(empty)',
        () {
      expect(
        planBrowserBulkMarkToggle(
          selectedCardIds: const [10],
          noteMarkedStates: const <bool>[],
        ),
        BrowserBulkMarkOperation.removeMarkedTag,
      );
    });
  });
}
