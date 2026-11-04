/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold norbert.nagold@gmail.com
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card deck config methods', () {
    test(
      'timeLimit looks up the current deck once and multiplies milliseconds',
      () {
        final values = <String, Object?>{'maxTaken': 23};
        final reads = <String>[];
        final config = _config(values, reads);
        final deckIds = <int>[];

        final result = cardTimeLimit(
          oDid: 0,
          did: 17,
          configForDeckId: (deckId) {
            deckIds.add(deckId);
            return config;
          },
        );

        expect(result, 23000);
        expect(deckIds, [17]);
        expect(reads, ['getInt:maxTaken']);
      },
    );

    test('timeLimit uses the original deck for filtered cards', () {
      final values = <String, Object?>{'maxTaken': 31};
      final reads = <String>[];
      final config = _config(values, reads);
      final deckIds = <int>[];

      final result = cardTimeLimit(
        oDid: 19,
        did: 41,
        configForDeckId: (deckId) {
          deckIds.add(deckId);
          return config;
        },
      );

      expect(result, 31000);
      expect(deckIds, [19]);
      expect(reads, ['getInt:maxTaken']);
    });

    test('timeLimit preserves Kotlin signed Int overflow', () {
      final config = _config({'maxTaken': 2147484}, []);

      expect(
        cardTimeLimit(oDid: 0, did: 1, configForDeckId: (_) => config),
        (2147484 * 1000).toSigned(32),
      );
    });

    test(
      'timer, replayq, and autoplay each read their matching property once',
      () {
        final values = <String, Object?>{
          'timer': 1,
          'replayq': false,
          'autoplay': false,
        };
        final reads = <String>[];
        final config = _config(values, reads);
        final deckIds = <int>[];
        LibAnkiDeckConfig configForDeckId(int deckId) {
          deckIds.add(deckId);
          return config;
        }

        expect(
          cardShouldShowTimer(
            oDid: 8,
            did: 3,
            configForDeckId: configForDeckId,
          ),
          isTrue,
        );
        expect(
          cardReplayQuestionAudioOnAnswerSide(
            oDid: 8,
            did: 3,
            configForDeckId: configForDeckId,
          ),
          isFalse,
        );
        expect(
          cardAutoplay(oDid: 8, did: 3, configForDeckId: configForDeckId),
          isFalse,
        );
        expect(deckIds, [8, 8, 8]);
        expect(reads, [
          'getInt:timer',
          'getBoolean:replayq',
          'optBoolean:autoplay:true',
        ]);
      },
    );

    test('shouldShowTimer retains the config getter fallback and logging', () {
      final firstFailure = Exception('timer integer read failed');
      final reads = <String>[];
      final config = _config(
        const {},
        reads,
        getInt: (_, key) {
          reads.add('getInt:$key');
          if (key == 'timer') throw firstFailure;
          throw StateError('unexpected integer read');
        },
        getBoolean: (_, key) {
          reads.add('getBoolean:$key');
          return true;
        },
      );

      expect(
        cardShouldShowTimer(oDid: 0, did: 2, configForDeckId: (_) => config),
        isTrue,
      );
      expect(reads, ['getInt:timer', 'log:$firstFailure', 'getBoolean:timer']);
    });

    test('property failures pass through unchanged', () {
      final failure = FormatException('maxTaken unavailable');
      final config = _config(const {}, [], getInt: (_, _) => throw failure);

      expect(
        () => cardTimeLimit(oDid: 0, did: 1, configForDeckId: (_) => config),
        throwsA(same(failure)),
      );
    });
  });
}

LibAnkiDeckConfig _config(
  Map<String, Object?> values,
  List<String> calls, {
  int Function(Object, String)? getInt,
  bool Function(Object, String)? getBoolean,
}) {
  final object = Object();
  return LibAnkiDeckConfig(
    jsonObject: object,
    callbacks: LibAnkiDeckConfigJsonCallbacks(
      getInt:
          getInt ??
          (json, key) {
            expect(json, same(object));
            calls.add('getInt:$key');
            return values[key]! as int;
          },
      getLong: (_, _) => throw UnimplementedError(),
      getString: (_, _) => throw UnimplementedError(),
      getBoolean:
          getBoolean ??
          (json, key) {
            expect(json, same(object));
            calls.add('getBoolean:$key');
            return values[key]! as bool;
          },
      optBoolean: (json, key, defaultValue) {
        expect(json, same(object));
        calls.add('optBoolean:$key:$defaultValue');
        return values[key] as bool? ?? defaultValue;
      },
      optDouble: (_, _, defaultValue) => defaultValue,
      getDouble: (_, _) => throw UnimplementedError(),
      getJsonArray: (_, _) => throw UnimplementedError(),
      getJsonObject: (_, _) => throw UnimplementedError(),
      put: (_, _, _) => throw UnimplementedError(),
      remove: (_, _) => throw UnimplementedError(),
      logWarning: (failure) => calls.add('log:$failure'),
      parseJsonObjectString: (_) => throw UnimplementedError(),
      jsonObjectEquals: (_, _) => throw UnimplementedError(),
      jsonObjectHashCode: (_) => throw UnimplementedError(),
      jsonObjectToString: (_) => throw UnimplementedError(),
    ),
  );
}
