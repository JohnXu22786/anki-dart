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
  group('browser appearance onCreate', () {
    test('failed screen short-circuits every later callback', () {
      final calls = <String>[];

      createBrowserAppearanceEditor<String>(
        showedActivityFailedScreen: (state) {
          calls.add('failed-screen:$state');
          return true;
        },
        superOnCreate: (_) => calls.add('super'),
        enableEdgeToEdge: () => calls.add('edge-to-edge'),
        installToolbarInsetsListener: () => calls.add('toolbar-insets'),
        installContentInsetsListener: () => calls.add('content-insets'),
        savedInstanceState: 'saved',
        readIntentExtras: () {
          calls.add('intent-extras');
          return 'intent';
        },
        showThemedErrorToast: () => calls.add('toast'),
        finish: () => calls.add('finish'),
        initializeFromBundle: (_) => calls.add('initialize'),
        setResultCanceled: () => calls.add('result-canceled'),
        registerBackCallback: () => calls.add('back-callback'),
        addQuestionTextListener: (_) => calls.add('question-listener'),
        addAnswerTextListener: (_) => calls.add('answer-listener'),
        hasChanges: () => false,
        setDiscardCallbackEnabled: (_) => calls.add('discard-enabled'),
      );

      expect(calls, ['failed-screen:saved']);
    });

    test('saved state takes precedence without reading intent extras', () {
      final calls = <String>[];

      createBrowserAppearanceEditor<String>(
        showedActivityFailedScreen: (_) => false,
        superOnCreate: (_) => calls.add('super'),
        enableEdgeToEdge: () => calls.add('edge-to-edge'),
        installToolbarInsetsListener: () => calls.add('toolbar-insets'),
        installContentInsetsListener: () => calls.add('content-insets'),
        savedInstanceState: 'saved',
        readIntentExtras: () {
          calls.add('intent-extras');
          return 'intent';
        },
        showThemedErrorToast: () => calls.add('toast'),
        finish: () => calls.add('finish'),
        initializeFromBundle: (bundle) => calls.add('initialize:$bundle'),
        setResultCanceled: () => calls.add('result-canceled'),
        registerBackCallback: () => calls.add('back-callback'),
        addQuestionTextListener: (_) => calls.add('question-listener'),
        addAnswerTextListener: (_) => calls.add('answer-listener'),
        hasChanges: () => false,
        setDiscardCallbackEnabled: (_) => calls.add('discard-enabled'),
      );

      expect(calls, [
        'super',
        'edge-to-edge',
        'toolbar-insets',
        'content-insets',
        'initialize:saved',
        'result-canceled',
        'back-callback',
        'question-listener',
        'answer-listener',
      ]);
    });

    test('missing bundle shows toast then finishes without initialization', () {
      final calls = <String>[];

      createBrowserAppearanceEditor<String>(
        showedActivityFailedScreen: (_) => false,
        superOnCreate: (_) => calls.add('super'),
        enableEdgeToEdge: () => calls.add('edge-to-edge'),
        installToolbarInsetsListener: () => calls.add('toolbar-insets'),
        installContentInsetsListener: () => calls.add('content-insets'),
        savedInstanceState: null,
        readIntentExtras: () {
          calls.add('intent-extras');
          return null;
        },
        showThemedErrorToast: () => calls.add('toast'),
        finish: () => calls.add('finish'),
        initializeFromBundle: (_) => calls.add('initialize'),
        setResultCanceled: () => calls.add('result-canceled'),
        registerBackCallback: () => calls.add('back-callback'),
        addQuestionTextListener: (_) => calls.add('question-listener'),
        addAnswerTextListener: (_) => calls.add('answer-listener'),
        hasChanges: () => false,
        setDiscardCallbackEnabled: (_) => calls.add('discard-enabled'),
      );

      expect(calls, [
        'super',
        'edge-to-edge',
        'toolbar-insets',
        'content-insets',
        'intent-extras',
        'toast',
        'finish',
      ]);
    });

    test('intent extras are read only when saved state is null', () {
      final calls = <String>[];

      createBrowserAppearanceEditor<String>(
        showedActivityFailedScreen: (_) => false,
        superOnCreate: (_) => calls.add('super'),
        enableEdgeToEdge: () => calls.add('edge-to-edge'),
        installToolbarInsetsListener: () => calls.add('toolbar-insets'),
        installContentInsetsListener: () => calls.add('content-insets'),
        savedInstanceState: null,
        readIntentExtras: () {
          calls.add('intent-extras');
          return 'intent';
        },
        showThemedErrorToast: () => calls.add('toast'),
        finish: () => calls.add('finish'),
        initializeFromBundle: (bundle) => calls.add('initialize:$bundle'),
        setResultCanceled: () => calls.add('result-canceled'),
        registerBackCallback: () => calls.add('back-callback'),
        addQuestionTextListener: (_) => calls.add('question-listener'),
        addAnswerTextListener: (_) => calls.add('answer-listener'),
        hasChanges: () => false,
        setDiscardCallbackEnabled: (_) => calls.add('discard-enabled'),
      );

      expect(calls, [
        'super',
        'edge-to-edge',
        'toolbar-insets',
        'content-insets',
        'intent-extras',
        'initialize:intent',
        'result-canceled',
        'back-callback',
        'question-listener',
        'answer-listener',
      ]);
    });

    test('registers watchers in order and evaluates each change lazily', () {
      final calls = <String>[];
      void Function(Object?)? questionListener;
      void Function(Object?)? answerListener;
      var changeChecks = 0;
      final enabledStates = <bool>[];

      createBrowserAppearanceEditor<String>(
        showedActivityFailedScreen: (_) => false,
        superOnCreate: (_) => calls.add('super'),
        enableEdgeToEdge: () => calls.add('edge-to-edge'),
        installToolbarInsetsListener: () => calls.add('toolbar-insets'),
        installContentInsetsListener: () => calls.add('content-insets'),
        savedInstanceState: 'saved',
        readIntentExtras: () => fail('saved state must win'),
        showThemedErrorToast: () => fail('bundle exists'),
        finish: () => fail('bundle exists'),
        initializeFromBundle: (bundle) => calls.add('initialize:$bundle'),
        setResultCanceled: () => calls.add('result-canceled'),
        registerBackCallback: () => calls.add('back-callback'),
        addQuestionTextListener: (listener) {
          calls.add('question-listener');
          questionListener = listener;
        },
        addAnswerTextListener: (listener) {
          calls.add('answer-listener');
          answerListener = listener;
        },
        hasChanges: () {
          changeChecks++;
          calls.add('has-changes:$changeChecks');
          return changeChecks.isOdd;
        },
        setDiscardCallbackEnabled: (enabled) {
          calls.add('discard:$enabled');
          enabledStates.add(enabled);
        },
      );

      expect(calls, [
        'super',
        'edge-to-edge',
        'toolbar-insets',
        'content-insets',
        'initialize:saved',
        'result-canceled',
        'back-callback',
        'question-listener',
        'answer-listener',
      ]);
      expect(changeChecks, 0);

      questionListener!('ignored question value');
      answerListener!('ignored answer value');

      expect(enabledStates, [true, false]);
      expect(changeChecks, 2);
      expect(calls.sublist(9), [
        'has-changes:1',
        'discard:true',
        'has-changes:2',
        'discard:false',
      ]);
    });

    test('initialization failure stops result and listener registration', () {
      final exception = StateError('initialize failed');
      final calls = <String>[];

      expect(
        () => createBrowserAppearanceEditor<String>(
          showedActivityFailedScreen: (_) => false,
          superOnCreate: (_) => calls.add('super'),
          enableEdgeToEdge: () => calls.add('edge-to-edge'),
          installToolbarInsetsListener: () => calls.add('toolbar-insets'),
          installContentInsetsListener: () => calls.add('content-insets'),
          savedInstanceState: 'saved',
          readIntentExtras: () => fail('saved state must win'),
          showThemedErrorToast: () => fail('bundle exists'),
          finish: () => fail('bundle exists'),
          initializeFromBundle: (_) {
            calls.add('initialize');
            throw exception;
          },
          setResultCanceled: () => calls.add('result-canceled'),
          registerBackCallback: () => calls.add('back-callback'),
          addQuestionTextListener: (_) => calls.add('question-listener'),
          addAnswerTextListener: (_) => calls.add('answer-listener'),
          hasChanges: () => false,
          setDiscardCallbackEnabled: (_) => calls.add('discard-enabled'),
        ),
        throwsA(same(exception)),
      );

      expect(calls, [
        'super',
        'edge-to-edge',
        'toolbar-insets',
        'content-insets',
        'initialize',
      ]);
    });
  });
}
