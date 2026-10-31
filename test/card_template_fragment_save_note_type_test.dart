/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from CardTemplateFragment.saveNoteType in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _Callbacks =
    CardTemplateFragmentSaveNoteTypeCallbacks<Object, Object, Object>;

void main() {
  group('cardTemplateFragmentSaveNoteType', () {
    test('unchanged note type finishes before button or task work', () {
      final events = <String>[];
      final callbacks = _callbacks(events, noteTypeHasChanged: () => false);

      expect(cardTemplateFragmentSaveNoteType(callbacks: callbacks), isTrue);
      expect(events, [
        'changed',
        'debug:CardTemplateEditor:: note type has not changed, exiting',
        'finish',
      ]);
    });

    test('disabled confirm click exits before localization and task work', () {
      final events = <String>[];
      final callbacks = _callbacks(
        events,
        noteTypeHasChanged: () => true,
        button: Object(),
        buttonEnabled: false,
      );

      expect(cardTemplateFragmentSaveNoteType(callbacks: callbacks), isTrue);
      expect(events, [
        'changed',
        'find button',
        'enabled',
        'debug:CardTemplateEditor::discarding extra click after button disabled',
      ]);
    });

    test('changed note type saves in source order and returns true', () {
      final events = <String>[];
      final model = Object();
      final activity = Object();
      final button = Object();
      final callbacks = _callbacks(
        events,
        noteTypeHasChanged: () => true,
        button: button,
        activity: activity,
        model: model,
      );

      expect(cardTemplateFragmentSaveNoteType(callbacks: callbacks), isTrue);
      expect(events, [
        'changed',
        'find button',
        'enabled',
        'disable button',
        'save error message',
        'launch:save error',
        'require activity',
        'progress message',
        'progress:saving',
        'temporary model',
        'save model',
        'model saved',
      ]);
    });

    test('Exception logs, posts re-enable, and rethrows the same object', () {
      final events = <String>[];
      final failure = FormatException('save failed');
      final button = Object();
      final callbacks = _callbacks(
        events,
        noteTypeHasChanged: () => true,
        button: button,
        failureAt: 'save model',
        failure: failure,
      );

      expect(
        () => cardTemplateFragmentSaveNoteType(callbacks: callbacks),
        throwsA(same(failure)),
      );
      expect(events, [
        'changed',
        'find button',
        'enabled',
        'disable button',
        'save error message',
        'launch:save error',
        'require activity',
        'progress message',
        'progress:saving',
        'temporary model',
        'save model',
        'error:CardTemplateEditor:: saveNoteType() failed',
        'post',
        'enable button',
      ]);
    });

    test('null confirm button still saves without view callbacks', () {
      final events = <String>[];
      final callbacks = _callbacks(
        events,
        noteTypeHasChanged: () => true,
        button: null,
      );

      expect(cardTemplateFragmentSaveNoteType(callbacks: callbacks), isTrue);
      expect(events, [
        'changed',
        'find button',
        'save error message',
        'launch:save error',
        'require activity',
        'progress message',
        'progress:saving',
        'temporary model',
        'save model',
        'model saved',
      ]);
    });

    test('Error propagates without Exception logging or button re-enable', () {
      final events = <String>[];
      final failure = AssertionError('save error');
      final callbacks = _callbacks(
        events,
        noteTypeHasChanged: () => true,
        button: Object(),
        failureAt: 'save model',
        failure: failure,
      );

      expect(
        () => cardTemplateFragmentSaveNoteType(callbacks: callbacks),
        throwsA(same(failure)),
      );
      expect(events, [
        'changed',
        'find button',
        'enabled',
        'disable button',
        'save error message',
        'launch:save error',
        'require activity',
        'progress message',
        'progress:saving',
        'temporary model',
        'save model',
      ]);
    });
  });
}

_Callbacks _callbacks(
  List<String> events, {
  required bool Function() noteTypeHasChanged,
  Object? button,
  bool buttonEnabled = true,
  Object? activity,
  Object? model,
  String? failureAt,
  Object? failure,
}) {
  final suppliedActivity = activity ?? Object();
  final suppliedModel = model ?? Object();

  void hit(String event) {
    events.add(event);
    if (failureAt == event) throw failure!;
  }

  return CardTemplateFragmentSaveNoteTypeCallbacks<Object, Object, Object>(
    noteTypeHasChanged: () {
      hit('changed');
      return noteTypeHasChanged();
    },
    debug: (message) => hit('debug:$message'),
    finish: () => hit('finish'),
    findConfirmButton: () {
      hit('find button');
      return button;
    },
    isButtonEnabled: (actualButton) {
      expect(actualButton, same(button));
      hit('enabled');
      return buttonEnabled;
    },
    setButtonEnabled: (actualButton, enabled) {
      expect(actualButton, same(button));
      hit(enabled ? 'enable button' : 'disable button');
    },
    saveErrorMessage: () {
      hit('save error message');
      return 'save error';
    },
    launchCatchingTask: (message, action) {
      hit('launch:$message');
      action();
    },
    requireActivity: () {
      hit('require activity');
      return suppliedActivity;
    },
    savingProgressMessage: () {
      hit('progress message');
      return 'saving';
    },
    withProgress: (actualActivity, message, action) {
      expect(actualActivity, same(suppliedActivity));
      hit('progress:$message');
      action();
    },
    readTemporaryModel: () {
      hit('temporary model');
      return suppliedModel;
    },
    saveToDatabase: (actualModel) {
      expect(actualModel, same(suppliedModel));
      hit('save model');
    },
    onModelSaved: () => hit('model saved'),
    logError: (message, actualFailure) {
      expect(actualFailure, same(failure));
      hit('error:$message');
    },
    post: (actualButton, action) {
      expect(actualButton, same(button));
      hit('post');
      action();
    },
  );
}
