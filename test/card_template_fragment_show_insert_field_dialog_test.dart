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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentShowInsertFieldDialog', () {
    test(
      'null field names return before every later source read or effect',
      () async {
        final harness = _Harness(fieldNames: null);

        cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);
        await harness.completion;

        expect(harness.events, ['launch', 'field names']);
      },
    );

    test('maps edit tabs and note ID boundaries into metadata', () async {
      for (final (tab, noteId, side, expectedId) in [
        (CardTemplateEditorEditTab.FRONT, 17, SingleCardSide.front, 17),
        (CardTemplateEditorEditTab.BACK, 1, SingleCardSide.back, 1),
        (CardTemplateEditorEditTab.STYLING, 0, SingleCardSide.front, null),
        (CardTemplateEditorEditTab.FRONT, -4, SingleCardSide.front, null),
      ]) {
        final harness = _Harness(tab: tab, noteId: noteId);

        cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);
        await harness.completion;

        expect(harness.metadata, (
          side: side,
          noteId: expectedId,
          ord: 8,
          templateName: 'Selected template',
          notetypeName: 'Exact note type',
        ));
        expect(harness.events, [
          'launch',
          'field names',
          'edit tab',
          'note ID',
          'deletion scan',
          'selected template ordinal',
          'template name',
          'note type name',
          'metadata query',
          'new dialog',
          'show dialog',
        ]);
      }
    });

    test(
      'deletions suppress ord reads and otherwise selected ord is read once',
      () async {
        final deleted = _Harness(hasDeletion: true);
        cardTemplateFragmentShowInsertFieldDialog(callbacks: deleted.callbacks);
        await deleted.completion;
        expect(deleted.ordReads, 0);
        expect(deleted.metadata?.ord, isNull);

        final unchanged = _Harness(hasDeletion: false);
        cardTemplateFragmentShowInsertFieldDialog(
          callbacks: unchanged.callbacks,
        );
        await unchanged.completion;
        expect(unchanged.ordReads, 1);
        expect(unchanged.metadata?.ord, 8);
      },
    );

    test('awaits metadata before creating and showing the dialog', () async {
      final gate = Completer<void>();
      final harness = _Harness(metadataGate: gate);

      cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);
      expect(harness.events, [
        'launch',
        'field names',
        'edit tab',
        'note ID',
        'deletion scan',
        'selected template ordinal',
        'template name',
        'note type name',
        'metadata query',
      ]);

      gate.complete();
      await harness.completion;
      expect(harness.events, [
        'launch',
        'field names',
        'edit tab',
        'note ID',
        'deletion scan',
        'selected template ordinal',
        'template name',
        'note type name',
        'metadata query',
        'new dialog',
        'show dialog',
      ]);
    });

    test('metadata future failures stop dialog creation and show', () async {
      final gate = Completer<void>();
      final harness = _Harness(metadataGate: gate);

      cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);
      gate.completeError(harness.failure);
      await expectLater(harness.completion, throwsA(same(harness.failure)));

      expect(harness.events.last, 'metadata query');
      expect(harness.events, isNot(contains('new dialog')));
      expect(harness.events, isNot(contains('show dialog')));
    });

    test(
      'passes exact field list, metadata, and request key before showing',
      () async {
        final harness = _Harness();

        cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);
        await harness.completion;

        expect(harness.dialogInputs?.fieldItems, same(harness.fieldNames));
        expect(harness.dialogInputs?.metadata, same(harness.metadataHandle));
        expect(harness.dialogInputs?.requestKey, 'request-key');
        expect(harness.shownDialog, same(harness.dialogHandle));
        expect(harness.events.last, 'show dialog');
      },
    );

    test(
      'async callback failures propagate unchanged and stop later callbacks',
      () async {
        const stages = [
          'field names',
          'edit tab',
          'note ID',
          'deletion scan',
          'selected template ordinal',
          'template name',
          'note type name',
          'metadata query',
          'new dialog',
          'show dialog',
        ];

        for (var i = 0; i < stages.length; i++) {
          final harness = _Harness(failAt: stages[i]);
          final failure = harness.failure;

          cardTemplateFragmentShowInsertFieldDialog(
            callbacks: harness.callbacks,
          );
          await expectLater(harness.completion, throwsA(same(failure)));
          expect(harness.events, [
            'launch',
            ...stages.take(i + 1),
          ], reason: stages[i]);
        }
      },
    );

    test('launch failure propagates before scheduling the task', () {
      final harness = _Harness(failAt: 'launch');

      expect(
        () => cardTemplateFragmentShowInsertFieldDialog(
          callbacks: harness.callbacks,
        ),
        throwsA(same(harness.failure)),
      );
      expect(harness.events, ['launch']);
      expect(harness.task, isNull);
    });
  });
}

final class _Harness {
  _Harness({
    this.fieldNames = const ['Front', 'Back'],
    this.tab = CardTemplateEditorEditTab.FRONT,
    this.noteId = 17,
    this.hasDeletion = false,
    this.failAt,
    this.metadataGate,
  });

  final List<String>? fieldNames;
  final CardTemplateEditorEditTab tab;
  final int noteId;
  final bool hasDeletion;
  final String? failAt;
  final Completer<void>? metadataGate;
  final failure = StateError('callback failed');
  final events = <String>[];
  final metadataHandle = Object();
  final dialogHandle = Object();
  int ordReads = 0;
  Future<void> Function()? task;
  Future<void>? runningTask;
  Future<void> get completion => runningTask!;
  ({
    SingleCardSide side,
    int? noteId,
    int? ord,
    String templateName,
    String notetypeName,
  })?
  metadata;
  ({List<String> fieldItems, Object metadata, String requestKey})? dialogInputs;
  Object? shownDialog;

  void hit(String stage) {
    events.add(stage);
    if (failAt == stage) throw failure;
  }

  CardTemplateFragmentShowInsertFieldDialogCallbacks<Object, Object>
  get callbacks => CardTemplateFragmentShowInsertFieldDialogCallbacks(
    launchCatchingTask: (scheduledTask) {
      hit('launch');
      task = scheduledTask;
      runningTask = scheduledTask();
    },
    readFieldNames: () {
      hit('field names');
      return fieldNames;
    },
    readCurrentEditTab: () {
      hit('edit tab');
      return tab;
    },
    readNoteId: () {
      hit('note ID');
      return noteId;
    },
    hasTemplateDeletion: () {
      hit('deletion scan');
      return hasDeletion;
    },
    readSelectedTemplateOrd: () {
      hit('selected template ordinal');
      ordReads++;
      return 8;
    },
    readTemplateName: () {
      hit('template name');
      return 'Selected template';
    },
    readNoteTypeName: () {
      hit('note type name');
      return 'Exact note type';
    },
    queryMetadata:
        ({
          required side,
          required noteId,
          required ord,
          required templateName,
          required notetypeName,
        }) async {
          hit('metadata query');
          await metadataGate?.future;
          metadata = (
            side: side,
            noteId: noteId,
            ord: ord,
            templateName: templateName,
            notetypeName: notetypeName,
          );
          return metadataHandle;
        },
    newDialog: ({required fieldItems, required metadata, required requestKey}) {
      hit('new dialog');
      dialogInputs = (
        fieldItems: fieldItems,
        metadata: metadata,
        requestKey: requestKey,
      );
      return dialogHandle;
    },
    insertFieldRequestKey: 'request-key',
    showDialogFragment: (dialog) {
      hit('show dialog');
      shownDialog = dialog;
    },
  );
}
