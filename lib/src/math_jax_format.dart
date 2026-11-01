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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: MathJaxFormat.kt and Toolbar.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_string_hash_code.dart';

/// MathJax text wrappers supported by AnkiDroid's note-editor toolbar.
///
/// Localized labels and editor/UI integration remain the host's responsibility.
enum MathJaxFormat {
  BLOCK(r'\[', r'\]'),
  CHEMISTRY(r'\( \ce{', r'} \)');

  const MathJaxFormat(this.prefix, this.suffix);

  final String prefix;
  final String suffix;

  /// Wraps [input] and computes the source-compatible selection range.
  StringFormat toTextWrapper(String input) {
    final text = '$prefix$input$suffix';
    final selection = input.isEmpty ? prefix.length : 0;
    return StringFormat(
      text,
      selection,
      input.isEmpty ? selection : text.length,
    );
  }
}

/// Mutable result matching `Toolbar.StringFormat`'s Kotlin data-class values.
class StringFormat {
  StringFormat(this.result, this.selectionStart, this.selectionEnd);

  String result;
  int selectionStart;
  int selectionEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringFormat &&
          result == other.result &&
          selectionStart == other.selectionStart &&
          selectionEnd == other.selectionEnd;

  @override
  int get hashCode {
    var hash = kotlinStringHashCode(result);
    hash = (hash * 31 + selectionStart) & 0xffffffff;
    hash = (hash * 31 + selectionEnd) & 0xffffffff;
    return hash >= 0x80000000 ? hash - 0x100000000 : hash;
  }

  @override
  String toString() =>
      'StringFormat(result=$result, selectionStart=$selectionStart, '
      'selectionEnd=$selectionEnd)';
}
