/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Reviewer mark-toggle operation cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer mark-toggle operation', () {
    for (final isMarked in [false, true]) {
      test('resolves and toggles once before publishing $isMarked', () async {
        final events = <String>[];
        final card = Object();
        final note = Object();
        var cardReads = 0;
        var noteLookups = 0;
        var toggles = 0;
        var markReads = 0;
        var publications = 0;
        Object? resolvedCard;
        Object? toggledNote;
        Object? readNote;
        bool? published;

        await executeReviewerMarkToggleOperation<Object, Object>(
          currentCard: () {
            events.add('currentCard');
            cardReads++;
            return card;
          },
          noteForCard: (value) {
            events.add('noteForCard');
            noteLookups++;
            resolvedCard = value;
            return note;
          },
          toggleMark: (value) {
            events.add('toggleMark');
            toggles++;
            toggledNote = value;
          },
          isMarked: (value) {
            events.add('isMarked');
            markReads++;
            readNote = value;
            return isMarked;
          },
          publishMarkState: (value) {
            events.add('publishMarkState');
            publications++;
            published = value;
          },
        );

        expect(events, [
          'currentCard',
          'noteForCard',
          'toggleMark',
          'isMarked',
          'publishMarkState',
        ]);
        expect(cardReads, 1);
        expect(noteLookups, 1);
        expect(toggles, 1);
        expect(markReads, 1);
        expect(publications, 1);
        expect(resolvedCard, same(card));
        expect(toggledNote, same(note));
        expect(readNote, same(note));
        expect(published, isMarked);
      });
    }

    test('current-card failure propagates unchanged and stops callbacks', () async {
      final events = <String>[];
      final failure = StateError('current card failed');

      await expectLater(
        executeReviewerMarkToggleOperation<Object, Object>(
          currentCard: () {
            events.add('currentCard');
            throw failure;
          },
          noteForCard: (_) {
            events.add('noteForCard');
            return Object();
          },
          toggleMark: (_) => events.add('toggleMark'),
          isMarked: (_) => false,
          publishMarkState: (_) => events.add('publishMarkState'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['currentCard']);
    });

    test('note-lookup failure propagates unchanged and stops callbacks', () async {
      final events = <String>[];
      final failure = StateError('note lookup failed');

      await expectLater(
        executeReviewerMarkToggleOperation<Object, Object>(
          currentCard: () {
            events.add('currentCard');
            return Object();
          },
          noteForCard: (_) {
            events.add('noteForCard');
            throw failure;
          },
          toggleMark: (_) => events.add('toggleMark'),
          isMarked: (_) => false,
          publishMarkState: (_) => events.add('publishMarkState'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['currentCard', 'noteForCard']);
    });

    test('toggle failure propagates unchanged and skips read and publish', () async {
      final events = <String>[];
      final failure = StateError('toggle failed');
      final note = Object();

      await expectLater(
        executeReviewerMarkToggleOperation<Object, Object>(
          currentCard: () => Object(),
          noteForCard: (_) => note,
          toggleMark: (value) {
            events.add('toggleMark');
            expect(value, same(note));
            throw failure;
          },
          isMarked: (_) {
            events.add('isMarked');
            return true;
          },
          publishMarkState: (_) => events.add('publishMarkState'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['toggleMark']);
    });

    test('marked-state read failure propagates and skips publication', () async {
      final events = <String>[];
      final failure = StateError('marked-state read failed');
      final note = Object();

      await expectLater(
        executeReviewerMarkToggleOperation<Object, Object>(
          currentCard: () => Object(),
          noteForCard: (_) => note,
          toggleMark: (value) {
            events.add('toggleMark');
            expect(value, same(note));
          },
          isMarked: (value) {
            events.add('isMarked');
            expect(value, same(note));
            throw failure;
          },
          publishMarkState: (_) => events.add('publishMarkState'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['toggleMark', 'isMarked']);
    });

    test('publication failure propagates unchanged', () async {
      final events = <String>[];
      final failure = StateError('publication failed');

      await expectLater(
        executeReviewerMarkToggleOperation<Object, Object>(
          currentCard: () => Object(),
          noteForCard: (_) => Object(),
          toggleMark: (_) => events.add('toggleMark'),
          isMarked: (_) {
            events.add('isMarked');
            return false;
          },
          publishMarkState: (value) {
            events.add('publishMarkState');
            expect(value, isFalse);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['toggleMark', 'isMarked', 'publishMarkState']);
    });
  });
}
