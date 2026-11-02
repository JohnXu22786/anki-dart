/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * Source-derived from View.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('isTouchWithinBounds', () {
    test('uses View origin and all drawing rectangle edges', () {
      expect(
        _hit(
          viewLeft: 100,
          viewTop: 200,
          left: 4,
          top: 5,
          right: 7,
          bottom: 8,
          x: -94,
          y: -194,
        ),
        isTrue,
      );
      expect(
        _hit(
          viewLeft: 100,
          viewTop: 200,
          left: 4,
          top: 5,
          right: 7,
          bottom: 8,
          x: -97,
          y: -197,
        ),
        isFalse,
      );
    });

    test('includes left/top and excludes right/bottom edges', () {
      expect(
        _hit(viewLeft: 10, viewTop: 20, right: 4, bottom: 5, x: -10, y: -20),
        isTrue,
      );
      expect(
        _hit(viewLeft: 10, viewTop: 20, right: 4, bottom: 5, x: -6, y: -15),
        isFalse,
      );
      expect(
        _hit(viewLeft: 10, viewTop: 20, right: 4, bottom: 5, x: -7, y: -16),
        isTrue,
      );
      expect(_hit(right: 0, x: 0, y: 0), isFalse);
    });

    test('truncates positive and negative fractions toward zero', () {
      expect(_hit(right: 1, bottom: 1, x: -0.9, y: -0.9), isTrue);
      expect(_hit(right: 4, bottom: 4, x: 3.9, y: 3.9), isTrue);
    });

    test('uses Float32 rounding for the Int conversion and addition', () {
      expect(
        _hit(viewLeft: 16777217, right: 1, bottom: 1, x: -16777216, y: 0),
        isTrue,
      );
      expect(
        _hit(
          viewLeft: 16777216,
          left: 16777217,
          right: 16777218,
          bottom: 1,
          x: 1,
          y: 0,
        ),
        isFalse,
      );
    });

    test('uses Kotlin Float.toInt NaN and Int32 saturation behavior', () {
      expect(_hit(right: 1, bottom: 1, x: double.nan, y: double.nan), isTrue);
      expect(
        _hit(
          left: -2147483648,
          top: -2147483648,
          right: -2147483647,
          bottom: -2147483647,
          x: double.negativeInfinity,
          y: double.negativeInfinity,
        ),
        isTrue,
      );
      expect(
        _hit(
          left: 2147483646,
          top: 2147483646,
          right: 2147483647,
          bottom: 2147483647,
          x: double.infinity,
          y: double.infinity,
        ),
        isFalse,
      );
    });
  });
}

bool _hit({
  int viewLeft = 0,
  int viewTop = 0,
  int left = 0,
  int top = 0,
  int right = 10,
  int bottom = 10,
  required double x,
  required double y,
}) => isTouchWithinBounds(
  viewLeft: viewLeft,
  viewTop: viewTop,
  drawingLeft: left,
  drawingTop: top,
  drawingRight: right,
  drawingBottom: bottom,
  eventX: x,
  eventY: y,
);
