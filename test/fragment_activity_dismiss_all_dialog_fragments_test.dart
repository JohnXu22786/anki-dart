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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FragmentActivity.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('dismissAllDialogFragments', () {
    test('saved state is checked once and skips popping', () {
      final events = <String>[];

      dismissAllDialogFragments(
        isStateSaved: () {
          events.add('isStateSaved');
          return true;
        },
        popBackStack: (name, flags) => events.add('popBackStack'),
      );

      expect(events, ['isStateSaved']);
    });

    test('unsaved state pops once with the exact tag and inclusive flag', () {
      final events = <String>[];
      final calls = <(String, int)>[];

      dismissAllDialogFragments(
        isStateSaved: () {
          events.add('isStateSaved');
          return false;
        },
        popBackStack: (name, flags) {
          events.add('popBackStack');
          calls.add((name, flags));
        },
      );

      expect(events, ['isStateSaved', 'popBackStack']);
      expect(calls, [(dialogFragmentTag, popBackStackInclusiveFlag)]);
    });

    test('callback failures propagate unchanged and stop later work', () {
      final stateFailure = StateError('state check failed');
      var popCalls = 0;

      expect(
        () => dismissAllDialogFragments(
          isStateSaved: () => throw stateFailure,
          popBackStack: (_, _) => popCalls++,
        ),
        throwsA(same(stateFailure)),
      );
      expect(popCalls, 0);

      final popFailure = StateError('pop failed');
      var stateChecks = 0;
      expect(
        () => dismissAllDialogFragments(
          isStateSaved: () {
            stateChecks++;
            return false;
          },
          popBackStack: (_, _) => throw popFailure,
        ),
        throwsA(same(popFailure)),
      );
      expect(stateChecks, 1);
    });
  });
}
