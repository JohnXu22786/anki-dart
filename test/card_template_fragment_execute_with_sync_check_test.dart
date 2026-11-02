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
 * Source-derived from CardTemplateFragment.executeWithSyncCheck in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('execute with sync check', () {
    test(
      'runs the successful sequence and reloads only fragmented previewers',
      () {
        final events = <String>[];
        final action = () => events.add('action');

        cardTemplateFragmentExecuteWithSyncCheck(
          schemaChangingAction: action,
          callbacks: _callbacks(events: events, fragmented: true),
        );

        expect(events, [
          'mod-schema:true',
          'action',
          'update-discard-state',
          'is-fragmented',
          'reload-previewer',
        ]);

        events.clear();
        cardTemplateFragmentExecuteWithSyncCheck(
          schemaChangingAction: action,
          callbacks: _callbacks(events: events, fragmented: false),
        );
        expect(events, [
          'mod-schema:true',
          'action',
          'update-discard-state',
          'is-fragmented',
        ]);
      },
    );

    test(
      'classified failure from the initial sequence registers then shows confirmation',
      () {
        final events = <String>[];
        final failure = _ConfirmModSchemaException();
        final dialog = _Dialog();
        final action = () => events.add('action');

        cardTemplateFragmentExecuteWithSyncCheck(
          schemaChangingAction: action,
          callbacks: _callbacks(
            events: events,
            dialog: dialog,
            initialFailure: failure,
            initialFailAt: 'update-discard-state',
          ),
        );

        expect(events, [
          'mod-schema:true',
          'action',
          'update-discard-state',
          'classify-confirm-failure',
          'log-confirm-failure',
          'create-dialog',
          'full-sync-message',
          'set-args',
          'register-confirm',
          'register-cancel',
          'show-dialog',
        ]);
        expect(dialog.message, 'Confirm full sync');

        events.clear();
        dialog.confirm!();
        expect(events, [
          'mod-schema:false',
          'action',
          'update-discard-state',
          'dismiss-all-dialogs',
        ]);

        events.clear();
        dialog.cancel!();
        expect(events, ['dismiss-all-dialogs']);
      },
    );

    test(
      'unclassified exceptions and Errors propagate unchanged and stop the sequence',
      () {
        final events = <String>[];
        final failure = Exception('action failed');

        expect(
          () => cardTemplateFragmentExecuteWithSyncCheck(
            schemaChangingAction: () {
              events.add('action');
              throw failure;
            },
            callbacks: _callbacks(events: events),
          ),
          throwsA(same(failure)),
        );
        expect(events, [
          'mod-schema:true',
          'action',
          'classify-confirm-failure',
        ]);

        events.clear();
        final error = StateError('action error');
        expect(
          () => cardTemplateFragmentExecuteWithSyncCheck(
            schemaChangingAction: () {
              events.add('action');
              throw error;
            },
            callbacks: _callbacks(events: events),
          ),
          throwsA(same(error)),
        );
        expect(events, ['mod-schema:true', 'action']);
      },
    );

    test(
      'confirmation callback failures propagate without later callbacks or dismissal',
      () {
        final events = <String>[];
        final syncFailure = StateError('unchecked schema update failed');
        final dialog = _Dialog();

        cardTemplateFragmentExecuteWithSyncCheck(
          schemaChangingAction: () => events.add('action'),
          callbacks: _callbacks(
            events: events,
            dialog: dialog,
            initialFailure: _ConfirmModSchemaException(),
            initialFailAt: 'update-discard-state',
            failAt: 'mod-schema:false',
            failure: syncFailure,
          ),
        );
        events.clear();

        expect(() => dialog.confirm!(), throwsA(same(syncFailure)));
        expect(events, ['mod-schema:false']);
      },
    );
  });
}

CardTemplateFragmentExecuteWithSyncCheckCallbacks<_Dialog> _callbacks({
  required List<String> events,
  _Dialog? dialog,
  bool fragmented = false,
  Object? initialFailure,
  String? initialFailAt,
  String? failAt,
  Object? failure,
}) {
  var initialFailureThrown = false;
  return CardTemplateFragmentExecuteWithSyncCheckCallbacks<_Dialog>(
    modSchema: (check) {
      final event = 'mod-schema:$check';
      events.add(event);
      if (event == failAt) throw failure ?? initialFailure!;
    },
    updateDiscardChangesState: () {
      events.add('update-discard-state');
      if (initialFailAt == 'update-discard-state' && !initialFailureThrown) {
        initialFailureThrown = true;
        throw initialFailure!;
      }
      if (failAt == 'update-discard-state') throw failure ?? initialFailure!;
    },
    isFragmented: () {
      events.add('is-fragmented');
      return fragmented;
    },
    reloadPreviewer: () => events.add('reload-previewer'),
    isConfirmModSchemaException: (error) {
      events.add('classify-confirm-failure');
      return identical(error, initialFailure);
    },
    logConfirmModSchemaException: (_) => events.add('log-confirm-failure'),
    createDialog: () {
      events.add('create-dialog');
      return dialog ?? _Dialog();
    },
    getFullSyncConfirmationMessage: () {
      events.add('full-sync-message');
      return 'Confirm full sync';
    },
    setDialogArgs: (actualDialog, message) {
      events.add('set-args');
      actualDialog.message = message;
    },
    setConfirm: (actualDialog, confirm) {
      events.add('register-confirm');
      actualDialog.confirm = confirm;
    },
    setCancel: (actualDialog, cancel) {
      events.add('register-cancel');
      actualDialog.cancel = cancel;
    },
    showDialog: (_) => events.add('show-dialog'),
    dismissAllDialogFragments: () => events.add('dismiss-all-dialogs'),
  );
}

final class _Dialog {
  String? message;
  void Function()? confirm;
  void Function()? cancel;
}

final class _ConfirmModSchemaException implements Exception {}
