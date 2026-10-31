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

/// Schedules focus for the current template fragment's edit field.
///
/// A non-current page skips all edit-field and focus work. The current field is
/// resolved once as the host's post receiver, then resolved again only when
/// the posted action runs. The host retains pager state, Android views, posting,
/// and focus behavior. No keyboard is shown. Callback failures propagate.
void cardTemplateFragmentScheduleInitialFocus<TEditText>({
  required bool Function() isCurrentPage,
  required TEditText Function() editText,
  required void Function(TEditText view, void Function() action) post,
  required void Function(TEditText editText) requestFocus,
}) {
  if (!isCurrentPage()) return;

  final postReceiver = editText();
  post(postReceiver, () {
    requestFocus(editText());
  });
}
