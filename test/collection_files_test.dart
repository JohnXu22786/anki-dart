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
 * Source-derived from CollectionFiles.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. The pinned source has no direct accessor tests.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('FolderBasedCollection', () {
    test('uses default name and preserves host child-construction order', () {
      final parent = Object();
      final calls = <(Object, String)>[];
      final results = <Object>[];
      final files = FolderBasedCollection(
        folderPath: parent,
        fileChild: (actualParent, child) {
          calls.add((actualParent, child));
          final result = Object();
          results.add(result);
          return result;
        },
      );

      expect(calls.map((call) => call.$2), [
        'collection.anki2',
        'collection.media',
        'collection.media.db',
      ]);
      expect(calls.every((call) => identical(call.$1, parent)), isTrue);
      expect(identical(files.colDb, results[0]), isTrue);
      expect(identical(files.mediaFolder, results[1]), isTrue);
      expect(identical(files.mediaDb, results[2]), isTrue);
    });

    test('uses a supplied collection name without interpreting host paths', () {
      final parent = Object();
      final names = <String>[];
      final files = FolderBasedCollection(
        folderPath: parent,
        collectionName: '../Profile/col',
        fileChild: (actualParent, child) {
          expect(identical(actualParent, parent), isTrue);
          names.add(child);
          return child;
        },
      );

      expect(names, [
        '../Profile/col.anki2',
        '../Profile/col.media',
        '../Profile/col.media.db',
      ]);
      expect(files.colDb, '../Profile/col.anki2');
      expect(files.mediaFolder, '../Profile/col.media');
      expect(files.mediaDb, '../Profile/col.media.db');
    });

    test(
      'propagates the exact child-construction failure and stops in order',
      () {
        final failure = Exception('host File failed');
        final calls = <String>[];

        expect(
          () => FolderBasedCollection(
            folderPath: Object(),
            fileChild: (_, child) {
              calls.add(child);
              if (calls.length == 2) throw failure;
              return Object();
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, ['collection.anki2', 'collection.media']);
      },
    );

    test(
      'disk accessors return the same collection and media folder objects',
      () {
        final media = Object();
        final files = FolderBasedCollection(
          folderPath: Object(),
          fileChild: (_, child) =>
              child == 'collection.media' ? media : Object(),
        );

        expect(identical(files.requireDiskBasedCollection(), files), isTrue);
        expect(identical(files.requireMediaFolder(), media), isTrue);
      },
    );
  });

  group('in-memory variants', () {
    test('InMemory is one stable singleton with no media folder', () {
      expect(identical(InMemory.instance, InMemory.instance), isTrue);
      expect(InMemory.instance.mediaFolder, isNull);
      expect(
        () => InMemory.instance.requireDiskBasedCollection(),
        throwsA(
          allOf(
            isA<Exception>(),
            isA<UnsupportedOperationException>().having(
              (error) => error.message,
              'message',
              'collection is in-memory',
            ),
          ),
        ),
      );
      expect(
        () => InMemory.instance.requireMediaFolder(),
        throwsA(
          allOf(
            isA<Exception>(),
            isA<UnsupportedOperationException>().having(
              (error) => error.message,
              'message',
              'collection is in-memory',
            ),
          ),
        ),
      );
    });

    test('separate InMemoryWithMedia instances keep regular identity', () {
      const media = Object();
      final first = InMemoryWithMedia(mediaFolder: media);
      final second = InMemoryWithMedia(mediaFolder: media);

      expect(identical(first, second), isFalse);
      expect(identical(first.mediaFolder, media), isTrue);
      expect(identical(second.mediaFolder, media), isTrue);
      expect(identical(first.requireMediaFolder(), media), isTrue);
      expect(
        () => first.requireDiskBasedCollection(),
        throwsA(
          allOf(
            isA<Exception>(),
            isA<UnsupportedOperationException>().having(
              (error) => error.message,
              'message',
              'collection is in-memory',
            ),
          ),
        ),
      );
    });
  });
}
