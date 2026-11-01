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
 * Source-derived from AnkiDroidJsAPI.kt:150–189, 681–696; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnkiDroid JS API contract', () {
    test(
      'empty inputs show invalid-data UI before parsing; whitespace is not empty',
      () {
        for (final input in [('', 'developer'), ('0.0.3', '')]) {
          final calls = <String>[];
          final result = requireJsApiVersion<String>(
            apiVer: input.$1,
            apiDevContact: input.$2,
            versions: _versions(calls),
            host: _host(calls),
          );

          expect(result, isFalse);
          expect(calls, ['invalid:']);
        }

        final calls = <String>[];
        final result = requireJsApiVersion<String>(
          apiVer: ' ',
          apiDevContact: ' ',
          versions: _versions(calls),
          host: _host(calls),
        );

        expect(result, isFalse);
        expect(calls, ['parse:0.0.3', 'parse: ', 'valid: ']);
      },
    );

    test(
      'parses current then supplied, and equal version returns true without UI',
      () {
        final calls = <String>[];
        final result = requireJsApiVersion<String>(
          apiVer: '0.0.3',
          apiDevContact: 'author',
          versions: _versions(calls),
          host: _host(calls),
        );

        expect(result, isTrue);
        expect(calls, ['parse:0.0.3', 'parse:0.0.3']);
      },
    );

    test('lower version shows update UI before checking the minimum floor', () {
      final calls = <String>[];
      final result = requireJsApiVersion<String>(
        apiVer: '0.0.2',
        apiDevContact: 'author',
        versions: _versions(calls),
        host: _host(calls),
      );

      expect(result, isTrue);
      expect(calls, [
        'parse:0.0.3',
        'parse:0.0.2',
        'update:author',
        'parse:0.0.3',
        'floor:0.0.2:0.0.3',
      ]);

      final belowFloorCalls = <String>[];
      final belowFloorResult = requireJsApiVersion<String>(
        apiVer: '0.0.2',
        apiDevContact: 'author',
        versions: _versions(belowFloorCalls, floorResult: false),
        host: _host(belowFloorCalls),
      );
      expect(belowFloorResult, isFalse);
      expect(belowFloorCalls, calls);
    });

    test(
      'greater version shows valid-version UI and does not parse the floor',
      () {
        final calls = <String>[];
        final result = requireJsApiVersion<String>(
          apiVer: '0.0.4',
          apiDevContact: 'author',
          versions: _versions(calls),
          host: _host(calls),
        );

        expect(result, isFalse);
        expect(calls, ['parse:0.0.3', 'parse:0.0.4', 'valid:author']);
      },
    );

    test('catches Exception from parsing or UI and warns exactly once', () {
      final parserFailure = Exception('bad version');
      final parseCalls = <String>[];
      final parserResult = requireJsApiVersion<String>(
        apiVer: 'broken',
        apiDevContact: 'author',
        versions: JsApiVersionOperations<String>(
          parse: (value) {
            parseCalls.add('parse:$value');
            if (value == '0.0.3') throw parserFailure;
            return value;
          },
          equals: (left, right) => left == right,
          isLowerThan: (_, _) => false,
          isHigherThanOrEquivalentTo: (_, _) => true,
        ),
        host: _host(parseCalls),
      );

      expect(parserResult, isFalse);
      expect(parseCalls, ['parse:0.0.3', 'warn:requireApiVersion::exception']);

      final callbackCalls = <String>[];
      final callbackFailure = Exception('snackbar failed');
      final callbackResult = requireJsApiVersion<String>(
        apiVer: '0.0.4',
        apiDevContact: 'author',
        versions: _versions(callbackCalls),
        host: JsApiVersionHostCallbacks(
          showInvalidDataSnackbar: (detail) =>
              callbackCalls.add('invalid:$detail'),
          showUpdateVersionSnackbar: (contact) =>
              callbackCalls.add('update:$contact'),
          showValidVersionSnackbar: (_) => throw callbackFailure,
          warn: (message) => callbackCalls.add('warn:$message'),
        ),
      );

      expect(callbackResult, isFalse);
      expect(callbackCalls, [
        'parse:0.0.3',
        'parse:0.0.4',
        'warn:requireApiVersion::exception',
      ]);
    });

    test(
      'does not catch Error-like failures and stops after the failing callback',
      () {
        final failure = StateError('fatal');
        final calls = <String>[];

        expect(
          () => requireJsApiVersion<String>(
            apiVer: '0.0.4',
            apiDevContact: 'author',
            versions: _versions(calls),
            host: JsApiVersionHostCallbacks(
              showInvalidDataSnackbar: (detail) => calls.add('invalid:$detail'),
              showUpdateVersionSnackbar: (contact) =>
                  calls.add('update:$contact'),
              showValidVersionSnackbar: (_) => throw failure,
              warn: (message) => calls.add('warn:$message'),
            ),
          ),
          throwsA(same(failure)),
        );
        expect(calls, ['parse:0.0.3', 'parse:0.0.4']);
      },
    );

    test(
      'ApiContract projects source fields and retains identity equality',
      () {
        final first = ApiContract(
          isValid: true,
          cardSuppliedDeveloperContact: 'author',
          cardSuppliedData: '{"key":"value"}',
        );
        final second = ApiContract(
          isValid: true,
          cardSuppliedDeveloperContact: 'author',
          cardSuppliedData: '{"key":"value"}',
        );

        expect(first.isValid, isTrue);
        expect(first.cardSuppliedDeveloperContact, 'author');
        expect(first.cardSuppliedData, '{"key":"value"}');
        expect(first, isNot(same(second)));
        expect(first, isNot(second));
      },
    );

    test('preserves result key constants', () {
      expect(VALUE_KEY, 'value');
      expect(SUCCESS_KEY, 'success');
    });

    test('retains each source result variant, status, value, and identity', () {
      final floatValue = double.nan;
      final results = <ApiResult>[
        ApiResultBoolean(true, true),
        ApiResultInteger(false, 42),
        ApiResultFloat(true, floatValue),
        ApiResultLong(false, 42),
        ApiResultString(true, 'value'),
      ];

      expect(results.map((result) => result.runtimeType), [
        ApiResultBoolean,
        ApiResultInteger,
        ApiResultFloat,
        ApiResultLong,
        ApiResultString,
      ]);
      expect(results.map((result) => result.status), [
        true,
        false,
        true,
        false,
        true,
      ]);
      expect((results[0] as ApiResultBoolean).value, isTrue);
      expect((results[1] as ApiResultInteger).value, 42);
      expect((results[2] as ApiResultFloat).value, same(floatValue));
      expect((results[3] as ApiResultLong).value, 42);
      expect((results[4] as ApiResultString).value, 'value');

      final first = ApiResultInteger(false, 42);
      final second = ApiResultInteger(false, 42);
      expect(first, isNot(same(second)));
      expect(first, isNot(second));
    });

    test(
      'projects ordered success then value entries without JSON encoding',
      () {
        final result = ApiResultString(false, 'a"b');

        final projection = result.toOrderedHostMap();

        expect(projection.keys.toList(), [SUCCESS_KEY, VALUE_KEY]);
        expect(projection[SUCCESS_KEY], isFalse);
        expect(projection[VALUE_KEY], same(result.value));
      },
    );

    test('success and failure factories construct String variants', () {
      final success = ApiResult.success('ok');
      final failure = ApiResult.failure('failed');

      expect(success, isA<ApiResultString>());
      expect(success.status, isTrue);
      expect((success as ApiResultString).value, 'ok');
      expect(failure, isA<ApiResultString>());
      expect(failure.status, isFalse);
      expect((failure as ApiResultString).value, 'failed');
    });

    test(
      'typed conversion projections select only source overload variants',
      () {
        final contract = ApiContract(
          isValid: false,
          cardSuppliedDeveloperContact: 'author',
          cardSuppliedData: '',
        );

        expect(apiResultFromBoolean(contract, true), isA<ApiResultBoolean>());
        expect(apiResultFromInteger(contract, 8), isA<ApiResultInteger>());
        expect(apiResultFromLong(contract, 8), isA<ApiResultLong>());
        expect(apiResultFromString(contract, '8'), isA<ApiResultString>());
        expect(apiResultFromBoolean(contract, true).status, isFalse);
        expect(apiResultFromInteger(contract, 8).status, isFalse);
        expect(apiResultFromLong(contract, 8).status, isFalse);
        expect(apiResultFromString(contract, '8').status, isFalse);
      },
    );

    test('host projection leaves formatting and encoding to the host', () {
      final result = ApiResultFloat(true, double.infinity);
      final projected = result.toOrderedHostMap();

      expect(projected[VALUE_KEY], double.infinity);
      final stringValue = 'a"b';
      final stringProjection = ApiResultString(
        true,
        stringValue,
      ).toOrderedHostMap();
      expect(stringProjection[VALUE_KEY], same(stringValue));
    });

    test(
      'parseJsApiContract reads source fields in order before checking version',
      () {
        final calls = <String>[];
        final parsed = <String, String>{
          'version': '0.0.3',
          'developer': 'author',
          'data': '{"payload":1}',
        };
        final contract = parseJsApiContract<Map<String, String>, String>(
          host: JsApiContractHostAdapter<Map<String, String>>(
            parseObject: () {
              calls.add('parse-object');
              return parsed;
            },
            optString: (object, key, fallback) {
              calls.add('read:$key:$fallback');
              return object[key] ?? fallback;
            },
            isJsonException: (_) => false,
            logJsonException: (_) => fail('unexpected JSON exception'),
            showInvalidJsonSnackbar: (_) =>
                fail('unexpected invalid-JSON snackbar'),
          ),
          versions: _versions(calls),
          versionHost: _host(calls),
        );

        expect(contract, isNotNull);
        expect(contract!.isValid, isTrue);
        expect(contract.cardSuppliedDeveloperContact, 'author');
        expect(contract.cardSuppliedData, '{"payload":1}');
        expect(calls, [
          'parse-object',
          'read:version:',
          'read:developer:',
          'read:data:',
          'parse:0.0.3',
          'parse:0.0.3',
        ]);
      },
    );

    test(
      'parseJsApiContract passes host fallback values and returns false contracts',
      () {
        final calls = <String>[];
        final parsed = <String, String>{};
        final contract = parseJsApiContract<Map<String, String>, String>(
          host: JsApiContractHostAdapter<Map<String, String>>(
            parseObject: () => parsed,
            optString: (object, key, fallback) {
              calls.add('read:$key:$fallback');
              return object[key] ?? fallback;
            },
            isJsonException: (_) => false,
            logJsonException: (_) => fail('unexpected JSON exception'),
            showInvalidJsonSnackbar: (_) =>
                fail('unexpected invalid-JSON snackbar'),
          ),
          versions: _versions(calls),
          versionHost: _host(calls),
        );

        expect(contract, isNotNull);
        expect(contract!.isValid, isFalse);
        expect(contract.cardSuppliedDeveloperContact, '');
        expect(contract.cardSuppliedData, '');
        expect(
          contract,
          isNot(
            same(
              ApiContract(
                isValid: false,
                cardSuppliedDeveloperContact: '',
                cardSuppliedData: '',
              ),
            ),
          ),
        );
        expect(calls, [
          'read:version:',
          'read:developer:',
          'read:data:',
          'invalid:',
        ]);
      },
    );

    test(
      'parseJsApiContract logs a host JSON exception before showing its message',
      () {
        final calls = <String>[];
        final failure = _JsonException('bad JSON', 'localized JSON detail');
        Exception? loggedException;
        Exception? shownException;
        final contract = parseJsApiContract<Map<String, String>, String>(
          host: JsApiContractHostAdapter<Map<String, String>>(
            parseObject: () => const {},
            optString: (_, key, fallback) {
              calls.add('read:$key');
              if (key == 'developer') throw failure;
              return fallback;
            },
            isJsonException: (exception) => exception is _JsonException,
            logJsonException: (exception) {
              loggedException = exception;
              calls.add('log:$exception');
            },
            showInvalidJsonSnackbar: (exception) {
              shownException = exception;
              calls.add('ui:${(exception as _JsonException).localized}');
            },
          ),
          versions: _versions(calls),
          versionHost: _host(calls),
        );

        expect(contract, isNull);
        expect(calls, [
          'read:version',
          'read:developer',
          'log:$failure',
          'ui:localized JSON detail',
        ]);
        expect(loggedException, same(failure));
        expect(shownException, same(failure));

        final parseFailure = _JsonException('parse failed', 'parse localized');
        final parseCalls = <String>[];
        final parseContract = parseJsApiContract<Map<String, String>, String>(
          host: JsApiContractHostAdapter<Map<String, String>>(
            parseObject: () {
              parseCalls.add('parse');
              throw parseFailure;
            },
            optString: (_, __, ___) => fail('fields follow successful parsing'),
            isJsonException: (exception) => exception is _JsonException,
            logJsonException: (exception) => parseCalls.add('log:$exception'),
            showInvalidJsonSnackbar: (exception) =>
                parseCalls.add('ui:${(exception as _JsonException).localized}'),
          ),
          versions: _versions(parseCalls),
          versionHost: _host(parseCalls),
        );
        expect(parseContract, isNull);
        expect(parseCalls, ['parse', 'log:parse failed', 'ui:parse localized']);
      },
    );

    test(
      'parseJsApiContract propagates non-JSON failures and catch-body failures',
      () {
        final ordinaryFailure = Exception('not JSON');
        final calls = <String>[];

        expect(
          () => parseJsApiContract<Map<String, String>, String>(
            host: JsApiContractHostAdapter<Map<String, String>>(
              parseObject: () => const {},
              optString: (_, __, ___) => throw ordinaryFailure,
              isJsonException: (_) => false,
              logJsonException: (_) => fail('unexpected JSON exception'),
              showInvalidJsonSnackbar: (_) =>
                  fail('unexpected invalid-JSON snackbar'),
            ),
            versions: _versions(calls),
            versionHost: _host(calls),
          ),
          throwsA(same(ordinaryFailure)),
        );

        final jsonFailure = _JsonException('bad JSON', 'localized');
        final loggingFailure = StateError('logger failed');
        expect(
          () => parseJsApiContract<Map<String, String>, String>(
            host: JsApiContractHostAdapter<Map<String, String>>(
              parseObject: () => const {},
              optString: (_, __, ___) => throw jsonFailure,
              isJsonException: (exception) => exception is _JsonException,
              logJsonException: (_) => throw loggingFailure,
              showInvalidJsonSnackbar: (_) => calls.add('ui'),
            ),
            versions: _versions(calls),
            versionHost: _host(calls),
          ),
          throwsA(same(loggingFailure)),
        );
        expect(calls, isEmpty);

        final uiFailure = Exception('UI failed');
        expect(
          () => parseJsApiContract<Map<String, String>, String>(
            host: JsApiContractHostAdapter<Map<String, String>>(
              parseObject: () => const {},
              optString: (_, __, ___) => throw jsonFailure,
              isJsonException: (exception) => exception is _JsonException,
              logJsonException: (_) => calls.add('log'),
              showInvalidJsonSnackbar: (_) => throw uiFailure,
            ),
            versions: _versions(calls),
            versionHost: _host(calls),
          ),
          throwsA(same(uiFailure)),
        );
        expect(calls, ['log']);

        final errorFailure = StateError('fatal');
        expect(
          () => parseJsApiContract<Map<String, String>, String>(
            host: JsApiContractHostAdapter<Map<String, String>>(
              parseObject: () => const {},
              optString: (_, __, ___) => throw errorFailure,
              isJsonException: (_) => fail('Error must bypass classification'),
              logJsonException: (_) => fail('unexpected JSON exception'),
              showInvalidJsonSnackbar: (_) =>
                  fail('unexpected invalid-JSON snackbar'),
            ),
            versions: _versions(calls),
            versionHost: _host(calls),
          ),
          throwsA(same(errorFailure)),
        );
      },
    );
  });
}

class _JsonException implements Exception {
  _JsonException(this.message, this.localized);

  final String message;
  final String localized;

  @override
  String toString() => message;
}

JsApiVersionOperations<String> _versions(
  List<String> calls, {
  bool floorResult = true,
}) => JsApiVersionOperations<String>(
  parse: (value) {
    calls.add('parse:$value');
    return value;
  },
  equals: (left, right) => left == right,
  isLowerThan: (version, other) => version == '0.0.2' && other == '0.0.3',
  isHigherThanOrEquivalentTo: (version, minimum) {
    calls.add('floor:$version:$minimum');
    return floorResult;
  },
);

JsApiVersionHostCallbacks _host(List<String> calls) =>
    JsApiVersionHostCallbacks(
      showInvalidDataSnackbar: (detail) => calls.add('invalid:$detail'),
      showUpdateVersionSnackbar: (contact) => calls.add('update:$contact'),
      showValidVersionSnackbar: (contact) => calls.add('valid:$contact'),
      warn: (message) => calls.add('warn:$message'),
    );
