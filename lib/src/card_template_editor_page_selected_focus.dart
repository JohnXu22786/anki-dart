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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Requests focus in the edit field of the selected host template fragment.
///
/// A missing fragment skips all following reads and the focus request. The host
/// retains the fragment, view binding, edit field, and Android focus behavior.
/// Callback failures propagate unchanged and stop later callbacks.
void cardTemplateEditorPageSelected({
  required int position,
  required Object? Function(int position) templateFragment,
  required Object? Function(Object fragment) binding,
  required Object? Function(Object binding) editText,
  required void Function(Object editText) requestFocus,
}) {
  final fragment = templateFragment(position);
  if (fragment == null) return;

  final fragmentBinding = binding(fragment);
  if (fragmentBinding == null) return;

  final editor = editText(fragmentBinding);
  if (editor == null) return;

  requestFocus(editor);
}
