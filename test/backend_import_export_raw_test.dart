/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from BackendImportExport.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BackendImportExportRaw', () {
    test(
      'getImportAnkiPackagePresetsRaw forwards and returns callback values',
      () {
        final calls = <String>[];
        final input = Uint8List.fromList([0, 1, 255]);
        final result = Uint8List.fromList([9, 0, 8]);
        final failure = StateError('backend failure');
        var shouldThrow = false;
        final backend = BackendImportExportRaw(
          BackendImportExportRawCallbacks(
            getImportAnkiPackagePresetsRaw: (bytes) {
              calls.add('getImportAnkiPackagePresetsRaw');
              expect(bytes, same(input));
              if (shouldThrow) throw failure;
              return result;
            },
            getCsvMetadataRaw: (_) => throw StateError('unexpected callback'),
            importCsvRaw: (_) => throw StateError('unexpected callback'),
          ),
        );

        expect(backend.getImportAnkiPackagePresetsRaw(input), same(result));
        expect(calls, ['getImportAnkiPackagePresetsRaw']);

        shouldThrow = true;
        expect(
          () => backend.getImportAnkiPackagePresetsRaw(input),
          throwsA(same(failure)),
        );
        expect(calls, [
          'getImportAnkiPackagePresetsRaw',
          'getImportAnkiPackagePresetsRaw',
        ]);
      },
    );

    test('getCsvMetadataRaw forwards and returns callback values', () {
      final calls = <String>[];
      final input = Uint8List.fromList([2, 0, 254]);
      final result = Uint8List.fromList([7, 6, 0]);
      final failure = StateError('backend failure');
      var shouldThrow = false;
      final backend = BackendImportExportRaw(
        BackendImportExportRawCallbacks(
          getImportAnkiPackagePresetsRaw: (_) =>
              throw StateError('unexpected callback'),
          getCsvMetadataRaw: (bytes) {
            calls.add('getCsvMetadataRaw');
            expect(bytes, same(input));
            if (shouldThrow) throw failure;
            return result;
          },
          importCsvRaw: (_) => throw StateError('unexpected callback'),
        ),
      );

      expect(backend.getCsvMetadataRaw(input), same(result));
      expect(calls, ['getCsvMetadataRaw']);

      shouldThrow = true;
      expect(() => backend.getCsvMetadataRaw(input), throwsA(same(failure)));
      expect(calls, ['getCsvMetadataRaw', 'getCsvMetadataRaw']);
    });

    test('importCsvRaw forwards and returns callback values', () {
      final calls = <String>[];
      final input = Uint8List.fromList([3, 255, 4]);
      final result = Uint8List.fromList([0, 5, 255]);
      final failure = StateError('backend failure');
      var shouldThrow = false;
      final backend = BackendImportExportRaw(
        BackendImportExportRawCallbacks(
          getImportAnkiPackagePresetsRaw: (_) =>
              throw StateError('unexpected callback'),
          getCsvMetadataRaw: (_) => throw StateError('unexpected callback'),
          importCsvRaw: (bytes) {
            calls.add('importCsvRaw');
            expect(bytes, same(input));
            if (shouldThrow) throw failure;
            return result;
          },
        ),
      );

      expect(backend.importCsvRaw(input), same(result));
      expect(calls, ['importCsvRaw']);

      shouldThrow = true;
      expect(() => backend.importCsvRaw(input), throwsA(same(failure)));
      expect(calls, ['importCsvRaw', 'importCsvRaw']);
    });
  });
}
