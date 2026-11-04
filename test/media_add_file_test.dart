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
  group('Media.addFile', () {
    test('rejects an empty file before all later callbacks', () {
      final file = Object();
      final events = <String>[];

      expect(
        () => Media.addFile<Object, List<int>, Object, Object>(
          file,
          fileLength: (value) {
            events.add('length');
            expect(identical(value, file), isTrue);
            return 0;
          },
          fileName: (_) {
            events.add('name');
            return 'unused';
          },
          readBytes: (_) {
            events.add('readBytes');
            return <int>[];
          },
          toByteString: (_) {
            events.add('toByteString');
            return Object();
          },
          addMediaFile: ({required desiredName, required data}) {
            events.add('addMediaFile');
            return Object();
          },
        ),
        throwsA(isA<EmptyMediaException>()),
      );
      expect(events, ['length']);
    });

    test('preserves callback order, values, and backend result identity', () {
      final file = Object();
      final bytes = <int>[1, 2, 3];
      final byteString = Object();
      final result = Object();
      final events = <String>[];

      final actual = Media.addFile<Object, List<int>, Object, Object>(
        file,
        fileLength: (value) {
          events.add('length');
          expect(identical(value, file), isTrue);
          return 3;
        },
        fileName: (value) {
          events.add('name');
          expect(identical(value, file), isTrue);
          return 'photo.jpg';
        },
        readBytes: (value) {
          events.add('readBytes');
          expect(identical(value, file), isTrue);
          return bytes;
        },
        toByteString: (value) {
          events.add('toByteString');
          expect(identical(value, bytes), isTrue);
          return byteString;
        },
        addMediaFile: ({required desiredName, required data}) {
          events.add('addMediaFile');
          expect(desiredName, 'photo.jpg');
          expect(identical(data, byteString), isTrue);
          return result;
        },
      );

      expect(events, [
        'length',
        'name',
        'readBytes',
        'toByteString',
        'addMediaFile',
      ]);
      expect(identical(actual, result), isTrue);
    });

    test(
      'propagates each callback failure unchanged and stops the sequence',
      () {
        final file = Object();
        final lengthFailure = StateError('length failed');
        final nameFailure = StateError('name failed');
        final bytesFailure = StateError('read failed');
        final conversionFailure = StateError('conversion failed');
        final backendFailure = StateError('backend failed');

        void expectFailure(
          Object failure, {
          required int length,
          required int failingStage,
        }) {
          final events = <String>[];
          expect(
            () => Media.addFile<Object, List<int>, Object, Object>(
              file,
              fileLength: (_) {
                events.add('length');
                if (failingStage == 0) throw failure;
                return length;
              },
              fileName: (_) {
                events.add('name');
                if (failingStage == 1) throw failure;
                return 'photo.jpg';
              },
              readBytes: (_) {
                events.add('readBytes');
                if (failingStage == 2) throw failure;
                return <int>[1];
              },
              toByteString: (_) {
                events.add('toByteString');
                if (failingStage == 3) throw failure;
                return Object();
              },
              addMediaFile: ({required desiredName, required data}) {
                events.add('addMediaFile');
                if (failingStage == 4) throw failure;
                return Object();
              },
            ),
            throwsA(same(failure)),
          );
          expect(events.length, failingStage + 1);
        }

        expectFailure(lengthFailure, length: 1, failingStage: 0);
        expectFailure(nameFailure, length: 1, failingStage: 1);
        expectFailure(bytesFailure, length: 1, failingStage: 2);
        expectFailure(conversionFailure, length: 1, failingStage: 3);
        expectFailure(backendFailure, length: 1, failingStage: 4);
      },
    );
  });
}
