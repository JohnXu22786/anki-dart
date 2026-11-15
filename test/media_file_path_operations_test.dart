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
  group('Media.findUnusedMediaFiles', () {
    test(
      'checks once and eagerly preserves order, directory, and File identity',
      () {
        final response = Object();
        final directory = Object();
        final firstFile = Object();
        final secondFile = Object();
        final sourceNames = <String>['unused-b.png', 'unused-a.mp3'];
        final events = <String>[];
        var checkCalls = 0;
        var unusedListCalls = 0;
        var directoryCalls = 0;
        var fileCalls = 0;

        final result = Media.findUnusedMediaFiles<Object, Object, Object>(
          checkMedia: () {
            checkCalls++;
            events.add('check');
            return response;
          },
          unusedList: (actualResponse) {
            unusedListCalls++;
            events.add('unusedList');
            expect(identical(actualResponse, response), isTrue);
            return sourceNames;
          },
          mediaDirectory: () {
            directoryCalls++;
            events.add('directory');
            return directory;
          },
          file: (actualDirectory, filename) {
            fileCalls++;
            events.add('file:$filename');
            expect(identical(actualDirectory, directory), isTrue);
            return switch (filename) {
              'unused-b.png' => firstFile,
              'unused-a.mp3' => secondFile,
              _ => fail('unexpected filename: $filename'),
            };
          },
        );

        expect(events, [
          'check',
          'unusedList',
          'directory',
          'file:unused-b.png',
          'file:unused-a.mp3',
        ]);
        expect(checkCalls, 1);
        expect(unusedListCalls, 1);
        expect(directoryCalls, 1);
        expect(fileCalls, 2);
        expect(result, hasLength(2));
        expect(identical(result, sourceNames), isFalse);
        expect(identical(result[0], firstFile), isTrue);
        expect(identical(result[1], secondFile), isTrue);
      },
    );

    test(
      'does not resolve the lazy directory when no filenames are unused',
      () {
        final response = Object();
        final events = <String>[];

        final result = Media.findUnusedMediaFiles<Object, Object, Object>(
          checkMedia: () {
            events.add('check');
            return response;
          },
          unusedList: (actualResponse) {
            events.add('unusedList');
            expect(identical(actualResponse, response), isTrue);
            return <String>[];
          },
          mediaDirectory: () => throw StateError('directory must stay lazy'),
          file: (_, _) => throw StateError('no files should be constructed'),
        );

        expect(events, ['check', 'unusedList']);
        expect(result, isEmpty);
      },
    );

    test(
      'propagates check, unused-list, directory, and File failures unchanged',
      () {
        final response = Object();
        final checkError = StateError('check failed');
        final unusedListError = StateError('unused list failed');
        final directoryError = StateError('directory failed');
        final fileError = StateError('File construction failed');
        final calls = <String>[];

        expect(
          () => Media.findUnusedMediaFiles<Object, Object, Object>(
            checkMedia: () {
              calls.add('check');
              throw checkError;
            },
            unusedList: (_) {
              calls.add('unusedList');
              return <String>[];
            },
            mediaDirectory: () {
              calls.add('directory');
              return Object();
            },
            file: (_, _) => Object(),
          ),
          throwsA(same(checkError)),
        );
        expect(calls, ['check']);

        calls.clear();
        expect(
          () => Media.findUnusedMediaFiles<Object, Object, Object>(
            checkMedia: () {
              calls.add('check');
              return response;
            },
            unusedList: (_) {
              calls.add('unusedList');
              throw unusedListError;
            },
            mediaDirectory: () {
              calls.add('directory');
              return Object();
            },
            file: (_, _) => Object(),
          ),
          throwsA(same(unusedListError)),
        );
        expect(calls, ['check', 'unusedList']);

        calls.clear();
        expect(
          () => Media.findUnusedMediaFiles<Object, Object, Object>(
            checkMedia: () {
              calls.add('check');
              return response;
            },
            unusedList: (_) {
              calls.add('unusedList');
              return <String>['first.png'];
            },
            mediaDirectory: () {
              calls.add('directory');
              throw directoryError;
            },
            file: (_, _) {
              calls.add('file');
              return Object();
            },
          ),
          throwsA(same(directoryError)),
        );
        expect(calls, ['check', 'unusedList', 'directory']);

        calls.clear();
        expect(
          () => Media.findUnusedMediaFiles<Object, Object, Object>(
            checkMedia: () {
              calls.add('check');
              return response;
            },
            unusedList: (_) {
              calls.add('unusedList');
              return <String>['first.png', 'second.png'];
            },
            mediaDirectory: () {
              calls.add('directory');
              return Object();
            },
            file: (_, filename) {
              calls.add('file:$filename');
              throw fileError;
            },
          ),
          throwsA(same(fileError)),
        );
        expect(calls, ['check', 'unusedList', 'directory', 'file:first.png']);
      },
    );
  });

  group('Media.have', () {
    test(
      'constructs one host File, checks it once, and returns its boolean',
      () {
        final directory = Object();
        final file = Object();
        final events = <String>[];
        var directoryCalls = 0;
        var fileCalls = 0;
        var existsCalls = 0;

        final result = Media.have<Object, Object>(
          'photo.jpg',
          mediaDirectory: () {
            directoryCalls++;
            events.add('directory');
            return directory;
          },
          file: (actualDirectory, filename) {
            fileCalls++;
            events.add('file');
            expect(identical(actualDirectory, directory), isTrue);
            expect(filename, 'photo.jpg');
            return file;
          },
          exists: (actualFile) {
            existsCalls++;
            events.add('exists');
            expect(identical(actualFile, file), isTrue);
            return false;
          },
        );

        expect(result, isFalse);
        expect(events, ['directory', 'file', 'exists']);
        expect(directoryCalls, 1);
        expect(fileCalls, 1);
        expect(existsCalls, 1);
      },
    );

    test('propagates directory, File, and exists failures unchanged', () {
      final directoryError = StateError('directory failed');
      final fileError = StateError('File construction failed');
      final existsError = StateError('exists failed');
      final calls = <String>[];

      expect(
        () => Media.have<Object, Object>(
          'photo.jpg',
          mediaDirectory: () {
            calls.add('directory');
            throw directoryError;
          },
          file: (_, _) {
            calls.add('file');
            return Object();
          },
          exists: (_) {
            calls.add('exists');
            return true;
          },
        ),
        throwsA(same(directoryError)),
      );
      expect(calls, ['directory']);

      calls.clear();
      expect(
        () => Media.have<Object, Object>(
          'photo.jpg',
          mediaDirectory: () {
            calls.add('directory');
            return Object();
          },
          file: (_, _) {
            calls.add('file');
            throw fileError;
          },
          exists: (_) {
            calls.add('exists');
            return true;
          },
        ),
        throwsA(same(fileError)),
      );
      expect(calls, ['directory', 'file']);

      calls.clear();
      expect(
        () => Media.have<Object, Object>(
          'photo.jpg',
          mediaDirectory: () {
            calls.add('directory');
            return Object();
          },
          file: (_, _) {
            calls.add('file');
            return Object();
          },
          exists: (_) {
            calls.add('exists');
            throw existsError;
          },
        ),
        throwsA(same(existsError)),
      );
      expect(calls, ['directory', 'file', 'exists']);
    });
  });
}
