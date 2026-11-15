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
 * Source-derived from FragmentActivity.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Schedules showing [newFragment] and reads the manager when the action runs.
///
/// The host scheduler is called once with one action, and this function does
/// not wait for that action. When it runs, the current host fragment manager is
/// read once and passed with the identical fragment token to the host display
/// adapter. Failures propagate unchanged and stop later work. Android
/// `FragmentActivity`, `FragmentManager`, and `DialogFragment` remain host-side.
void showDialogFragment<TFragmentManager, TFragment>({
  required TFragment newFragment,
  required void Function(void Function() action) runOnUiThread,
  required TFragmentManager Function() supportFragmentManager,
  required void Function(TFragmentManager manager, TFragment fragment)
  showDialogFragmentImpl,
}) {
  runOnUiThread(() {
    showDialogFragmentImpl(supportFragmentManager(), newFragment);
  });
}
