/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _Callbacks =
    CardTemplateFragmentLoadPreviewerIfFragmentedCallbacks<
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object,
      Object
    >;

void main() {
  group('cardTemplateFragmentLoadPreviewerIfFragmented', () {
    test(
      'evaluates default ordinal before fragmented and skips task when false',
      () {
        final state = _State(fragmentedValue: false);
        cardTemplateFragmentLoadPreviewerIfFragmented(
          callbacks: state.callbacks(),
        );
        expect(state.calls, ['pager current item', 'fragmented']);
      },
    );

    test('explicit ordinal bypasses pager read before fragmented guard', () {
      final state = _State(fragmentedValue: false);
      cardTemplateFragmentLoadPreviewerIfFragmented(
        callbacks: state.callbacks(),
        ordinal: state.explicitOrdinal,
      );
      expect(state.calls, ['fragmented']);
    });

    test('schedules task and uses fallback for an absent current fragment', () {
      final state = _State(absentFragment: true);
      cardTemplateFragmentLoadPreviewerIfFragmented(
        callbacks: state.callbacks(),
      );
      expect(state.calls, ['pager current item', 'fragmented', 'launch']);
      expect(state.task, isNotNull);
      state.task!();
      expect(state.calls, [
        'pager current item',
        'fragmented',
        'launch',
        'assert notetype',
        'activity context',
        'notetype file',
        'withCol',
        'current fragment',
        'notetype id',
        'note from notetype',
        'note id',
        'note fields',
        'note tags',
        'arguments',
        'create fragment',
        'commit now',
        'fragment view',
        'post callback',
      ]);
      expect(state.fallbackInput, (state.collection, state.notetypeId));
      expect(state.argumentsInput, (
        state.notetypeFile,
        state.fallbackNote,
        state.pagerOrdinal,
        state.fields,
        state.tags,
        true,
      ));
    });

    test(
      'uses current fragment note, falling back only when its result is null',
      () {
        final existing = _State();
        cardTemplateFragmentLoadPreviewerIfFragmented(
          callbacks: existing.callbacks(),
        );
        existing.task!();
        expect(existing.calls, contains('get note'));
        expect(existing.calls, isNot(contains('note from notetype')));
        expect(existing.argumentsInput, (
          existing.notetypeFile,
          existing.noteFromFragment,
          existing.pagerOrdinal,
          existing.fields,
          existing.tags,
          true,
        ));

        final nullResult = _State(nullFragmentNote: true);
        cardTemplateFragmentLoadPreviewerIfFragmented(
          callbacks: nullResult.callbacks(),
        );
        nullResult.task!();
        expect(nullResult.calls, contains('note from notetype'));
        expect(nullResult.fallbackInput, (
          nullResult.collection,
          nullResult.notetypeId,
        ));
      },
    );

    test('preserves preview argument and synchronous commit order', () {
      final state = _State();
      cardTemplateFragmentLoadPreviewerIfFragmented(
        callbacks: state.callbacks(),
        ordinal: state.explicitOrdinal,
      );
      state.task!();
      expect(
        state.calls.indexOf('arguments'),
        lessThan(state.calls.indexOf('create fragment')),
      );
      expect(
        state.calls.indexOf('create fragment'),
        lessThan(state.calls.indexOf('commit now')),
      );
      expect(
        state.calls.indexOf('commit now'),
        lessThan(state.calls.indexOf('fragment view')),
      );
      expect(state.argumentsInput, (
        state.notetypeFile,
        state.noteFromFragment,
        state.explicitOrdinal,
        state.fields,
        state.tags,
        true,
      ));
      expect(state.committedContainer, same(state.fragmentContainerId));
    });

    test(
      'does not post layout callback when committed fragment has null view',
      () {
        final state = _State(nullView: true);
        cardTemplateFragmentLoadPreviewerIfFragmented(
          callbacks: state.callbacks(),
        );
        state.task!();
        expect(state.calls, isNot(contains('post callback')));
        expect(state.calls, isNot(contains('show answer')));
      },
    );

    test(
      'defers layout effects and applies button then web margin changes in order',
      () {
        final state = _State();
        cardTemplateFragmentLoadPreviewerIfFragmented(
          callbacks: state.callbacks(),
        );
        state.task!();
        expect(state.calls, isNot(contains('show answer')));
        final posted = state.postedCallback!;
        posted();
        expect(state.calls.last, 'assign web params');
        expect(state.calls.sublist(state.calls.indexOf('show answer')), [
          'show answer',
          'button params',
          'button context',
          '80dp conversion',
          'set button height',
          'request button layout',
          'webview container',
          'container params',
          'margin params cast',
          'reviewer margin resource',
          'set top margin',
          'assign web params',
        ]);
        expect(state.buttonHeightInput, (80, state.buttonContext));
        expect(state.buttonHeight, 80);
        expect(state.topMargin, state.reviewerMargin);
        expect(state.assignedMarginParams, same(state.containerLayoutParams));
      },
    );

    test(
      'callback failures stop later effects and margin cast failures propagate',
      () {
        for (final stage in [
          'assert notetype',
          'withCol',
          'commit now',
          'fragment view',
          'show answer',
          'button params',
          'button context',
          '80dp conversion',
          'set button height',
          'request button layout',
          'margin params cast',
          'webview container',
          'container params',
          'reviewer margin resource',
          'set top margin',
        ]) {
          final failure = StateError('$stage failed');
          final state = _State(failAt: stage, failure: failure);
          cardTemplateFragmentLoadPreviewerIfFragmented(
            callbacks: state.callbacks(),
          );
          if (state.task != null) {
            if (stage == 'show answer' ||
                stage == 'button params' ||
                stage == 'button context' ||
                stage == '80dp conversion' ||
                stage == 'set button height' ||
                stage == 'request button layout' ||
                stage == 'webview container' ||
                stage == 'container params' ||
                stage == 'margin params cast' ||
                stage == 'reviewer margin resource' ||
                stage == 'set top margin') {
              state.task!();
              expect(state.postedCallback, isNotNull);
              expect(
                state.postedCallback,
                throwsA(same(failure)),
                reason: stage,
              );
            } else {
              expect(state.task, throwsA(same(failure)), reason: stage);
            }
          } else {
            expect(() {}, returnsNormally);
          }
        }

        final failure = TypeError();
        final state = _State(failCast: true, failure: failure);
        cardTemplateFragmentLoadPreviewerIfFragmented(
          callbacks: state.callbacks(),
        );
        state.task!();
        expect(state.postedCallback, throwsA(same(failure)));
        expect(state.calls, isNot(contains('reviewer margin resource')));
      },
    );
  });
}

final class _State {
  _State({
    this.fragmentedValue = true,
    bool absentFragment = false,
    bool nullFragmentNote = false,
    bool nullView = false,
    this.failAt,
    this.failure,
    this.failCast = false,
  }) : currentFragmentValue = absentFragment ? null : existingFragment,
       noteFromFragment = nullFragmentNote ? null : existingNote,
       viewValue = nullView ? null : _view;

  static final Object existingFragment = Object();
  static final Object existingNote = Object();
  static final Object _view = Object();

  final bool fragmentedValue;
  final Object? currentFragmentValue;
  final Object? noteFromFragment;
  final Object? viewValue;
  final String? failAt;
  final Object? failure;
  final bool failCast;
  final calls = <String>[];
  final pagerOrdinal = Object();
  final explicitOrdinal = Object();
  final notetype = Object();
  final notetypeId = Object();
  final collection = Object();
  final context = Object();
  final notetypeFile = Object();
  final fallbackNote = Object();
  final fields = Object();
  final tags = Object();
  final args = Object();
  final fragment = Object();
  final fragmentContainerId = Object();
  final button = Object();
  final buttonContext = Object();
  final buttonLayoutParams = Object();
  final webContainer = Object();
  final containerLayoutParams = Object();
  final int reviewerMargin = 23;
  void Function()? task;
  void Function()? postedCallback;
  Object? fallbackInput;
  Object? argumentsInput;
  Object? committedContainer;
  Object? buttonHeightInput;
  int? buttonHeight;
  int? topMargin;
  Object? assignedMarginParams;

  void hit(String stage) {
    calls.add(stage);
    if (failAt == stage) throw failure!;
  }

  _Callbacks callbacks() => _Callbacks(
    pagerCurrentItem: () {
      hit('pager current item');
      return pagerOrdinal;
    },
    fragmented: () {
      hit('fragmented');
      return fragmentedValue;
    },
    launchCatchingTask: (action) {
      hit('launch');
      task = action;
    },
    notetype: () {
      hit('assert notetype');
      return notetype;
    },
    activityContext: () {
      hit('activity context');
      return context;
    },
    createNotetypeFile: (context, notetype) {
      hit('notetype file');
      return notetypeFile;
    },
    withCol: <TResult>(action) {
      hit('withCol');
      return action(collection);
    },
    currentFragment: () {
      hit('current fragment');
      return currentFragmentValue;
    },
    getNote: (fragment, collection) {
      hit('get note');
      return noteFromFragment;
    },
    notetypeId: (notetype) {
      hit('notetype id');
      return this.notetypeId;
    },
    createNoteFromNotetypeId: (collection, id) {
      hit('note from notetype');
      fallbackInput = (collection, id);
      return fallbackNote;
    },
    noteId: (note) {
      hit('note id');
      return note;
    },
    fields: (note) {
      hit('note fields');
      return this.fields;
    },
    tags: (note) {
      hit('note tags');
      return this.tags;
    },
    createArguments: (file, id, ordinal, fields, tags, {required fillEmpty}) {
      hit('arguments');
      argumentsInput = (file, id, ordinal, fields, tags, fillEmpty);
      return args;
    },
    createFragment: (arguments) {
      hit('create fragment');
      return fragment;
    },
    fragmentContainerId: () => fragmentContainerId,
    commitNow: (container, fragment) {
      hit('commit now');
      committedContainer = container;
    },
    fragmentView: (fragment) {
      hit('fragment view');
      return viewValue;
    },
    post: (view, callback) {
      hit('post callback');
      postedCallback = callback;
    },
    showAnswerButton: (fragment) {
      hit('show answer');
      return button;
    },
    buttonContext: (button) {
      hit('button context');
      return this.buttonContext;
    },
    buttonLayoutParams: (button) {
      hit('button params');
      return buttonLayoutParams;
    },
    toPx: (dp, context) {
      hit('80dp conversion');
      buttonHeightInput = (dp, context);
      return 80;
    },
    setButtonHeight: (params, height) {
      hit('set button height');
      buttonHeight = height;
    },
    requestButtonLayout: (button) {
      hit('request button layout');
    },
    webViewContainer: (fragment) {
      hit('webview container');
      return webContainer;
    },
    containerLayoutParams: (container) {
      hit('container params');
      return containerLayoutParams;
    },
    asMarginLayoutParams: (params) {
      hit('margin params cast');
      if (failCast) throw failure!;
      return params;
    },
    reviewerSideMarginPx: () {
      hit('reviewer margin resource');
      return reviewerMargin;
    },
    setTopMargin: (params, margin) {
      hit('set top margin');
      topMargin = margin;
    },
    assignContainerLayoutParams: (container, params) {
      hit('assign web params');
      assignedMarginParams = params;
    },
  );
}
