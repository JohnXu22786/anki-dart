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
 * Source-derived from CardTemplateFragment.confirmAddCards in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('confirm add cards', () {
    test(
      'preserves source callback order and defers add until confirmation',
      () {
        final host = _Host();
        final notetype = Object();
        const affectedCards = 23;
        final dialog = _Dialog();

        cardTemplateFragmentConfirmAddCards<Object, _Dialog>(
          notetype: notetype,
          numAffectedCards: affectedCards,
          callbacks: host.callbacks(dialog),
        );

        expect(host.events, [
          'create-dialog',
          'quantity:23',
          'format:quantity-template:23',
          'title',
          'positive-label',
          'set-args',
          'register-confirm',
          'show-dialog',
        ]);
        expect(dialog.title, 'Add card type');
        expect(dialog.message, 'This note type has 23 cards.');
        expect(dialog.positiveButtonText, 'Add');
        expect(dialog.confirm, isNotNull);

        dialog.confirm!();
        expect(host.events, [
          'create-dialog',
          'quantity:23',
          'format:quantity-template:23',
          'title',
          'positive-label',
          'set-args',
          'register-confirm',
          'show-dialog',
          'sync-check',
          'add-template',
        ]);
        expect(host.addedNotetype, same(notetype));
      },
    );

    test(
      'callback failures stop later effects and sync failure prevents add',
      () {
        final formatFailure = StateError('message formatting failed');
        final formatHost = _Host()..formatFailure = formatFailure;

        expect(
          () => cardTemplateFragmentConfirmAddCards<Object, _Dialog>(
            notetype: Object(),
            numAffectedCards: 2,
            callbacks: formatHost.callbacks(_Dialog()),
          ),
          throwsA(same(formatFailure)),
        );
        expect(formatHost.events, [
          'create-dialog',
          'quantity:2',
          'format:quantity-template:2',
        ]);

        final syncFailure = StateError('sync check failed');
        final syncHost = _Host()..syncFailure = syncFailure;
        final syncDialog = _Dialog();
        cardTemplateFragmentConfirmAddCards<Object, _Dialog>(
          notetype: Object(),
          numAffectedCards: 2,
          callbacks: syncHost.callbacks(syncDialog),
        );

        expect(() => syncDialog.confirm!(), throwsA(same(syncFailure)));
        expect(syncHost.events.last, 'sync-check');
        expect(syncHost.events, isNot(contains('add-template')));
      },
    );
  });
}

final class _Dialog {
  String? title;
  String? message;
  String? positiveButtonText;
  void Function()? confirm;
}

final class _Host {
  final events = <String>[];
  Object? formatFailure;
  Object? syncFailure;
  Object? addedNotetype;

  CardTemplateFragmentConfirmAddCardsCallbacks<Object, _Dialog> callbacks(
    _Dialog dialog,
  ) => CardTemplateFragmentConfirmAddCardsCallbacks<Object, _Dialog>(
    createDialog: () {
      events.add('create-dialog');
      return dialog;
    },
    getQuantityString: (count) {
      events.add('quantity:$count');
      return 'quantity-template';
    },
    formatMessage: (messageTemplate, count) {
      events.add('format:$messageTemplate:$count');
      if (formatFailure case final failure?) throw failure;
      expect(messageTemplate, 'quantity-template');
      return 'This note type has $count cards.';
    },
    getTitle: () {
      events.add('title');
      return 'Add card type';
    },
    getPositiveButtonText: () {
      events.add('positive-label');
      return 'Add';
    },
    setArgs: (actualDialog, title, message, positiveButtonText) {
      events.add('set-args');
      actualDialog
        ..title = title
        ..message = message
        ..positiveButtonText = positiveButtonText;
    },
    addNewTemplate: (notetype) {
      events.add('add-template');
      addedNotetype = notetype;
    },
    executeWithSyncCheck: (addAction) {
      events.add('sync-check');
      if (syncFailure case final failure?) throw failure;
      addAction();
    },
    setConfirm: (actualDialog, confirm) {
      events.add('register-confirm');
      actualDialog.confirm = confirm;
    },
    showDialog: (actualDialog) {
      expect(actualDialog, same(dialog));
      events.add('show-dialog');
    },
  );
}
