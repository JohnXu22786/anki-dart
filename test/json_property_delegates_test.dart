/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONContainer.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('JSONObjectHolder JSON property delegates', () {
    test(
      'jsonBoolean selects get or opt by non-null fallback and puts value',
      () {
        final object = Object();
        final holder = _Holder(object);
        final calls = <String>[];
        final delegate = holder.jsonBoolean(
          key: 'enabled',
          getBoolean: (json, key) {
            calls.add('get:$key');
            expect(json, same(object));
            return true;
          },
          optBoolean: (json, key, fallback) {
            calls.add('opt:$key:$fallback');
            expect(json, same(object));
            return fallback;
          },
          put: (json, key, value) {
            calls.add('put:$key:$value');
            expect(json, same(object));
          },
        );

        expect(delegate.getValue(null, null), isTrue);
        expect(calls, ['get:enabled']);
        calls.clear();
        delegate.setValue(null, null, false);
        expect(calls, ['put:enabled:false']);
      },
    );

    test('jsonBoolean forwards non-null fallback and propagates failures', () {
      final holder = _Holder(Object());
      final calls = <String>[];
      final delegate = holder.jsonBoolean(
        key: 'enabled',
        fallback: false,
        getBoolean: (_, _) => throw StateError('unused get'),
        optBoolean: (_, key, fallback) {
          calls.add('$key:$fallback');
          return fallback;
        },
        put: (_, _, _) {},
      );
      expect(delegate.getValue(Object(), Object()), isFalse);
      expect(calls, ['enabled:false']);

      final failure = FormatException('host read failed');
      final throwing = holder.jsonBoolean(
        key: 'enabled',
        getBoolean: (_, _) => throw failure,
        optBoolean: (_, _, _) => true,
        put: (_, _, _) {},
      );
      expect(() => throwing.getValue(null, null), throwsA(same(failure)));
    });

    test('jsonInt selects get or opt by non-null fallback and puts value', () {
      final object = Object();
      final calls = <String>[];
      final holder = _Holder(object);
      final delegate = holder.jsonInt(
        key: 'count',
        getInt: (json, key) {
          calls.add('get:$key');
          expect(json, same(object));
          return 7;
        },
        optInt: (json, key, fallback) {
          calls.add('opt:$key:$fallback');
          expect(json, same(object));
          return fallback;
        },
        put: (json, key, value) {
          calls.add('put:$key:$value');
          expect(json, same(object));
        },
      );

      expect(delegate.getValue(null, null), 7);
      expect(calls, ['get:count']);
      calls.clear();
      delegate.setValue(null, null, 12);
      expect(calls, ['put:count:12']);

      calls.clear();
      final fallback = holder.jsonInt(
        key: 'count',
        fallback: 0,
        getInt: (_, _) => throw StateError('unused get'),
        optInt: (_, key, value) {
          calls.add('$key:$value');
          return value;
        },
        put: (_, _, _) {},
      );
      expect(fallback.getValue(null, null), 0);
      expect(calls, ['count:0']);
    });

    test('jsonLong selects get or opt by non-null fallback and puts value', () {
      final object = Object();
      final calls = <String>[];
      final holder = _Holder(object);
      final delegate = holder.jsonLong(
        key: 'count',
        getLong: (json, key) {
          calls.add('get:$key');
          expect(json, same(object));
          return 7;
        },
        optLong: (json, key, fallback) {
          calls.add('opt:$key:$fallback');
          expect(json, same(object));
          return fallback;
        },
        put: (json, key, value) {
          calls.add('put:$key:$value');
          expect(json, same(object));
        },
      );

      expect(delegate.getValue(null, null), 7);
      expect(calls, ['get:count']);
      calls.clear();
      delegate.setValue(null, null, 12);
      expect(calls, ['put:count:12']);

      calls.clear();
      final fallback = holder.jsonLong(
        key: 'count',
        fallback: 0,
        getLong: (_, _) => throw StateError('unused get'),
        optLong: (_, key, value) {
          calls.add('$key:$value');
          return value;
        },
        put: (_, _, _) {},
      );
      expect(fallback.getValue(null, null), 0);
      expect(calls, ['count:0']);
    });

    test(
      'jsonDouble selects get or opt by non-null fallback and puts value',
      () {
        final object = Object();
        final calls = <String>[];
        final holder = _Holder(object);
        final delegate = holder.jsonDouble(
          key: 'ratio',
          getDouble: (json, key) {
            calls.add('get:$key');
            expect(json, same(object));
            return 1.5;
          },
          optDouble: (json, key, fallback) {
            calls.add('opt:$key:$fallback');
            expect(json, same(object));
            return fallback;
          },
          put: (json, key, value) {
            calls.add('put:$key:$value');
            expect(json, same(object));
          },
        );

        expect(delegate.getValue(null, null), 1.5);
        expect(calls, ['get:ratio']);
        calls.clear();
        delegate.setValue(null, null, 2.5);
        expect(calls, ['put:ratio:2.5']);

        calls.clear();
        final fallback = holder.jsonDouble(
          key: 'ratio',
          fallback: 0,
          getDouble: (_, _) => throw StateError('unused get'),
          optDouble: (_, key, value) {
            calls.add('$key:$value');
            return value;
          },
          put: (_, _, _) {},
        );
        expect(fallback.getValue(null, null), 0);
        expect(calls, ['ratio:0.0']);
      },
    );

    test(
      'jsonString selects get or opt by non-null fallback and puts value',
      () {
        final object = Object();
        final calls = <String>[];
        final holder = _Holder(object);
        final delegate = holder.jsonString(
          key: 'label',
          getString: (json, key) {
            calls.add('get:$key');
            expect(json, same(object));
            return 'value';
          },
          optString: (json, key, fallback) {
            calls.add('opt:$key:$fallback');
            expect(json, same(object));
            return fallback;
          },
          put: (json, key, value) {
            calls.add('put:$key:$value');
            expect(json, same(object));
          },
        );

        expect(delegate.getValue(null, null), 'value');
        expect(calls, ['get:label']);
        calls.clear();
        delegate.setValue(null, null, 'next');
        expect(calls, ['put:label:next']);

        calls.clear();
        final fallback = holder.jsonString(
          key: 'label',
          fallback: '',
          getString: (_, _) => throw StateError('unused get'),
          optString: (_, key, value) {
            calls.add('$key:$value');
            return value;
          },
          put: (_, _, _) {},
        );
        expect(fallback.getValue(null, null), '');
        expect(calls, ['label:']);
      },
    );

    test('jsonArray forwards typed get and exact value to put', () {
      final object = Object();
      final array = <Object>[];
      final calls = <String>[];
      final holder = _Holder(object);
      final delegate = holder.jsonArray<List<Object>>(
        key: 'items',
        getJSONArray: (json, key) {
          calls.add('get:$key');
          expect(json, same(object));
          return array;
        },
        put: (json, key, value) {
          calls.add('put:$key');
          expect(json, same(object));
          expect(value, same(array));
        },
      );

      expect(delegate.getValue(null, null), same(array));
      expect(calls, ['get:items']);
      calls.clear();
      delegate.setValue(null, null, array);
      expect(calls, ['put:items']);
    });

    test(
      'each factory captures the holder object once and ignores metadata',
      () {
        final object = Object();
        final holder = _Holder(object);
        final delegate = holder.jsonBoolean(
          key: 'enabled',
          getBoolean: (json, _) {
            expect(json, same(object));
            return true;
          },
          optBoolean: (_, _, fallback) => fallback,
          put: (_, _, _) {},
        );

        expect(holder.readCount, 1);
        expect(delegate.getValue(Object(), Object()), isTrue);
        expect(holder.readCount, 1);
      },
    );
  });
}

final class _Holder implements JSONObjectHolder {
  _Holder(this._object);

  final Object _object;
  int readCount = 0;

  @override
  Object get jsonObject {
    readCount++;
    return _object;
  }
}
