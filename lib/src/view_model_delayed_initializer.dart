/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ViewModelUtils.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Progress of a host ViewModel's initialization block.
sealed class InitStatus {
  const InitStatus();

  /// Initialization has not started.
  static const InitStatus pending = InitStatusPending._();

  /// Initialization is running.
  static const InitStatus inProgress = InitStatusInProgress._();

  /// Initialization completed successfully.
  static const InitStatus completed = InitStatusCompleted._();

  /// Initialization failed with [exception].
  static InitStatusFailed failed(Exception exception) =>
      InitStatusFailed(exception);
}

/// Singleton state before initialization begins.
final class InitStatusPending extends InitStatus {
  const InitStatusPending._();

  @override
  bool operator ==(Object other) => other is InitStatusPending;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Singleton state while initialization is running.
final class InitStatusInProgress extends InitStatus {
  const InitStatusInProgress._();

  @override
  bool operator ==(Object other) => other is InitStatusInProgress;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Singleton state after initialization completes successfully.
final class InitStatusCompleted extends InitStatus {
  const InitStatusCompleted._();

  @override
  bool operator ==(Object other) => other is InitStatusCompleted;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// State after initialization fails with a source [Exception].
final class InitStatusFailed extends InitStatus {
  const InitStatusFailed(this.exception);

  final Exception exception;

  @override
  bool operator ==(Object other) =>
      other is InitStatusFailed && other.exception == exception;

  @override
  int get hashCode => Object.hash(InitStatusFailed, exception);
}

/// Schedules [block] through host callbacks and reports its progress.
///
/// [launch] receives the work closure and decides when to run it, matching the
/// host coroutine scope's scheduling boundary. The closure publishes
/// [InitStatus.inProgress] before its try region, then mirrors the source log,
/// success, and Exception handling order. Non-Exception errors propagate.
/// Exceptions thrown by the warning logger or Failed publication also
/// propagate from the catch handler.
void projectViewModelDelayedInit({
  required void Function(Future<void> Function() work) launch,
  required void Function(InitStatus status) publishStatus,
  required void Function(String message) logDebug,
  required void Function(Exception exception, String message) logWarning,
  required Future<void> Function() block,
}) {
  launch(() async {
    publishStatus(InitStatus.inProgress);
    try {
      logDebug('init started');
      await block();
      logDebug('init completed');
      publishStatus(InitStatus.completed);
    } on Exception catch (exception) {
      logWarning(exception, 'Failed to initialize ViewModel');
      publishStatus(InitStatus.failed(exception));
    }
  });
}
