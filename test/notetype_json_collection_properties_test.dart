// Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
// SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from NotetypeJson.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonCollectionProperties', () {
    test('getters read each source key once and wrap the exact host array', () {
      final json = Object();
      final fieldsArray = Object();
      final templatesArray = Object();
      final calls = <String>[];
      final properties = _properties(
        json,
        getJSONArray: (object, key) {
          calls.add('getJSONArray:$key');
          expect(object, same(json));
          return key == 'flds' ? fieldsArray : templatesArray;
        },
        fieldsFromJsonArray: (array) {
          calls.add('wrapFields');
          expect(array, same(fieldsArray));
          return _fields(array);
        },
        templatesFromJsonArray: (array) {
          calls.add('wrapTemplates');
          expect(array, same(templatesArray));
          return _templates(array);
        },
      );

      final fields = properties.fields;
      expect(fields, isA<LibAnkiFields<Object>>());
      expect(fields.jsonArray, same(fieldsArray));
      expect(calls, ['getJSONArray:flds', 'wrapFields']);

      calls.clear();
      final templates = properties.templates;
      expect(templates, isA<LibAnkiCardTemplates<Object>>());
      expect(templates.jsonArray, same(templatesArray));
      expect(calls, ['getJSONArray:tmpls', 'wrapTemplates']);
    });

    test('setters put each exact backing array once under its source key', () {
      final json = Object();
      final fieldsArray = Object();
      final templatesArray = Object();
      final calls = <String>[];
      final properties = _properties(
        json,
        getJSONArray: (_, _) => throw StateError('unused'),
        fieldsFromJsonArray: _fields,
        templatesFromJsonArray: _templates,
        put: (object, key, value) {
          calls.add('put:$key');
          expect(object, same(json));
          expect(value, same(key == 'flds' ? fieldsArray : templatesArray));
        },
      );

      properties.fields = _fields(fieldsArray);
      expect(calls, ['put:flds']);

      calls.clear();
      properties.templates = _templates(templatesArray);
      expect(calls, ['put:tmpls']);
    });

    test('host getJSONArray and put failures propagate unchanged', () {
      final json = Object();
      final getFailure = StateError('getJSONArray failed');
      final getter = _properties(
        json,
        getJSONArray: (_, _) => throw getFailure,
        fieldsFromJsonArray: _fields,
        templatesFromJsonArray: _templates,
      );
      expect(() => getter.fields, throwsA(same(getFailure)));
      expect(() => getter.templates, throwsA(same(getFailure)));

      final putFailure = StateError('put failed');
      final setter = _properties(
        json,
        getJSONArray: (_, _) => throw StateError('unused'),
        fieldsFromJsonArray: _fields,
        templatesFromJsonArray: _templates,
        put: (_, _, _) => throw putFailure,
      );
      expect(
        () => setter.fields = _fields(Object()),
        throwsA(same(putFailure)),
      );
      expect(
        () => setter.templates = _templates(Object()),
        throwsA(same(putFailure)),
      );
    });
  });
}

NotetypeJsonCollectionProperties<Object, Object> _properties(
  Object json, {
  required Object Function(Object jsonObject, String key) getJSONArray,
  required LibAnkiFields<Object> Function(Object array) fieldsFromJsonArray,
  required LibAnkiCardTemplates<Object> Function(Object array)
  templatesFromJsonArray,
  void Function(Object jsonObject, String key, Object? value)? put,
}) => NotetypeJsonCollectionProperties<Object, Object>(
  jsonObject: json,
  getJSONArray: getJSONArray,
  fieldsFromJsonArray: fieldsFromJsonArray,
  templatesFromJsonArray: templatesFromJsonArray,
  put: put ?? (_, _, _) => throw StateError('unused'),
);

LibAnkiFields<Object> _fields(Object array) => LibAnkiFields<Object>(
  jsonArray: array,
  constructor: (_) => throw StateError('unused'),
  jsonObjectIterator: (_) => const <Object>[].iterator,
  getJsonObject: (_, _) => throw StateError('unused'),
  put: (_, _, _) => throw StateError('unused'),
  length: (_) => 0,
);

LibAnkiCardTemplates<Object> _templates(Object array) =>
    LibAnkiCardTemplates<Object>(
      jsonArray: array,
      constructor: (_) => throw StateError('unused'),
      jsonObjectIterator: (_) => const <Object>[].iterator,
      getJsonObject: (_, _) => throw StateError('unused'),
      put: (_, _, _) => throw StateError('unused'),
      length: (_) => 0,
    );
