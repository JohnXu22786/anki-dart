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
 * Source-derived from CardTemplateFragment.restoreNotetypeToStock in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentRestoreNotetypeToStock', () {
    test(
      'awaits restore before saving and showing the localized toast',
      () async {
        final events = <String>[];
        final temporaryModel = Object();
        final noteTypeId = Object();
        final kind = Object();
        final context = Object();
        final toastText = Object();
        final restoreCompletion = Completer<void>();

        final result = cardTemplateFragmentRestoreNotetypeToStock(
          kind: kind,
          callbacks: _callbacks(
            events,
            temporaryModel: temporaryModel,
            temporaryModelId: (model) {
              expect(model, same(temporaryModel));
              return 53;
            },
            notetypeId: (id) {
              expect(id, 53);
              return noteTypeId;
            },
            runUndoableOperation: (action) async {
              await action();
            },
            restoreNotetypeToStock: (nid, actualKind) {
              expect(nid, same(noteTypeId));
              expect(actualKind, same(kind));
              return restoreCompletion.future;
            },
            onModelSaved: () {},
            requireContext: () {
              return context;
            },
            restoredToDefaultToastText: (actualContext) {
              expect(actualContext, same(context));
              return toastText;
            },
            showThemedToast:
                (actualContext, actualText, {required shortLength}) {
                  expect(actualContext, same(context));
                  expect(actualText, same(toastText));
                  expect(shortLength, isFalse);
                },
          ),
        );

        expect(events, [
          'temporary model',
          'temporary model id',
          'notetype id',
          'undoable start',
          'restore',
        ]);

        restoreCompletion.complete();
        await result;

        expect(events, [
          'temporary model',
          'temporary model id',
          'notetype id',
          'undoable start',
          'restore',
          'undoable complete',
          'model saved',
          'context',
          'localized text',
          'themed toast',
        ]);
      },
    );

    test('preserves null kind unchanged', () async {
      final events = <String>[];
      Object? receivedKind = Object();

      await cardTemplateFragmentRestoreNotetypeToStock(
        kind: null,
        callbacks: _callbacks(
          events,
          temporaryModel: Object(),
          temporaryModelId: (_) => 7,
          notetypeId: (_) => Object(),
          restoreNotetypeToStock: (nid, kind) async {
            receivedKind = kind;
          },
        ),
      );

      expect(receivedKind, isNull);
      expect(events, contains('model saved'));
    });

    test('callback failures propagate unchanged and stop later work', () async {
      const sourceOrder = [
        'temporary model',
        'temporary model id',
        'notetype id',
        'undoable start',
        'restore',
        'undoable complete',
        'model saved',
        'context',
        'localized text',
        'themed toast',
      ];

      for (var i = 0; i < sourceOrder.length; i++) {
        final failedAt = sourceOrder[i];
        final events = <String>[];
        final failure = StateError(failedAt);

        await expectLater(
          cardTemplateFragmentRestoreNotetypeToStock(
            kind: 'kind',
            callbacks: _callbacks(
              events,
              temporaryModel: Object(),
              temporaryModelId: (_) => 7,
              notetypeId: (_) => Object(),
              failAt: failedAt,
              failure: failure,
            ),
          ),
          throwsA(same(failure)),
          reason: failedAt,
        );
        expect(events, sourceOrder.take(i + 1).toList(), reason: failedAt);
      }
    });
  });
}

CardTemplateFragmentRestoreNotetypeToStockCallbacks<
  Object,
  int,
  Object,
  Object,
  Object,
  Object
>
_callbacks(
  List<String> events, {
  required Object temporaryModel,
  required int Function(Object model) temporaryModelId,
  required Object Function(int id) notetypeId,
  Future<void> Function(Object nid, Object? kind)? restoreNotetypeToStock,
  Future<void> Function(Future<void> Function() action)? runUndoableOperation,
  void Function()? onModelSaved,
  Object Function()? requireContext,
  Object Function(Object context)? restoredToDefaultToastText,
  void Function(Object context, Object text, {required bool shortLength})?
  showThemedToast,
  String? failAt,
  Object? failure,
}) {
  void hit(String event) {
    events.add(event);
    if (event == failAt) throw failure!;
  }

  return CardTemplateFragmentRestoreNotetypeToStockCallbacks<
    Object,
    int,
    Object,
    Object,
    Object,
    Object
  >(
    temporaryModel: () {
      hit('temporary model');
      return temporaryModel;
    },
    temporaryModelId: (model) {
      hit('temporary model id');
      return temporaryModelId(model);
    },
    notetypeId: (id) {
      hit('notetype id');
      return notetypeId(id);
    },
    runUndoableOperation: (action) {
      hit('undoable start');
      return (runUndoableOperation ?? (action) async => await action())(
        action,
      ).then((_) => hit('undoable complete'));
    },
    restoreNotetypeToStock: (nid, kind) {
      events.add('restore');
      if (failAt == 'restore') return Future<void>.error(failure!);
      return (restoreNotetypeToStock ?? (nid, kind) async {})(nid, kind);
    },
    onModelSaved: () {
      hit('model saved');
      onModelSaved?.call();
    },
    requireContext: () {
      hit('context');
      return requireContext?.call() ?? Object();
    },
    restoredToDefaultToastText: (context) {
      hit('localized text');
      return restoredToDefaultToastText?.call(context) ?? Object();
    },
    showThemedToast: (context, text, {required shortLength}) {
      hit('themed toast');
      showThemedToast?.call(context, text, shortLength: shortLength);
    },
  );
}
