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
 * Behavioral reference: MediaCheckViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Media Check missing tagging plan', () {
    test('preserves missing note IDs and tag under adding-tags progress', () {
      final noteIds = [17, 29];
      const tag = 'missing';

      final plan = planMediaCheckMissingTagging(noteIds, tag);

      expect(plan.progress, MediaCheckProgress.addingTags);
      expect(plan.bulkAddEffect.noteIds, same(noteIds));
      expect(plan.bulkAddEffect.tag, tag);
    });

    test('keeps an explicitly empty missing-note list empty', () {
      final plan = planMediaCheckMissingTagging([], 'missing');

      expect(plan.bulkAddEffect.noteIds, isEmpty);
      expect(plan.completeBulkAdd(succeeded: true, taggedCount: 0)!.count, 0);
    });

    test('uses an empty missing-note list when the current result is null', () {
      final plan = planMediaCheckMissingTagging(null, 'missing');

      expect(plan.bulkAddEffect.noteIds, isEmpty);
      expect(plan.progress, MediaCheckProgress.addingTags);
      expect(plan.bulkAddEffect.tag, 'missing');
    });

    test('publishes the host result count only after bulk-add succeeds', () {
      final plan = planMediaCheckMissingTagging([17, 29], 'missing');

      expect(plan.completeBulkAdd(succeeded: true, taggedCount: 5)!.count, 5);
      expect(plan.completeBulkAdd(succeeded: false, taggedCount: 0), isNull);
    });
  });
}
