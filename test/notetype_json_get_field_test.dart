// Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
// SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from NotetypeJson.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonGetField', () {
    test('reads fields once and returns the exact indexed field wrapper', () {
      final notetypeJson = Object();
      final array = Object();
      final jsonObject = Object();
      final expectedField = LibAnkiField(
        jsonObject: jsonObject,
        callbacks: _fieldCallbacks,
      );
      final calls = <String>[];
      final fields = LibAnkiFields<Object>(
        jsonArray: array,
        constructor: (object) {
          calls.add('wrap');
          expect(object, same(jsonObject));
          return expectedField;
        },
        jsonObjectIterator: (_) => const <Object>[].iterator,
        getJsonObject: (fieldArray, index) {
          calls.add('index:$index');
          expect(fieldArray, same(array));
          return jsonObject;
        },
        put: (_, _, _) {},
        length: (_) => 0,
      );
      final getter = NotetypeJsonGetField<Object>(
        notetypeJson: notetypeJson,
        getFields: (object) {
          calls.add('fields');
          expect(object, same(notetypeJson));
          return fields;
        },
      );

      final actualField = getter.getField(7);

      expect(actualField, same(expectedField));
      expect(calls, ['fields', 'index:7', 'wrap']);
    });

    test('propagates the exact host indexing failure', () {
      final failure = RangeError.index(4, const <Object>[]);
      final getter = NotetypeJsonGetField<Object>(
        notetypeJson: Object(),
        getFields: (_) => LibAnkiFields<Object>(
          jsonArray: Object(),
          constructor: (_) => throw StateError('unused'),
          jsonObjectIterator: (_) => const <Object>[].iterator,
          getJsonObject: (_, _) => throw failure,
          put: (_, _, _) {},
          length: (_) => 0,
        ),
      );

      expect(() => getter.getField(4), throwsA(same(failure)));
    });
  });
}

const _fieldCallbacks = LibAnkiFieldJsonCallbacks(
  getString: _unusedString,
  getInt: _unusedInt,
  getBoolean: _unusedBool,
  getStringOrNull: _unusedNullableString,
  put: _unusedPut,
  nullSentinel: Object(),
  jsonObjectEquals: _unusedEquals,
  jsonObjectHashCode: _unusedHash,
  jsonObjectToString: _unusedToString,
);

String _unusedString(Object _, String __) => '';
int _unusedInt(Object _, String __) => 0;
bool _unusedBool(Object _, String __) => false;
String? _unusedNullableString(Object _, String __) => null;
void _unusedPut(Object _, String __, Object? ___) {}
bool _unusedEquals(Object _, Object __) => false;
int _unusedHash(Object _) => 0;
String _unusedToString(Object _) => '';
