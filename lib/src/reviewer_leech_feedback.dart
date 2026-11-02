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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Composes the source leech feedback using host-localized message callbacks.
///
/// The base message is requested once. When [isSuspended] is true, the
/// suspended message is then requested once and appended after one literal
/// ASCII space. Localization, leech detection, and feedback delivery remain
/// host-side. Callback exceptions propagate unchanged.
String reviewerLeechFeedbackMessage({
  required bool isSuspended,
  required String Function() studyingCardWasALeech,
  required String Function() studyingItHasBeenSuspended,
}) {
  final message = StringBuffer(studyingCardWasALeech());
  if (isSuspended) {
    message.write(' ');
    message.write(studyingItHasBeenSuspended());
  }
  return message.toString();
}
