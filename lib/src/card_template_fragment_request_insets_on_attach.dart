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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host adapter for `View.doOnAttach`.
///
/// The host retains Android `View` access, attach-listener registration,
/// lifecycle, and `ViewCompat.requestApplyInsets`.
typedef CardTemplateFragmentDoOnAttach<TView> =
    void Function(TView view, void Function(TView attachedView) callback);

/// Registers the host's inset request for the template fragment root.
///
/// The root is resolved once as the `doOnAttach` receiver. The host decides
/// when its attach callback runs, including its behavior for an already
/// attached view. Each invocation forwards the exact attached view once;
/// callback failures propagate unchanged.
void cardTemplateFragmentRequestInsetsOnAttach<TView>({
  required TView Function() root,
  required CardTemplateFragmentDoOnAttach<TView> doOnAttach,
  required void Function(TView view) requestApplyInsets,
}) {
  final receiver = root();
  doOnAttach(receiver, requestApplyInsets);
}
