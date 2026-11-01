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
  });
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
