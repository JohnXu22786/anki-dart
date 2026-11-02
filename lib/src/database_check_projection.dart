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
 * Source-derived from DatabaseCheck.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// The fields from a generated database-check progress event used by the host.
///
/// The generated Anki progress objects remain host-side.
final class DatabaseCheckProgressEvent {
  const DatabaseCheckProgressEvent({
    required this.stage,
    required this.stageCurrent,
    required this.stageTotal,
  });

  final String stage;
  final int stageCurrent;
  final int stageTotal;
}

/// A projected database-check stage and its optional amount.
final class DatabaseCheckProgressProjection {
  const DatabaseCheckProgressProjection({
    required this.stage,
    required this.amount,
  });

  final String stage;
  final (int, int)? amount;
}

/// Projects a present database-check event, or returns null when absent.
///
/// A null result means the host must leave both progress fields unchanged. For
/// a present event the stage is copied exactly, and amount is set only when the
/// total is positive. Values are forwarded without clamping or validation.
DatabaseCheckProgressProjection? projectDatabaseCheckProgress(
  DatabaseCheckProgressEvent? event,
) {
  if (event == null) return null;

  final amount = event.stageTotal > 0
      ? (event.stageCurrent, event.stageTotal)
      : null;
  return DatabaseCheckProgressProjection(stage: event.stage, amount: amount);
}

/// Selects the database-check completion message from the source branches.
///
/// Nonempty problems are joined in order with one line feed and bypass the host
/// localization callback. When there are no problems, the callback runs once
/// and its result or failure is passed through unchanged.
String databaseCheckResultMessage({
  required List<String> problems,
  required String Function() databaseCheckRebuilt,
}) => problems.isNotEmpty ? problems.join('\n') : databaseCheckRebuilt();
