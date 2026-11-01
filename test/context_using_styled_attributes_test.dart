/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from Context.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('usingStyledAttributes', () {
    test(
      'forwards arguments and preserves successful callback order and identity',
      () {
        final set = Object();
        final attrs = Object();
        final token = Object();
        final result = Object();
        final events = <String>[];
        var obtainCount = 0;
        var blockCount = 0;
        var recycleCount = 0;
        Object? receivedSet;
        Object? receivedAttrs;
        var receivedDefStyleAttr = 0;
        var receivedDefStyleRes = 0;

        final actual = usingStyledAttributes<Object>(
          set: set,
          attrs: attrs,
          defStyleAttr: 19,
          defStyleRes: 23,
          obtainStyledAttributes:
              (receivedSetValue, receivedAttrsValue, attr, res) {
                events.add('obtain');
                obtainCount++;
                receivedSet = receivedSetValue;
                receivedAttrs = receivedAttrsValue;
                receivedDefStyleAttr = attr;
                receivedDefStyleRes = res;
                return token;
              },
          block: (typedArray) {
            events.add('block');
            blockCount++;
            expect(identical(typedArray, token), isTrue);
            return result;
          },
          recycle: (typedArray) {
            events.add('recycle');
            recycleCount++;
            expect(identical(typedArray, token), isTrue);
          },
        );

        expect(identical(receivedSet, set), isTrue);
        expect(identical(receivedAttrs, attrs), isTrue);
        expect(receivedDefStyleAttr, 19);
        expect(receivedDefStyleRes, 23);
        expect(obtainCount, 1);
        expect(blockCount, 1);
        expect(recycleCount, 1);
        expect(events, ['obtain', 'block', 'recycle']);
        expect(identical(actual, result), isTrue);
      },
    );

    test(
      'an acquisition failure propagates without invoking block or recycle',
      () {
        final failure = StateError('obtain failed');
        final events = <String>[];

        expect(
          () => usingStyledAttributes<Object>(
            set: null,
            attrs: Object(),
            obtainStyledAttributes: (_, _, _, _) {
              events.add('obtain');
              throw failure;
            },
            block: (_) {
              events.add('block');
              return Object();
            },
            recycle: (_) => events.add('recycle'),
          ),
          throwsA(same(failure)),
        );
        expect(events, ['obtain']);
      },
    );

    test('a block failure propagates unchanged without recycling', () {
      final token = Object();
      final failure = StateError('block failed');
      final events = <String>[];

      expect(
        () => usingStyledAttributes<Object>(
          set: null,
          attrs: Object(),
          obtainStyledAttributes: (_, _, _, _) {
            events.add('obtain');
            return token;
          },
          block: (typedArray) {
            events.add('block');
            expect(identical(typedArray, token), isTrue);
            throw failure;
          },
          recycle: (_) => events.add('recycle'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['obtain', 'block']);
    });

    test(
      'a recycle failure propagates after the block without returning its result',
      () {
        final token = Object();
        final result = Object();
        final failure = StateError('recycle failed');
        final events = <String>[];

        expect(
          () => usingStyledAttributes<Object>(
            set: null,
            attrs: Object(),
            obtainStyledAttributes: (_, _, _, _) {
              events.add('obtain');
              return token;
            },
            block: (typedArray) {
              events.add('block');
              expect(identical(typedArray, token), isTrue);
              return result;
            },
            recycle: (typedArray) {
              events.add('recycle');
              expect(identical(typedArray, token), isTrue);
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(events, ['obtain', 'block', 'recycle']);
      },
    );
  });
}
