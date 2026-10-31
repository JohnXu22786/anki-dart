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
 * Source-derived ReviewerViewModel.handlePostRequest() cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer POST request routing', () {
    test(
      'focus methods precede backend routes and return empty responses',
      () async {
        for (final method in ['focusin', 'focusout']) {
          final calls = <String>[];
          final bytes = <int>[1, 2, 3];

          final response = await routeReviewerPostRequest<Object>(
            ankidroidMethodName: method,
            backendMethodName: 'getSchedulingStatesWithContext',
            request: Object(),
            bytes: bytes,
            setInputFocusedRaw: (value) => calls.add('focus:$value'),
            statesMutatedRaw: () => calls.add('mutated'),
            getSchedulingStatesWithContextRaw: () {
              calls.add('getSchedulingStatesWithContext');
              return <int>[9];
            },
            setSchedulingStatesRaw: (_) => calls.add('setSchedulingStates'),
            baseHandler: (_, __) {
              calls.add('base');
              return <int>[8];
            },
          );

          expect(response, isEmpty);
          expect(calls, [
            if (method == 'focusin') 'focus:true' else 'focus:false',
          ]);
        }
      },
    );

    test(
      'statesMutated invokes the host callback before returning empty bytes',
      () async {
        final calls = <String>[];
        final response = await routeReviewerPostRequest<Object>(
          ankidroidMethodName: 'statesMutated',
          backendMethodName: null,
          request: Object(),
          bytes: <int>[4],
          setInputFocusedRaw: (_) => calls.add('focus'),
          statesMutatedRaw: () => calls.add('mutated'),
          getSchedulingStatesWithContextRaw: () => <int>[9],
          setSchedulingStatesRaw: (_) => calls.add('set'),
          baseHandler: (_, __) => <int>[8],
        );

        expect(calls, ['mutated']);
        expect(response, isEmpty);
      },
    );

    test(
      'getSchedulingStatesWithContext returns the exact host response',
      () async {
        final expectedResponse = <int>[7, 8];
        var callbackCount = 0;
        final response = await routeReviewerPostRequest<Object>(
          ankidroidMethodName: null,
          backendMethodName: 'getSchedulingStatesWithContext',
          request: Object(),
          bytes: <int>[],
          setInputFocusedRaw: (_) {},
          statesMutatedRaw: () {},
          getSchedulingStatesWithContextRaw: () {
            callbackCount++;
            return expectedResponse;
          },
          setSchedulingStatesRaw: (_) => fail('set route must not run'),
          baseHandler: (_, __) => fail('base route must not run'),
        );

        expect(callbackCount, 1);
        expect(response, same(expectedResponse));
      },
    );

    test(
      'setSchedulingStates forwards the original bytes then returns empty',
      () async {
        final bytes = <int>[0, 127, 255];
        List<int>? receivedBytes;
        var baseCalled = false;
        final response = await routeReviewerPostRequest<Object>(
          ankidroidMethodName: null,
          backendMethodName: 'setSchedulingStates',
          request: Object(),
          bytes: bytes,
          setInputFocusedRaw: (_) {},
          statesMutatedRaw: () {},
          getSchedulingStatesWithContextRaw: () =>
              fail('get route must not run'),
          setSchedulingStatesRaw: (value) => receivedBytes = value,
          baseHandler: (_, __) {
            baseCalled = true;
            return <int>[9];
          },
        );

        expect(receivedBytes, same(bytes));
        expect(response, isEmpty);
        expect(baseCalled, isFalse);
      },
    );

    test(
      'unrecognized and case-different methods delegate exact request and bytes',
      () async {
        for (final method in [
          'other',
          'FocusIn',
          'FocusOut',
          'StatesMutated',
        ]) {
          for (final backendMethod in [
            'other',
            'GetSchedulingStatesWithContext',
            'setSchedulingStatesExtra',
          ]) {
            final request = Object();
            final bytes = <int>[0, 2, 255];
            final expectedResponse = <int>[7, 8];
            Object? receivedRequest;
            List<int>? receivedBytes;

            final response = await routeReviewerPostRequest<Object>(
              ankidroidMethodName: method,
              backendMethodName: backendMethod,
              request: request,
              bytes: bytes,
              setInputFocusedRaw: (_) => fail('focus route must not run'),
              statesMutatedRaw: () => fail('mutation route must not run'),
              getSchedulingStatesWithContextRaw: () =>
                  fail('get route must not run'),
              setSchedulingStatesRaw: (_) => fail('set route must not run'),
              baseHandler: (value, body) {
                receivedRequest = value;
                receivedBytes = body;
                return expectedResponse;
              },
            );

            expect(receivedRequest, same(request));
            expect(receivedBytes, same(bytes));
            expect(response, same(expectedResponse));
          }
        }
      },
    );

    test('callback failures propagate and stop subsequent routing', () async {
      final error = StateError('host callback failed');
      var mutationCalled = false;
      var baseCalled = false;

      await expectLater(
        routeReviewerPostRequest<Object>(
          ankidroidMethodName: 'focusin',
          backendMethodName: 'getSchedulingStatesWithContext',
          request: Object(),
          bytes: <int>[],
          setInputFocusedRaw: (_) => throw error,
          statesMutatedRaw: () => mutationCalled = true,
          getSchedulingStatesWithContextRaw: () => <int>[1],
          setSchedulingStatesRaw: (_) => fail('set route must not run'),
          baseHandler: (_, __) {
            baseCalled = true;
            return <int>[];
          },
        ),
        throwsA(same(error)),
      );
      expect(mutationCalled, isFalse);
      expect(baseCalled, isFalse);

      await expectLater(
        routeReviewerPostRequest<Object>(
          ankidroidMethodName: 'statesMutated',
          backendMethodName: 'setSchedulingStates',
          request: Object(),
          bytes: <int>[],
          setInputFocusedRaw: (_) {},
          statesMutatedRaw: () => throw error,
          getSchedulingStatesWithContextRaw: () => <int>[1],
          setSchedulingStatesRaw: (_) => fail('set route must not run'),
          baseHandler: (_, __) {
            baseCalled = true;
            return <int>[];
          },
        ),
        throwsA(same(error)),
      );
      expect(baseCalled, isFalse);

      await expectLater(
        routeReviewerPostRequest<Object>(
          ankidroidMethodName: null,
          backendMethodName: 'setSchedulingStates',
          request: Object(),
          bytes: <int>[],
          setInputFocusedRaw: (_) {},
          statesMutatedRaw: () {},
          getSchedulingStatesWithContextRaw: () => <int>[1],
          setSchedulingStatesRaw: (_) => throw error,
          baseHandler: (_, __) {
            baseCalled = true;
            return <int>[];
          },
        ),
        throwsA(same(error)),
      );
      expect(baseCalled, isFalse);
    });
  });
}
