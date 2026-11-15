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
  group('showDialogFragment', () {
    test('schedules once and resolves the manager only when action runs', () {
      final events = <String>[];
      final fragment = Object();
      final manager = Object();
      final scheduledActions = <void Function()>[];
      final managers = <Object>[];
      final fragments = <Object>[];

      showDialogFragment<Object, Object>(
        newFragment: fragment,
        runOnUiThread: (action) {
          events.add('schedule');
          scheduledActions.add(action);
        },
        supportFragmentManager: () {
          events.add('manager');
          return manager;
        },
        showDialogFragmentImpl: (actualManager, actualFragment) {
          events.add('show');
          managers.add(actualManager);
          fragments.add(actualFragment);
        },
      );

      expect(events, ['schedule']);
      expect(scheduledActions, hasLength(1));
      scheduledActions.single();

      expect(events, ['schedule', 'manager', 'show']);
      expect(managers, hasLength(1));
      expect(identical(managers.single, manager), isTrue);
      expect(fragments, hasLength(1));
      expect(identical(fragments.single, fragment), isTrue);
    });

    test('scheduling failure propagates without looking up or showing', () {
      final failure = StateError('schedule failed');
      var managerCalls = 0;
      var showCalls = 0;

      expect(
        () => showDialogFragment<Object, Object>(
          newFragment: Object(),
          runOnUiThread: (_) => throw failure,
          supportFragmentManager: () {
            managerCalls++;
            return Object();
          },
          showDialogFragmentImpl: (_, _) => showCalls++,
        ),
        throwsA(same(failure)),
      );
      expect(managerCalls, 0);
      expect(showCalls, 0);
    });

    test('manager lookup failure propagates and skips showing', () {
      final failure = StateError('manager failed');
      final actions = <void Function()>[];
      var managerCalls = 0;
      var showCalls = 0;

      showDialogFragment<Object, Object>(
        newFragment: Object(),
        runOnUiThread: actions.add,
        supportFragmentManager: () {
          managerCalls++;
          throw failure;
        },
        showDialogFragmentImpl: (_, _) => showCalls++,
      );

      expect(managerCalls, 0);
      expect(actions.single, throwsA(same(failure)));
      expect(managerCalls, 1);
      expect(showCalls, 0);
    });

    test('show failure propagates after one manager read and show call', () {
      final failure = StateError('show failed');
      final actions = <void Function()>[];
      final manager = Object();
      var managerCalls = 0;
      final managers = <Object>[];
      final fragments = <Object>[];

      showDialogFragment<Object, Object>(
        newFragment: Object(),
        runOnUiThread: actions.add,
        supportFragmentManager: () {
          managerCalls++;
          return manager;
        },
        showDialogFragmentImpl: (actualManager, actualFragment) {
          managers.add(actualManager);
          fragments.add(actualFragment);
          throw failure;
        },
      );

      expect(managerCalls, 0);
      expect(actions.single, throwsA(same(failure)));
      expect(managerCalls, 1);
      expect(managers, hasLength(1));
      expect(identical(managers.single, manager), isTrue);
      expect(fragments, hasLength(1));
    });
  });
}
