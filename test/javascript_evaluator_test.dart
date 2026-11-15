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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('JavascriptEvaluator', () {
    test('keeps the exact source wrapper when the script is empty', () {
      final calls = <String>[];
      final evaluator = _RecordingJavascriptEvaluator(calls.add);

      evaluator.evaluateAfterDOMContentLoaded('');

      expect(calls, [
        '\n' +
            '''                var codeToRun = function() {\x20
\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
                }
\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
                if (document.readyState === "loading") {
                  document.addEventListener("DOMContentLoaded", codeToRun);
                } else {
                  codeToRun();
                }
        ''',
      ]);
    });

    test('inserts a multiline template script verbatim in one callback', () {
      final calls = <String>[];
      final evaluator = _RecordingJavascriptEvaluator(calls.add);
      const script = r'''const total = `${answer} + ${bonus}`;
run(total);''';

      evaluator.evaluateAfterDOMContentLoaded(script);

      expect(calls, [
        '\n' +
            '''                var codeToRun = function() {\x20
                    const total = `\${answer} + \${bonus}`;
run(total);
                }
\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
                if (document.readyState === "loading") {
                  document.addEventListener("DOMContentLoaded", codeToRun);
                } else {
                  codeToRun();
                }
        ''',
      ]);
    });

    test('propagates the identical callback error after one call', () {
      final error = StateError('evaluation failed');
      var calls = 0;
      final evaluator = _RecordingJavascriptEvaluator((_) {
        calls++;
        throw error;
      });

      expect(
        () => evaluator.evaluateAfterDOMContentLoaded('run();'),
        throwsA(same(error)),
      );
      expect(calls, 1);
    });
  });
}

class _RecordingJavascriptEvaluator extends JavascriptEvaluator {
  _RecordingJavascriptEvaluator(this._callback);

  final void Function(String js) _callback;

  @override
  void eval(String js) => _callback(js);
}
