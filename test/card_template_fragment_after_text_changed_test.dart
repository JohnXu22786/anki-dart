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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardTemplateFragment.afterTextChanged', () {
    for (final entry in <(Object?, String, String)>[
      (CardTemplateEditorEditTab.STYLING, 'css', 'set-css'),
      (CardTemplateEditorEditTab.BACK, 'answer', 'set-answer'),
      (CardTemplateEditorEditTab.FRONT, 'question', 'set-question'),
      (null, 'question', 'set-question'),
      ('unknown', 'question', 'set-question'),
    ]) {
      test('routes ${entry.$1} and preserves source callback order', () {
        final harness = _Harness(tab: entry.$1);

        cardTemplateFragmentAfterTextChanged<Object, Object, Object, int>(
          editable: Object(),
          callbacks: harness.callbacks,
        );

        expect(harness.events, [
          'read-previous',
          'read-tab',
          if (entry.$1 == CardTemplateEditorEditTab.STYLING) 'read-model-css',
          'read-text',
          entry.$3,
          'read-model-update',
          'read-index',
          'update-template',
          'create-runnable',
          'set-runnable',
          'post-delayed:1000',
          'update-discard',
        ]);
        expect(harness.assignedValue, 'edited text');
        expect(harness.updatedTemplate, same(harness.template));
        expect(harness.updatedIndex, 4);
        expect(harness.scheduledRunnable, same(harness.createdRunnable));
        expect(harness.currentRunnable, same(harness.createdRunnable));

        harness.createdRunnable!.action();
        expect(harness.events.last, 'load-preview');
      });
    }

    test('cancels only a non-null prior delayed runnable', () {
      final harness = _Harness(tab: CardTemplateEditorEditTab.FRONT);
      harness.previousRunnable = _Runnable(() {});

      cardTemplateFragmentAfterTextChanged<Object, Object, Object, int>(
        editable: Object(),
        callbacks: harness.callbacks,
      );

      expect(harness.events.take(3), [
        'read-previous',
        'remove-previous',
        'read-tab',
      ]);
    });

    test('ignores the Editable argument', () {
      final first = _Harness(tab: CardTemplateEditorEditTab.FRONT);
      final second = _Harness(tab: CardTemplateEditorEditTab.FRONT);

      cardTemplateFragmentAfterTextChanged<Object, Object, Object, int>(
        editable: 'first editable',
        callbacks: first.callbacks,
      );
      cardTemplateFragmentAfterTextChanged<Object, Object, Object, int>(
        editable: 'different editable',
        callbacks: second.callbacks,
      );

      expect(first.events, second.events);
      expect(first.assignedValue, second.assignedValue);
    });
  });
}

final class _Harness {
  _Harness({required this.tab});

  final Object? tab;
  final events = <String>[];
  final template = Object();
  final model = Object();
  _Runnable? createdRunnable;
  Object? currentRunnable;
  Object? previousRunnable;
  Object? scheduledRunnable;
  Object? assignedValue;
  Object? updatedTemplate;
  int? updatedIndex;

  CardTemplateFragmentAfterTextChangedCallbacks<Object, Object, Object, int>
  get callbacks => CardTemplateFragmentAfterTextChangedCallbacks(
    currentRefreshRunnable: () {
      events.add('read-previous');
      return previousRunnable;
    },
    removeCallbacks: (_) => events.add('remove-previous'),
    currentEditTab: () {
      events.add('read-tab');
      return tab;
    },
    editorText: () {
      events.add('read-text');
      return 'edited text';
    },
    template: template,
    temporaryModel: () {
      final readingCss =
          tab == CardTemplateEditorEditTab.STYLING &&
          !events.contains('set-css');
      events.add(readingCss ? 'read-model-css' : 'read-model-update');
      return model;
    },
    cardIndex: () {
      events.add('read-index');
      return 4;
    },
    setCss: (_, value) {
      events.add('set-css');
      assignedValue = value;
    },
    setAnswerFormat: (_, value) {
      events.add('set-answer');
      assignedValue = value;
    },
    setQuestionFormat: (_, value) {
      events.add('set-question');
      assignedValue = value;
    },
    updateTemplate: (_, index, value) {
      events.add('update-template');
      updatedIndex = index;
      updatedTemplate = value;
    },
    createRunnable: (action) {
      events.add('create-runnable');
      final runnable = _Runnable(action);
      createdRunnable = runnable;
      return runnable;
    },
    setCurrentRefreshRunnable: (runnable) {
      events.add('set-runnable');
      currentRunnable = runnable;
    },
    postDelayed: (value, delay) {
      events.add('post-delayed:$delay');
      scheduledRunnable = value;
    },
    refreshPreviewDelay: 1000,
    loadTemplatePreviewerFragmentIfFragmented: () => events.add('load-preview'),
    updateDiscardChangesCallback: () => events.add('update-discard'),
  );
}

final class _Runnable {
  _Runnable(this.action);

  final void Function() action;
}
