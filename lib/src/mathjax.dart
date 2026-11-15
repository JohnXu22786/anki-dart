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
 * Behavioral reference: MathJax.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Detects MathJax delimiters using AnkiDroid's source-compatible index check.
///
/// This reports whether supported delimiter pairs appear in text. Rendering,
/// including MathJax and WebView setup, remains the host application's job.
class MathJax {
  MathJax._();

  static const _openings = [r'\(', r'\['];
  static const _closings = [r'\)', r'\]'];

  /// Returns true when the first opener precedes the last matching closer.
  ///
  /// Each delimiter type is checked independently. This intentionally mirrors
  /// the source algorithm rather than parsing or validating expression syntax.
  static bool textContainsMathjax(String txt) {
    for (var i = 0; i < _openings.length; i++) {
      final firstOpeningIndex = txt.indexOf(_openings[i]);
      final lastClosingIndex = txt.lastIndexOf(_closings[i]);
      if (firstOpeningIndex != -1 &&
          lastClosingIndex != -1 &&
          firstOpeningIndex < lastClosingIndex) {
        return true;
      }
    }
    return false;
  }
}
