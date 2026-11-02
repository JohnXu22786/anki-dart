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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _Callbacks =
    CardTemplateFragmentPerformPreviewCallbacks<
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
  group('cardTemplateFragmentPerformPreview', () {
    test('reads and forwards preview values in source order', () {
      final calls = <Object?>[];
      final values = _PreviewValues();

      cardTemplateFragmentPerformPreview(callbacks: _callbacks(calls, values));

      expect(calls, [
        'launch',
        'notetype',
        'context:1',
        'notetype file',
        'withCol',
        'getNote',
        'note id',
        'ordinal',
        'fields',
        'tags',
        'arguments',
        'context:2',
        'intent',
        'start activity',
      ]);
      expect(values.argumentsPayload, (
        values.notetypeFile,
        values.noteId,
        values.ordinalValue,
        values.fieldsValue,
        values.tagsValue,
        true,
      ));
      expect(values.notetypeFileInputs, (values.context, values.notetype));
      expect(values.noteIdInput, same(values.note));
      expect(values.fieldsInput, same(values.note));
      expect(values.tagsInput, same(values.note));
      expect(values.intentPayload, (values.context, values.arguments));
      expect(values.startedIntent, same(values.intent));
    });

    test('uses the existing note and lazily creates a note only on null', () {
      final values = _PreviewValues();
      final existingCalls = <Object?>[];
      cardTemplateFragmentPerformPreview(
        callbacks: _callbacks(existingCalls, values),
      );
      expect(existingCalls, isNot(contains('fallback note')));

      final fallbackValues = _PreviewValues(returnNullNote: true);
      final fallbackCalls = <Object?>[];
      cardTemplateFragmentPerformPreview(
        callbacks: _callbacks(fallbackCalls, fallbackValues),
      );
      expect(fallbackCalls, contains('fallback note'));
      expect(fallbackValues.fallbackPayload, (
        fallbackValues.collection,
        fallbackValues.notetype,
      ));
      expect(fallbackValues.noteIdInput, same(fallbackValues.fallbackNote));
    });

    test(
      'passes the exact host objects and true fillEmpty to argument creation',
      () {
        final calls = <Object?>[];
        final values = _PreviewValues();

        cardTemplateFragmentPerformPreview(
          callbacks: _callbacks(calls, values),
        );

        expect(values.argumentsPayload, (
          values.notetypeFile,
          values.noteId,
          values.ordinalValue,
          values.fieldsValue,
          values.tagsValue,
          true,
        ));
      },
    );

    test('propagates callback failures immediately without later effects', () {
      const failureStages = [
        'launch',
        'notetype',
        'context:1',
        'notetype file',
        'withCol',
        'getNote',
        'fallback note',
        'note id',
        'ordinal',
        'fields',
        'tags',
        'arguments',
        'context:2',
        'intent',
        'start activity',
      ];

      for (final stage in failureStages) {
        final failure = StateError('$stage failed');
        final calls = <Object?>[];
        final values = _PreviewValues(
          returnNullNote: true,
          failAt: stage,
          failure: failure,
        );

        expect(
          () => cardTemplateFragmentPerformPreview(
            callbacks: _callbacks(calls, values),
          ),
          throwsA(same(failure)),
          reason: 'failure at $stage should propagate',
        );
        expect(calls.last, stage);
        if (stage != 'start activity') {
          expect(
            calls,
            isNot(contains('start activity')),
            reason: 'failure at $stage should stop before activity',
          );
        }
      }
    });
  });
}

final class _PreviewValues {
  _PreviewValues({this.returnNullNote = false, this.failAt, this.failure});

  final Object context = Object();
  final Object notetype = Object();
  final Object collection = Object();
  final Object notetypeFile = Object();
  final Object note = Object();
  final Object fallbackNote = Object();
  final Object noteId = Object();
  final Object ordinalValue = Object();
  final Object fieldsValue = Object();
  final Object tagsValue = Object();
  final Object arguments = Object();
  final Object intent = Object();
  final bool returnNullNote;
  final String? failAt;
  final Object? failure;
  Object? argumentsPayload;
  Object? notetypeFileInputs;
  Object? intentPayload;
  Object? fallbackPayload;
  Object? noteIdInput;
  Object? fieldsInput;
  Object? tagsInput;
  Object? startedIntent;
}

_Callbacks _callbacks(List<Object?> calls, _PreviewValues values) {
  var contextReads = 0;

  void hit(String stage) {
    calls.add(stage);
    if (values.failAt == stage) throw values.failure!;
  }

  return CardTemplateFragmentPerformPreviewCallbacks<
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
  >(
    launchCatchingTask: (action) {
      hit('launch');
      action();
    },
    notetype: () {
      hit('notetype');
      return values.notetype;
    },
    requireContext: () {
      contextReads++;
      hit('context:$contextReads');
      return values.context;
    },
    createNotetypeFile: (context, notetype) {
      hit('notetype file');
      values.notetypeFileInputs = (context, notetype);
      return values.notetypeFile;
    },
    withCol: <TResult>(operation) {
      hit('withCol');
      return operation(values.collection);
    },
    getNote: (collection) {
      hit('getNote');
      return values.returnNullNote ? null : values.note;
    },
    createNoteFromNotetypeId: (collection, notetype) {
      hit('fallback note');
      values.fallbackPayload = (collection, notetype);
      return values.fallbackNote;
    },
    noteId: (note) {
      hit('note id');
      values.noteIdInput = note;
      return values.noteId;
    },
    ordinal: () {
      hit('ordinal');
      return values.ordinalValue;
    },
    fields: (note) {
      hit('fields');
      values.fieldsInput = note;
      return values.fieldsValue;
    },
    tags: (note) {
      hit('tags');
      values.tagsInput = note;
      return values.tagsValue;
    },
    createArguments:
        (notetypeFile, noteId, ordinal, fields, tags, {required fillEmpty}) {
          hit('arguments');
          values.argumentsPayload = (
            notetypeFile,
            noteId,
            ordinal,
            fields,
            tags,
            fillEmpty,
          );
          return values.arguments;
        },
    getIntent: (context, arguments) {
      hit('intent');
      values.intentPayload = (context, arguments);
      return values.intent;
    },
    startActivity: (intent) {
      hit('start activity');
      values.startedIntent = intent;
    },
  );
}
