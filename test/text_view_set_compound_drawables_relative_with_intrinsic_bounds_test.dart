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
 * Source-derived from TextView.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('textViewSetCompoundDrawablesRelativeWithIntrinsicBounds', () {
    test('defaults each omitted resource ID to zero', () {
      final textView = Object();
      final calls = <List<Object?>>[];

      textViewSetCompoundDrawablesRelativeWithIntrinsicBounds(
        textView: textView,
        setCompoundDrawablesRelativeWithIntrinsicBounds:
            (receivedTextView, start, top, end, bottom) {
              calls.add([receivedTextView, start, top, end, bottom]);
            },
      );

      expect(calls, hasLength(1));
      expect(identical(calls.single.first, textView), isTrue);
      expect(calls.single.skip(1), [0, 0, 0, 0]);
    });

    test(
      'forwards explicit resource IDs once in start-top-end-bottom order',
      () {
        final textView = Object();
        final calls = <List<Object?>>[];

        textViewSetCompoundDrawablesRelativeWithIntrinsicBounds(
          textView: textView,
          start: 11,
          top: 22,
          end: 33,
          bottom: 44,
          setCompoundDrawablesRelativeWithIntrinsicBounds:
              (receivedTextView, start, top, end, bottom) {
                calls.add([receivedTextView, start, top, end, bottom]);
              },
        );

        expect(calls, hasLength(1));
        expect(identical(calls.single.first, textView), isTrue);
        expect(calls.single.skip(1), [11, 22, 33, 44]);
      },
    );

    test('propagates host callback failures unchanged', () {
      final failure = StateError('TextView callback failed');

      expect(
        () => textViewSetCompoundDrawablesRelativeWithIntrinsicBounds(
          textView: Object(),
          setCompoundDrawablesRelativeWithIntrinsicBounds: (_, _, _, _, _) {
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
    });
  });
}
