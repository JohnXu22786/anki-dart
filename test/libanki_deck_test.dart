/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Deck.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiDeck constructors', () {
    test(
      'clones JSONObject once and parses JSON text once through the host',
      () {
        final source = Object();
        final clone = Object();
        final parsed = Object();
        final calls = <String>[];
        final callbacks = _callbacks(
          deepCloneJsonObject: (json) {
            calls.add('clone');
            expect(json, same(source));
            return clone;
          },
          parseJsonObjectString: (text) {
            calls.add('parse:$text');
            return parsed;
          },
        );

        final clonedDeck = LibAnkiDeck.fromJsonObject(
          jsonObject: source,
          callbacks: callbacks,
        );
        expect(clonedDeck.jsonObject, same(clone));
        expect(calls, ['clone']);

        calls.clear();
        final parsedDeck = LibAnkiDeck.fromJsonString(
          jsonString: '{"name":"Default"}',
          callbacks: callbacks,
        );
        expect(parsedDeck.jsonObject, same(parsed));
        expect(calls, ['parse:{"name":"Default"}']);
      },
    );

    test('host clone and parse failures propagate unchanged', () {
      final failure = FormatException('host rejected JSON');
      final callbacks = _callbacks(
        deepCloneJsonObject: (_) => throw failure,
        parseJsonObjectString: (_) => throw failure,
      );
      expect(
        () => LibAnkiDeck.fromJsonObject(
          jsonObject: Object(),
          callbacks: callbacks,
        ),
        throwsA(same(failure)),
      );
      expect(
        () => LibAnkiDeck.fromJsonString(jsonString: '{', callbacks: callbacks),
        throwsA(same(failure)),
      );
    });
  });

  group('LibAnkiDeck JSON properties', () {
    test('uses source getters, keys, defaults and setter call order', () {
      final object = Object();
      final calls = <String>[];
      final values = <String, Object?>{
        'dyn': 2,
        'name': 'Filtered',
        'collapsed': true,
        'browserCollapsed': false,
        'id': 1234567890123,
        'conf': 7,
        'desc': 'description',
        'md': true,
      };
      final deck = LibAnkiDeck(
        jsonObject: object,
        callbacks: _callbacks(
          getInt: (json, key) {
            expect(json, same(object));
            calls.add('getInt:$key');
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
          getLong: (json, key) {
            expect(json, same(object));
            calls.add('getLong:$key');
            return values[key]! as int;
          },
          optLong: (json, key) {
            expect(json, same(object));
            calls.add('optLong:$key');
            return values[key] as int? ?? 0;
          },
          optBoolean: (json, key, defaultValue) {
            expect(json, same(object));
            calls.add('optBoolean:$key:$defaultValue');
            return values[key] as bool? ?? defaultValue;
          },
          optString: (json, key, defaultValue) {
            expect(json, same(object));
            calls.add('optString:$key:$defaultValue');
            return values[key] as String? ?? defaultValue;
          },
          put: (json, key, value) {
            expect(json, same(object));
            calls.add('put:$key=$value');
            values[key] = value;
          },
        ),
      );

      expect(deck.isFiltered, isTrue);
      expect(deck.isNormal, isFalse);
      expect(deck.name, 'Filtered');
      expect(deck.collapsed, isTrue);
      expect(deck.browserCollapsed, isFalse);
      expect(deck.id, 1234567890123);
      expect(deck.conf, 7);
      expect(deck.description, 'description');
      expect(deck.descriptionAsMarkdown, isTrue);
      expect(calls, [
        'getInt:dyn',
        'getInt:dyn',
        'getString:name',
        'getBoolean:collapsed',
        'optBoolean:browserCollapsed:false',
        'getLong:id',
        'optLong:conf',
        'optString:desc:',
        'optBoolean:md:false',
      ]);

      calls.clear();
      deck.name = 'Normal';
      deck.collapsed = false;
      deck.browserCollapsed = true;
      deck.id = 9;
      deck.conf = 3;
      deck.description = 'new';
      deck.descriptionAsMarkdown = false;
      expect(calls, [
        'put:name=Normal',
        'put:collapsed=false',
        'put:browserCollapsed=true',
        'put:id=9',
        'put:conf=3',
        'put:desc=new',
        'put:md=false',
      ]);
      expect(values, {
        'dyn': 2,
        'name': 'Normal',
        'collapsed': false,
        'browserCollapsed': true,
        'id': 9,
        'conf': 3,
        'desc': 'new',
        'md': false,
      });
    });

    test(
      'uses false and empty defaults and normal classification from dyn zero',
      () {
        final calls = <String>[];
        final deck = LibAnkiDeck(
          jsonObject: Object(),
          callbacks: _callbacks(
            getInt: (_, key) {
              calls.add('getInt:$key');
              return 0;
            },
            optBoolean: (_, key, defaultValue) {
              calls.add('optBoolean:$key:$defaultValue');
              return defaultValue;
            },
            optString: (_, key, defaultValue) {
              calls.add('optString:$key:$defaultValue');
              return defaultValue;
            },
          ),
        );

        expect(deck.isFiltered, isFalse);
        expect(deck.isNormal, isTrue);
        expect(deck.browserCollapsed, isFalse);
        expect(deck.description, isEmpty);
        expect(deck.descriptionAsMarkdown, isFalse);
        expect(calls, [
          'getInt:dyn',
          'getInt:dyn',
          'optBoolean:browserCollapsed:false',
          'optString:desc:',
          'optBoolean:md:false',
        ]);
      },
    );

    test('property callback failures propagate unchanged', () {
      final failure = StateError('JSONObject failure');
      final deck = LibAnkiDeck(
        jsonObject: Object(),
        callbacks: _callbacks(
          getInt: (_, _) => throw failure,
          put: (_, _, _) => throw failure,
        ),
      );
      expect(() => deck.isFiltered, throwsA(same(failure)));
      expect(() => deck.name = 'Default', throwsA(same(failure)));
    });
  });

  group('LibAnkiDeck configuration', () {
    test(
      'conf reads optLong once and falls back to one for nonpositive values',
      () {
        final calls = <String>[];
        var value = 11;
        final deck = LibAnkiDeck(
          jsonObject: Object(),
          callbacks: _callbacks(
            optLong: (_, key) {
              calls.add('optLong:$key');
              return value;
            },
          ),
        );

        expect(deck.conf, 11);
        value = 0;
        expect(deck.conf, 1);
        value = -4;
        expect(deck.conf, 1);
        expect(calls, ['optLong:conf', 'optLong:conf', 'optLong:conf']);
      },
    );

    test('confOrNull returns positive values and catches Exception only', () {
      final object = Object();
      final calls = <String>[];
      var value = 12;
      Object? failure;
      final deck = LibAnkiDeck(
        jsonObject: object,
        callbacks: _callbacks(
          getLong: (json, key) {
            expect(json, same(object));
            calls.add('getLong:$key');
            if (failure != null) throw failure;
            return value;
          },
        ),
      );

      expect(deck.confOrNull(), 12);
      value = 0;
      expect(deck.confOrNull(), isNull);
      value = -5;
      expect(deck.confOrNull(), isNull);
      failure = FormatException('missing conf');
      expect(deck.confOrNull(), isNull);
      expect(calls, [
        'getLong:conf',
        'getLong:conf',
        'getLong:conf',
        'getLong:conf',
      ]);

      final errorDeck = LibAnkiDeck(
        jsonObject: object,
        callbacks: _callbacks(getLong: (_, _) => throw StateError('fatal')),
      );
      expect(errorDeck.confOrNull, throwsA(isA<StateError>()));
    });
  });
}

LibAnkiDeckJsonCallbacks _callbacks({
  int Function(Object jsonObject, String key)? getInt,
  String Function(Object jsonObject, String key)? getString,
  bool Function(Object jsonObject, String key)? getBoolean,
  int Function(Object jsonObject, String key)? getLong,
  int Function(Object jsonObject, String key)? optLong,
  bool Function(Object jsonObject, String key, bool defaultValue)? optBoolean,
  String Function(Object jsonObject, String key, String defaultValue)?
  optString,
  void Function(Object jsonObject, String key, Object? value)? put,
  Object Function(Object jsonObject)? deepCloneJsonObject,
  Object Function(String jsonString)? parseJsonObjectString,
}) => LibAnkiDeckJsonCallbacks(
  getInt: getInt ?? (_, _) => throw StateError('unused getInt'),
  getString: getString ?? (_, _) => throw StateError('unused getString'),
  getBoolean: getBoolean ?? (_, _) => throw StateError('unused getBoolean'),
  getLong: getLong ?? (_, _) => throw StateError('unused getLong'),
  optLong: optLong ?? (_, _) => throw StateError('unused optLong'),
  optBoolean: optBoolean ?? (_, _, _) => throw StateError('unused optBoolean'),
  optString: optString ?? (_, _, _) => throw StateError('unused optString'),
  put: put ?? (_, _, _) => throw StateError('unused put'),
  deepCloneJsonObject:
      deepCloneJsonObject ?? (_) => throw StateError('unused clone'),
  parseJsonObjectString:
      parseJsonObjectString ?? (_) => throw StateError('unused parse'),
);
