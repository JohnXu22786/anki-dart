/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from Context.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('getSizeOfBitmapFromCollection', () {
    test(
      'preserves source order and projects bounds despite a null decode',
      () {
        final context = Object();
        final directory = Object();
        final file = Object();
        final options = Object();
        final events = <String>[];

        final result = getSizeOfBitmapFromCollection(
          context: context,
          filename: 'collection/media/image.png',
          getCurrentAnkiDroidDirectory: (actualContext) {
            expect(actualContext, same(context));
            events.add('directory');
            return directory;
          },
          createFile: (actualDirectory, filename) {
            expect(actualDirectory, same(directory));
            expect(filename, 'collection/media/image.png');
            events.add('file');
            return file;
          },
          fileExists: (actualFile) {
            expect(actualFile, same(file));
            events.add('exists');
            return true;
          },
          createBitmapFactoryOptions: () {
            events.add('options');
            return options;
          },
          setInJustDecodeBounds: (actualOptions, value) {
            expect(actualOptions, same(options));
            expect(value, isTrue);
            events.add('bounds');
          },
          getAbsolutePath: (actualFile) {
            expect(actualFile, same(file));
            events.add('absolutePath');
            return '/collection/media/image.png';
          },
          decodeFile: (path, actualOptions) {
            expect(path, '/collection/media/image.png');
            expect(actualOptions, same(options));
            events.add('decode');
            return null;
          },
          getOutWidth: (actualOptions) {
            expect(actualOptions, same(options));
            events.add('width');
            return 640;
          },
          getOutHeight: (actualOptions) {
            expect(actualOptions, same(options));
            events.add('height');
            return 480;
          },
        );

        expect(result, const BitmapSize(640, 480));
        expect(events, [
          'directory',
          'file',
          'exists',
          'options',
          'bounds',
          'absolutePath',
          'decode',
          'width',
          'height',
        ]);
      },
    );

    test('returns null for a missing file before creating options', () {
      final events = <String>[];
      final result = getSizeOfBitmapFromCollection(
        context: Object(),
        filename: 'missing.png',
        getCurrentAnkiDroidDirectory: (_) {
          events.add('directory');
          return Object();
        },
        createFile: (_, _) {
          events.add('file');
          return Object();
        },
        fileExists: (_) {
          events.add('exists');
          return false;
        },
        createBitmapFactoryOptions: () => fail('must not create options'),
        setInJustDecodeBounds: (_, _) => fail('must not set bounds'),
        getAbsolutePath: (_) => fail('must not read the path'),
        decodeFile: (_, _) => fail('must not decode'),
        getOutWidth: (_) => fail('must not read width'),
        getOutHeight: (_) => fail('must not read height'),
      );

      expect(result, isNull);
      expect(events, ['directory', 'file', 'exists']);
    });

    test('propagates each callback failure and skips later operations', () {
      const stages = [
        'directory',
        'file',
        'exists',
        'options',
        'bounds',
        'absolutePath',
        'decode',
        'width',
        'height',
      ];

      for (final failedStage in stages) {
        final failure = StateError(failedStage);
        final events = <String>[];

        T invoke<T>(String stage, T Function() body) {
          events.add(stage);
          if (stage == failedStage) throw failure;
          return body();
        }

        expect(
          () => getSizeOfBitmapFromCollection(
            context: Object(),
            filename: 'image.png',
            getCurrentAnkiDroidDirectory: (_) =>
                invoke('directory', Object.new),
            createFile: (_, _) => invoke('file', Object.new),
            fileExists: (_) => invoke('exists', () => true),
            createBitmapFactoryOptions: () => invoke('options', Object.new),
            setInJustDecodeBounds: (_, _) => invoke('bounds', () {}),
            getAbsolutePath: (_) => invoke('absolutePath', () => '/image.png'),
            decodeFile: (_, _) => invoke('decode', () => null),
            getOutWidth: (_) => invoke('width', () => 1),
            getOutHeight: (_) => invoke('height', () => 2),
          ),
          throwsA(same(failure)),
          reason: 'failure at $failedStage must propagate unchanged',
        );

        expect(events, stages.take(stages.indexOf(failedStage) + 1));
      }
    });
  });

  group('BitmapSize', () {
    test('has Kotlin data-class value equality and projections', () {
      final size = BitmapSize(-1, 480);
      final equalSize = BitmapSize(-1, 480);
      final differentSize = BitmapSize(480, -1);

      expect(identical(size, equalSize), isFalse);
      expect(size, equalSize);
      expect(size.hashCode, equalSize.hashCode);
      expect(size.hashCode, 449);
      expect(size, isNot(differentSize));
      expect(size.copy(), size);
      expect(size.copy(width: 640), const BitmapSize(640, 480));
      expect(size.component1(), -1);
      expect(size.component2(), 480);
      expect(size.toString(), 'BitmapSize(width=-1, height=480)');
    });
  });
}
