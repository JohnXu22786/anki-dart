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
 * Source-derived from Fragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'fragment_activity_show_dialog_fragment.dart';

/// Resolves [fragment]'s host Activity, then delegates dialog display to it.
///
/// The Activity is required once before UI scheduling and is captured by both
/// Activity callbacks. Scheduling, deferred manager lookup, and host display
/// use [showDialogFragment]. Android Fragment, FragmentActivity, FragmentManager,
/// and DialogFragment remain host-side. Failures propagate unchanged.
void fragmentShowDialogFragment<
  TFragment,
  TFragmentActivity,
  TFragmentManager,
  TDialogFragment
>({
  required TFragment fragment,
  required TDialogFragment newFragment,
  required TFragmentActivity Function(TFragment fragment) requireActivity,
  required void Function(TFragmentActivity activity, void Function() action)
  runOnUiThread,
  required TFragmentManager Function(TFragmentActivity activity)
  supportFragmentManager,
  required void Function(TFragmentManager manager, TDialogFragment fragment)
  showDialogFragmentImpl,
}) {
  final activity = requireActivity(fragment);
  showDialogFragment<TFragmentManager, TDialogFragment>(
    newFragment: newFragment,
    runOnUiThread: (action) => runOnUiThread(activity, action),
    supportFragmentManager: () => supportFragmentManager(activity),
    showDialogFragmentImpl: showDialogFragmentImpl,
  );
}
