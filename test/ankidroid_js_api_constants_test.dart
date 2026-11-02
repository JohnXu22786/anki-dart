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
 * Source-derived constants from AnkiDroidJsAPIConstants.kt; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnkiDroid JS API constants', () {
    test('preserves every source error code', () {
      expect(
        [
          ANKI_JS_ERROR_CODE_ERROR,
          ANKI_JS_ERROR_CODE_DEFAULT,
          ANKI_JS_ERROR_CODE_MARK_CARD,
          ANKI_JS_ERROR_CODE_FLAG_CARD,
          ANKI_JS_ERROR_CODE_BURY_CARD,
          ANKI_JS_ERROR_CODE_SUSPEND_CARD,
          ANKI_JS_ERROR_CODE_BURT_NOTE,
          ANKI_JS_ERROR_CODE_SUSPEND_NOTE,
          ANKI_JS_ERROR_CODE_SET_DUE,
          ANKI_JS_ERROR_CODE_SEARCH_CARD,
        ],
        [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8],
      );
    });

    test('preserves current and minimum API version boundaries', () {
      expect(currentJsApiVersion, '0.0.3');
      expect(minimumJsApiVersion, '0.0.3');
    });

    test('preserves the ordered flag command table and nullable lookup', () {
      expect(flagCommands.keys.toList(), [
        'none',
        'red',
        'orange',
        'green',
        'blue',
        'pink',
        'turquoise',
        'purple',
      ]);
      expect(flagCommands.values.toList(), [
        ViewerCommand.UNSET_FLAG,
        ViewerCommand.TOGGLE_FLAG_RED,
        ViewerCommand.TOGGLE_FLAG_ORANGE,
        ViewerCommand.TOGGLE_FLAG_GREEN,
        ViewerCommand.TOGGLE_FLAG_BLUE,
        ViewerCommand.TOGGLE_FLAG_PINK,
        ViewerCommand.TOGGLE_FLAG_TURQUOISE,
        ViewerCommand.TOGGLE_FLAG_PURPLE,
      ]);
      expect(flagCommands['unknown'], isNull);
    });
  });
}
