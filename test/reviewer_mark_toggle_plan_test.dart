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
 * Source-derived Reviewer mark-toggle cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer mark-toggle plan', () {
    test('reads and publishes the state after toggling the note', () {
      final plan = planReviewerMarkToggle();
      final read = plan.readStateAfterToggle(succeeded: true)!;
      final publication = plan.publicationAfterRead(
        readEffect: read,
        succeeded: true,
        isMarked: true,
      )!;

      expect(
        [
          plan.toggleEffect,
          read,
          publication,
        ].map((effect) => effect.runtimeType),
        [
          ReviewerToggleMarkEffect,
          ReviewerReadMarkStateEffect,
          ReviewerPublishMarkStateEffect,
        ],
      );
      expect(publication.isMarked, isTrue);
    });

    test(
      'a failed toggle skips reading and a failed read skips publication',
      () {
        final plan = planReviewerMarkToggle();

        expect(plan.readStateAfterToggle(succeeded: false), isNull);
        expect(
          plan.publicationAfterRead(
            readEffect: plan.readStateAfterToggle(succeeded: true)!,
            succeeded: false,
            isMarked: true,
          ),
          isNull,
        );
      },
    );
  });
}
