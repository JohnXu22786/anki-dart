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
 * Source-derived from Directory.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Directory.createInstance', () {
    test('returns null when the host file does not exist', () {
      final file = Object();
      final calls = <String>[];

      final directory = Directory.createInstanceFromFile<Object>(
        file: file,
        exists: (actualFile) {
          calls.add('exists');
          expect(actualFile, same(file));
          return false;
        },
        isDirectory: (_) {
          calls.add('isDirectory');
          return true;
        },
        listFiles: (_) => null,
        canonicalPath: (_) => '/unused',
      );

      expect(directory, isNull);
      expect(calls, ['exists']);
    });

    test(
      'checks directory only after existence and retains the exact file',
      () {
        final file = Object();
        final calls = <String>[];

        final directory = Directory.createInstanceFromFile<Object>(
          file: file,
          exists: (actualFile) {
            calls.add('exists');
            expect(actualFile, same(file));
            return true;
          },
          isDirectory: (actualFile) {
            calls.add('isDirectory');
            expect(actualFile, same(file));
            return true;
          },
          listFiles: (_) => null,
          canonicalPath: (_) => '/unused',
        );

        expect(directory!.file, same(file));
        expect(calls, ['exists', 'isDirectory']);
      },
    );

    test('returns null for a non-directory after one check', () {
      final calls = <String>[];
      final directory = Directory.createInstanceFromFile<Object>(
        file: Object(),
        exists: (_) {
          calls.add('exists');
          return true;
        },
        isDirectory: (_) {
          calls.add('isDirectory');
          return false;
        },
        listFiles: (_) => null,
        canonicalPath: (_) => '/unused',
      );

      expect(directory, isNull);
      expect(calls, ['exists', 'isDirectory']);
    });

    test('path creation constructs one host file and delegates validation', () {
      const path = 'relative/../directory';
      final file = Object();
      final calls = <String>[];
      final directory = Directory.createInstanceFromPath<Object>(
        path: path,
        createFile: (actualPath) {
          calls.add('createFile');
          expect(actualPath, path);
          return file;
        },
        exists: (actualFile) {
          calls.add('exists');
          expect(actualFile, same(file));
          return true;
        },
        isDirectory: (actualFile) {
          calls.add('isDirectory');
          expect(actualFile, same(file));
          return true;
        },
        listFiles: (_) => null,
        canonicalPath: (_) => '/unused',
      );

      expect(directory!.file, same(file));
      expect(calls, ['createFile', 'exists', 'isDirectory']);
    });

    test('propagates validation failures and stops later callbacks', () {
      for (final failingCallback in ['exists', 'isDirectory']) {
        final failure = Object();
        final calls = <String>[];

        expect(
          () => Directory.createInstanceFromFile<Object>(
            file: Object(),
            exists: (_) {
              calls.add('exists');
              if (failingCallback == 'exists') throw failure;
              return true;
            },
            isDirectory: (_) {
              calls.add('isDirectory');
              if (failingCallback == 'isDirectory') throw failure;
              return true;
            },
            listFiles: (_) => null,
            canonicalPath: (_) => '/unused',
          ),
          throwsA(same(failure)),
        );
        expect(
          calls,
          failingCallback == 'exists' ? ['exists'] : ['exists', 'isDirectory'],
        );
      }

      final failure = Object();
      final calls = <String>[];
      expect(
        () => Directory.createInstanceFromPath<Object>(
          path: 'verbatim path',
          createFile: (_) {
            calls.add('createFile');
            throw failure;
          },
          exists: (_) => throw StateError('must not run'),
          isDirectory: (_) => throw StateError('must not run'),
          listFiles: (_) => null,
          canonicalPath: (_) => '/unused',
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['createFile']);
    });
  });

  group('Directory.listFiles', () {
    test('returns the exact non-null host list after one call', () {
      final file = Object();
      final files = [Object(), Object()];
      var calls = 0;
      final directory = Directory.createInstanceFromFile<Object>(
        file: file,
        exists: (_) => true,
        isDirectory: (_) => true,
        listFiles: (actualFile) {
          calls++;
          expect(actualFile, same(file));
          return files;
        },
        canonicalPath: (_) => '/unused',
      )!;

      expect(directory.listFiles(), same(files));
      expect(calls, 1);
    });

    test('returns a fresh empty list for each null host result', () {
      final directory = Directory.createInstanceFromFile<Object>(
        file: Object(),
        exists: (_) => true,
        isDirectory: (_) => true,
        listFiles: (_) => null,
        canonicalPath: (_) => '/unused',
      )!;

      final first = directory.listFiles();
      final second = directory.listFiles();

      expect(first, isEmpty);
      expect(second, isEmpty);
      expect(first, isNot(same(second)));
      first.add(Object());
      expect(second, isEmpty);
    });

    test('propagates host listing failures unchanged', () {
      final failure = Object();
      var calls = 0;
      final directory = Directory.createInstanceFromFile<Object>(
        file: Object(),
        exists: (_) => true,
        isDirectory: (_) => true,
        listFiles: (_) {
          calls++;
          throw failure;
        },
        canonicalPath: (_) => '/unused',
      )!;

      expect(() => directory.listFiles(), throwsA(same(failure)));
      expect(calls, 1);
    });
  });

  group('Directory.toString', () {
    test(
      'reads canonical path on every call without normalizing supplied text',
      () {
        final file = Object();
        final paths = ['../dir/./child', '/canonical/second'];
        final calls = <Object>[];
        var index = 0;
        final directory = Directory.createInstanceFromFile<Object>(
          file: file,
          exists: (_) => true,
          isDirectory: (_) => true,
          listFiles: (_) => null,
          canonicalPath: (actualFile) {
            calls.add(actualFile);
            return paths[index++];
          },
        )!;

        expect(directory.toString(), paths[0]);
        expect(directory.toString(), paths[1]);
        expect(calls, everyElement(same(file)));
        expect(calls, hasLength(2));
      },
    );

    test('propagates canonical path failures unchanged', () {
      final failure = Object();
      var calls = 0;
      final directory = Directory.createInstanceFromFile<Object>(
        file: Object(),
        exists: (_) => true,
        isDirectory: (_) => true,
        listFiles: (_) => null,
        canonicalPath: (_) {
          calls++;
          throw failure;
        },
      )!;

      expect(() => directory.toString(), throwsA(same(failure)));
      expect(calls, 1);
    });
  });
}
