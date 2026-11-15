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
 * Source-derived from BitmapDrawable.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('bitmapDrawableToBase64Png', () {
    test('preserves PNG compression, snapshot, encoding, and close order', () {
      final events = <String>[];
      final bitmap = Object();
      final pngFormat = Object();
      final defaultFlag = Object();
      final bytes = Uint8List.fromList([1, 2, 3]);
      final stream = _FakeBitmapPngOutputStream(events, bytes: bytes);
      final encoded = 'host base64 result';
      var createCount = 0;
      Uint8List? encodedBytes;
      Object? encodedFlag;

      final result = bitmapDrawableToBase64Png(
        bitmap: bitmap,
        pngFormat: pngFormat,
        base64Default: defaultFlag,
        createOutputStream: () {
          createCount++;
          events.add('create');
          return stream;
        },
        compress: (receivedBitmap, format, quality, outputStream) {
          events.add('compress');
          expect(identical(receivedBitmap, bitmap), isTrue);
          expect(identical(format, pngFormat), isTrue);
          expect(quality, 100);
          expect(identical(outputStream, stream), isTrue);
          return false;
        },
        encodeToString: (receivedBytes, flag) {
          events.add('encode');
          encodedBytes = receivedBytes;
          encodedFlag = flag;
          return encoded;
        },
      );

      expect(result, same(encoded));
      expect(createCount, 1);
      expect(stream.snapshotCount, 1);
      expect(identical(encodedBytes, bytes), isTrue);
      expect(identical(encodedFlag, defaultFlag), isTrue);
      expect(events, ['create', 'compress', 'snapshot', 'encode', 'close']);
    });

    test(
      'closes and preserves the original compression, snapshot, or encoder failure',
      () {
        for (final failedAt in ['compress', 'snapshot', 'encode']) {
          final events = <String>[];
          final failure = StateError('$failedAt failed');
          final stream = _FakeBitmapPngOutputStream(
            events,
            snapshotFailure: failedAt == 'snapshot' ? failure : null,
            closeFailure: failedAt == 'compress'
                ? StateError('close failed')
                : null,
          );

          expect(
            () => bitmapDrawableToBase64Png(
              bitmap: Object(),
              pngFormat: Object(),
              base64Default: Object(),
              createOutputStream: () {
                events.add('create');
                return stream;
              },
              compress: (_, _, _, _) {
                events.add('compress');
                if (failedAt == 'compress') throw failure;
                return true;
              },
              encodeToString: (_, _) {
                events.add('encode');
                if (failedAt == 'encode') throw failure;
                return 'unused';
              },
            ),
            throwsA(same(failure)),
            reason: '$failedAt failure identity must be preserved',
          );

          final expectedEvents = switch (failedAt) {
            'compress' => ['create', 'compress', 'close'],
            'snapshot' => ['create', 'compress', 'snapshot', 'close'],
            _ => ['create', 'compress', 'snapshot', 'encode', 'close'],
          };
          expect(events, expectedEvents);
          expect(stream.closeCount, 1);
        }
      },
    );

    test('propagates a close failure after success without closing twice', () {
      final events = <String>[];
      final failure = StateError('close failed');
      final stream = _FakeBitmapPngOutputStream(events, closeFailure: failure);

      expect(
        () => bitmapDrawableToBase64Png(
          bitmap: Object(),
          pngFormat: Object(),
          base64Default: Object(),
          createOutputStream: () {
            events.add('create');
            return stream;
          },
          compress: (_, _, _, _) {
            events.add('compress');
            return true;
          },
          encodeToString: (_, _) {
            events.add('encode');
            return 'encoded';
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['create', 'compress', 'snapshot', 'encode', 'close']);
      expect(stream.closeCount, 1);
    });
  });
}

final class _FakeBitmapPngOutputStream implements BitmapPngOutputStream {
  _FakeBitmapPngOutputStream(
    this.events, {
    Uint8List? bytes,
    this.snapshotFailure,
    this.closeFailure,
  }) : bytes = bytes ?? Uint8List(0);

  final List<String> events;
  final Uint8List bytes;
  final Object? snapshotFailure;
  final Object? closeFailure;
  int snapshotCount = 0;
  int closeCount = 0;

  @override
  Object get hostOutputStream => this;

  @override
  Uint8List toByteArray() {
    snapshotCount++;
    events.add('snapshot');
    if (snapshotFailure != null) throw snapshotFailure!;
    return bytes;
  }

  @override
  void close() {
    closeCount++;
    events.add('close');
    if (closeFailure != null) throw closeFailure!;
  }
}
