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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentGetCurrentCardTemplateIndex', () {
    test('requires arguments once before reading the exact index once', () {
      final events = <String>[];
      final arguments = Object();
      var requireCount = 0;
      var readCount = 0;

      final result = cardTemplateFragmentGetCurrentCardTemplateIndex<Object>(
        requireArguments: () {
          requireCount++;
          events.add('require arguments');
          return arguments;
        },
        readCardIndex: (value) {
          readCount++;
          expect(value, same(arguments));
          events.add('get CARD_INDEX');
          return -2147483648;
        },
      );

      expect(result, -2147483648);
      expect(requireCount, 1);
      expect(readCount, 1);
      expect(events, ['require arguments', 'get CARD_INDEX']);
    });

    test('propagates either host callback failure unchanged', () {
      final requireFailure = StateError('require arguments');
      final requireEvents = <String>[];
      expect(
        () => cardTemplateFragmentGetCurrentCardTemplateIndex<Object>(
          requireArguments: () {
            requireEvents.add('require arguments');
            throw requireFailure;
          },
          readCardIndex: (_) {
            requireEvents.add('get CARD_INDEX');
            return 4;
          },
        ),
        throwsA(same(requireFailure)),
      );
      expect(requireEvents, ['require arguments']);

      final readFailure = StateError('get CARD_INDEX');
      final readEvents = <String>[];
      expect(
        () => cardTemplateFragmentGetCurrentCardTemplateIndex<Object>(
          requireArguments: () {
            readEvents.add('require arguments');
            return Object();
          },
          readCardIndex: (_) {
            readEvents.add('get CARD_INDEX');
            throw readFailure;
          },
        ),
        throwsA(same(readFailure)),
      );
      expect(readEvents, ['require arguments', 'get CARD_INDEX']);
    });
  });
}
