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
 * Source-derived ViewerRefresh updateState cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ViewerRefresh.updateState', () {
    test('returns null when there are no changes and no current state', () {
      expect(
        ViewerRefresh.updateState(
          currentState: null,
          studyQueues: false,
          noteText: false,
          card: false,
        ),
        isNull,
      );
    });

    test(
      'returns the existing object by identity when there are no changes',
      () {
        const current = ViewerRefresh(queues: true, note: false, card: true);

        expect(
          ViewerRefresh.updateState(
            currentState: current,
            studyQueues: false,
            noteText: false,
            card: false,
          ),
          same(current),
        );
      },
    );

    test('maps each incoming flag to its matching output', () {
      for (final (studyQueues, noteText, card) in [
        (true, false, false),
        (false, true, false),
        (false, false, true),
      ]) {
        expect(
          ViewerRefresh.updateState(
            currentState: null,
            studyQueues: studyQueues,
            noteText: noteText,
            card: card,
          ),
          ViewerRefresh(queues: studyQueues, note: noteText, card: card),
        );
      }
    });

    test('preserves simultaneous incoming flags', () {
      expect(
        ViewerRefresh.updateState(
          currentState: null,
          studyQueues: true,
          noteText: true,
          card: true,
        ),
        const ViewerRefresh(queues: true, note: true, card: true),
      );
    });

    test('accumulates prior true flags with new changes', () {
      const current = ViewerRefresh(queues: true, note: false, card: true);

      expect(
        ViewerRefresh.updateState(
          currentState: current,
          studyQueues: false,
          noteText: true,
          card: false,
        ),
        const ViewerRefresh(queues: true, note: true, card: true),
      );
    });

    test('creates a fresh state object when changes are present', () {
      const current = ViewerRefresh(queues: false, note: false, card: false);
      final updated = ViewerRefresh.updateState(
        currentState: current,
        studyQueues: true,
        noteText: false,
        card: false,
      );

      expect(updated, isNot(same(current)));
      expect(
        updated,
        const ViewerRefresh(queues: true, note: false, card: false),
      );
    });

    test('matches Kotlin data-class equality, hash, and string form', () {
      const first = ViewerRefresh(queues: true, note: false, card: true);
      const equal = ViewerRefresh(queues: true, note: false, card: true);
      const different = ViewerRefresh(queues: true, note: true, card: true);

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(different));
      expect(
        first.toString(),
        'ViewerRefresh(queues=true, note=false, card=true)',
      );
    });
  });
}
