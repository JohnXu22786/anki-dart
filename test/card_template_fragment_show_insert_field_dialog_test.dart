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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentShowInsertFieldDialog', () {
    test(
      'null field names return before every later source read or effect',
      () {
        final harness = _Harness(fieldNames: null);

        cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);

        expect(harness.events, ['launch', 'field names']);
      },
    );

    test('maps edit tabs and note ID boundaries into metadata', () {
      for (final (tab, noteId, side, expectedId) in [
        (CardTemplateEditorEditTab.FRONT, 17, SingleCardSide.front, 17),
        (CardTemplateEditorEditTab.BACK, 1, SingleCardSide.back, 1),
        (CardTemplateEditorEditTab.STYLING, 0, SingleCardSide.front, null),
        (CardTemplateEditorEditTab.FRONT, -4, SingleCardSide.front, null),
      ]) {
        final harness = _Harness(tab: tab, noteId: noteId);

        cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);

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
      () {
        final deleted = _Harness(hasDeletion: true);
        cardTemplateFragmentShowInsertFieldDialog(callbacks: deleted.callbacks);
        expect(deleted.ordReads, 0);
        expect(deleted.metadata?.ord, isNull);

        final unchanged = _Harness(hasDeletion: false);
        cardTemplateFragmentShowInsertFieldDialog(
          callbacks: unchanged.callbacks,
        );
        expect(unchanged.ordReads, 1);
        expect(unchanged.metadata?.ord, 8);
      },
    );

    test(
      'passes exact field list, metadata, and request key before showing',
      () {
        final harness = _Harness();

        cardTemplateFragmentShowInsertFieldDialog(callbacks: harness.callbacks);

        expect(harness.dialogInputs?.fieldItems, same(harness.fieldNames));
        expect(harness.dialogInputs?.metadata, same(harness.metadataHandle));
        expect(harness.dialogInputs?.requestKey, 'request-key');
        expect(harness.shownDialog, same(harness.dialogHandle));
        expect(harness.events.last, 'show dialog');
      },
    );

    test(
      'callback failures propagate unchanged and stop subsequent callbacks',
      () {
        const stages = [
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
        ];

        for (var i = 0; i < stages.length; i++) {
          final harness = _Harness(failAt: stages[i]);
          final failure = harness.failure;

          expect(
            () => cardTemplateFragmentShowInsertFieldDialog(
              callbacks: harness.callbacks,
            ),
            throwsA(same(failure)),
            reason: stages[i],
          );
          expect(harness.events, stages.take(i + 1), reason: stages[i]);
        }
      },
    );
  });
}

final class _Harness {
  _Harness({
    this.fieldNames = const ['Front', 'Back'],
    this.tab = CardTemplateEditorEditTab.FRONT,
    this.noteId = 17,
    this.hasDeletion = false,
    this.failAt,
  });

  final List<String>? fieldNames;
  final CardTemplateEditorEditTab tab;
  final int noteId;
  final bool hasDeletion;
  final String? failAt;
  final failure = StateError('callback failed');
  final events = <String>[];
  final metadataHandle = Object();
  final dialogHandle = Object();
  int ordReads = 0;
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
    launchCatchingTask: (task) {
      hit('launch');
      task();
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
        }) {
          hit('metadata query');
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
