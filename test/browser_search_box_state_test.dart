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
 * Source-derived cases for CardBrowserViewModel search-box state transitions;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search box state', () {
    test('expanding preserves unsubmitted text', () {
      final changes = setBrowserSearchQueryExpanded(true);

      expect(changes, hasLength(1));
      expect(changes.single, isA<BrowserSearchBoxExpansionChange>());
      expect(
        (changes.single as BrowserSearchBoxExpansionChange).isExpanded,
        isTrue,
      );
    });

    test('collapsing clears text before setting expanded false', () {
      final changes = setBrowserSearchQueryExpanded(false);

      expect(changes.map((change) => change.runtimeType), [
        BrowserSearchBoxInputChange,
        BrowserSearchBoxExpansionChange,
      ]);
      expect((changes.first as BrowserSearchBoxInputChange).text, isNull);
      expect(
        (changes.last as BrowserSearchBoxExpansionChange).isExpanded,
        isFalse,
      );
    });

    test('query text replacement preserves expansion and exact text', () {
      final withText = updateBrowserSearchQueryText('  exact\n');
      final withEmptyText = updateBrowserSearchQueryText('');

      expect(withText, hasLength(1));
      expect(
        (withText.single as BrowserSearchBoxInputChange).text,
        '  exact\n',
      );
      expect((withEmptyText.single as BrowserSearchBoxInputChange).text, '');
    });

    test('removing unsubmitted input preserves expansion', () {
      final changes = removeBrowserUnsubmittedInput();

      expect(changes, hasLength(1));
      expect((changes.single as BrowserSearchBoxInputChange).text, isNull);
    });
  });
}
