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

/// Returns the first localized card-template name not already in [existingNames].
///
/// [templateCount] is the host-resolved `CardTemplates.length()`. The host also
/// owns the ordered names and localization callback; this helper preserves the
/// source's signed 32-bit `Int` wrap, exact name equality, and iteration order.
String newCardName({
  required int templateCount,
  required Iterable<String> existingNames,
  required String Function(int number) localizeName,
}) {
  var number = _toInt32(templateCount + 1);
  while (true) {
    final candidate = localizeName(number);
    var matches = false;
    for (final existingName in existingNames) {
      if (candidate == existingName) {
        matches = true;
        break;
      }
    }
    if (!matches) {
      return candidate;
    }
    number = _toInt32(number + 1);
  }
}

int _toInt32(int value) {
  final wrapped = value & 0xffffffff;
  return wrapped >= 0x80000000 ? wrapped - 0x100000000 : wrapped;
}
