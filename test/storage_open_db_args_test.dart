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
 * Source-derived from Storage.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenDbArgs', () {
    test('Path checks existence once and negates the result', () {
      final file = Object();
      final calls = <Object>[];
      for (final (exists, expected) in [(true, false), (false, true)]) {
        calls.clear();
        final args = OpenDbPath(
          file,
          exists: (candidate) {
            calls.add(candidate);
            return exists;
          },
          absolutePath: (_) => fail('absolutePath is not read here'),
        );

        expect(args.isNewDatabase(), expected);
        expect(calls, [same(file)]);
      }
    });

    test('Path propagates the identical exists failure', () {
      final error = StateError('exists failed');
      final args = OpenDbPath(
        Object(),
        exists: (_) => throw error,
        absolutePath: (_) => fail('absolutePath is not read here'),
      );

      expect(() => args.isNewDatabase(), throwsA(same(error)));
    });

    test(
      'collectionPath returns the exact host path and propagates failures',
      () {
        final file = Object();
        final calls = <Object>[];
        final args = OpenDbPath(
          file,
          exists: (_) => fail('exists is not read here'),
          absolutePath: (candidate) {
            calls.add(candidate);
            return r'/host/path/../collection.anki2';
          },
        );

        expect(args.collectionPath, r'/host/path/../collection.anki2');
        expect(calls, [same(file)]);

        final error = StateError('absolutePath failed');
        final failingArgs = OpenDbPath(
          file,
          exists: (_) => fail('exists is not read here'),
          absolutePath: (_) => throw error,
        );
        expect(() => failingArgs.collectionPath, throwsA(same(error)));
      },
    );

    test(
      'InMemory is canonical and returns source constants without callbacks',
      () {
        expect(OpenDbInMemory.instance, same(OpenDbInMemory.instance));
        expect(OpenDbInMemory.instance.isNewDatabase(), isTrue);
        expect(OpenDbInMemory.instance.collectionPath, ':memory:');
      },
    );

    test('Path equality and copy preserve the source File value component', () {
      final file = _FileValue('collection');
      bool exists(Object candidate) => false;
      String absolutePath(Object candidate) => '/collection';
      final original = OpenDbPath(
        file,
        exists: exists,
        absolutePath: absolutePath,
      );
      final equal = OpenDbPath(
        _FileValue('collection'),
        exists: (_) => true,
        absolutePath: (_) => '/different',
      );
      final copy = original.copyWith(path: _FileValue('collection'));

      expect(original, equal);
      expect(original.hashCode, equal.hashCode);
      expect(copy, original);
      expect(copy.exists, same(exists));
      expect(copy.absolutePath, same(absolutePath));
    });
  });
}

final class _FileValue {
  const _FileValue(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is _FileValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
