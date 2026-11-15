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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Card Browser EditSelection destination cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser note-editor destination', () {
    test('empty card IDs produce no destination', () {
      expect(
        browserEditNoteDestination(cardIds: const [], isFragmented: false),
        isNull,
      );
    });

    test('phone destination preserves IDs and uses the default transition', () {
      final cardIds = [5, 4, 5];

      final destination = browserEditNoteDestination(
        cardIds: cardIds,
        isFragmented: false,
      );

      expect(destination, isNotNull);
      expect(destination!.cardIds, same(cardIds));
      expect(destination.cardIds, [5, 4, 5]);
      expect(
        destination.animation,
        BrowserNoteEditorTransitionDirection.defaultDirection,
      );
      expect(destination.inCardBrowserActivity, isFalse);
    });

    test('fragmented destination is marked as inside the browser activity', () {
      final cardIds = [8, 3];

      final destination = browserEditNoteDestination(
        cardIds: cardIds,
        isFragmented: true,
      );

      expect(destination, isNotNull);
      expect(destination!.cardIds, same(cardIds));
      expect(destination.cardIds, [8, 3]);
      expect(
        destination.animation,
        BrowserNoteEditorTransitionDirection.defaultDirection,
      );
      expect(destination.inCardBrowserActivity, isTrue);
    });
  });
}
