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
 * Behavioral reference: BrowserColumnCollection.kt and its tests in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserColumnCollection', () {
    test('uses the caller-supplied defaults when no preference exists', () {
      final cards = BrowserColumnCollection.load(
        preferenceValue: null,
        defaultColumnKeys: const ['noteFld', 'template', 'cardDue', 'deck'],
      );
      final notes = BrowserColumnCollection.load(
        preferenceValue: null,
        defaultColumnKeys: const ['noteFld', 'note', 'template', 'noteTags'],
      );

      expect(cards.columns.map((column) => column.key).toList(), [
        'noteFld',
        'template',
        'cardDue',
        'deck',
      ]);
      expect(notes.columns.map((column) => column.key).toList(), [
        'noteFld',
        'note',
        'template',
        'noteTags',
      ]);
    });

    test('preserves stored order and removes duplicates when loading', () {
      final collection = BrowserColumnCollection.load(
        preferenceValue: 'deck|noteFld|deck|question',
        defaultColumnKeys: const ['template'],
      );

      expect(collection.backendKeys, ['deck', 'noteFld', 'question']);
      expect(collection.count, 3);
      expect(collection[1], BrowserColumn.sortField);
    });

    test('falls back to defaults for malformed or unknown keys', () {
      const defaults = ['noteFld', 'template'];
      for (final stored in ['unknown|deck', 'deck||noteFld', '']) {
        final collection = BrowserColumnCollection.load(
          preferenceValue: stored,
          defaultColumnKeys: defaults,
        );

        expect(collection.backendKeys, defaults, reason: stored);
      }
    });

    test('successful update removes null columns and serializes in order', () {
      final update = BrowserColumnCollection.update(
        preferenceValue: 'noteFld|template|cardDue',
        defaultColumnKeys: const ['deck'],
        mutate: (columns) {
          columns
            ..clear()
            ..addAll([
              BrowserColumn.sortField,
              null,
              BrowserColumn.fsrsStability,
            ]);
          return true;
        },
      );

      expect(update!.collection.backendKeys, ['noteFld', 'stability']);
      expect(update.preferenceValue, 'noteFld|stability');
    });

    test('a rejected update returns null', () {
      var mutationCalls = 0;
      final update = BrowserColumnCollection.update(
        preferenceValue: 'noteFld|deck',
        defaultColumnKeys: const ['template'],
        mutate: (columns) {
          mutationCalls++;
          columns.clear();
          return false;
        },
      );

      expect(update, isNull);
      expect(mutationCalls, 1);
    });

    test('replacement returns old columns and new serialized values', () {
      final replacement = BrowserColumnCollection.replace(
        preferenceValue: 'deck|noteFld|deck',
        defaultColumnKeys: const ['template'],
        newColumns: const [BrowserColumn.question, BrowserColumn.tags],
      );

      expect(replacement.originalColumns, [
        BrowserColumn.deck,
        BrowserColumn.sortField,
      ]);
      expect(replacement.newColumns.columns, [
        BrowserColumn.question,
        BrowserColumn.tags,
      ]);
      expect(replacement.preferenceValue, 'question|noteTags');
    });

    test('update retains duplicate values until the next load', () {
      final update = BrowserColumnCollection.update(
        preferenceValue: 'deck',
        defaultColumnKeys: const ['template'],
        mutate: (columns) {
          columns.add(BrowserColumn.deck);
          return true;
        },
      )!;

      expect(
          update.collection.columns, [BrowserColumn.deck, BrowserColumn.deck]);
      expect(update.preferenceValue, 'deck|deck');
      expect(
        BrowserColumnCollection.load(
          preferenceValue: update.preferenceValue,
          defaultColumnKeys: const ['template'],
        ).columns,
        [BrowserColumn.deck],
      );
    });

    test('exposes read-only views while retaining constructor list aliasing',
        () {
      final input = <BrowserColumn>[BrowserColumn.question];
      final collection = BrowserColumnCollection(input);

      expect(
        () => collection.columns.add(BrowserColumn.tags),
        throwsUnsupportedError,
      );

      // The Kotlin constructor retains the supplied List reference and caches
      // count once, so later changes through another alias remain observable.
      input.add(BrowserColumn.tags);
      expect(collection.columns, [BrowserColumn.question, BrowserColumn.tags]);
      expect(collection.count, 1);
    });
  });
}
