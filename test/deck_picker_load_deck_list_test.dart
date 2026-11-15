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
 * Source-derived from DeckPickerViewModel.kt:374–387 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('loadDeckList', () {
    test(
      'closed collection returns before reading fingerprint or doing effects',
      () async {
        final calls = <String>[];

        await loadDeckList(
          isCollectionOpen: () {
            calls.add('isOpen');
            return false;
          },
          fingerprint: () {
            calls.add('fingerprint');
            throw StateError('closed collection must not read fingerprint');
          },
          launchBackupInBackground: () => calls.add('backup'),
          logUpdateDeckList: () => calls.add('log'),
          reloadDeckCounts: () async => calls.add('reload'),
        );

        expect(calls, ['isOpen']);
      },
    );

    test(
      'exact Robolectric fingerprint skips backup and continues in order',
      () async {
        final calls = <String>[];

        await loadDeckList(
          isCollectionOpen: () {
            calls.add('isOpen');
            return true;
          },
          fingerprint: () {
            calls.add('fingerprint');
            return 'robolectric';
          },
          launchBackupInBackground: () => calls.add('backup'),
          logUpdateDeckList: () => calls.add('log'),
          reloadDeckCounts: () async => calls.add('reload'),
        );

        expect(calls, ['isOpen', 'fingerprint', 'log', 'reload']);
      },
    );

    test(
      'launches non-Robolectric backup without waiting, before log and reload',
      () async {
        final calls = <String>[];
        final backup = Completer<void>();

        await loadDeckList(
          isCollectionOpen: () {
            calls.add('isOpen');
            return true;
          },
          fingerprint: () {
            calls.add('fingerprint');
            return 'pixel';
          },
          launchBackupInBackground: () {
            calls.add('backupLaunch');
            unawaited(backup.future);
          },
          logUpdateDeckList: () => calls.add('log'),
          reloadDeckCounts: () async => calls.add('reload'),
        );

        expect(calls, [
          'isOpen',
          'fingerprint',
          'backupLaunch',
          'log',
          'reload',
        ]);
        expect(backup.isCompleted, isFalse);
        backup.complete();
      },
    );

    test('waits for reload to finish', () async {
      final reload = Completer<void>();
      var completed = false;
      final operation = loadDeckList(
        isCollectionOpen: () => true,
        fingerprint: () => 'robolectric',
        launchBackupInBackground: () {},
        logUpdateDeckList: () {},
        reloadDeckCounts: () => reload.future,
      ).then((_) => completed = true);

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      reload.complete();
      await operation;
      expect(completed, isTrue);
    });

    test(
      'callback failures propagate unchanged and stop later effects',
      () async {
        final cases = <({String stage, Object failure})>[
          (stage: 'isOpen', failure: StateError('isOpen')),
          (stage: 'fingerprint', failure: StateError('fingerprint')),
          (stage: 'backupLaunch', failure: StateError('backupLaunch')),
          (stage: 'log', failure: StateError('log')),
          (stage: 'reload', failure: StateError('reload')),
        ];

        for (final testCase in cases) {
          final calls = <String>[];
          void failAt(String stage) {
            calls.add(stage);
            if (testCase.stage == stage) throw testCase.failure;
          }

          await expectLater(
            loadDeckList(
              isCollectionOpen: () {
                failAt('isOpen');
                return true;
              },
              fingerprint: () {
                failAt('fingerprint');
                return 'pixel';
              },
              launchBackupInBackground: () => failAt('backupLaunch'),
              logUpdateDeckList: () => failAt('log'),
              reloadDeckCounts: () async => failAt('reload'),
            ),
            throwsA(same(testCase.failure)),
          );

          final expectedCalls = switch (testCase.stage) {
            'isOpen' => ['isOpen'],
            'fingerprint' => ['isOpen', 'fingerprint'],
            'backupLaunch' => ['isOpen', 'fingerprint', 'backupLaunch'],
            'log' => ['isOpen', 'fingerprint', 'backupLaunch', 'log'],
            'reload' => [
              'isOpen',
              'fingerprint',
              'backupLaunch',
              'log',
              'reload',
            ],
            _ => throw StateError('unexpected test stage: ${testCase.stage}'),
          };
          expect(calls, expectedCalls);
        }
      },
    );
  });
}
