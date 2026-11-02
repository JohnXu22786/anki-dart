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

/// Reads and returns the current template, preserving the source exception boundary.
///
/// The current index is read before the guarded template access. The host read
/// callback performs its temporary-model null assertion and indexed access;
/// [isJsonException] must identify only the host's source-equivalent
/// `JSONException` type. A classified exception is passed unchanged to [warn]
/// with the source warning format and index, then null is returned. The host
/// retains Android arguments, generated model/list access, exception
/// classification, and logging.
T? cardTemplateEditorCurrentTemplate<T>({
  required int Function() readCurrentIndex,
  required T? Function(int index) readCurrentTemplate,
  required bool Function(Exception exception) isJsonException,
  required void Function(Exception exception, String message, int index) warn,
}) {
  final index = readCurrentIndex();
  try {
    return readCurrentTemplate(index);
  } on Exception catch (exception) {
    if (!isJsonException(exception)) {
      rethrow;
    }
    warn(
      exception,
      'CardTemplateEditor::getCurrentTemplate - unexpectedly unable to fetch template? %d',
      index,
    );
    return null;
  }
}
