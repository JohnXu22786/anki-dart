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
 * Source-derived from CardTemplateEditor.kt and CardTemplateEditorTest.kt;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Template Editor noteTypeHasChanged', () {
    test('does not look up stored type before the temporary type exists', () {
      var lookups = 0;

      final changed = cardTemplateNoteTypeHasChanged(
        hasTemporaryNoteType: false,
        lookupStoredJsonEquality: () {
          lookups++;
          return false;
        },
      );

      expect(changed, isFalse);
      expect(lookups, 0);
    });

    test('returns changed when the single stored-type lookup is missing', () {
      var lookups = 0;

      final changed = cardTemplateNoteTypeHasChanged(
        hasTemporaryNoteType: true,
        lookupStoredJsonEquality: () {
          lookups++;
          return null;
        },
      );

      expect(changed, isTrue);
      expect(lookups, 1);
    });

    test('returns unchanged when the single JSON projection is equal', () {
      final calls = <String>[];

      final changed = cardTemplateNoteTypeHasChanged(
        hasTemporaryNoteType: true,
        lookupStoredJsonEquality: () {
          calls.add('lookup and compare');
          return true;
        },
      );

      expect(changed, isFalse);
      expect(calls, ['lookup and compare']);
    });

    test('returns changed when the single JSON projection differs', () {
      var lookups = 0;

      final changed = cardTemplateNoteTypeHasChanged(
        hasTemporaryNoteType: true,
        lookupStoredJsonEquality: () {
          lookups++;
          return false;
        },
      );

      expect(changed, isTrue);
      expect(lookups, 1);
    });

    test('detects a nested edit and clears the change after reversion', () {
      final equalityResults = <bool?>[true, false, true];
      var lookups = 0;

      final changedResults = [
        for (var i = 0; i < equalityResults.length; i++)
          cardTemplateNoteTypeHasChanged(
            hasTemporaryNoteType: true,
            lookupStoredJsonEquality: () {
              lookups++;
              return equalityResults[i];
            },
          ),
      ];

      expect(changedResults, [false, true, false]);
      expect(lookups, 3);
    });

    test('propagates the original lookup or equality callback exception', () {
      final error = StateError('host equality failed');

      expect(
        () => cardTemplateNoteTypeHasChanged(
          hasTemporaryNoteType: true,
          lookupStoredJsonEquality: () => throw error,
        ),
        throwsA(same(error)),
      );
    });
  });
}
