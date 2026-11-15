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
 * SPDX-FileCopyrightText: 2024 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Field.kt in AnkiDroid 2.25.3; no direct pinned test for
 * Field's property wrapper was found. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiField JSON properties', () {
    test('reads and writes each mutable property through its source key', () {
      final object = Object();
      final calls = <String>[];
      final values = <String, Object?>{
        'name': 'Front',
        'ord': 2,
        'sticky': true,
        'font': 'Arial',
        'size': 18,
      };
      final field = LibAnkiField(
        jsonObject: object,
        callbacks: _callbacks(
          getString: (json, key) {
            calls.add('getString:$key');
            expect(json, same(object));
            return values[key]! as String;
          },
          getInt: (json, key) {
            calls.add('getInt:$key');
            expect(json, same(object));
            return values[key]! as int;
          },
          getBoolean: (json, key) {
            calls.add('getBoolean:$key');
            expect(json, same(object));
            return values[key]! as bool;
          },
          put: (json, key, value) {
            calls.add('put:$key=$value');
            expect(json, same(object));
            values[key] = value;
          },
        ),
      );

      expect(field.name, 'Front');
      expect(field.ord, 2);
      expect(field.sticky, isTrue);
      expect(field.font, 'Arial');
      expect(field.fontSize, 18);
      expect(calls, [
        'getString:name',
        'getInt:ord',
        'getBoolean:sticky',
        'getString:font',
        'getInt:size',
      ]);

      calls.clear();
      field.name = 'Back';
      field.sticky = false;
      field.font = 'Serif';
      field.fontSize = 20;
      expect(calls, [
        'put:name=Back',
        'put:sticky=false',
        'put:font=Serif',
        'put:size=20',
      ]);
      expect(values, {
        'name': 'Back',
        'ord': 2,
        'sticky': false,
        'font': 'Serif',
        'size': 20,
      });
    });

    test('setOrd writes the integer or exact host null sentinel once', () {
      final object = Object();
      final nullSentinel = Object();
      final calls = <String>[];
      final received = <Object?>[];
      final field = LibAnkiField(
        jsonObject: object,
        callbacks: _callbacks(
          nullSentinel: nullSentinel,
          put: (json, key, value) {
            expect(json, same(object));
            calls.add('put:$key');
            received.add(value);
          },
        ),
      );

      field.setOrd(7);
      field.setOrd(null);
      expect(calls, ['put:ord', 'put:ord']);
      expect(received.first, 7);
      expect(received.last, same(nullSentinel));
    });

    test('property and setter callback failures propagate unchanged', () {
      final failure = StateError('JSON callback failed');
      final field = LibAnkiField(
        jsonObject: Object(),
        callbacks: _callbacks(
          getString: (_, _) => throw failure,
          put: (_, _, _) => throw failure,
        ),
      );

      expect(() => field.name, throwsA(same(failure)));
      expect(() => field.name = 'Front', throwsA(same(failure)));
    });
  });

  group('LibAnkiField image occlusion tag', () {
    test('delegates nullable getStringOrNull by the tag key once', () {
      final object = Object();
      final calls = <String>[];
      final field = LibAnkiField(
        jsonObject: object,
        callbacks: _callbacks(
          getStringOrNull: (json, key) {
            calls.add('getStringOrNull:$key');
            expect(json, same(object));
            return null;
          },
        ),
      );

      expect(field.imageOcclusionTag, isNull);
      expect(calls, ['getStringOrNull:tag']);
    });

    test('propagates getStringOrNull failures unchanged', () {
      final failure = FormatException('bad tag');
      final field = LibAnkiField(
        jsonObject: Object(),
        callbacks: _callbacks(getStringOrNull: (_, _) => throw failure),
      );

      expect(() => field.imageOcclusionTag, throwsA(same(failure)));
    });
  });

  group('LibAnkiField wrapper behavior', () {
    test('returns the host JSON string and propagates its failure', () {
      final object = Object();
      final calls = <Object>[];
      final field = LibAnkiField(
        jsonObject: object,
        callbacks: _callbacks(
          jsonObjectToString: (json) {
            calls.add(json);
            return '{"name":"host format"}';
          },
        ),
      );
      expect(field.toString(), '{"name":"host format"}');
      expect(calls, [same(object)]);

      final failure = StateError('toString failed');
      final failingField = LibAnkiField(
        jsonObject: object,
        callbacks: _callbacks(jsonObjectToString: (_) => throw failure),
      );
      expect(() => failingField.toString(), throwsA(same(failure)));
    });

    test(
      'preserves the data-class constructor, copy, component and value hooks',
      () {
        final firstObject = Object();
        final equalObject = Object();
        final otherObject = Object();
        final calls = <String>[];
        final callbacks = _callbacks(
          jsonObjectEquals: (left, right) {
            calls.add('equals');
            return identical(left, right) ||
                (identical(left, firstObject) && identical(right, equalObject));
          },
          jsonObjectHashCode: (json) {
            calls.add('hashCode');
            return identical(json, otherObject) ? 29 : 11;
          },
        );
        final field = LibAnkiField(
          jsonObject: firstObject,
          callbacks: callbacks,
        );
        final equalField = LibAnkiField(
          jsonObject: equalObject,
          callbacks: callbacks,
        );
        final differentField = LibAnkiField(
          jsonObject: otherObject,
          callbacks: callbacks,
        );

        expect(field.jsonObject, same(firstObject));
        expect(field.component1(), same(firstObject));
        expect(field.copy().jsonObject, same(firstObject));
        expect(
          field.copy(jsonObject: otherObject).jsonObject,
          same(otherObject),
        );
        final dynamic nullJsonObject = null;
        expect(
          () => field.copy(jsonObject: nullJsonObject),
          throwsA(isA<TypeError>()),
        );
        expect(field == field, isTrue);
        expect(field == equalField, isTrue);
        expect(field == differentField, isFalse);
        expect(field.hashCode, 11);
        expect(differentField.hashCode, 29);
        expect(calls, ['equals', 'equals', 'hashCode', 'hashCode']);
      },
    );
  });
}

LibAnkiFieldJsonCallbacks _callbacks({
  String Function(Object jsonObject, String key)? getString,
  int Function(Object jsonObject, String key)? getInt,
  bool Function(Object jsonObject, String key)? getBoolean,
  String? Function(Object jsonObject, String key)? getStringOrNull,
  void Function(Object jsonObject, String key, Object? value)? put,
  Object? nullSentinel,
  bool Function(Object left, Object right)? jsonObjectEquals,
  int Function(Object jsonObject)? jsonObjectHashCode,
  String Function(Object jsonObject)? jsonObjectToString,
}) => LibAnkiFieldJsonCallbacks(
  getString: getString ?? (_, key) => throw StateError('unused getString:$key'),
  getInt: getInt ?? (_, key) => throw StateError('unused getInt:$key'),
  getBoolean:
      getBoolean ?? (_, key) => throw StateError('unused getBoolean:$key'),
  getStringOrNull:
      getStringOrNull ??
      (_, key) => throw StateError('unused getStringOrNull:$key'),
  put: put ?? (_, key, _) => throw StateError('unused put:$key'),
  nullSentinel: nullSentinel ?? _NullSentinel(),
  jsonObjectEquals: jsonObjectEquals ?? identical,
  jsonObjectHashCode: jsonObjectHashCode ?? identityHashCode,
  jsonObjectToString:
      jsonObjectToString ?? (jsonObject) => jsonObject.toString(),
);

final class _NullSentinel {
  @override
  String toString() => 'NULL';
}
