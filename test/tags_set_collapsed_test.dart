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
 * Source-derived adapter cases for Tags.setCollapsed(); see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('tagsSetCollapsed', () {
    test(
      'forwards the tag and collapsed value once and returns the result',
      () {
        final result = Object();
        var calls = 0;

        final actual = tagsSetCollapsed(
          tag: 'root::child',
          collapsed: true,
          setTagCollapsed: ({required name, required collapsed}) {
            calls++;
            expect(name, 'root::child');
            expect(collapsed, isTrue);
            return result;
          },
        );

        expect(calls, 1);
        expect(actual, same(result));
      },
    );

    test('propagates the exact backend exception', () {
      final failure = StateError('backend failed');

      expect(
        () => tagsSetCollapsed(
          tag: 'root',
          collapsed: false,
          setTagCollapsed: ({required name, required collapsed}) =>
              throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
