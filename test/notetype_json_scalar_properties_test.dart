// Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from NotetypeJson.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonScalarProperties', () {
    test('string properties read and write their source keys once', () {
      final json = Object();
      final calls = <String>[];
      final properties = NotetypeJsonScalarProperties<Object, Object>(
        jsonObject: json,
        originalStockKindUnknownValue: -1,
        getString: (object, key) {
          calls.add('getString:$key');
          expect(object, same(json));
          return 'value:$key';
        },
        getLong: (_, _) => throw StateError('unused'),
        getInt: (_, _) => throw StateError('unused'),
        optInt: (_, _, _) => throw StateError('unused'),
        optBoolean: (_, _, _) => throw StateError('unused'),
        getJSONArray: (_, _) => throw StateError('unused'),
        put: (object, key, value) {
          calls.add('put:$key:$value');
          expect(object, same(json));
        },
      );

      expect(properties.name, 'value:name');
      expect(calls, ['getString:name']);
      calls.clear();
      expect(properties.css, 'value:css');
      expect(calls, ['getString:css']);
      calls.clear();
      expect(properties.latexPre, 'value:latexPre');
      expect(calls, ['getString:latexPre']);
      calls.clear();
      expect(properties.latexPost, 'value:latexPost');
      expect(calls, ['getString:latexPost']);

      calls.clear();
      properties.name = 'Name';
      properties.css = 'CSS';
      properties.latexPre = 'pre';
      properties.latexPost = 'post';
      expect(calls, [
        'put:name:Name',
        'put:css:CSS',
        'put:latexPre:pre',
        'put:latexPost:post',
      ]);
    });

    test('Long and Int properties use typed reads and matching writes', () {
      final json = Object();
      final calls = <String>[];
      final properties = NotetypeJsonScalarProperties<Object, Object>(
        jsonObject: json,
        originalStockKindUnknownValue: -1,
        getString: (_, _) => throw StateError('unused'),
        getLong: (object, key) {
          calls.add('getLong:$key');
          expect(object, same(json));
          return key == 'id' ? 42 : 99;
        },
        getInt: (object, key) {
          calls.add('getInt:$key');
          expect(object, same(json));
          return key == 'sortf' ? 2 : -1;
        },
        optInt: (_, _, _) => throw StateError('unused'),
        optBoolean: (_, _, _) => throw StateError('unused'),
        getJSONArray: (_, _) => throw StateError('unused'),
        put: (object, key, value) {
          calls.add('put:$key:$value');
          expect(object, same(json));
        },
      );

      expect(properties.id, 42);
      expect(calls, ['getLong:id']);
      calls.clear();
      expect(properties.mod, 99);
      expect(calls, ['getLong:mod']);
      calls.clear();
      expect(properties.sortf, 2);
      expect(calls, ['getInt:sortf']);
      calls.clear();
      expect(properties.usn, -1);
      expect(calls, ['getInt:usn']);

      calls.clear();
      properties.id = 42;
      properties.mod = 99;
      properties.sortf = 2;
      properties.usn = -1;
      expect(calls, ['put:id:42', 'put:mod:99', 'put:sortf:2', 'put:usn:-1']);
    });

    test('originalStockKind forwards host unknown fallback to optInt', () {
      final json = Object();
      final calls = <String>[];
      final properties = NotetypeJsonScalarProperties<Object, Object>(
        jsonObject: json,
        originalStockKindUnknownValue: 73,
        getString: (_, _) => throw StateError('unused'),
        getLong: (_, _) => throw StateError('unused'),
        getInt: (_, _) => throw StateError('unused'),
        optInt: (object, key, fallback) {
          calls.add('optInt:$key:$fallback');
          expect(object, same(json));
          return fallback;
        },
        optBoolean: (_, _, _) => throw StateError('unused'),
        getJSONArray: (_, _) => throw StateError('unused'),
        put: (_, _, _) => throw StateError('unused'),
      );

      expect(properties.originalStockKind, 73);
      expect(calls, ['optInt:originalStockKind:73']);
    });

    test('type maps known and unknown codes and writes the exact code', () {
      final json = Object();
      final calls = <String>[];
      var code = 0;
      final properties = NotetypeJsonScalarProperties<Object, Object>(
        jsonObject: json,
        originalStockKindUnknownValue: -1,
        getString: (_, _) => throw StateError('unused'),
        getLong: (_, _) => throw StateError('unused'),
        getInt: (object, key) {
          calls.add('getInt:$key');
          expect(object, same(json));
          return code;
        },
        optInt: (_, _, _) => throw StateError('unused'),
        optBoolean: (_, _, _) => throw StateError('unused'),
        getJSONArray: (_, _) => throw StateError('unused'),
        put: (object, key, value) {
          calls.add('put:$key:$value');
          expect(object, same(json));
        },
      );

      expect(properties.type, LibAnkiNoteTypeKind.std);
      expect(calls, ['getInt:type']);
      calls.clear();
      code = 1;
      expect(properties.type, LibAnkiNoteTypeKind.cloze);
      expect(calls, ['getInt:type']);
      calls.clear();
      code = 27;
      final unknown = properties.type;
      expect(unknown, isA<LibAnkiNoteTypeKindUnknown>());
      expect(unknown.code, 27);
      expect(calls, ['getInt:type']);

      calls.clear();
      properties.type = LibAnkiNoteTypeKindUnknown(43);
      expect(calls, ['put:type:43']);
    });

    test('latexsvg always requests optBoolean with false fallback', () {
      final json = Object();
      final calls = <String>[];
      final properties = NotetypeJsonScalarProperties<Object, Object>(
        jsonObject: json,
        originalStockKindUnknownValue: -1,
        getString: (_, _) => throw StateError('unused'),
        getLong: (_, _) => throw StateError('unused'),
        getInt: (_, _) => throw StateError('unused'),
        optInt: (_, _, _) => throw StateError('unused'),
        optBoolean: (object, key, fallback) {
          calls.add('optBoolean:$key:$fallback');
          expect(object, same(json));
          return fallback;
        },
        getJSONArray: (_, _) => throw StateError('unused'),
        put: (_, _, _) => throw StateError('latexsvg is read-only'),
      );

      expect(properties.latexsvg, isFalse);
      expect(calls, ['optBoolean:latexsvg:false']);
    });

    test('deprecated req reads and writes the exact host array', () {
      final json = Object();
      final sourceArray = Object();
      final replacementArray = Object();
      final calls = <String>[];
      final properties = NotetypeJsonScalarProperties<Object, Object>(
        jsonObject: json,
        originalStockKindUnknownValue: -1,
        getString: (_, _) => throw StateError('unused'),
        getLong: (_, _) => throw StateError('unused'),
        getInt: (_, _) => throw StateError('unused'),
        optInt: (_, _, _) => throw StateError('unused'),
        optBoolean: (_, _, _) => throw StateError('unused'),
        getJSONArray: (object, key) {
          calls.add('getJSONArray:$key');
          expect(object, same(json));
          return sourceArray;
        },
        put: (object, key, value) {
          calls.add('put:$key');
          expect(object, same(json));
          expect(value, same(replacementArray));
        },
      );

      expect(properties.req, same(sourceArray));
      expect(calls, ['getJSONArray:req']);
      calls.clear();
      properties.req = replacementArray;
      expect(calls, ['put:req']);
    });

    test('host callback failures propagate unchanged', () {
      final json = Object();
      final getStringFailure = StateError('getString failed');
      final getStringProperties = _properties(
        json,
        getString: (_, _) => throw getStringFailure,
      );
      expect(() => getStringProperties.name, throwsA(same(getStringFailure)));

      final getLongFailure = StateError('getLong failed');
      final getLongProperties = _properties(
        json,
        getLong: (_, _) => throw getLongFailure,
      );
      expect(() => getLongProperties.id, throwsA(same(getLongFailure)));

      final getIntFailure = StateError('getInt failed');
      final getIntProperties = _properties(
        json,
        getInt: (_, _) => throw getIntFailure,
      );
      expect(() => getIntProperties.sortf, throwsA(same(getIntFailure)));
      expect(() => getIntProperties.type, throwsA(same(getIntFailure)));

      final optIntFailure = StateError('optInt failed');
      final optIntProperties = _properties(
        json,
        optInt: (_, _, _) => throw optIntFailure,
      );
      expect(
        () => optIntProperties.originalStockKind,
        throwsA(same(optIntFailure)),
      );

      final optBooleanFailure = StateError('optBoolean failed');
      final optBooleanProperties = _properties(
        json,
        optBoolean: (_, _, _) => throw optBooleanFailure,
      );
      expect(
        () => optBooleanProperties.latexsvg,
        throwsA(same(optBooleanFailure)),
      );

      final getArrayFailure = StateError('getJSONArray failed');
      final getArrayProperties = _properties(
        json,
        getJSONArray: (_, _) => throw getArrayFailure,
      );
      expect(() => getArrayProperties.req, throwsA(same(getArrayFailure)));

      final putFailure = StateError('put failed');
      final putProperties = _properties(
        json,
        put: (_, _, _) => throw putFailure,
      );
      expect(() => putProperties.name = 'name', throwsA(same(putFailure)));
      expect(
        () => putProperties.type = LibAnkiNoteTypeKind.cloze,
        throwsA(same(putFailure)),
      );
      expect(() => putProperties.req = Object(), throwsA(same(putFailure)));
    });
  });
}

NotetypeJsonScalarProperties<Object, Object> _properties(
  Object json, {
  String Function(Object, String)? getString,
  int Function(Object, String)? getLong,
  int Function(Object, String)? getInt,
  int Function(Object, String, int)? optInt,
  bool Function(Object, String, bool)? optBoolean,
  Object Function(Object, String)? getJSONArray,
  void Function(Object, String, Object?)? put,
}) => NotetypeJsonScalarProperties<Object, Object>(
  jsonObject: json,
  originalStockKindUnknownValue: -1,
  getString: getString ?? (_, _) => '',
  getLong: getLong ?? (_, _) => 0,
  getInt: getInt ?? (_, _) => 0,
  optInt: optInt ?? (_, _, fallback) => fallback,
  optBoolean: optBoolean ?? (_, _, fallback) => fallback,
  getJSONArray: getJSONArray ?? (_, _) => Object(),
  put: put ?? (_, _, _) {},
);
