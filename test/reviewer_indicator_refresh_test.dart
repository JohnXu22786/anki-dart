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
 * Source-derived Reviewer indicator refresh cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer mark icon refresh', () {
    test(
      'resolves and emits once in source order with host object identity',
      () async {
        final calls = <String>[];
        final card = Object();
        Object? resolvedCard;
        bool? emitted;

        await executeReviewerUpdateMarkIcon(
          resolveCurrentCard: () async {
            calls.add('currentCard');
            return card;
          },
          readMarkedTagForCard: (value) async {
            calls.add('withCollection.markedTag');
            resolvedCard = value;
            return true;
          },
          emitMarkIcon: (value) async {
            calls.add('emit');
            emitted = value;
          },
        );

        expect(calls, ['currentCard', 'withCollection.markedTag', 'emit']);
        expect(resolvedCard, same(card));
        expect(emitted, isTrue);
      },
    );

    test('current-card failure propagates and stops later callbacks', () async {
      final failure = StateError('current card');
      final calls = <String>[];

      await expectLater(
        executeReviewerUpdateMarkIcon(
          resolveCurrentCard: () async {
            calls.add('currentCard');
            throw failure;
          },
          readMarkedTagForCard: (_) async {
            calls.add('withCollection.markedTag');
            return false;
          },
          emitMarkIcon: (_) async => calls.add('emit'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['currentCard']);
    });

    test(
      'collection marked-tag lookup failure propagates and stops emission',
      () async {
        final failure = StateError('collection marked tag');
        final calls = <String>[];
        final card = Object();

        await expectLater(
          executeReviewerUpdateMarkIcon(
            resolveCurrentCard: () async {
              calls.add('currentCard');
              return card;
            },
            readMarkedTagForCard: (value) async {
              calls.add('withCollection.markedTag');
              expect(value, same(card));
              throw failure;
            },
            emitMarkIcon: (_) async => calls.add('emit'),
          ),
          throwsA(same(failure)),
        );
        expect(calls, ['currentCard', 'withCollection.markedTag']);
      },
    );

    test('emission failure propagates after one lookup sequence', () async {
      final failure = StateError('emit mark');
      final calls = <String>[];

      await expectLater(
        executeReviewerUpdateMarkIcon(
          resolveCurrentCard: () async {
            calls.add('currentCard');
            return Object();
          },
          readMarkedTagForCard: (_) async {
            calls.add('withCollection.markedTag');
            return false;
          },
          emitMarkIcon: (value) async {
            calls.add('emit:$value');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['currentCard', 'withCollection.markedTag', 'emit:false']);
    });
  });

  group('Reviewer flag icon refresh', () {
    test('resolves and emits the exact flag once in source order', () async {
      final calls = <String>[];
      final card = Object();
      Object? resolvedCard;
      int? emitted;

      await executeReviewerUpdateFlagIcon(
        resolveCurrentCard: () async {
          calls.add('currentCard');
          return card;
        },
        readCardFlag: (value) {
          calls.add('flag');
          resolvedCard = value;
          return 3;
        },
        emitFlagIcon: (value) async {
          calls.add('emit');
          emitted = value;
        },
      );

      expect(calls, ['currentCard', 'flag', 'emit']);
      expect(resolvedCard, same(card));
      expect(emitted, 3);
    });

    test('current-card failure propagates and stops later callbacks', () async {
      final failure = StateError('current card');
      final calls = <String>[];

      await expectLater(
        executeReviewerUpdateFlagIcon(
          resolveCurrentCard: () async {
            calls.add('currentCard');
            throw failure;
          },
          readCardFlag: (_) {
            calls.add('flag');
            return 0;
          },
          emitFlagIcon: (_) async => calls.add('emit'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['currentCard']);
    });

    test('flag read failure propagates and stops emission', () async {
      final failure = StateError('flag');
      final calls = <String>[];

      await expectLater(
        executeReviewerUpdateFlagIcon(
          resolveCurrentCard: () async {
            calls.add('currentCard');
            return Object();
          },
          readCardFlag: (_) {
            calls.add('flag');
            throw failure;
          },
          emitFlagIcon: (_) async => calls.add('emit'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['currentCard', 'flag']);
    });

    test('emission failure propagates after one lookup sequence', () async {
      final failure = StateError('emit flag');
      final calls = <String>[];

      await expectLater(
        executeReviewerUpdateFlagIcon(
          resolveCurrentCard: () async {
            calls.add('currentCard');
            return Object();
          },
          readCardFlag: (_) {
            calls.add('flag');
            return 0;
          },
          emitFlagIcon: (value) async {
            calls.add('emit:$value');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['currentCard', 'flag', 'emit:0']);
    });
  });
}
