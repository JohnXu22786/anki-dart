// Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from NotetypeJson.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJson name getters', () {
    test('fieldsNames reads fields and names once in source order', () {
      final notetype = Object();
      final firstField = Object();
      final secondField = Object();
      final thirdField = Object();
      final calls = <String>[];
      final getters = NotetypeJsonNameGetters<Object, Object>(
        notetypeJson: notetype,
        getFields: (json) {
          calls.add('fields');
          expect(json, same(notetype));
          return [firstField, secondField, thirdField];
        },
        getFieldName: (field) {
          calls.add(
            'name:${identical(field, firstField)
                ? 'first'
                : identical(field, secondField)
                ? 'second'
                : 'third'}',
          );
          return identical(field, firstField)
              ? 'Front'
              : identical(field, secondField)
              ? 'Back'
              : 'Extra';
        },
        getJSONArray: (_, _) => throw StateError('unused'),
        toStringList: (_, _) => throw StateError('unused'),
      );

      final result = getters.fieldsNames;

      expect(result, ['Front', 'Back', 'Extra']);
      expect(calls, ['fields', 'name:first', 'name:second', 'name:third']);
      expect(getters.fieldsNames, isNot(same(result)));
    });

    test('templatesNames forwards the exact array and returned list', () {
      final notetype = Object();
      final jsonArray = Object();
      final returnedList = ['Card 1', 'Card 2'];
      final calls = <String>[];
      final getters = NotetypeJsonNameGetters<Object, Object>(
        notetypeJson: notetype,
        getFields: (_) => throw StateError('unused'),
        getFieldName: (_) => throw StateError('unused'),
        getJSONArray: (json, key) {
          calls.add('getJSONArray:$key');
          expect(json, same(notetype));
          return jsonArray;
        },
        toStringList: (array, key) {
          calls.add('toStringList:$key');
          expect(array, same(jsonArray));
          return returnedList;
        },
      );

      final result = getters.templatesNames;

      expect(calls, ['getJSONArray:tmpls', 'toStringList:name']);
      expect(result, same(returnedList));
    });

    test(
      'host failures propagate unchanged and short-circuit later callbacks',
      () {
        final notetype = Object();
        final jsonArray = Object();
        final fieldFailure = StateError('field name failed');
        final jsonArrayFailure = StateError('tmpls lookup failed');
        final arrayFailure = FormatException('array failed');
        final fieldCalls = <String>[];
        final fieldGetters = NotetypeJsonNameGetters<Object, Object>(
          notetypeJson: notetype,
          getFields: (_) {
            fieldCalls.add('fields');
            return [Object(), Object()];
          },
          getFieldName: (_) {
            fieldCalls.add('name');
            if (fieldCalls.length == 2) throw fieldFailure;
            return 'first';
          },
          getJSONArray: (_, _) => throw StateError('unused'),
          toStringList: (_, _) => throw StateError('unused'),
        );
        expect(() => fieldGetters.fieldsNames, throwsA(same(fieldFailure)));
        expect(fieldCalls, ['fields', 'name']);

        final jsonArrayCalls = <String>[];
        final jsonArrayGetters = NotetypeJsonNameGetters<Object, Object>(
          notetypeJson: notetype,
          getFields: (_) => throw StateError('unused'),
          getFieldName: (_) => throw StateError('unused'),
          getJSONArray: (_, key) {
            jsonArrayCalls.add('getJSONArray:$key');
            throw jsonArrayFailure;
          },
          toStringList: (_, _) => throw StateError('must not run'),
        );
        expect(
          () => jsonArrayGetters.templatesNames,
          throwsA(same(jsonArrayFailure)),
        );
        expect(jsonArrayCalls, ['getJSONArray:tmpls']);

        final templateCalls = <String>[];
        final templateGetters = NotetypeJsonNameGetters<Object, Object>(
          notetypeJson: notetype,
          getFields: (_) => throw StateError('unused'),
          getFieldName: (_) => throw StateError('unused'),
          getJSONArray: (_, key) {
            templateCalls.add('getJSONArray:$key');
            return jsonArray;
          },
          toStringList: (_, key) {
            templateCalls.add('toStringList:$key');
            throw arrayFailure;
          },
        );
        expect(
          () => templateGetters.templatesNames,
          throwsA(same(arrayFailure)),
        );
        expect(templateCalls, ['getJSONArray:tmpls', 'toStringList:name']);
      },
    );
  });
}
