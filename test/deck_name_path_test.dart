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
 * Behavioral reference: Decks.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('deck name paths', () {
    test('matches split, basename, and immediate parent projections', () {
      expect(deckNamePath('Science::Math::Algebra'), [
        'Science',
        'Math',
        'Algebra',
      ]);
      expect(deckNameBasename('Science::Math::Algebra'), 'Algebra');
      expect(immediateParentDeckNamePath('Science::Math::Algebra'), [
        'Science',
        'Math',
      ]);
      expect(
        immediateParentDeckName('Science::Math::Algebra'),
        'Science::Math',
      );

      expect(deckNamePath('Science'), ['Science']);
      expect(deckNameBasename('Science'), 'Science');
      expect(immediateParentDeckNamePath('Science'), isEmpty);
      expect(immediateParentDeckName('Science'), isNull);

      expect(deckNamePath('::Science'), ['', 'Science']);
      expect(deckNameBasename('::Science'), 'Science');
      expect(immediateParentDeckNamePath('::Science'), ['']);
      expect(immediateParentDeckName('::Science'), '');

      expect(deckNamePath('Science::::Algebra'), ['Science', '', 'Algebra']);
      expect(deckNameBasename('Science::::Algebra'), 'Algebra');
      expect(immediateParentDeckNamePath('Science::::Algebra'), [
        'Science',
        '',
      ]);
      expect(immediateParentDeckName('Science::::Algebra'), 'Science::');

      expect(deckNamePath('Science::'), ['Science', '']);
      expect(deckNameBasename('Science::'), '');
      expect(immediateParentDeckNamePath('Science::'), ['Science']);
      expect(immediateParentDeckName('Science::'), 'Science');

      expect(deckNamePath(''), ['']);
      expect(deckNameBasename(''), '');
      expect(immediateParentDeckNamePath(''), isEmpty);
      expect(immediateParentDeckName(''), isNull);
    });
  });
}
