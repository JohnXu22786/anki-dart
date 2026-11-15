/*
 * Copyright (c) 2011 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Media.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Media initialization', () {
    test(
      'reads mediaFolder twice and logs the first result before null exit',
      () {
        final calls = <String>[];
        var reads = 0;
        final directory = Object();
        final lazyDirectory = Media.initialize<Object>(
          mediaFolder: () {
            reads++;
            calls.add('mediaFolder:$reads');
            return null;
          },
          logVerbose: (message, value) {
            calls.add('verbose');
            expect(message, 'dir %s');
            expect(value, isNull);
          },
          exists: (_) {
            calls.add('exists');
            return false;
          },
          logInfo: (_) => calls.add('info'),
          mkdirs: (_) {
            calls.add('mkdirs');
            return false;
          },
          requireMediaFolder: () {
            calls.add('requireMediaFolder');
            return directory;
          },
        );

        expect(reads, 2);
        expect(calls, ['mediaFolder:1', 'verbose', 'mediaFolder:2']);
        expect(lazyDirectory, isA<Function>());
        expect(calls, isNot(contains('requireMediaFolder')));
      },
    );

    test(
      'checks an existing directory once without logging or creating it',
      () {
        final calls = <String>[];
        final directory = Object();
        final lazyDirectory = Media.initialize<Object>(
          mediaFolder: () {
            calls.add('mediaFolder');
            return directory;
          },
          logVerbose: (message, value) {
            calls.add('verbose');
            expect(message, 'dir %s');
            expect(identical(value, directory), isTrue);
          },
          exists: (value) {
            calls.add('exists');
            expect(identical(value, directory), isTrue);
            return true;
          },
          logInfo: (_) => calls.add('info'),
          mkdirs: (_) {
            calls.add('mkdirs');
            return false;
          },
          requireMediaFolder: () => directory,
        );

        expect(calls, ['mediaFolder', 'verbose', 'mediaFolder', 'exists']);
        expect(lazyDirectory, isA<Function>());
      },
    );

    test('logs then creates a missing directory and ignores mkdirs false', () {
      final calls = <String>[];
      final directory = Object();
      Media.initialize<Object>(
        mediaFolder: () {
          calls.add('mediaFolder');
          return directory;
        },
        logVerbose: (message, value) {
          calls.add('verbose');
          expect(message, 'dir %s');
          expect(identical(value, directory), isTrue);
        },
        exists: (value) {
          calls.add('exists');
          expect(identical(value, directory), isTrue);
          return false;
        },
        logInfo: (message) {
          calls.add('info');
          expect(message, 'Creating collection.media');
        },
        mkdirs: (value) {
          calls.add('mkdirs');
          expect(identical(value, directory), isTrue);
          return false;
        },
        requireMediaFolder: () => directory,
      );

      expect(calls, [
        'mediaFolder',
        'verbose',
        'mediaFolder',
        'exists',
        'info',
        'mkdirs',
      ]);
    });

    test(
      'propagates callback failures and stops later initialization steps',
      () {
        final error = StateError('callback failed');
        final directory = Object();
        const order = [
          'mediaFolder:1',
          'verbose',
          'mediaFolder:2',
          'exists',
          'info',
          'mkdirs',
        ];

        for (final failingStep in order) {
          final calls = <String>[];
          var mediaFolderReads = 0;
          void record(String step) {
            calls.add(step);
            if (step == failingStep) throw error;
          }

          expect(
            () => Media.initialize<Object>(
              mediaFolder: () {
                mediaFolderReads++;
                record('mediaFolder:$mediaFolderReads');
                return directory;
              },
              logVerbose: (_, _) => record('verbose'),
              exists: (_) {
                record('exists');
                return false;
              },
              logInfo: (_) => record('info'),
              mkdirs: (_) {
                record('mkdirs');
                return false;
              },
              requireMediaFolder: () => directory,
            ),
            throwsA(same(error)),
            reason: 'failure at $failingStep must propagate unchanged',
          );
          expect(calls, order.take(order.indexOf(failingStep) + 1));
        }
      },
    );

    test(
      'resolves the lazy directory on first access, memoizes success, and retries errors',
      () {
        final calls = <String>[];
        final directory = Object();
        final lazyDirectory = Media.initialize<Object>(
          mediaFolder: () => null,
          logVerbose: (_, _) => calls.add('verbose'),
          exists: (_) => fail('null mediaFolder must not be checked'),
          logInfo: (_) => fail('null mediaFolder must not be logged'),
          mkdirs: (_) => fail('null mediaFolder must not be created'),
          requireMediaFolder: () {
            calls.add('requireMediaFolder');
            return directory;
          },
        );

        expect(calls, ['verbose']);
        expect(identical(lazyDirectory(), directory), isTrue);
        expect(identical(lazyDirectory(), directory), isTrue);
        expect(calls, ['verbose', 'requireMediaFolder']);

        final error = StateError('directory unavailable');
        var attempts = 0;
        final retrying = Media.initialize<Object>(
          mediaFolder: () => null,
          logVerbose: (_, _) {},
          exists: (_) => fail('null mediaFolder must not be checked'),
          logInfo: (_) => fail('null mediaFolder must not be logged'),
          mkdirs: (_) => fail('null mediaFolder must not be created'),
          requireMediaFolder: () {
            attempts++;
            if (attempts == 1) throw error;
            return directory;
          },
        );

        expect(() => retrying(), throwsA(same(error)));
        expect(identical(retrying(), directory), isTrue);
        expect(identical(retrying(), directory), isTrue);
        expect(attempts, 2);
      },
    );
  });
}
