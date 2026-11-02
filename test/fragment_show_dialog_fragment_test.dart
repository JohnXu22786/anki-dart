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
 * Source-derived from Fragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('fragmentShowDialogFragment', () {
    test(
      'resolves activity before scheduling and forwards captured activity and dialog',
      () {
        final events = <String>[];
        final fragment = Object();
        final activity = Object();
        final replacementActivity = Object();
        final dialog = Object();
        final manager = Object();
        Object? currentActivity = activity;
        final scheduledActions = <void Function()>[];
        final managers = <Object>[];
        final dialogs = <Object>[];

        fragmentShowDialogFragment<Object, Object, Object, Object>(
          fragment: fragment,
          newFragment: dialog,
          requireActivity: (actualFragment) {
            events.add('requireActivity');
            expect(identical(actualFragment, fragment), isTrue);
            return currentActivity!;
          },
          runOnUiThread: (actualActivity, action) {
            events.add('schedule');
            expect(identical(actualActivity, activity), isTrue);
            scheduledActions.add(action);
          },
          supportFragmentManager: (actualActivity) {
            events.add('manager');
            expect(identical(actualActivity, activity), isTrue);
            expect(identical(actualActivity, replacementActivity), isFalse);
            return manager;
          },
          showDialogFragmentImpl: (actualManager, actualDialog) {
            events.add('show');
            managers.add(actualManager);
            dialogs.add(actualDialog);
          },
        );

        expect(events, ['requireActivity', 'schedule']);
        expect(scheduledActions, hasLength(1));
        currentActivity = replacementActivity;
        scheduledActions.single();

        expect(events, ['requireActivity', 'schedule', 'manager', 'show']);
        expect(managers, hasLength(1));
        expect(identical(managers.single, manager), isTrue);
        expect(dialogs, hasLength(1));
        expect(identical(dialogs.single, dialog), isTrue);
      },
    );

    test('activity lookup failure prevents scheduling and later callbacks', () {
      final failure = StateError('activity failed');
      final fragment = Object();
      var activityCalls = 0;
      var schedulerCalls = 0;
      var managerCalls = 0;
      var showCalls = 0;

      expect(
        () => fragmentShowDialogFragment<Object, Object, Object, Object>(
          fragment: fragment,
          newFragment: Object(),
          requireActivity: (actualFragment) {
            activityCalls++;
            expect(identical(actualFragment, fragment), isTrue);
            throw failure;
          },
          runOnUiThread: (_, _) => schedulerCalls++,
          supportFragmentManager: (_) {
            managerCalls++;
            return Object();
          },
          showDialogFragmentImpl: (_, _) => showCalls++,
        ),
        throwsA(same(failure)),
      );
      expect(activityCalls, 1);
      expect(schedulerCalls, 0);
      expect(managerCalls, 0);
      expect(showCalls, 0);
    });

    test('scheduler failure prevents deferred manager lookup and display', () {
      final failure = StateError('schedule failed');
      var managerCalls = 0;
      var showCalls = 0;

      expect(
        () => fragmentShowDialogFragment<Object, Object, Object, Object>(
          fragment: Object(),
          newFragment: Object(),
          requireActivity: (_) => Object(),
          runOnUiThread: (_, _) => throw failure,
          supportFragmentManager: (_) {
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
  });
}
