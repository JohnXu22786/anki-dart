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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

const _cardTemplateFragmentCurrentTemplateWarning =
    'Exception loading template in CardTemplateFragment. Probably stale fragment.';

/// Projects the fragment's current template inside its source Exception boundary.
///
/// [readAndProjectCurrentTemplate] is one host callback: it reads
/// `tempNoteType`, asserts it is non-null, resolves the current ordinal, fetches
/// the backend template, reads `qfmt`, `afmt`, then `css`, and constructs the
/// host-projected CardTemplate in front/back/style order. The callback must
/// preserve those source operations and values without normalization. Android
/// ordinal access, backend model access, `BackendCardTemplate`, and Timber stay
/// host-side. Any [Exception] from the full callback is passed unchanged to
/// [warn] once with the source message before null is returned; [Error] and failures from [warn]
/// propagate.
T? cardTemplateFragmentCurrentTemplate<T>({
  required T Function() readAndProjectCurrentTemplate,
  required void Function(Exception exception, String message) warn,
}) {
  try {
    return readAndProjectCurrentTemplate();
  } on Exception catch (exception) {
    warn(exception, _cardTemplateFragmentCurrentTemplateWarning);
    return null;
  }
}
