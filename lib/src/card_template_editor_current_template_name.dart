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

/// Reads the current template name, preserving the source's Exception boundary.
///
/// The host supplies a callback that reads the current template ordinal and a
/// callback that reads the name by that ordinal. Both callbacks run inside the
/// same source-compatible `Exception` boundary, in that order. If either read
/// throws an [Exception], [warn] is called once with that exception before an
/// empty string is returned. Errors and failures from [warn] propagate.
/// Backend model access and Timber logging stay with the host.
String cardTemplateEditorCurrentTemplateName({
  required int Function() readCurrentOrdinal,
  required String Function(int ordinal) readTemplateName,
  required void Function(Exception exception) warn,
}) {
  try {
    return readTemplateName(readCurrentOrdinal());
  } on Exception catch (exception) {
    warn(exception);
    return '';
  }
}
