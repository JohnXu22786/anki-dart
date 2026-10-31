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
 * Behavioral reference: ReminderTroubleshootingViewModelTest.kt in AnkiDroid
 * 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reminder troubleshooting state', () {
    test('CheckResult.from maps values and preserves exception boundaries', () {
      const failure = CheckResult.warning;
      final exception = FormatException('source exception');
      final nonExceptionError = StateError('not an Exception');

      expect(
        CheckResult.from(() => true, onFailure: failure),
        CheckResult.passed,
      );
      expect(CheckResult.from(() => false, onFailure: failure), same(failure));
      expect(
        CheckResult.from(() => null, onFailure: failure),
        CheckResult.unavailable,
      );
      final mappedException = CheckResult.from(
        () => throw exception,
        onFailure: failure,
      );
      expect(mappedException, isA<CheckResultError>());
      expect((mappedException as CheckResultError).exception, same(exception));
      expect(
        () =>
            CheckResult.from(() => throw nonExceptionError, onFailure: failure),
        throwsA(same(nonExceptionError)),
      );
    });

    test('battery optimization maps null and Exception distinctly', () {
      expect(
        mapBatteryOptimizationState(
          () => BatteryOptimizationState.unrestricted,
        ),
        CheckResult.passed,
      );
      expect(
        mapBatteryOptimizationState(() => BatteryOptimizationState.optimized),
        CheckResult.warning,
      );
      expect(
        mapBatteryOptimizationState(() => BatteryOptimizationState.restricted),
        CheckResult.failed,
      );
      expect(mapBatteryOptimizationState(() => null), CheckResult.unavailable);

      final exception = FormatException('battery state unavailable');
      final result = mapBatteryOptimizationState(() => throw exception);
      expect(result, isA<CheckResultError>());
      expect((result as CheckResultError).exception, same(exception));
    });

    test('defaults retain all six Loading checks in source order', () {
      const state = ReminderTroubleshootingState();

      expect(state.notificationPermission.result, CheckResult.loading);
      expect(state.notificationChannelEnabled.result, CheckResult.loading);
      expect(state.doNotDisturbOff.result, CheckResult.loading);
      expect(state.batteryOptimizationDisabled.result, CheckResult.loading);
      expect(state.powerSavingModeOff.result, CheckResult.loading);
      expect(state.exactAlarmPermission.result, CheckResult.loading);
      expect(state.checks, [
        state.notificationPermission,
        state.notificationChannelEnabled,
        state.doNotDisturbOff,
        state.batteryOptimizationDisabled,
        state.powerSavingModeOff,
        state.exactAlarmPermission,
      ]);
      expect(state.summaryStatus, SummaryStatus.ok);

      const unavailable = ReminderTroubleshootingState(
        notificationPermission: NotificationPermissionCheck(
          result: CheckResult.unavailable,
        ),
        notificationChannelEnabled: NotificationChannelEnabledCheck(
          result: CheckResult.unavailable,
        ),
        doNotDisturbOff: DoNotDisturbOffCheck(result: CheckResult.unavailable),
        batteryOptimizationDisabled: BatteryOptimizationCheck(
          result: CheckResult.unavailable,
        ),
        powerSavingModeOff: PowerSavingModeOffCheck(
          result: CheckResult.unavailable,
        ),
        exactAlarmPermission: ExactAlarmPermissionCheck(
          result: CheckResult.unavailable,
        ),
      );
      expect(unavailable.summaryStatus, SummaryStatus.ok);
    });

    test(
      'summary prioritizes blocking checks, then warns for other issues',
      () {
        const warningAndBlockingFailed = ReminderTroubleshootingState(
          doNotDisturbOff: DoNotDisturbOffCheck(result: CheckResult.warning),
          notificationPermission: NotificationPermissionCheck(
            result: CheckResult.failed,
          ),
        );
        expect(warningAndBlockingFailed.summaryStatus, SummaryStatus.error);

        final blockingException = FormatException('permission failed');
        final warningAndBlockingError = ReminderTroubleshootingState(
          batteryOptimizationDisabled: BatteryOptimizationCheck(
            result: CheckResult.failed,
          ),
          notificationChannelEnabled: NotificationChannelEnabledCheck(
            result: CheckResult.error(blockingException),
          ),
        );
        expect(warningAndBlockingError.summaryStatus, SummaryStatus.error);

        const nonBlockingFailure = ReminderTroubleshootingState(
          exactAlarmPermission: ExactAlarmPermissionCheck(
            result: CheckResult.failed,
          ),
        );
        expect(nonBlockingFailure.summaryStatus, SummaryStatus.warning);
      },
    );
  });
}
