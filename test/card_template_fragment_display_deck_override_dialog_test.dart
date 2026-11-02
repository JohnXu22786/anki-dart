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
    CardTemplateFragmentDisplayDeckOverrideDialogCallbacks<Object, Object>;

void main() {
  group('cardTemplateFragmentDisplayDeckOverrideDialog', () {
    test(
      'rejects cloze before reading the template or resolving dialog text',
      () {
        final calls = <Object?>[];
        final values = _DialogValues(isCloze: true);

        cardTemplateFragmentDisplayDeckOverrideDialog(
          tempModel: values.tempModel,
          callbacks: _callbacks(calls, values),
        );

        expect(calls, [
          'launch',
          'require activity',
          'is cloze',
          'multimedia error',
          'snackbar',
        ]);
        expect(values.snackbarPayload, (
          values.errorMessage,
          values.shortDuration,
        ));
      },
    );

    test(
      'resolves text and opens the dialog in source order with exact values',
      () {
        final calls = <Object?>[];
        final values = _DialogValues();

        cardTemplateFragmentDisplayDeckOverrideDialog(
          tempModel: values.tempModel,
          callbacks: _callbacks(calls, values),
        );

        expect(calls, [
          'launch',
          'require activity',
          'is cloze',
          'ordinal',
          'template name',
          'title',
          'explanation',
          'deck dialog',
        ]);
        expect(values.nameModelInput, same(values.tempModel));
        expect(values.dialogPayload, (
          values.title,
          'Override for Exact Template',
          false,
          false,
        ));
      },
    );

    test(
      'propagates callback failures and stops subsequent source operations',
      () {
        const stages = [
          'launch',
          'require activity',
          'is cloze',
          'multimedia error',
          'snackbar',
          'ordinal',
          'template name',
          'warn',
          'title',
          'explanation',
          'deck dialog',
        ];

        for (final stage in stages) {
          final calls = <Object?>[];
          final failure = StateError('$stage failed');
          final values = _DialogValues(
            failAt: stage,
            failure: failure,
            isCloze: stage == 'multimedia error' || stage == 'snackbar',
            templateNameFailure: stage == 'warn'
                ? Exception('name failed')
                : null,
          );

          expect(
            () => cardTemplateFragmentDisplayDeckOverrideDialog(
              tempModel: values.tempModel,
              callbacks: _callbacks(calls, values),
            ),
            throwsA(same(failure)),
            reason: 'failure at $stage should propagate unchanged',
          );
          expect(calls.last, stage);
          expect(
            calls.length,
            calls.indexOf(stage) + 1,
            reason: 'failure at $stage should stop later callbacks',
          );
        }
      },
    );
  });
}

final class _DialogValues {
  _DialogValues({
    this.isCloze = false,
    this.failAt,
    this.failure,
    this.templateNameFailure,
  });

  final Object tempModel = Object();
  final Object shortDuration = Object();
  final String errorMessage = 'Multimedia editor error';
  final String title = 'Deck override';
  final bool isCloze;
  final String? failAt;
  final Object? failure;
  final Exception? templateNameFailure;
  Object? nameModelInput;
  Object? snackbarPayload;
  Object? dialogPayload;
}

_Callbacks _callbacks(List<Object?> calls, _DialogValues values) {
  void hit(String stage) {
    calls.add(stage);
    if (values.failAt == stage) throw values.failure!;
  }

  return CardTemplateFragmentDisplayDeckOverrideDialogCallbacks<Object, Object>(
    launchCatchingTask: (action) {
      hit('launch');
      action();
    },
    requireAnkiActivity: () => hit('require activity'),
    isCloze: (model) {
      hit('is cloze');
      expect(model, same(values.tempModel));
      return values.isCloze;
    },
    multimediaEditorErrorString: () {
      hit('multimedia error');
      return values.errorMessage;
    },
    showSnackbar: (message, duration) {
      hit('snackbar');
      values.snackbarPayload = (message, duration);
    },
    snackbarLengthShort: values.shortDuration,
    readCurrentOrdinal: () {
      hit('ordinal');
      return 2;
    },
    readTemplateName: (model, ordinal) {
      hit('template name');
      values.nameModelInput = model;
      expect(ordinal, 2);
      if (values.templateNameFailure case final failure?) throw failure;
      return 'Exact Template';
    },
    warnTemplateNameRead: (_) => hit('warn'),
    deckOverrideTitle: () {
      hit('title');
      return values.title;
    },
    deckOverrideExplanation: (name) {
      hit('explanation');
      expect(name, 'Exact Template');
      return 'Override for $name';
    },
    showDeckSelectionDialog:
        (title, explanation, {required allowAll, required allowFiltered}) {
          hit('deck dialog');
          values.dialogPayload = (title, explanation, allowAll, allowFiltered);
        },
  );
}
