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
 * Source-derived from CardTemplateFragment.confirmDeleteCards in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('confirm delete cards', () {
    test('resolves dialog values in order and defers the confirmed action', () {
      final events = <String>[];
      final dialog = _Dialog();
      final template = _Template('Card 1');
      final notetype = _Notetype();
      const affectedCards = 23;

      cardTemplateFragmentConfirmDeleteCards<_Template, _Notetype, _Dialog>(
        template: template,
        notetype: notetype,
        numAffectedCards: affectedCards,
        callbacks: _callbacks(
          events: events,
          dialog: dialog,
          template: template,
          expectedNotetype: notetype,
          deleteTemplate: (actualTemplate, actualNotetype) {
            events.add('delete');
            expect(actualTemplate, same(template));
            expect(actualNotetype, same(notetype));
          },
        ),
      );

      expect(events, [
        'create-dialog',
        'quantity:23',
        'name',
        'format:23:Card 1',
        'title',
        'positive-label',
        'set-args',
        'register-confirm',
        'show-dialog',
      ]);
      expect(dialog.title, 'Delete card type');
      expect(
        dialog.message,
        'Delete the “Card 1” card type, and its 23 cards?',
      );
      expect(dialog.positiveButtonText, 'Delete');

      dialog.confirm!();
      expect(events, [
        'create-dialog',
        'quantity:23',
        'name',
        'format:23:Card 1',
        'title',
        'positive-label',
        'set-args',
        'register-confirm',
        'show-dialog',
        'sync-check',
        'delete',
      ]);
    });

    test('preserves zero count and an empty host-projected template name', () {
      final events = <String>[];
      final template = _Template('');

      cardTemplateFragmentConfirmDeleteCards<_Template, _Notetype, _Dialog>(
        template: template,
        notetype: _Notetype(),
        numAffectedCards: 0,
        callbacks: _callbacks(
          events: events,
          template: template,
          templateName: '',
        ),
      );

      expect(events, [
        'create-dialog',
        'quantity:0',
        'name',
        'format:0:',
        'title',
        'positive-label',
        'set-args',
        'register-confirm',
        'show-dialog',
      ]);
    });

    test(
      'callback failures stop subsequent effects and confirmation failures propagate',
      () {
        final formatFailure = StateError('message formatting failed');
        final formatEvents = <String>[];

        expect(
          () =>
              cardTemplateFragmentConfirmDeleteCards<
                _Template,
                _Notetype,
                _Dialog
              >(
                template: _Template('Card 1'),
                notetype: _Notetype(),
                numAffectedCards: 2,
                callbacks: _callbacks(
                  events: formatEvents,
                  formatMessage: (_, _, _) => throw formatFailure,
                ),
              ),
          throwsA(same(formatFailure)),
        );
        expect(formatEvents, [
          'create-dialog',
          'quantity:2',
          'name',
          'format:2:Card 1',
        ]);

        final syncFailure = StateError('sync check failed');
        final confirmEvents = <String>[];
        final dialog = _Dialog();
        cardTemplateFragmentConfirmDeleteCards<_Template, _Notetype, _Dialog>(
          template: _Template('Card 1'),
          notetype: _Notetype(),
          numAffectedCards: 2,
          callbacks: _callbacks(
            events: confirmEvents,
            dialog: dialog,
            executeWithSyncCheck: (_) => throw syncFailure,
          ),
        );

        expect(dialog.confirm, isNotNull);
        expect(() => dialog.confirm!(), throwsA(same(syncFailure)));
        expect(confirmEvents.last, 'sync-check');
        expect(confirmEvents, isNot(contains('delete')));
      },
    );
  });
}

CardTemplateFragmentConfirmDeleteCardsCallbacks<_Template, _Notetype, _Dialog>
_callbacks({
  required List<String> events,
  _Dialog? dialog,
  _Template? template,
  _Notetype? expectedNotetype,
  String? templateName,
  String Function(String template, int count, String name)? formatMessage,
  void Function(_Template template, _Notetype notetype)? deleteTemplate,
  void Function(void Function() deleteAction)? executeWithSyncCheck,
}) =>
    CardTemplateFragmentConfirmDeleteCardsCallbacks<
      _Template,
      _Notetype,
      _Dialog
    >(
      createDialog: () {
        events.add('create-dialog');
        return dialog ?? _Dialog();
      },
      getQuantityString: (count) {
        events.add('quantity:$count');
        return 'quantity-template';
      },
      readTemplateName: (actualTemplate) {
        events.add('name');
        if (template != null) expect(actualTemplate, same(template));
        return templateName ?? 'Card 1';
      },
      formatMessage: (messageTemplate, count, name) {
        events.add('format:$count:$name');
        expect(messageTemplate, 'quantity-template');
        return formatMessage?.call(messageTemplate, count, name) ??
            'Delete the “$name” card type, and its $count cards?';
      },
      getTitle: () {
        events.add('title');
        return 'Delete card type';
      },
      getPositiveButtonText: () {
        events.add('positive-label');
        return 'Delete';
      },
      setArgs: (actualDialog, title, message, positiveButtonText) {
        events.add('set-args');
        actualDialog
          ..title = title
          ..message = message
          ..positiveButtonText = positiveButtonText;
      },
      deleteTemplate: (actualTemplate, actualNotetype) {
        if (expectedNotetype != null) {
          expect(actualNotetype, same(expectedNotetype));
        }
        deleteTemplate?.call(actualTemplate, actualNotetype);
      },
      executeWithSyncCheck: (deleteAction) {
        events.add('sync-check');
        if (executeWithSyncCheck != null) {
          executeWithSyncCheck(deleteAction);
        } else {
          deleteAction();
        }
      },
      setConfirm: (actualDialog, confirm) {
        events.add('register-confirm');
        actualDialog.confirm = confirm;
      },
      showDialog: (actualDialog) {
        events.add('show-dialog');
        if (dialog != null) expect(actualDialog, same(dialog));
      },
    );

final class _Dialog {
  String? title;
  String? message;
  String? positiveButtonText;
  void Function()? confirm;
}

final class _Template {
  const _Template(this.name);

  final String name;
}

final class _Notetype {}
