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
 * Source-derived from CardTemplateBrowserAppearanceEditor.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browser appearance instance-state save', () {
    test('reads and writes question then answer before superclass save', () {
      final calls = <String>[];
      final writes = <String?>[];

      saveBrowserAppearanceInstanceState(
        readQuestionFormat: () {
          calls.add('read-question');
          return 'question';
        },
        writeQuestionFormat: (value) {
          calls.add('write-question');
          writes.add(value);
        },
        readAnswerFormat: () {
          calls.add('read-answer');
          return 'answer';
        },
        writeAnswerFormat: (value) {
          calls.add('write-answer');
          writes.add(value);
        },
        saveSuperclassState: () => calls.add('super'),
      );

      expect(calls, [
        'read-question',
        'write-question',
        'read-answer',
        'write-answer',
        'super',
      ]);
      expect(writes, ['question', 'answer']);
    });

    test('passes null saved values through unchanged', () {
      final writes = <String?>[];

      saveBrowserAppearanceInstanceState(
        readQuestionFormat: () => null,
        writeQuestionFormat: writes.add,
        readAnswerFormat: () => null,
        writeAnswerFormat: writes.add,
        saveSuperclassState: () {},
      );

      expect(writes, [null, null]);
    });

    test('question write failure stops answer access and superclass save', () {
      final exception = StateError('question write failed');
      final calls = <String>[];

      expect(
        () => saveBrowserAppearanceInstanceState(
          readQuestionFormat: () {
            calls.add('read-question');
            return 'question';
          },
          writeQuestionFormat: (_) {
            calls.add('write-question');
            throw exception;
          },
          readAnswerFormat: () {
            calls.add('read-answer');
            return 'answer';
          },
          writeAnswerFormat: (_) => calls.add('write-answer'),
          saveSuperclassState: () => calls.add('super'),
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['read-question', 'write-question']);
    });
  });

  group('browser appearance state initialization', () {
    test('applies values and performs host effects in source order', () {
      final calls = <String>[];
      var hasChangesCalls = 0;

      initializeBrowserAppearanceUiFromBundle(
        readQuestionFormatExtra: () {
          calls.add('read-question');
          return 'question';
        },
        setQuestionFormat: (value) => calls.add('question:$value'),
        readAnswerFormatExtra: () {
          calls.add('read-answer');
          return 'answer';
        },
        setAnswerFormat: (value) => calls.add('answer:$value'),
        hasChanges: () {
          hasChangesCalls++;
          calls.add('has-changes');
          return true;
        },
        setDiscardCallbackEnabled: (enabled) => calls.add('discard:$enabled'),
        enableToolbar: () => calls.add('toolbar'),
        setBrowserAppearanceTitle: () => calls.add('title'),
      );

      expect(hasChangesCalls, 1);
      expect(calls, [
        'read-question',
        'question:question',
        'read-answer',
        'answer:answer',
        'has-changes',
        'discard:true',
        'toolbar',
        'title',
      ]);
    });

    test('passes null extras through unchanged', () {
      final values = <String?>[];

      initializeBrowserAppearanceUiFromBundle(
        readQuestionFormatExtra: () => null,
        setQuestionFormat: values.add,
        readAnswerFormatExtra: () => null,
        setAnswerFormat: values.add,
        hasChanges: () => false,
        setDiscardCallbackEnabled: (_) {},
        enableToolbar: () {},
        setBrowserAppearanceTitle: () {},
      );

      expect(values, [null, null]);
    });

    test('answer setter failure stops change check and later host effects', () {
      final exception = StateError('answer setter failed');
      final calls = <String>[];

      expect(
        () => initializeBrowserAppearanceUiFromBundle(
          readQuestionFormatExtra: () {
            calls.add('read-question');
            return 'question';
          },
          setQuestionFormat: (value) => calls.add('question:$value'),
          readAnswerFormatExtra: () {
            calls.add('read-answer');
            return 'answer';
          },
          setAnswerFormat: (value) {
            calls.add('answer:$value');
            throw exception;
          },
          hasChanges: () {
            calls.add('has-changes');
            return true;
          },
          setDiscardCallbackEnabled: (_) => calls.add('discard'),
          enableToolbar: () => calls.add('toolbar'),
          setBrowserAppearanceTitle: () => calls.add('title'),
        ),
        throwsA(same(exception)),
      );
      expect(calls, [
        'read-question',
        'question:question',
        'read-answer',
        'answer:answer',
      ]);
    });
  });
}
