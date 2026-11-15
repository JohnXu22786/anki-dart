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
 * Source-derived Reviewer tag-edit operation tests; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('executeReviewerEditedTags', () {
    test('updates selected tags before the undoable note update', () async {
      final card = Object();
      final note = Object();
      final calls = <Object?>[];

      final changed = await executeReviewerEditedTags(
        selectedTags: [' first ', '', 'third\t'],
        currentCard: () async {
          calls.add('card');
          return card;
        },
        noteForCard: (value) async {
          calls.add(value);
          return note;
        },
        tagsForNote: (value) {
          calls.add(value);
          return ['old'];
        },
        setTagsFromString: (value, tags) async {
          calls.add(('set', value, tags));
        },
        updateNoteUndoably: (value) async {
          calls.add(('update', value));
        },
      );

      expect(changed, isTrue);
      expect(calls, [
        'card',
        card,
        note,
        ('set', note, ' first   third\t'),
        ('update', note),
      ]);
    });

    test('equal ordered tags stop before mutation', () async {
      final calls = <String>[];
      final changed = await executeReviewerEditedTags(
        selectedTags: ['one', 'two'],
        currentCard: () async {
          calls.add('card');
          return Object();
        },
        noteForCard: (_) async {
          calls.add('note');
          return Object();
        },
        tagsForNote: (_) {
          calls.add('tags');
          return ['one', 'two'];
        },
        setTagsFromString: (_, __) async => calls.add('set'),
        updateNoteUndoably: (_) async => calls.add('update'),
      );

      expect(changed, isFalse);
      expect(calls, ['card', 'note', 'tags']);
    });

    test('tag-write failure prevents the undoable update', () async {
      final failure = StateError('tag write');
      final calls = <String>[];

      await expectLater(
        executeReviewerEditedTags(
          selectedTags: ['new'],
          currentCard: () async => Object(),
          noteForCard: (_) async => Object(),
          tagsForNote: (_) => ['old'],
          setTagsFromString: (_, __) async {
            calls.add('set');
            throw failure;
          },
          updateNoteUndoably: (_) async => calls.add('update'),
        ),
        throwsA(same(failure)),
      );

      expect(calls, ['set']);
    });

    test('undoable-update failure propagates after tag mutation', () async {
      final failure = StateError('undoable update');
      final calls = <String>[];

      await expectLater(
        executeReviewerEditedTags(
          selectedTags: ['new'],
          currentCard: () async => Object(),
          noteForCard: (_) async => Object(),
          tagsForNote: (_) => ['old'],
          setTagsFromString: (_, __) async => calls.add('set'),
          updateNoteUndoably: (_) async {
            calls.add('update');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );

      expect(calls, ['set', 'update']);
    });
  });
}
