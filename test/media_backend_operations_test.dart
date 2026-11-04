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
 * Source-derived from Media.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

class _RecordingList extends ListBase<String> {
  _RecordingList(this.calls, this.values);

  final List<String> calls;
  final List<String> values;

  @override
  int get length {
    calls.add('size');
    return values.length;
  }

  @override
  set length(int value) => throw UnsupportedError('read-only');

  @override
  String operator [](int index) => values[index];

  @override
  void operator []=(int index, String value) =>
      throw UnsupportedError('read-only');
}

void main() {
  group('media backend forwarding', () {
    test('forwards values once and preserves source order and results', () {
      final calls = <String>[];
      final opaqueBytes = Object();
      final opaqueWriteResult = Object();
      final opaqueCheckResult = Object();
      final opaqueEmptyResult = Object();
      final opaqueRestoreResult = Object();
      final opaqueDirectory = Object();
      final files = _RecordingList(calls, ['one.png', 'two.mp3']);
      var pathReads = 0;
      var writeCalls = 0;
      var checkCalls = 0;
      var emptyCalls = 0;
      var resyncCalls = 0;
      var trashCalls = 0;
      var restoreCalls = 0;

      expect(
        Media.writeData<Object, Object>(
          'wanted.png',
          opaqueBytes,
          addMediaFile: ({required desiredName, required data}) {
            writeCalls++;
            calls.add('addMediaFile');
            expect(desiredName, 'wanted.png');
            expect(identical(data, opaqueBytes), isTrue);
            return opaqueWriteResult;
          },
        ),
        same(opaqueWriteResult),
      );
      expect(
        Media.check<Object>(
          checkMedia: () {
            checkCalls++;
            calls.add('checkMedia');
            return opaqueCheckResult;
          },
        ),
        same(opaqueCheckResult),
      );
      expect(
        Media.emptyTrash<Object>(
          emptyTrash: () {
            emptyCalls++;
            calls.add('emptyTrash');
            return opaqueEmptyResult;
          },
        ),
        same(opaqueEmptyResult),
      );
      Media.forceResync(
        collectionDbAbsolutePath: () {
          pathReads++;
          calls.add('absolutePath');
          return '/collection/collection.anki2';
        },
        removeMediaDb: ({required colPath}) {
          resyncCalls++;
          calls.add('removeMediaDb');
          expect(colPath, '/collection/collection.anki2');
        },
      );
      Media.trashFiles(
        files,
        mediaDirectory: () {
          calls.add('directory');
          return opaqueDirectory;
        },
        logInfo: (message, count, directory) {
          calls.add('logInfo');
          expect(message, 'Deleting %d file(s) from %s');
          expect(count, 2);
          expect(identical(directory, opaqueDirectory), isTrue);
        },
        trashMediaFiles: ({required fnames}) {
          trashCalls++;
          calls.add('trashMediaFiles');
          expect(identical(fnames, files), isTrue);
        },
      );
      expect(
        Media.restoreTrash<Object>(
          restoreTrash: () {
            restoreCalls++;
            calls.add('restoreTrash');
            return opaqueRestoreResult;
          },
        ),
        same(opaqueRestoreResult),
      );

      expect(calls, [
        'addMediaFile',
        'checkMedia',
        'emptyTrash',
        'absolutePath',
        'removeMediaDb',
        'size',
        'directory',
        'logInfo',
        'trashMediaFiles',
        'restoreTrash',
      ]);
      expect(writeCalls, 1);
      expect(checkCalls, 1);
      expect(emptyCalls, 1);
      expect(pathReads, 1);
      expect(resyncCalls, 1);
      expect(trashCalls, 1);
      expect(restoreCalls, 1);
    });

    test('host errors propagate and stop subsequent trash operations', () {
      final pathError = StateError('path failed');
      final backendError = StateError('backend failed');
      final directoryError = StateError('directory failed');
      final logError = StateError('log failed');
      var pathReads = 0;
      var removeCalls = 0;

      expect(
        () => Media.forceResync(
          collectionDbAbsolutePath: () {
            pathReads++;
            throw pathError;
          },
          removeMediaDb: ({required colPath}) => removeCalls++,
        ),
        throwsA(same(pathError)),
      );
      expect(pathReads, 1);
      expect(removeCalls, 0);

      expect(
        () => Media.forceResync(
          collectionDbAbsolutePath: () => '/collection/collection.anki2',
          removeMediaDb: ({required colPath}) => throw backendError,
        ),
        throwsA(same(backendError)),
      );

      expect(
        () => Media.check<Object>(checkMedia: () => throw backendError),
        throwsA(same(backendError)),
      );
      expect(
        () => Media.emptyTrash<Object>(emptyTrash: () => throw backendError),
        throwsA(same(backendError)),
      );
      expect(
        () =>
            Media.restoreTrash<Object>(restoreTrash: () => throw backendError),
        throwsA(same(backendError)),
      );

      final files = <String>['one.png'];
      final directoryCalls = <String>[];
      expect(
        () => Media.trashFiles(
          files,
          mediaDirectory: () {
            directoryCalls.add('directory');
            throw directoryError;
          },
          logInfo: (message, count, directory) => directoryCalls.add('logInfo'),
          trashMediaFiles: ({required fnames}) =>
              directoryCalls.add('trashMediaFiles'),
        ),
        throwsA(same(directoryError)),
      );
      expect(directoryCalls, ['directory']);

      expect(
        () => Media.trashFiles(
          files,
          mediaDirectory: () => Object(),
          logInfo: (message, count, directory) => throw logError,
          trashMediaFiles: ({required fnames}) =>
              directoryCalls.add('trashMediaFiles'),
        ),
        throwsA(same(logError)),
      );
      expect(directoryCalls, ['directory']);

      expect(
        () => Media.trashFiles(
          files,
          mediaDirectory: () => Object(),
          logInfo: (message, count, directory) {},
          trashMediaFiles: ({required fnames}) => throw backendError,
        ),
        throwsA(same(backendError)),
      );

      expect(
        () => Media.writeData<Object, Object>(
          'wanted.png',
          Object(),
          addMediaFile: ({required desiredName, required data}) =>
              throw backendError,
        ),
        throwsA(same(backendError)),
      );
    });
  });
}
