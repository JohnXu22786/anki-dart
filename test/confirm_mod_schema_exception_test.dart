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
 * Source-derived from ConfirmModSchemaException.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ConfirmModSchemaException', () {
    test(
      'is catchable by its distinct type and has no-argument construction',
      () {
        final exception = ConfirmModSchemaException();

        try {
          throw exception;
        } on ConfirmModSchemaException catch (caught) {
          expect(caught, same(exception));
          expect(caught, isA<Exception>());
        } on Exception {
          fail(
            'ConfirmModSchemaException should be caught by its distinct type',
          );
        }
      },
    );

    test('logs itself through the host callback exactly once', () {
      final exception = ConfirmModSchemaException();
      final logged = <Object>[];

      exception.log(logged.add);

      expect(logged, hasLength(1));
      expect(logged.single, same(exception));
    });

    test('propagates host logger failures unchanged', () {
      final exception = ConfirmModSchemaException();
      final failure = StateError('logger failed');
      var calls = 0;

      expect(
        () => exception.log((_) {
          calls++;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });
  });
}
