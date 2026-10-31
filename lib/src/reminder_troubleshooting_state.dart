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
 * Source-derived from ReminderTroubleshootingViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

/// Result of one portable reminder troubleshooting check.
sealed class CheckResult {
  const CheckResult();

  static const CheckResult loading = CheckResultLoading();
  static const CheckResult passed = CheckResultPassed();
  static const CheckResult failed = CheckResultFailed();
  static const CheckResult warning = CheckResultWarning();
  static const CheckResult unavailable = CheckResultUnavailable();

  /// Creates a result carrying the exact exception thrown by a host read.
  static CheckResult error(Exception exception) => CheckResultError(exception);

  /// Maps a nullable boolean read, catching only Dart [Exception] values.
  static CheckResult from(
    bool? Function() check, {
    required CheckResult onFailure,
  }) {
    try {
      return switch (check()) {
        true => passed,
        false => onFailure,
        null => unavailable,
      };
    } on Exception catch (exception) {
      return error(exception);
    }
  }

  /// Whether this result reports a failure, warning, or error.
  bool get hasIssue =>
      this is CheckResultFailed ||
      this is CheckResultWarning ||
      this is CheckResultError;

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class CheckResultLoading extends CheckResult {
  const CheckResultLoading();
}

final class CheckResultPassed extends CheckResult {
  const CheckResultPassed();
}

final class CheckResultFailed extends CheckResult {
  const CheckResultFailed();
}

final class CheckResultWarning extends CheckResult {
  const CheckResultWarning();
}

final class CheckResultUnavailable extends CheckResult {
  const CheckResultUnavailable();
}

final class CheckResultError extends CheckResult {
  const CheckResultError(this.exception);

  final Exception exception;

  @override
  bool operator ==(Object other) =>
      other is CheckResultError && identical(other.exception, exception);

  @override
  int get hashCode =>
      Object.hash(CheckResultError, identityHashCode(exception));
}

/// One of the reminder checks displayed to the user.
sealed class TroubleshootingCheck {
  const TroubleshootingCheck(this.result);

  final CheckResult result;

  @override
  bool operator ==(Object other) =>
      other is TroubleshootingCheck &&
      other.runtimeType == runtimeType &&
      other.result == result;

  @override
  int get hashCode => Object.hash(runtimeType, result);
}

final class NotificationPermissionCheck extends TroubleshootingCheck {
  const NotificationPermissionCheck({CheckResult result = CheckResult.loading})
    : super(result);
}

final class NotificationChannelEnabledCheck extends TroubleshootingCheck {
  const NotificationChannelEnabledCheck({
    CheckResult result = CheckResult.loading,
  }) : super(result);
}

final class DoNotDisturbOffCheck extends TroubleshootingCheck {
  const DoNotDisturbOffCheck({CheckResult result = CheckResult.loading})
    : super(result);
}

final class BatteryOptimizationCheck extends TroubleshootingCheck {
  const BatteryOptimizationCheck({CheckResult result = CheckResult.loading})
    : super(result);
}

final class PowerSavingModeOffCheck extends TroubleshootingCheck {
  const PowerSavingModeOffCheck({CheckResult result = CheckResult.loading})
    : super(result);
}

final class ExactAlarmPermissionCheck extends TroubleshootingCheck {
  const ExactAlarmPermissionCheck({CheckResult result = CheckResult.loading})
    : super(result);
}

/// Overall status of all reminder troubleshooting checks.
enum SummaryStatus { ok, warning, error }

/// The source enum supplied by the Android repository, represented as a host
/// value so callers can map it without importing Android APIs.
enum BatteryOptimizationState { unrestricted, optimized, restricted }

/// Maps one battery optimization read to its source result semantics.
CheckResult mapBatteryOptimizationState(
  BatteryOptimizationState? Function() readState,
) {
  try {
    return switch (readState()) {
      BatteryOptimizationState.unrestricted => CheckResult.passed,
      BatteryOptimizationState.optimized => CheckResult.warning,
      BatteryOptimizationState.restricted => CheckResult.failed,
      null => CheckResult.unavailable,
    };
  } on Exception catch (exception) {
    return CheckResult.error(exception);
  }
}

/// Portable check values and summary semantics from AnkiDroid's ViewModel.
///
/// Android permission/channel reads, repository checks, ViewModel lifecycle,
/// StateFlow/coroutines, localization, and UI remain host-side.
final class ReminderTroubleshootingState {
  const ReminderTroubleshootingState({
    this.notificationPermission = const NotificationPermissionCheck(),
    this.notificationChannelEnabled = const NotificationChannelEnabledCheck(),
    this.doNotDisturbOff = const DoNotDisturbOffCheck(),
    this.batteryOptimizationDisabled = const BatteryOptimizationCheck(),
    this.powerSavingModeOff = const PowerSavingModeOffCheck(),
    this.exactAlarmPermission = const ExactAlarmPermissionCheck(),
  });

  final NotificationPermissionCheck notificationPermission;
  final NotificationChannelEnabledCheck notificationChannelEnabled;
  final DoNotDisturbOffCheck doNotDisturbOff;
  final BatteryOptimizationCheck batteryOptimizationDisabled;
  final PowerSavingModeOffCheck powerSavingModeOff;
  final ExactAlarmPermissionCheck exactAlarmPermission;

  /// Checks in the source's stable display and summary order.
  List<TroubleshootingCheck> get checks => [
    notificationPermission,
    notificationChannelEnabled,
    doNotDisturbOff,
    batteryOptimizationDisabled,
    powerSavingModeOff,
    exactAlarmPermission,
  ];

  /// Blocking notification failures take precedence over all other issues.
  SummaryStatus get summaryStatus {
    final permissionResult = notificationPermission.result;
    final channelResult = notificationChannelEnabled.result;
    if (permissionResult is CheckResultFailed ||
        permissionResult is CheckResultError ||
        channelResult is CheckResultFailed ||
        channelResult is CheckResultError) {
      return SummaryStatus.error;
    }
    return checks.any((check) => check.result.hasIssue)
        ? SummaryStatus.warning
        : SummaryStatus.ok;
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderTroubleshootingState &&
      other.notificationPermission == notificationPermission &&
      other.notificationChannelEnabled == notificationChannelEnabled &&
      other.doNotDisturbOff == doNotDisturbOff &&
      other.batteryOptimizationDisabled == batteryOptimizationDisabled &&
      other.powerSavingModeOff == powerSavingModeOff &&
      other.exactAlarmPermission == exactAlarmPermission;

  @override
  int get hashCode => Object.hash(
    notificationPermission,
    notificationChannelEnabled,
    doNotDisturbOff,
    batteryOptimizationDisabled,
    powerSavingModeOff,
    exactAlarmPermission,
  );
}
