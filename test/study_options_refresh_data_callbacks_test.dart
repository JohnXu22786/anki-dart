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
 * Source-derived cases for StudyOptionsViewModel.refreshData(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Study Options refresh data callbacks', () {
    test('refreshes derived state when the collection is open', () async {
      final calls = <String>[];
      final callbacks = StudyOptionsRefreshDataCallbacks(
        withOpenColOrNull: (operation) async {
          calls.add('collection open');
          await operation();
          calls.add('collection operation complete');
        },
        updateStateFromCollection: () async => calls.add('refresh state'),
      );

      await callbacks.refreshData();

      expect(calls, [
        'collection open',
        'refresh state',
        'collection operation complete',
      ]);
    });

    test('skips refresh when the collection is closed', () async {
      final calls = <String>[];
      final callbacks = StudyOptionsRefreshDataCallbacks(
        withOpenColOrNull: (_) async => calls.add('collection closed'),
        updateStateFromCollection: () async => calls.add('refresh state'),
      );

      await callbacks.refreshData();

      expect(calls, ['collection closed']);
    });

    test(
      'propagates refresh failures unchanged through the collection wrapper',
      () async {
        final failure = StateError('refresh failed');
        final calls = <String>[];
        final callbacks = StudyOptionsRefreshDataCallbacks(
          withOpenColOrNull: (operation) async {
            calls.add('collection open');
            await operation();
            calls.add('collection operation complete');
          },
          updateStateFromCollection: () async {
            calls.add('refresh state');
            throw failure;
          },
        );

        await expectLater(callbacks.refreshData(), throwsA(same(failure)));
        expect(calls, ['collection open', 'refresh state']);
      },
    );
  });
}
