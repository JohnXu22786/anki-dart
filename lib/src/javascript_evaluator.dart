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
 * Source-derived from JavascriptEvaluator.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host callback for evaluating JavaScript in the WebView.
///
/// This port only builds the source wrapper and delegates it to [eval]. The
/// host retains document state and JavaScript execution.
abstract class JavascriptEvaluator {
  /// Evaluates [js] in the host WebView.
  void eval(String js);

  /// Builds the source wrapper and sends it to [eval] once.
  ///
  /// This preserves the upstream raw string's indentation and whitespace. The
  /// supplied [script] is interpolated verbatim; it is not executed in Dart.
  void evaluateAfterDOMContentLoaded(String script) {
    // Restore the initial newline Kotlin keeps; Dart drops it after triple quotes.
    eval(
      '\n' +
          '''                var codeToRun = function() {\x20
                    $script
                }
\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
                if (document.readyState === "loading") {
                  document.addEventListener("DOMContentLoaded", codeToRun);
                } else {
                  codeToRun();
                }
        ''',
    );
  }
}
