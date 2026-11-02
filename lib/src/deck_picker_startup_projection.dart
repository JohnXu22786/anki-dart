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
 * Behavioral reference: `StartupResponse`, `handleStartup`, `updateDeckList`,
 * and `onScreenResumed` in DeckPickerViewModel.kt, AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The source `StartupResponse` values emitted by AnkiDroid's Deck Picker.
sealed class DeckPickerStartupResponse {
  const DeckPickerStartupResponse();
}

final class DeckPickerStartupRequestPermissions
    extends DeckPickerStartupResponse {
  const DeckPickerStartupRequestPermissions(this.requiredPermissions);

  final Object requiredPermissions;
}

final class DeckPickerStartupFatalError extends DeckPickerStartupResponse {
  const DeckPickerStartupFatalError(this.failure);

  final Object failure;
}

final class DeckPickerStartupSuccess extends DeckPickerStartupResponse {
  const DeckPickerStartupSuccess();
}

/// Ordered source operations after the host has checked Android permissions.
///
/// These values describe intent only. The host performs the Android work,
/// coroutine scheduling, and StateFlow publication.
enum DeckPickerStartupEffect {
  publishRequestPermissions,
  checkStartupFailureOnIo,
  publishFatalError,
  configureRenderingMode,
  launchDeckListLoadOnIo,
  publishSuccess,
}

/// The source-derived permission gate and startup-job intent for one call.
final class DeckPickerStartupPlan {
  const DeckPickerStartupPlan({
    required this.response,
    required this.startupServesFirstRefresh,
    required this.assignStartupJob,
    required this.effects,
  });

  /// A permission request when denied; null while the assigned startup job
  /// performs its asynchronous failure check.
  final DeckPickerStartupResponse? response;

  /// The value of the source's `startupServesFirstRefresh` after this plan.
  final bool startupServesFirstRefresh;

  /// Whether the host assigns a startup job before checking for startup failure.
  final bool assignStartupJob;

  /// Ordered operations. A successful load is launched before success is
  /// published; its completion is not awaited by startup.
  final List<DeckPickerStartupEffect> effects;
}

/// Projects `handleStartup`'s permission gate and startup-job assignment.
///
/// Permission denial returns before changing the first-refresh flag or
/// assigning a startup job. [requiredPermissions] is used only on that branch;
/// the host need not read it when permission is already granted. With
/// permissions, the source sets the flag and
/// assigns the job before that job checks for failure on IO. The host performs
/// the Android permission check, job assignment, and asynchronous work; this
/// function does not execute startup synchronously.
DeckPickerStartupPlan planDeckPickerStartup({
  required bool hasRequiredPermissions,
  Object? requiredPermissions,
  required bool startupServesFirstRefresh,
}) {
  if (!hasRequiredPermissions) {
    return DeckPickerStartupPlan(
      response: DeckPickerStartupRequestPermissions(requiredPermissions!),
      startupServesFirstRefresh: startupServesFirstRefresh,
      assignStartupJob: false,
      effects: const [DeckPickerStartupEffect.publishRequestPermissions],
    );
  }

  return const DeckPickerStartupPlan(
    response: null,
    startupServesFirstRefresh: true,
    assignStartupJob: true,
    effects: [DeckPickerStartupEffect.checkStartupFailureOnIo],
  );
}

/// Projects the response after the host's startup-failure check completes.
///
/// Failure publishes FatalError and stops. Success configures rendering,
/// launches deck-list loading on IO without waiting for it, then publishes
/// Success. The host performs every listed effect and MutableStateFlow update.
DeckPickerStartupPlan completeDeckPickerStartup({required Object? failure}) {
  if (failure case final startupFailure?) {
    return DeckPickerStartupPlan(
      response: DeckPickerStartupFatalError(startupFailure),
      startupServesFirstRefresh: true,
      assignStartupJob: false,
      effects: const [DeckPickerStartupEffect.publishFatalError],
    );
  }

  return const DeckPickerStartupPlan(
    response: DeckPickerStartupSuccess(),
    startupServesFirstRefresh: true,
    assignStartupJob: false,
    effects: [
      DeckPickerStartupEffect.configureRenderingMode,
      DeckPickerStartupEffect.launchDeckListLoadOnIo,
      DeckPickerStartupEffect.publishSuccess,
    ],
  );
}

/// Source transition returned by `updateDeckList` without executing a Job.
final class DeckPickerUpdateDeckListPlan {
  const DeckPickerUpdateDeckListPlan({
    required this.shouldStartDeckListLoad,
    required this.startupServesFirstRefresh,
  });

  final bool shouldStartDeckListLoad;
  final bool startupServesFirstRefresh;
}

/// Projects `updateDeckList`'s startup-job and one-shot-refresh guards.
///
/// An active startup job takes precedence and preserves the flag. Otherwise a
/// true flag is consumed without starting another load; only the ordinary path
/// requests a host-scheduled IO load.
DeckPickerUpdateDeckListPlan planDeckPickerUpdateDeckList({
  required bool startupJobActive,
  required bool startupServesFirstRefresh,
}) {
  if (startupJobActive) {
    return DeckPickerUpdateDeckListPlan(
      shouldStartDeckListLoad: false,
      startupServesFirstRefresh: startupServesFirstRefresh,
    );
  }
  if (startupServesFirstRefresh) {
    return const DeckPickerUpdateDeckListPlan(
      shouldStartDeckListLoad: false,
      startupServesFirstRefresh: false,
    );
  }
  return const DeckPickerUpdateDeckListPlan(
    shouldStartDeckListLoad: true,
    startupServesFirstRefresh: false,
  );
}

/// Projects `onScreenResumed`'s unconditional first-refresh flag clear.
bool planDeckPickerScreenResumed({required bool startupServesFirstRefresh}) =>
    false;
