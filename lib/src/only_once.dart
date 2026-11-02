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
 * Source-derived from OnlyOnce.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Method identifiers guarded by [OnlyOnce], in AnkiDroid source order.
enum OnlyOnceMethod { ANSWER_CARD, UNIT_TEST }

/// Guards host work by method name until its host job completes.
///
/// The host supplies job creation, completion registration, and logging. The
/// adapter preserves the source callback order and propagates callback errors.
class OnlyOnce {
  final Set<OnlyOnceMethod> _blockedFunctions = {};

  /// Runs [function] only if [name] is not currently blocked.
  ///
  /// A synchronous error from [function] leaves [name] blocked, matching the
  /// source behavior. The completion callback logs before removing the block.
  void preventSimultaneousExecutions<T>({
    required OnlyOnceMethod name,
    required T Function() function,
    required void Function(T job, void Function() callback) invokeOnCompletion,
    required void Function(String message) logWarning,
    required void Function(String message) logVerbose,
  }) {
    if (!_blockedFunctions.add(name)) {
      logWarning('simultaneously executions of ${name.name} blocked');
      return;
    }
    logVerbose('executing ${name.name}');
    final job = function();
    invokeOnCompletion(job, () {
      logVerbose('completed ${name.name}');
      _blockedFunctions.remove(name);
    });
  }
}

/// Prevents overlapping host launches using the source's activity-check order.
class RunOnlyOnce<T> {
  RunOnlyOnce({T? initialJob}) : _job = initialJob;

  T? _job;

  /// The last job returned by a successful host launch, if any.
  T? get job => _job;

  /// Skips an active job; otherwise stores the result after [launch] succeeds.
  void launch({
    required bool Function(T? job) isActive,
    required T Function() launch,
    required void Function(String message) logDebug,
  }) {
    if (isActive(_job)) {
      logDebug('skipped multiple executions of job');
      return;
    }
    _job = launch();
  }
}
