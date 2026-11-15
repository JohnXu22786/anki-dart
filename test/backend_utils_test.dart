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
 * Source-derived from BackendUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:convert';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BackendUtilsHostAdapter', () {
    test('parses bytes through one exact UTF-8 read before JSONObject', () {
      final calls = <String>[];
      final bytes = _ByteString([0xc3, 0xa9]);
      final object = _JsonObject('host object');
      final array = _JsonArray('host array');
      final utils = _backendUtils(
        stringFromUtf8: (value) {
          calls.add('toStringUtf8');
          expect(value, same(bytes));
          return '{"name":"é 😀"}';
        },
        createJsonObject: (json) {
          calls.add('JSONObject:$json');
          return object;
        },
        createJsonArray: (json) {
          calls.add('JSONArray:$json');
          return array;
        },
      );

      expect(utils.fromJsonBytes(bytes), same(object));
      expect(calls, ['toStringUtf8', 'JSONObject:{"name":"é 😀"}']);

      calls.clear();
      expect(utils.jsonToArray(bytes), same(array));
      expect(calls, ['toStringUtf8', 'JSONArray:{"name":"é 😀"}']);
    });

    test(
      'serializes JSONObject once and returns the host ByteString object',
      () {
        final calls = <String>[];
        final object = _JsonObject('unused');
        final bytes = _ByteString([0x7b, 0x22, 0xc3, 0xa9, 0x22, 0x7d]);
        final utils = _backendUtils(
          jsonObjectToString: (value) {
            calls.add('toString');
            expect(value, same(object));
            return '{"é":"😀"}';
          },
          copyFromUtf8: (value) {
            calls.add('copyFromUtf8:$value');
            expect(value, '{"é":"😀"}');
            expect(utf8.encode(value), [
              0x7b,
              0x22,
              0xc3,
              0xa9,
              0x22,
              0x3a,
              0x22,
              0xf0,
              0x9f,
              0x98,
              0x80,
              0x22,
              0x7d,
            ]);
            return bytes;
          },
        );

        expect(utils.toByteString(object), same(bytes));
        expect(utils.toJsonBytes(object), same(bytes));
        expect(calls, [
          'toString',
          'copyFromUtf8:{"é":"😀"}',
          'toString',
          'copyFromUtf8:{"é":"😀"}',
        ]);
      },
    );

    test('reads holder JSONObject exactly once before serialization', () {
      final calls = <String>[];
      final object = _JsonObject('unused');
      final holder = _Holder(object, () => calls.add('jsonObject'));
      final bytes = _ByteString([1, 2, 3]);
      final utils = _backendUtils(
        jsonObjectToString: (value) {
          calls.add('toString');
          expect(value, same(object));
          return 'host-json';
        },
        copyFromUtf8: (value) {
          calls.add('copyFromUtf8:$value');
          expect(value, 'host-json');
          return bytes;
        },
      );

      expect(utils.toJsonBytesFromHolder(holder), same(bytes));
      expect(calls, ['jsonObject', 'toString', 'copyFromUtf8:host-json']);
      expect(holder.readCount, 1);
    });

    test(
      'propagates host callback failures unchanged and stops later calls',
      () {
        final parseFailure = FormatException('host parse failure');
        final bytes = _ByteString([0]);
        final parseCalls = <String>[];
        final parser = _backendUtils(
          stringFromUtf8: (_) {
            parseCalls.add('toStringUtf8');
            throw parseFailure;
          },
          createJsonObject: (_) {
            parseCalls.add('JSONObject');
            return _JsonObject('unexpected');
          },
        );
        expect(() => parser.fromJsonBytes(bytes), throwsA(same(parseFailure)));
        expect(parseCalls, ['toStringUtf8']);

        final jsonFailure = FormatException('host JSONObject failure');
        final jsonCalls = <String>[];
        final jsonParser = _backendUtils(
          stringFromUtf8: (_) {
            jsonCalls.add('toStringUtf8');
            return 'host-input';
          },
          createJsonObject: (value) {
            jsonCalls.add('JSONObject:$value');
            throw jsonFailure;
          },
        );
        expect(
          () => jsonParser.fromJsonBytes(bytes),
          throwsA(same(jsonFailure)),
        );
        expect(jsonCalls, ['toStringUtf8', 'JSONObject:host-input']);

        final serializeFailure = StateError('host serialization failure');
        final copyCalls = <String>[];
        final serializer = _backendUtils(
          jsonObjectToString: (_) {
            copyCalls.add('toString');
            throw serializeFailure;
          },
          copyFromUtf8: (_) {
            copyCalls.add('copyFromUtf8');
            throw StateError('unexpected');
          },
        );
        expect(
          () => serializer.toJsonBytes(_JsonObject('unused')),
          throwsA(same(serializeFailure)),
        );
        expect(copyCalls, ['toString']);

        final copyFailure = ArgumentError('host ByteString failure');
        final copyFailureCalls = <String>[];
        final copier = _backendUtils(
          jsonObjectToString: (_) {
            copyFailureCalls.add('toString');
            return 'exact-json';
          },
          copyFromUtf8: (value) {
            copyFailureCalls.add('copyFromUtf8:$value');
            throw copyFailure;
          },
        );
        expect(
          () => copier.toJsonBytes(_JsonObject('unused')),
          throwsA(same(copyFailure)),
        );
        expect(copyFailureCalls, ['toString', 'copyFromUtf8:exact-json']);
      },
    );
  });
}

BackendUtilsHostAdapter<_JsonObject, _JsonArray, _ByteString> _backendUtils({
  String Function(_ByteString)? stringFromUtf8,
  _JsonObject Function(String)? createJsonObject,
  _JsonArray Function(String)? createJsonArray,
  String Function(_JsonObject)? jsonObjectToString,
  _ByteString Function(String)? copyFromUtf8,
}) => BackendUtilsHostAdapter(
  stringFromUtf8: stringFromUtf8 ?? (_) => throw StateError('not used'),
  createJsonObject: createJsonObject ?? (_) => throw StateError('not used'),
  createJsonArray: createJsonArray ?? (_) => throw StateError('not used'),
  jsonObjectToString: jsonObjectToString ?? (_) => throw StateError('not used'),
  copyFromUtf8: copyFromUtf8 ?? (_) => throw StateError('not used'),
  holderJsonObject: (holder) => holder.jsonObject as _JsonObject,
);

class _ByteString {
  _ByteString(this.bytes);

  final List<int> bytes;
}

class _JsonObject {
  _JsonObject(this.serialized);

  final String serialized;
}

class _JsonArray {
  _JsonArray(this.parsed);

  final String parsed;
}

class _Holder implements JSONObjectHolder {
  _Holder(this._jsonObject, this.onRead);

  final _JsonObject _jsonObject;
  final void Function() onRead;
  int readCount = 0;

  @override
  _JsonObject get jsonObject {
    onRead();
    readCount++;
    return _jsonObject;
  }
}
