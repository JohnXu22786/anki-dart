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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ProfileSwitchGuard.kt and ProfileSwitchGuardTest.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Profile switch guard', () {
    test(
      'source-derived: awaits checks in order, including after a blocker',
      () async {
        final calls = <String>[];
        final firstCheckGate = Completer<void>();
        final target = const ProfileId('p_12345678');
        var switchCount = 0;

        final resultFuture = invokeProfileSwitchGuard(
          targetProfileId: target,
          checks: [
            () async {
              calls.add('first-start');
              await firstCheckGate.future;
              calls.add('first-end');
              return ProfileSwitchBlockReason.BACKUP_IN_PROGRESS;
            },
            () {
              calls.add('second');
              return ProfileSwitchBlockReason.MEDIA_SYNC_IN_PROGRESS;
            },
          ],
          switchActiveProfile: (_) => switchCount++,
        );

        await Future<void>.delayed(Duration.zero);
        expect(calls, ['first-start']);
        firstCheckGate.complete();

        final result = await resultFuture;

        expect(calls, ['first-start', 'first-end', 'second']);
        expect(result, isA<ProfileSwitchGuardBlocked>());
        expect(switchCount, 0);
      },
    );

    test('source-derived: collects blockers once in encounter order', () async {
      final result = await invokeProfileSwitchGuard(
        targetProfileId: const ProfileId('p_12345678'),
        checks: [
          () => ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
          () => ProfileSwitchBlockReason.MEDIA_SYNC_IN_PROGRESS,
          () => ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
          () => ProfileSwitchBlockReason.COLLECTION_BUSY,
        ],
        switchActiveProfile: (_) {},
      );

      expect(result, isA<ProfileSwitchGuardBlocked>());
      expect((result as ProfileSwitchGuardBlocked).reasons.toList(), [
        ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
        ProfileSwitchBlockReason.MEDIA_SYNC_IN_PROGRESS,
        ProfileSwitchBlockReason.COLLECTION_BUSY,
      ]);
    });

    test('ignores skipped blockers but returns remaining blockers', () async {
      var switchCount = 0;
      final result = await invokeProfileSwitchGuard(
        targetProfileId: const ProfileId('p_12345678'),
        checks: [
          () => ProfileSwitchBlockReason.MEDIA_SYNC_IN_PROGRESS,
          () => ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
          () => null,
        ],
        skipReasons: const {ProfileSwitchBlockReason.MEDIA_SYNC_IN_PROGRESS},
        switchActiveProfile: (_) => switchCount++,
      );

      expect(result, isA<ProfileSwitchGuardBlocked>());
      expect((result as ProfileSwitchGuardBlocked).reasons, {
        ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
      });
      expect(switchCount, 0);
    });

    test(
      'switches once with the exact target when no blockers remain',
      () async {
        const target = ProfileId('p_12345678');
        final switchedTargets = <ProfileId>[];
        final result = await invokeProfileSwitchGuard(
          targetProfileId: target,
          checks: [() => null, () => ProfileSwitchBlockReason.COLLECTION_BUSY],
          skipReasons: const {ProfileSwitchBlockReason.COLLECTION_BUSY},
          switchActiveProfile: switchedTargets.add,
        );

        expect(result, isA<ProfileSwitchGuardSuccess>());
        expect(switchedTargets, [target]);
      },
    );

    test('source-derived: empty checks switch once', () async {
      const target = ProfileId('p_12345678');
      final switchedTargets = <ProfileId>[];

      final result = await invokeProfileSwitchGuard(
        targetProfileId: target,
        checks: const [],
        switchActiveProfile: switchedTargets.add,
      );

      expect(result, isA<ProfileSwitchGuardSuccess>());
      expect(switchedTargets, [target]);
    });

    test(
      'source-derived: check failure propagates and stops later work',
      () async {
        final failure = StateError('safety check failed');
        final calls = <String>[];

        final resultFuture = invokeProfileSwitchGuard(
          targetProfileId: const ProfileId('p_12345678'),
          checks: [
            () {
              calls.add('first');
              return null;
            },
            () {
              calls.add('second');
              throw failure;
            },
            () {
              calls.add('third');
              return null;
            },
          ],
          switchActiveProfile: (_) => calls.add('switch'),
        );

        await expectLater(resultFuture, throwsA(same(failure)));
        expect(calls, ['first', 'second']);
      },
    );

    test('source-derived: host switch failure propagates unchanged', () async {
      final failure = StateError('profile switch failed');
      const target = ProfileId('p_12345678');
      final switchedTargets = <ProfileId>[];

      final resultFuture = invokeProfileSwitchGuard(
        targetProfileId: target,
        checks: [() => null],
        switchActiveProfile: (profileId) {
          switchedTargets.add(profileId);
          throw failure;
        },
      );

      await expectLater(resultFuture, throwsA(same(failure)));
      expect(switchedTargets, [target]);
    });
  });
}
