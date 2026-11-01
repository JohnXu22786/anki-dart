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
 * Source-derived from NoteEditorFragment.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Android's `Intent.ACTION_SEND` action string.
const androidIntentActionSend = 'android.intent.action.SEND';

/// Android's `Intent.ACTION_VIEW` action string.
const androidIntentActionView = 'android.intent.action.VIEW';

/// Adapts `NoteEditorFragment.intentLaunchedWithImage(intent)`.
///
/// The host supplies the Intent action, invalid-view policy, and resolved MIME
/// type. These callbacks run in source order and any callback failure
/// propagates. The action callback is read again for the VIEW comparison when
/// the first read is not SEND, matching the source expression's short circuit.
bool intentLaunchedWithImage<TIntent>({
  required TIntent intent,
  required String? Function(TIntent intent) actionOf,
  required bool Function(TIntent intent) isInvalidViewIntent,
  required String? Function(TIntent intent) resolveMimeType,
}) {
  if (actionOf(intent) != androidIntentActionSend &&
      actionOf(intent) != androidIntentActionView) {
    return false;
  }
  if (isInvalidViewIntent(intent)) {
    return false;
  }
  return resolveMimeType(intent)?.startsWith('image/') == true;
}
