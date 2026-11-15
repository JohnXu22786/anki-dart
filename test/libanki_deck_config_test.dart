/*
 * Copyright (c) 2020 David Allison <davidallisongithub@gmail.com>
 * Copyright (c) 2020 Arthur Milchior <Arthur@Milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <Arthur@Milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckConfig.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. The pinned DeckConfigTest.kt covers core property
 * behavior but not callback identity, timer fallback logging, or Kotlin data
 * class hooks.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiDeckConfig construction', () {
    test(
      'retains the supplied object and asks the host to parse text once',
      () {
        final source = Object();
        final parsed = Object();
        final calls = <String>[];
        final callbacks = _callbacks(
          parseJsonObjectString: (json) {
            calls.add('parse:$json');
            return parsed;
          },
        );

        final fromObject = LibAnkiDeckConfig(
          jsonObject: source,
          callbacks: callbacks,
        );
        expect(fromObject.jsonObject, same(source));
        expect(calls, isEmpty);

        final fromString = LibAnkiDeckConfig.fromJsonString(
          jsonString: '{"id":7}',
          callbacks: callbacks,
        );
        expect(fromString.jsonObject, same(parsed));
        expect(calls, ['parse:{"id":7}']);
      },
    );

    test(
      'uses the host JSONObject string and propagates conversion failure',
      () {
        final object = Object();
        final calls = <Object>[];
        final config = LibAnkiDeckConfig(
          jsonObject: object,
          callbacks: _callbacks(
            jsonObjectToString: (json) {
              calls.add(json);
              return '{host-json}';
            },
          ),
        );
        expect(config.toString(), '{host-json}');
        expect(calls, [same(object)]);

        final failure = FormatException('string conversion failed');
        final failingConfig = LibAnkiDeckConfig(
          jsonObject: object,
          callbacks: _callbacks(jsonObjectToString: (_) => throw failure),
        );
        expect(() => failingConfig.toString(), throwsA(same(failure)));
      },
    );

    test('parser and JSON callbacks propagate their original failures', () {
      final failure = FormatException('host JSON failure');
      final config = LibAnkiDeckConfig(
        jsonObject: Object(),
        callbacks: _callbacks(
          parseJsonObjectString: (_) => throw failure,
          getLong: (_, _) => throw failure,
        ),
      );

      expect(
        () => LibAnkiDeckConfig.fromJsonString(
          jsonString: '{',
          callbacks: config.callbacks,
        ),
        throwsA(same(failure)),
      );
      expect(() => config.conf, throwsA(same(failure)));
    });
  });

  group('LibAnkiDeckConfig JSON properties', () {
    test('uses source keys, typed getters, defaults, setters, and removal', () {
      final object = Object();
      final calls = <String>[];
      final values = <String, Object?>{
        'cong': 17,
        'id': 42,
        'name': 'Default',
        'waitForAudio': null,
        'stopTimerOnAnswer': true,
        'secondsToShowQuestion': null,
        'secondsToShowAnswer': 5.5,
        'maxTaken': 60,
        'autoplay': null,
        'replayq': false,
      };
      final config = LibAnkiDeckConfig(
        jsonObject: object,
        callbacks: _callbacks(
          getLong: (json, key) {
            expect(json, same(object));
            calls.add('getLong:$key');
            return values[key]! as int;
          },
          getString: (json, key) {
            expect(json, same(object));
            calls.add('getString:$key');
            return values[key]! as String;
          },
          getBoolean: (json, key) {
            expect(json, same(object));
            calls.add('getBoolean:$key');
            return values[key]! as bool;
          },
          optBoolean: (json, key, defaultValue) {
            expect(json, same(object));
            calls.add('optBoolean:$key:$defaultValue');
            return values[key] as bool? ?? defaultValue;
          },
          optDouble: (json, key, defaultValue) {
            expect(json, same(object));
            calls.add('optDouble:$key:$defaultValue');
            return values[key] as double? ?? defaultValue;
          },
          getInt: (json, key) {
            expect(json, same(object));
            calls.add('getInt:$key');
            return values[key]! as int;
          },
          put: (json, key, value) {
            expect(json, same(object));
            calls.add('put:$key=$value');
            values[key] = value;
          },
          remove: (json, key) {
            expect(json, same(object));
            calls.add('remove:$key');
            values.remove(key);
          },
        ),
      );

      expect(config.conf, 17);
      expect(config.id, 42);
      expect(config.name, 'Default');
      expect(config.waitForAudio, isTrue);
      expect(config.stopTimerOnAnswer, isTrue);
      expect(config.secondsToShowQuestion, 0.0);
      expect(config.secondsToShowAnswer, 5.5);
      expect(config.maxTaken, 60);
      expect(config.autoplay, isTrue);
      expect(config.replayq, isFalse);
      expect(calls, [
        'getLong:cong',
        'getLong:id',
        'getString:name',
        'optBoolean:waitForAudio:true',
        'getBoolean:stopTimerOnAnswer',
        'optDouble:secondsToShowQuestion:0.0',
        'optDouble:secondsToShowAnswer:0.0',
        'getInt:maxTaken',
        'optBoolean:autoplay:true',
        'getBoolean:replayq',
      ]);

      values['waitForAudio'] = false;
      values['autoplay'] = false;
      calls.clear();
      expect(config.waitForAudio, isFalse);
      expect(config.autoplay, isFalse);
      expect(calls, [
        'optBoolean:waitForAudio:true',
        'optBoolean:autoplay:true',
      ]);

      calls.clear();
      config.conf = 18;
      config.id = 43;
      config.name = 'Renamed';
      config.secondsToShowQuestion = 1.25;
      config.secondsToShowAnswer = 2.75;
      config.autoplay = false;
      config.replayq = true;
      config.removeAnswerAction();
      expect(calls, [
        'put:cong=18',
        'put:id=43',
        'put:name=Renamed',
        'put:secondsToShowQuestion=1.25',
        'put:secondsToShowAnswer=2.75',
        'put:autoplay=false',
        'put:replayq=true',
        'remove:answerAction',
      ]);
      expect(LibAnkiDeckConfig.QUESTION_ACTION, 'questionAction');
      expect(LibAnkiDeckConfig.ANSWER_ACTION, 'answerAction');
    });
  });

  group('LibAnkiDeckConfig timer', () {
    test('uses integer timer and falls back to boolean only on Exception', () {
      final object = Object();
      final calls = <String>[];
      final config = LibAnkiDeckConfig(
        jsonObject: object,
        callbacks: _callbacks(
          getInt: (json, key) {
            expect(json, same(object));
            calls.add('int:$key');
            return 0;
          },
          getBoolean: (json, key) {
            expect(json, same(object));
            calls.add('bool:$key');
            return true;
          },
          logWarning: (_) => calls.add('warn'),
        ),
      );
      expect(config.timer, isFalse);
      expect(calls, ['int:timer']);

      calls.clear();
      final intFailure = FormatException('not int');
      final fallbackConfig = LibAnkiDeckConfig(
        jsonObject: object,
        callbacks: _callbacks(
          getInt: (_, key) {
            calls.add('int:$key');
            throw intFailure;
          },
          getBoolean: (_, key) {
            calls.add('bool:$key');
            return false;
          },
          logWarning: (failure) {
            expect(failure, same(intFailure));
            calls.add('warn');
          },
        ),
      );
      expect(fallbackConfig.timer, isFalse);
      expect(calls, ['int:timer', 'warn', 'bool:timer']);
    });

    test(
      'logs both Exceptions and defaults true, but does not catch Error',
      () {
        final calls = <String>[];
        final intFailure = FormatException('not int');
        final boolFailure = FormatException('not bool');
        final config = LibAnkiDeckConfig(
          jsonObject: Object(),
          callbacks: _callbacks(
            getInt: (_, key) {
              calls.add('int:$key');
              throw intFailure;
            },
            getBoolean: (_, key) {
              calls.add('bool:$key');
              throw boolFailure;
            },
            logWarning: (failure) {
              calls.add(
                'warn:${identical(failure, intFailure) ? 'int' : 'bool'}',
              );
            },
          ),
        );
        expect(config.timer, isTrue);
        expect(calls, ['int:timer', 'warn:int', 'bool:timer', 'warn:bool']);

        final error = StateError('not an Exception');
        final errorConfig = LibAnkiDeckConfig(
          jsonObject: Object(),
          callbacks: _callbacks(getInt: (_, _) => throw error),
        );
        expect(() => errorConfig.timer, throwsA(same(error)));
      },
    );
  });

  group('LibAnkiDeckConfig nested JSON models', () {
    test('wraps each exact nested object on each read and maps its fields', () {
      final root = Object();
      final newObject = Object();
      final lapseObject = Object();
      final revObject = Object();
      final newDelays = Object();
      final lapseDelays = Object();
      final revDelays = Object();
      final calls = <String>[];
      final putKeys = <String>[];
      final config = LibAnkiDeckConfig(
        jsonObject: root,
        callbacks: _callbacks(
          getJsonObject: (json, key) {
            expect(json, same(root));
            calls.add('object:$key');
            return switch (key) {
              'new' => newObject,
              'lapse' => lapseObject,
              'rev' => revObject,
              _ => throw StateError('unexpected object key $key'),
            };
          },
          getJsonArray: (json, key) {
            expect(key, 'delays');
            if (identical(json, newObject)) return newDelays;
            if (identical(json, lapseObject)) return lapseDelays;
            if (identical(json, revObject)) return revDelays;
            throw StateError('unexpected JSONArray receiver');
          },
          getInt: (json, key) {
            if (identical(json, newObject)) {
              expect(key, 'perDay');
              return 20;
            }
            if (identical(json, lapseObject)) {
              expect(key, 'leechAction');
              return 3;
            }
            if (identical(json, revObject)) {
              expect(key, anyOf('perDay', 'hardFactor'));
              return key == 'perDay' ? 30 : 45;
            }
            throw StateError('unexpected JSONObject receiver');
          },
          getBoolean: (json, key) {
            expect(json, same(newObject));
            expect(key, 'bury');
            return true;
          },
          getDouble: (json, key) {
            expect(json, same(lapseObject));
            expect(key, 'mult');
            return 1.5;
          },
          put: (json, key, value) {
            final prefix = identical(json, newObject)
                ? 'new'
                : identical(json, lapseObject)
                ? 'lapse'
                : 'rev';
            putKeys.add('$prefix.$key');
            calls.add('put:$prefix.$key=$value');
          },
        ),
      );

      final newConfig = config.newConfig;
      expect(newConfig.jsonObject, same(newObject));
      expect(newConfig.perDay, 20);
      expect(newConfig.delays, same(newDelays));
      expect(newConfig.bury, isTrue);
      newConfig.perDay = 21;
      newConfig.delays = Object();
      newConfig.bury = false;

      final lapseConfig = config.lapseConfig;
      expect(lapseConfig.jsonObject, same(lapseObject));
      expect(lapseConfig.delays, same(lapseDelays));
      expect(lapseConfig.leechAction, 3);
      expect(lapseConfig.mult, 1.5);
      lapseConfig.delays = Object();
      lapseConfig.leechAction = 4;
      lapseConfig.mult = 2.0;

      final revConfig = config.revConfig;
      expect(revConfig.jsonObject, same(revObject));
      expect(revConfig.perDay, 30);
      expect(revConfig.delays, same(revDelays));
      expect(revConfig.hardFactor, 45);
      revConfig.perDay = 31;
      revConfig.delays = Object();
      revConfig.hardFactor = 46;

      expect(config.newConfig.jsonObject, same(newObject));
      expect(config.lapseConfig.jsonObject, same(lapseObject));
      expect(config.revConfig.jsonObject, same(revObject));
      expect(calls.take(1), ['object:new']);
      expect(calls.where((call) => call == 'object:new'), hasLength(2));
      expect(calls.where((call) => call == 'object:lapse'), hasLength(2));
      expect(calls.where((call) => call == 'object:rev'), hasLength(2));
      expect(calls.where((call) => call.startsWith('object:')).toList(), [
        'object:new',
        'object:lapse',
        'object:rev',
        'object:new',
        'object:lapse',
        'object:rev',
      ]);
      expect(
        calls,
        containsAll([
          'put:new.perDay=21',
          'put:new.delays=Instance of \'Object\'',
          'put:new.bury=false',
          'put:lapse.leechAction=4',
          'put:lapse.mult=2.0',
          'put:rev.perDay=31',
          'put:rev.hardFactor=46',
        ]),
      );
      expect(putKeys, [
        'new.perDay',
        'new.delays',
        'new.bury',
        'lapse.delays',
        'lapse.leechAction',
        'lapse.mult',
        'rev.perDay',
        'rev.delays',
        'rev.hardFactor',
      ]);
    });
  });

  group('LibAnkiDeckConfig data-class wrappers', () {
    test('component, copy, equality, and hash use only jsonObject', () {
      final first = Object();
      final equal = Object();
      final other = Object();
      final calls = <String>[];
      final callbacks = _callbacks(
        jsonObjectEquals: (left, right) {
          calls.add('equals');
          return identical(left, right) ||
              (identical(left, first) && identical(right, equal));
        },
        jsonObjectHashCode: (json) {
          calls.add('hash');
          return identical(json, other) ? 27 : 13;
        },
      );
      final config = LibAnkiDeckConfig(jsonObject: first, callbacks: callbacks);
      final equalConfig = LibAnkiDeckConfig(
        jsonObject: equal,
        callbacks: callbacks,
      );
      final otherConfig = LibAnkiDeckConfig(
        jsonObject: other,
        callbacks: callbacks,
      );

      expect(config.component1(), same(first));
      expect(config.copy().jsonObject, same(first));
      expect(config.copy(jsonObject: other).jsonObject, same(other));
      dynamic nullObject = null;
      expect(
        () => config.copy(jsonObject: nullObject),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => LibAnkiDeckConfig(jsonObject: nullObject, callbacks: callbacks),
        throwsA(isA<TypeError>()),
      );
      expect(config, config);
      expect(config == equalConfig, isTrue);
      expect(config == otherConfig, isFalse);
      expect(config.hashCode, 13);
      expect(otherConfig.hashCode, 27);
      expect(calls, ['equals', 'equals', 'hash', 'hash']);
    });

    test('nested wrappers use the same data-class value hooks', () {
      final json = Object();
      final callbacks = _callbacks(
        jsonObjectEquals: (left, right) => identical(left, right),
        jsonObjectHashCode: (_) => 51,
        jsonObjectToString: (_) => '{host}',
      );
      final wrappers = <JSONObjectHolder>[
        LibAnkiDeckConfigNew(jsonObject: json, callbacks: callbacks),
        LibAnkiDeckConfigLapse(jsonObject: json, callbacks: callbacks),
        LibAnkiDeckConfigRev(jsonObject: json, callbacks: callbacks),
      ];
      final equalWrappers = <JSONObjectHolder>[
        LibAnkiDeckConfigNew(jsonObject: json, callbacks: callbacks),
        LibAnkiDeckConfigLapse(jsonObject: json, callbacks: callbacks),
        LibAnkiDeckConfigRev(jsonObject: json, callbacks: callbacks),
      ];
      for (var i = 0; i < wrappers.length; i++) {
        final wrapper = wrappers[i];
        expect(wrapper.toString(), contains('jsonObject={host}'));
        expect(wrapper.hashCode, 51);
        expect(wrapper == wrapper, isTrue);
        expect(wrapper == equalWrappers[i], isTrue);
      }

      final dynamic newConfig = wrappers[0];
      final dynamic lapseConfig = wrappers[1];
      final dynamic revConfig = wrappers[2];
      expect(newConfig.component1(), same(json));
      expect(newConfig.copy().jsonObject, same(json));
      expect(
        newConfig.copy(jsonObject: Object()).jsonObject,
        isNot(same(json)),
      );
      expect(lapseConfig.component1(), same(json));
      expect(lapseConfig.copy().jsonObject, same(json));
      expect(
        lapseConfig.copy(jsonObject: Object()).jsonObject,
        isNot(same(json)),
      );
      expect(revConfig.component1(), same(json));
      expect(revConfig.copy().jsonObject, same(json));
      expect(
        revConfig.copy(jsonObject: Object()).jsonObject,
        isNot(same(json)),
      );
      dynamic nullObject = null;
      expect(
        () => newConfig.copy(jsonObject: nullObject),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => lapseConfig.copy(jsonObject: nullObject),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => revConfig.copy(jsonObject: nullObject),
        throwsA(isA<TypeError>()),
      );
      expect(
        () =>
            LibAnkiDeckConfigNew(jsonObject: nullObject, callbacks: callbacks),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => LibAnkiDeckConfigLapse(
          jsonObject: nullObject,
          callbacks: callbacks,
        ),
        throwsA(isA<TypeError>()),
      );
      expect(
        () =>
            LibAnkiDeckConfigRev(jsonObject: nullObject, callbacks: callbacks),
        throwsA(isA<TypeError>()),
      );
    });
  });
}

LibAnkiDeckConfigJsonCallbacks _callbacks({
  int Function(Object jsonObject, String key)? getInt,
  int Function(Object jsonObject, String key)? getLong,
  String Function(Object jsonObject, String key)? getString,
  bool Function(Object jsonObject, String key)? getBoolean,
  bool Function(Object jsonObject, String key, bool defaultValue)? optBoolean,
  double Function(Object jsonObject, String key, double defaultValue)?
  optDouble,
  double Function(Object jsonObject, String key)? getDouble,
  Object Function(Object jsonObject, String key)? getJsonArray,
  Object Function(Object jsonObject, String key)? getJsonObject,
  void Function(Object jsonObject, String key, Object? value)? put,
  void Function(Object jsonObject, String key)? remove,
  void Function(Exception failure)? logWarning,
  Object Function(String jsonString)? parseJsonObjectString,
  bool Function(Object left, Object right)? jsonObjectEquals,
  int Function(Object jsonObject)? jsonObjectHashCode,
  String Function(Object jsonObject)? jsonObjectToString,
}) => LibAnkiDeckConfigJsonCallbacks(
  getInt: getInt ?? (_, key) => throw StateError('unused getInt:$key'),
  getLong: getLong ?? (_, key) => throw StateError('unused getLong:$key'),
  getString: getString ?? (_, key) => throw StateError('unused getString:$key'),
  getBoolean:
      getBoolean ?? (_, key) => throw StateError('unused getBoolean:$key'),
  optBoolean:
      optBoolean ?? (_, key, _) => throw StateError('unused optBoolean:$key'),
  optDouble:
      optDouble ?? (_, key, _) => throw StateError('unused optDouble:$key'),
  getDouble: getDouble ?? (_, key) => throw StateError('unused getDouble:$key'),
  getJsonArray:
      getJsonArray ?? (_, key) => throw StateError('unused getJsonArray:$key'),
  getJsonObject:
      getJsonObject ??
      (_, key) => throw StateError('unused getJsonObject:$key'),
  put: put ?? (_, key, _) => throw StateError('unused put:$key'),
  remove: remove ?? (_, key) => throw StateError('unused remove:$key'),
  logWarning: logWarning ?? (_) {},
  parseJsonObjectString:
      parseJsonObjectString ?? (_) => throw StateError('unused parse'),
  jsonObjectEquals: jsonObjectEquals ?? identical,
  jsonObjectHashCode: jsonObjectHashCode ?? identityHashCode,
  jsonObjectToString:
      jsonObjectToString ?? (jsonObject) => jsonObject.toString(),
);
