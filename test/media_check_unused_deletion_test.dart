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
 * Source-derived from MediaCheckViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Media Check unused deletion plan', () {
    test('uses the supplied unused files and deleting progress', () {
      final unused = ['one.png', 'two.webp'];

      final plan = planMediaCheckUnusedDeletion(unused);

      expect(plan.progress, MediaCheckProgress.deletingMedia);
      expect(plan.trashEffect.files, same(unused));
    });

    test('keeps an explicitly empty unused list empty', () {
      final plan = planMediaCheckUnusedDeletion([]);

      expect(plan.trashEffect.files, isEmpty);
      expect(plan.completeTrash(succeeded: true)!.count, 0);
    });

    test('uses an empty unused list when the current result is null', () {
      final plan = planMediaCheckUnusedDeletion(null);

      expect(plan.trashEffect.files, isEmpty);
      expect(plan.progress, MediaCheckProgress.deletingMedia);
    });

    test('publishes the deleted count only after trash succeeds', () {
      final plan = planMediaCheckUnusedDeletion(['one.png', 'two.webp']);

      expect(plan.completeTrash(succeeded: true)!.count, 2);
      expect(plan.completeTrash(succeeded: false), isNull);
    });
  });
}
