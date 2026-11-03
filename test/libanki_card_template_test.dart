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
 * Source-derived from CardTemplate.kt in AnkiDroid 2.25.3; no direct pinned
 * test for the libanki JSON model was found. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiCardTemplate JSON properties', () {
    test('reads and writes each mutable property through its source key', () {
      final object = Object();
      final calls = <String>[];
      final values = <String, Object?>{
        'name': 'Card 1',
        'ord': 3,
        'qfmt': '{{Front}}',
        'afmt': '{{FrontSide}}{{Back}}',
        'bqfmt': '{{Front}}',
        'bafmt': '{{Back}}',
      };
      final template = LibAnkiCardTemplate(
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
          put: (json, key, value) {
            calls.add('put:$key=$value');
            expect(json, same(object));
            values[key] = value;
          },
        ),
      );

      expect(template.name, 'Card 1');
      expect(template.ord, 3);
      expect(template.qfmt, '{{Front}}');
      expect(template.afmt, '{{FrontSide}}{{Back}}');
      expect(template.bqfmt, '{{Front}}');
      expect(template.bafmt, '{{Back}}');
      expect(calls, [
        'getString:name',
        'getInt:ord',
        'getString:qfmt',
        'getString:afmt',
        'getString:bqfmt',
        'getString:bafmt',
      ]);

      calls.clear();
      template.name = 'Back';
      template.qfmt = '{{FrontSide}}';
      template.afmt = '{{Back}}';
      template.bqfmt = 'browser front';
      template.bafmt = 'browser back';
      expect(calls, [
        'put:name=Back',
        'put:qfmt={{FrontSide}}',
        'put:afmt={{Back}}',
        'put:bqfmt=browser front',
        'put:bafmt=browser back',
      ]);
      expect(values, {
        'name': 'Back',
        'ord': 3,
        'qfmt': '{{FrontSide}}',
        'afmt': '{{Back}}',
        'bqfmt': 'browser front',
        'bafmt': 'browser back',
      });
    });

    test('setOrd writes the integer or exact host null sentinel once', () {
      final object = Object();
      final nullSentinel = Object();
      final calls = <String>[];
      final received = <Object?>[];
      final template = LibAnkiCardTemplate(
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

      template.setOrd(7);
      template.setOrd(null);
      expect(calls, ['put:ord', 'put:ord']);
      expect(received.first, 7);
      expect(received.last, same(nullSentinel));
    });

    test('property callback failures propagate unchanged', () {
      final failure = StateError('JSON callback failed');
      final template = LibAnkiCardTemplate(
        jsonObject: Object(),
        callbacks: _callbacks(
          getString: (_, _) => throw failure,
          getInt: (_, _) => throw failure,
          put: (_, _, _) => throw failure,
        ),
      );

      expect(() => template.name, throwsA(same(failure)));
      expect(() => template.ord, throwsA(same(failure)));
      expect(() => template.qfmt = 'x', throwsA(same(failure)));
      expect(() => template.setOrd(null), throwsA(same(failure)));
    });
  });

  group('LibAnkiCardTemplate wrapper behavior', () {
    test('deepClone reads and clones the exact JSON object once', () {
      final source = Object();
      final clone = Object();
      final calls = <String>[];
      final template = LibAnkiCardTemplate(
        jsonObject: source,
        callbacks: _callbacks(
          deepCloneJsonObject: (json) {
            calls.add('clone');
            expect(json, same(source));
            return clone;
          },
        ),
      );

      final result = template.deepClone();
      expect(calls, ['clone']);
      expect(result, isA<LibAnkiCardTemplate>());
      expect(result, isNot(isA<CardTemplate>()));
      expect(result.jsonObject, same(clone));
      expect(identical(result.callbacks, template.callbacks), isTrue);
    });

    test('deepClone propagates a clone failure unchanged', () {
      final source = Object();
      final cloneFailure = StateError('clone failed');
      final cloneCalls = <String>[];
      final cloneFailureTemplate = LibAnkiCardTemplate(
        jsonObject: source,
        callbacks: _callbacks(
          deepCloneJsonObject: (_) {
            cloneCalls.add('clone');
            throw cloneFailure;
          },
        ),
      );
      expect(cloneFailureTemplate.deepClone, throwsA(same(cloneFailure)));
      expect(cloneCalls, ['clone']);
    });

    test('toString returns the exact host JSON string and failure', () {
      final object = Object();
      final calls = <Object>[];
      final template = LibAnkiCardTemplate(
        jsonObject: object,
        callbacks: _callbacks(
          jsonObjectToString: (json) {
            calls.add(json);
            return '{"name":"host format"}';
          },
        ),
      );
      expect(template.toString(), '{"name":"host format"}');
      expect(calls, [same(object)]);

      final failure = StateError('toString failed');
      final failingTemplate = LibAnkiCardTemplate(
        jsonObject: object,
        callbacks: _callbacks(jsonObjectToString: (_) => throw failure),
      );
      expect(() => failingTemplate.toString(), throwsA(same(failure)));
    });

    test('data-class operations use JSON equality and hash callbacks only', () {
      final firstObject = Object();
      final equalObject = Object();
      final otherObject = Object();
      final calls = <String>[];
      final firstCallbacks = _callbacks(
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
      final otherCallbacks = _callbacks(
        jsonObjectEquals: (_, _) {
          calls.add('otherEquals');
          return false;
        },
        jsonObjectHashCode: (_) {
          calls.add('otherHashCode');
          return -1;
        },
      );
      final template = LibAnkiCardTemplate(
        jsonObject: firstObject,
        callbacks: firstCallbacks,
      );
      final equalTemplate = LibAnkiCardTemplate(
        jsonObject: equalObject,
        callbacks: otherCallbacks,
      );
      final differentTemplate = LibAnkiCardTemplate(
        jsonObject: otherObject,
        callbacks: firstCallbacks,
      );

      expect(template.jsonObject, same(firstObject));
      expect(template.component1(), same(firstObject));
      expect(template.copy().jsonObject, same(firstObject));
      expect(identical(template.copy().callbacks, firstCallbacks), isTrue);
      expect(
        template.copy(jsonObject: otherObject).jsonObject,
        same(otherObject),
      );
      final dynamic nullJsonObject = null;
      expect(
        () => template.copy(jsonObject: nullJsonObject),
        throwsA(isA<TypeError>()),
      );
      expect(template == template, isTrue);
      expect(template == equalTemplate, isTrue);
      expect(template == differentTemplate, isFalse);
      expect(template.hashCode, 11);
      expect(differentTemplate.hashCode, 29);
      expect(calls, ['equals', 'equals', 'hashCode', 'hashCode']);
    });

    test('equality and hash failures propagate unchanged', () {
      final equalityFailure = StateError('equals failed');
      final hashFailure = StateError('hashCode failed');
      final callbacks = _callbacks(
        jsonObjectEquals: (_, _) => throw equalityFailure,
        jsonObjectHashCode: (_) => throw hashFailure,
      );
      final template = LibAnkiCardTemplate(
        jsonObject: Object(),
        callbacks: callbacks,
      );
      final otherTemplate = LibAnkiCardTemplate(
        jsonObject: Object(),
        callbacks: callbacks,
      );

      expect(() => template == otherTemplate, throwsA(same(equalityFailure)));
      expect(() => template.hashCode, throwsA(same(hashFailure)));
    });
  });

  test('the libanki JSON type is distinct from rendered CardTemplate', () {
    final jsonTemplate = LibAnkiCardTemplate(
      jsonObject: Object(),
      callbacks: _callbacks(),
    );
    final renderedTemplate = CardTemplate(
      'pre::style::style::script::script::class::class::content::content',
    );

    expect(jsonTemplate, isA<LibAnkiCardTemplate>());
    expect(jsonTemplate, isNot(isA<CardTemplate>()));
    expect(renderedTemplate, isA<CardTemplate>());
    expect(renderedTemplate, isNot(isA<LibAnkiCardTemplate>()));
  });
}

LibAnkiCardTemplateJsonCallbacks _callbacks({
  String Function(Object jsonObject, String key)? getString,
  int Function(Object jsonObject, String key)? getInt,
  void Function(Object jsonObject, String key, Object? value)? put,
  Object? nullSentinel,
  Object Function(Object jsonObject)? deepCloneJsonObject,
  bool Function(Object left, Object right)? jsonObjectEquals,
  int Function(Object jsonObject)? jsonObjectHashCode,
  String Function(Object jsonObject)? jsonObjectToString,
}) => LibAnkiCardTemplateJsonCallbacks(
  getString: getString ?? (_, key) => throw StateError('unused getString:$key'),
  getInt: getInt ?? (_, key) => throw StateError('unused getInt:$key'),
  put: put ?? (_, key, _) => throw StateError('unused put:$key'),
  nullSentinel: nullSentinel ?? Object(),
  deepCloneJsonObject:
      deepCloneJsonObject ?? (_) => throw StateError('unused clone'),
  jsonObjectEquals: jsonObjectEquals ?? identical,
  jsonObjectHashCode: jsonObjectHashCode ?? identityHashCode,
  jsonObjectToString: jsonObjectToString ?? (json) => json.toString(),
);
