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
 * Source-derived from BottomSheetDialogFragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Reads a dialog's Material bottom-sheet behavior through host callbacks.
///
/// The host supplies its exact `com.google.android.material.R.id.design_bottom_sheet`
/// value as [designBottomSheetResourceId]. [requireDialog] runs once, then
/// [findViewById] runs once on that dialog with the same resource ID. A missing
/// view throws through Dart's null assertion, matching Kotlin's `!!`. The exact
/// view returned is passed once to [bottomSheetBehaviorFrom], whose result is
/// returned unchanged. Android dialog, view, resource, and Material behavior
/// implementations remain host-side; callback failures propagate unchanged.
TBehavior bottomSheetDialogFragmentBehavior<
  TFragment,
  TDialog,
  TView,
  TBehavior,
  TViewId
>({
  required TFragment fragment,
  required TViewId designBottomSheetResourceId,
  required TDialog Function(TFragment fragment) requireDialog,
  required TView? Function(TDialog dialog, TViewId resourceId) findViewById,
  required TBehavior Function(TView view) bottomSheetBehaviorFrom,
}) {
  final dialog = requireDialog(fragment);
  final view = findViewById(dialog, designBottomSheetResourceId)!;
  return bottomSheetBehaviorFrom(view);
}
