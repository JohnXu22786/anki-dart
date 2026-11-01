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
 * Source-derived from CsvImporterDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CsvImporterDestination', () {
    test(
      'forwards exact paths and context once and returns the same Intent',
      () {
        final paths = <String>[
          '',
          '/tmp/a, b.csv',
          r'C:\tmp\..\imports\é.csv',
          '  odd/../path\n.csv  ',
          'nul\u0000byte.csv',
        ];

        for (final path in paths) {
          final context = Object();
          final intent = Object();
          final destination = CsvImporterDestination(path);
          final calls = <(Object, String)>[];

          final result = destination.toIntent<Object, Object>(context, (
            actualContext,
            actualPath,
          ) {
            calls.add((actualContext, actualPath));
            return intent;
          });

          expect(destination.filePath, path);
          expect(result, same(intent));
          expect(calls, [(context, path)]);
          expect(identical(calls.single.$1, context), isTrue);
          expect(identical(calls.single.$2, path), isTrue);
        }
      },
    );

    test('getIntent failures propagate unchanged', () {
      final failure = StateError('getIntent failed');
      final destination = CsvImporterDestination('file.csv');
      var calls = 0;

      expect(
        () => destination.toIntent<Object, Object>(Object(), (_, _) {
          calls++;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });
  });
}
