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
 * Source-derived from Fields.kt and CardTemplates.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('libanki field collections', () {
    test('keeps the backing array and names distinct from the renderer', () {
      final fieldArray = _JsonArray([]);
      final templateArray = _JsonArray([]);
      final fields = _fields(fieldArray);
      final templates = _cardTemplates(templateArray);

      expect(fields.jsonArray, same(fieldArray));
      expect(templates.jsonArray, same(templateArray));
      expect(fields, isA<LibAnkiFields<_JsonArray>>());
      expect(templates, isA<LibAnkiCardTemplates<_JsonArray>>());
      expect(LibAnkiCardTemplates, isNot(CardTemplate));
    });

    test('wraps objects lazily in source iteration order', () {
      final values = [Object(), Object()];
      final source = _JsonArray(values);
      final calls = <Object>[];
      final fields = _fields(source, onConstruct: calls.add);
      final templateCalls = <Object>[];
      final templates = _cardTemplates(
        _JsonArray(values),
        onConstruct: templateCalls.add,
      );

      final iterator = fields.iterator;
      expect(calls, isEmpty);
      expect(iterator.moveNext(), isTrue);
      expect(calls, [values[0]]);
      expect(iterator.current.jsonObject, same(values[0]));
      expect(iterator.moveNext(), isTrue);
      expect(calls, values);
      expect(iterator.current.jsonObject, same(values[1]));
      expect(iterator.moveNext(), isFalse);
      expect(calls, values);

      final templateIterator = templates.iterator;
      expect(templateCalls, isEmpty);
      expect(templateIterator.moveNext(), isTrue);
      expect(templateCalls, [values[0]]);
      expect(templateIterator.current.jsonObject, same(values[0]));
      expect(templateIterator.moveNext(), isTrue);
      expect(templateCalls, values);
      expect(templateIterator.current.jsonObject, same(values[1]));
    });

    test('delegates typed item constructors for both collection wrappers', () {
      final fieldObject = Object();
      final templateObject = Object();
      final field = _fields(_JsonArray([fieldObject]))[0];
      final template = _cardTemplates(_JsonArray([templateObject]))[0];

      expect(field, isA<LibAnkiField>());
      expect(field.jsonObject, same(fieldObject));
      expect(template, isA<LibAnkiCardTemplate>());
      expect(template.jsonObject, same(templateObject));
    });

    test(
      'delegates indexing, writes, size, and optional JSONContainer operations',
      () {
        final first = Object();
        final replacement = Object();
        final source = _JsonArray([first]);
        final calls = <String>[];
        final fields = _fields(source, calls: calls);

        expect(fields.length, 1);
        expect(fields.size, 1);
        expect(fields[0].jsonObject, same(first));
        fields[4] = _field(replacement);
        expect(source.lastPutIndex, 4);
        expect(source.lastPutValue, same(replacement));
        fields.append(_field(replacement));
        fields.remove(_field(replacement));
        expect(fields.index(_field(replacement)), 3);
        fields.insert(2, _field(replacement));
        expect(calls, [
          'get:0',
          'put:4',
          'append',
          'remove',
          'index',
          'insert:2',
        ]);
      },
    );
  });
}

LibAnkiFields<_JsonArray> _fields(
  _JsonArray source, {
  void Function(Object object)? onConstruct,
  List<String>? calls,
}) => LibAnkiFields<_JsonArray>(
  jsonArray: source,
  constructor: (object) {
    onConstruct?.call(object);
    return _field(object);
  },
  jsonObjectIterator: (array) => array.values.iterator,
  getJsonObject: (array, index) {
    calls?.add('get:$index');
    return array.values[index];
  },
  put: (array, index, object) {
    calls?.add('put:$index');
    array.lastPutIndex = index;
    array.lastPutValue = object;
  },
  length: (array) => array.values.length,
  append: (_, _) => calls?.add('append'),
  remove: (_, _) => calls?.add('remove'),
  index: (_, _) {
    calls?.add('index');
    return 3;
  },
  insert: (_, index, _) => calls?.add('insert:$index'),
);

LibAnkiCardTemplates<_JsonArray> _cardTemplates(
  _JsonArray source, {
  void Function(Object object)? onConstruct,
}) => LibAnkiCardTemplates<_JsonArray>(
  jsonArray: source,
  constructor: (object) {
    onConstruct?.call(object);
    return LibAnkiCardTemplate(
      jsonObject: object,
      callbacks: _cardTemplateCallbacks,
    );
  },
  jsonObjectIterator: (array) => array.values.iterator,
  getJsonObject: (array, index) => array.values[index],
  put: (_, _, _) {},
  length: (array) => array.values.length,
);

LibAnkiField _field(Object object) =>
    LibAnkiField(jsonObject: object, callbacks: _fieldCallbacks);

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

const _cardTemplateCallbacks = LibAnkiCardTemplateJsonCallbacks(
  getString: _unusedString,
  getInt: _unusedInt,
  put: _unusedPut,
  nullSentinel: Object(),
  deepCloneJsonObject: _identity,
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
Object _identity(Object object) => object;

final class _JsonArray {
  _JsonArray(this.values);

  final List<Object> values;
  int? lastPutIndex;
  Object? lastPutValue;
}
