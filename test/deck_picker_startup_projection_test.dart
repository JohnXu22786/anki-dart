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
 * Source-derived from DeckPickerViewModel.kt:352–372,483–565 in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planDeckPickerStartup', () {
    test(
      'permission denial leaves refresh state unchanged and does not assign startup work',
      () {
        final permissions = Object();
        final plan = planDeckPickerStartup(
          hasRequiredPermissions: false,
          requiredPermissions: permissions,
          startupServesFirstRefresh: true,
        );

        expect(plan.response, isA<DeckPickerStartupRequestPermissions>());
        expect(
          (plan.response! as DeckPickerStartupRequestPermissions)
              .requiredPermissions,
          same(permissions),
        );
        expect(plan.startupServesFirstRefresh, isTrue);
        expect(plan.assignStartupJob, isFalse);
        expect(plan.effects, [
          DeckPickerStartupEffect.publishRequestPermissions,
        ]);
      },
    );

    test(
      'failure publishes fatal response after assigning startup job and stops before success effects',
      () {
        final startup = planDeckPickerStartup(
          hasRequiredPermissions: true,
          startupServesFirstRefresh: false,
        );
        final failure = Object();
        final completed = completeDeckPickerStartup(failure: failure);

        expect(startup.response, isNull);
        expect(startup.assignStartupJob, isTrue);
        expect(startup.startupServesFirstRefresh, isTrue);
        expect(startup.effects, [
          DeckPickerStartupEffect.checkStartupFailureOnIo,
        ]);
        expect(completed.response, isA<DeckPickerStartupFatalError>());
        expect(
          (completed.response! as DeckPickerStartupFatalError).failure,
          same(failure),
        );
        expect(completed.assignStartupJob, isFalse);
        expect(completed.effects, [DeckPickerStartupEffect.publishFatalError]);
      },
    );

    test(
      'success orders rendering, asynchronous deck-list launch, then success publication',
      () {
        final startup = planDeckPickerStartup(
          hasRequiredPermissions: true,
          startupServesFirstRefresh: false,
        );
        final completed = completeDeckPickerStartup(failure: null);

        expect(startup.response, isNull);
        expect(startup.assignStartupJob, isTrue);
        expect(startup.startupServesFirstRefresh, isTrue);
        expect(startup.effects, [
          DeckPickerStartupEffect.checkStartupFailureOnIo,
        ]);
        expect(completed.response, isA<DeckPickerStartupSuccess>());
        expect(completed.assignStartupJob, isFalse);
        expect(completed.effects, [
          DeckPickerStartupEffect.configureRenderingMode,
          DeckPickerStartupEffect.launchDeckListLoadOnIo,
          DeckPickerStartupEffect.publishSuccess,
        ]);
      },
    );
  });

  group('deck-picker first-refresh projection', () {
    test(
      'startup activity blocks refresh without consuming first-refresh state',
      () {
        final plan = planDeckPickerUpdateDeckList(
          startupJobActive: true,
          startupServesFirstRefresh: true,
        );

        expect(plan.shouldStartDeckListLoad, isFalse);
        expect(plan.startupServesFirstRefresh, isTrue);
      },
    );

    test(
      'first post-startup refresh consumes the flag; resumed screen also clears it',
      () {
        final firstRefresh = planDeckPickerUpdateDeckList(
          startupJobActive: false,
          startupServesFirstRefresh: true,
        );
        final afterResume = planDeckPickerScreenResumed(
          startupServesFirstRefresh: true,
        );

        expect(firstRefresh.shouldStartDeckListLoad, isFalse);
        expect(firstRefresh.startupServesFirstRefresh, isFalse);
        expect(afterResume, isFalse);
      },
    );

    test('ordinary refresh requests a deck-list load', () {
      final plan = planDeckPickerUpdateDeckList(
        startupJobActive: false,
        startupServesFirstRefresh: false,
      );

      expect(plan.shouldStartDeckListLoad, isTrue);
      expect(plan.startupServesFirstRefresh, isFalse);
    });
  });
}
