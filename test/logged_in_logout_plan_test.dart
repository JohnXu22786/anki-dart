/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived cases for LoggedInViewModel.onLogout() in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Logged-in logout plan', () {
    test('runs host callbacks in source order', () {
      final calls = <String>[];
      final plan = _plan(calls);

      plan.run();

      expect(calls, [
        'clearSavedHkey',
        'clearUsername',
        'clearCurrentSyncUri',
        'forceMediaResync',
      ]);
    });

    test('propagates callback failures and stops later callbacks', () {
      const callbacks = [
        'clearSavedHkey',
        'clearUsername',
        'clearCurrentSyncUri',
        'forceMediaResync',
      ];

      for (var failedAt = 0; failedAt < callbacks.length; failedAt++) {
        final calls = <String>[];
        final failure = StateError('logout callback failed');
        final plan = planLoggedInLogout(
          LoggedInLogoutCallbacks(
            clearSavedHkey: () =>
                _invoke(calls, callbacks[0], failure, failedAt),
            clearUsername: () =>
                _invoke(calls, callbacks[1], failure, failedAt),
            clearCurrentSyncUri: () =>
                _invoke(calls, callbacks[2], failure, failedAt),
            forceMediaResync: () =>
                _invoke(calls, callbacks[3], failure, failedAt),
          ),
        );

        expect(() => plan.run(), throwsA(same(failure)));
        expect(calls, callbacks.take(failedAt + 1));
      }
    });
  });
}

LoggedInLogoutPlan _plan(List<String> calls) => planLoggedInLogout(
  LoggedInLogoutCallbacks(
    clearSavedHkey: () => calls.add('clearSavedHkey'),
    clearUsername: () => calls.add('clearUsername'),
    clearCurrentSyncUri: () => calls.add('clearCurrentSyncUri'),
    forceMediaResync: () => calls.add('forceMediaResync'),
  ),
);

void _invoke(
  List<String> calls,
  String callback,
  Object failure,
  int failedAt,
) {
  calls.add(callback);
  if (calls.length - 1 == failedAt) throw failure;
}
