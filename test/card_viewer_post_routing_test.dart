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
 * Source-derived CardViewerViewModel.handlePostRequest() cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardViewer POST request routing', () {
    test('null backend method uses the unhandled POST message', () async {
      var callbackCalled = false;
      await expectLater(
        routeCardViewerPostRequest(
          backendMethodName: null,
          uri: 'host URI rendering',
          bytes: <int>[],
          i18nResourcesRaw: (_) {
            callbackCalled = true;
          },
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'Unhandled POST request: host URI rendering',
          ),
        ),
      );
      expect(callbackCalled, isFalse);
    });

    test(
      'exact i18nResources name forwards bytes and returns host response',
      () async {
        final bytes = <int>[0, 1, 127, 255];
        final response = Object();
        List<int>? forwardedBytes;

        final actualResponse = await routeCardViewerPostRequest<Object>(
          backendMethodName: 'i18nResources',
          uri: 'unused URI rendering',
          bytes: bytes,
          i18nResourcesRaw: (value) {
            forwardedBytes = value;
            return response;
          },
        );

        expect(forwardedBytes, same(bytes));
        expect(forwardedBytes, [0, 1, 127, 255]);
        expect(actualResponse, same(response));
      },
    );

    test(
      'similar, case-different, and unrecognized names use Anki error',
      () async {
        for (final methodName in [
          'i18nResourcesRaw',
          'I18nResources',
          'i18nresources',
          'unknown',
        ]) {
          var callbackCalled = false;
          await expectLater(
            routeCardViewerPostRequest(
              backendMethodName: methodName,
              uri: 'URI for $methodName',
              bytes: <int>[],
              i18nResourcesRaw: (_) {
                callbackCalled = true;
              },
            ),
            throwsA(
              isA<ArgumentError>().having(
                (error) => error.message,
                'message',
                'Unhandled Anki request: URI for $methodName',
              ),
            ),
            reason: 'only the exact recognized method name is routed',
          );
          expect(callbackCalled, isFalse);
        }
      },
    );
  });
}
