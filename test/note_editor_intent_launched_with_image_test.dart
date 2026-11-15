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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('intentLaunchedWithImage', () {
    test('unsupported action short-circuits after the second action read', () {
      final intent = Object();
      final reads = <String?>[];
      var invalidViewCalls = 0;
      var mimeCalls = 0;

      final result = intentLaunchedWithImage(
        intent: intent,
        actionOf: (candidate) {
          expect(identical(candidate, intent), isTrue);
          reads.add('android.intent.action.EDIT');
          return 'android.intent.action.EDIT';
        },
        isInvalidViewIntent: (_) {
          invalidViewCalls++;
          return false;
        },
        resolveMimeType: (_) {
          mimeCalls++;
          return 'image/png';
        },
      );

      expect(result, isFalse);
      expect(reads, hasLength(2));
      expect(invalidViewCalls, 0);
      expect(mimeCalls, 0);
    });

    test(
      'SEND reads action once and reaches invalid-view then MIME callbacks',
      () {
        final intent = Object();
        final calls = <String>[];
        final result = intentLaunchedWithImage(
          intent: intent,
          actionOf: (candidate) {
            expect(identical(candidate, intent), isTrue);
            calls.add('action');
            return 'android.intent.action.SEND';
          },
          isInvalidViewIntent: (candidate) {
            expect(identical(candidate, intent), isTrue);
            calls.add('invalid');
            return false;
          },
          resolveMimeType: (candidate) {
            expect(identical(candidate, intent), isTrue);
            calls.add('mime');
            return 'image/png';
          },
        );

        expect(result, isTrue);
        expect(calls, ['action', 'invalid', 'mime']);
      },
    );

    test('VIEW is accepted by the conditional second action read', () {
      final actions = <String?>[
        'android.intent.action.EDIT',
        'android.intent.action.VIEW',
      ];
      var calls = 0;
      final result = intentLaunchedWithImage(
        intent: Object(),
        actionOf: (_) => actions[calls++],
        isInvalidViewIntent: (_) => false,
        resolveMimeType: (_) => 'image/webp',
      );

      expect(result, isTrue);
      expect(calls, 2);
    });

    test('invalid VIEW intent skips MIME resolution', () {
      var mimeCalls = 0;
      final result = intentLaunchedWithImage(
        intent: Object(),
        actionOf: (_) => 'android.intent.action.VIEW',
        isInvalidViewIntent: (_) => true,
        resolveMimeType: (_) {
          mimeCalls++;
          return 'image/png';
        },
      );

      expect(result, isFalse);
      expect(mimeCalls, 0);
    });

    test(
      'resolves MIME exactly once and uses the case-sensitive image prefix',
      () {
        for (final (mimeType, expected) in <(String?, bool)>[
          (null, false),
          ('text/plain', false),
          ('Image/png', false),
          ('image/', true),
          ('image/jpeg', true),
        ]) {
          var mimeCalls = 0;
          final result = intentLaunchedWithImage(
            intent: Object(),
            actionOf: (_) => 'android.intent.action.SEND',
            isInvalidViewIntent: (_) => false,
            resolveMimeType: (_) {
              mimeCalls++;
              return mimeType;
            },
          );

          expect(result, expected, reason: 'MIME: $mimeType');
          expect(mimeCalls, 1, reason: 'MIME: $mimeType');
        }
      },
    );

    test('propagates each callback failure and stops later callbacks', () {
      final actionFailure = StateError('action');
      var invalidCalls = 0;
      var mimeCalls = 0;
      expect(
        () => intentLaunchedWithImage(
          intent: Object(),
          actionOf: (_) => throw actionFailure,
          isInvalidViewIntent: (_) {
            invalidCalls++;
            return false;
          },
          resolveMimeType: (_) {
            mimeCalls++;
            return 'image/png';
          },
        ),
        throwsA(same(actionFailure)),
      );
      expect(invalidCalls, 0);
      expect(mimeCalls, 0);

      final invalidViewFailure = StateError('invalid view');
      mimeCalls = 0;
      expect(
        () => intentLaunchedWithImage(
          intent: Object(),
          actionOf: (_) => 'android.intent.action.VIEW',
          isInvalidViewIntent: (_) => throw invalidViewFailure,
          resolveMimeType: (_) {
            mimeCalls++;
            return 'image/png';
          },
        ),
        throwsA(same(invalidViewFailure)),
      );
      expect(mimeCalls, 0);

      final mimeFailure = StateError('mime');
      expect(
        () => intentLaunchedWithImage(
          intent: Object(),
          actionOf: (_) => 'android.intent.action.SEND',
          isInvalidViewIntent: (_) => false,
          resolveMimeType: (_) => throw mimeFailure,
        ),
        throwsA(same(mimeFailure)),
      );
    });
  });
}
