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

/// Tag used by AnkiDroid dialog fragments in the fragment back stack.
const dialogFragmentTag = 'dialog';

/// AndroidX `FragmentManager.POP_BACK_STACK_INCLUSIVE` from the pinned source.
const popBackStackInclusiveFlag = 1;

/// Pops the tagged dialog-fragment back stack unless the host state is saved.
///
/// [isStateSaved] is read once. If it returns true, [popBackStack] is not
/// called. Otherwise, the host receives the exact dialog tag and inclusive flag
/// once, in that order. Callback failures propagate unchanged and prevent later
/// work. Android `FragmentActivity` and `FragmentManager` remain host-side.
void dismissAllDialogFragments({
  required bool Function() isStateSaved,
  required void Function(String name, int flags) popBackStack,
}) {
  if (!isStateSaved()) {
    popBackStack(dialogFragmentTag, popBackStackInclusiveFlag);
  }
}
