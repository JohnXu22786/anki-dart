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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserChangeNoteType', () {
    test('empty selection needs no membership input', () {
      expect(
        planBrowserChangeNoteType(selectedNoteIds: const []),
        isA<BrowserChangeNoteTypeNoSelection>(),
      );
    });

    test('any selected ID outside membership selects mixed response', () {
      expect(
        planBrowserChangeNoteType(
          selectedNoteIds: const [3, 7],
          firstNoteTypeMembershipIds: const [3, 5],
        ),
        isA<BrowserChangeNoteTypeMixedSelection>(),
      );
    });

    test('one member produces the change-note-type response', () {
      final plan = planBrowserChangeNoteType(
        selectedNoteIds: const [3],
        firstNoteTypeMembershipIds: const [3, 5],
      );

      expect(plan, isA<BrowserChangeNoteTypeSelection>());
      expect((plan as BrowserChangeNoteTypeSelection).noteIds, [3]);
    });

    test('same-type notes preserve selected order', () {
      final plan = planBrowserChangeNoteType(
        selectedNoteIds: const [7, 3],
        firstNoteTypeMembershipIds: const [3, 5, 7],
      );

      expect(plan, isA<BrowserChangeNoteTypeSelection>());
      expect((plan as BrowserChangeNoteTypeSelection).noteIds, [7, 3]);
    });

    test('duplicate selected IDs are removed at first occurrence', () {
      final plan = planBrowserChangeNoteType(
        selectedNoteIds: const [7, 3, 7, 5, 3],
        firstNoteTypeMembershipIds: const [3, 5, 7],
      );

      expect(plan, isA<BrowserChangeNoteTypeSelection>());
      expect((plan as BrowserChangeNoteTypeSelection).noteIds, [7, 3, 5]);
    });

    test('empty membership does not contain a nonempty selection', () {
      expect(
        planBrowserChangeNoteType(
          selectedNoteIds: const [3],
          firstNoteTypeMembershipIds: const [],
        ),
        isA<BrowserChangeNoteTypeMixedSelection>(),
      );
    });

    test('change response factory enforces its nonempty precondition', () {
      expect(
        () => BrowserChangeNoteTypeSelection.fromNoteIds(const <int>[]),
        throwsArgumentError,
      );
    });
  });
}
