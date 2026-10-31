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
 * Source-derived from CardTemplateFragment.deleteCardTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('delete card template', () {
    test('one-template guard returns before orphan and count checks', () async {
      final events = <String>[];
      final model = _Model(templateCount: 1);

      await cardTemplateFragmentDeleteCardTemplate<
        _Model,
        _Template,
        _Notetype
      >(
        callbacks: _callbacks(
          events: events,
          model: model,
          deletionWouldOrphanNote: (_, _) async {
            return false;
          },
        ),
      );

      expect(events, [
        'model',
        'ordinal',
        'template',
        'template-count',
        'cannot-delete',
      ]);
    });

    test(
      'orphan guard returns before pending-add and confirmation checks',
      () async {
        final events = <String>[];

        await cardTemplateFragmentDeleteCardTemplate<
          _Model,
          _Template,
          _Notetype
        >(
          callbacks: _callbacks(
            events: events,
            deletionWouldOrphanNote: (_, _) async {
              return true;
            },
          ),
        );

        expect(events, [
          'model',
          'ordinal',
          'template',
          'template-count',
          'orphan-check',
          'orphan-dialog',
        ]);
      },
    );

    test('pending add confirms zero and skips count log and query', () async {
      final events = <String>[];
      final template = _Template();
      final model = _Model(template: template);

      await cardTemplateFragmentDeleteCardTemplate<
        _Model,
        _Template,
        _Notetype
      >(
        callbacks: _callbacks(
          events: events,
          model: model,
          isOrdinalPendingAdd: (_, ordinal) {
            expect(ordinal, 3);
            return true;
          },
          confirmDeleteCards: (actualTemplate, notetype, count) {
            expect(actualTemplate, same(template));
            expect(notetype, same(model.notetype));
            expect(count, 0);
          },
        ),
      );

      expect(events, [
        'model',
        'ordinal',
        'template',
        'template-count',
        'orphan-check',
        'pending-add',
        'notetype',
        'confirm',
      ]);
    });

    test(
      'ordinary ordinal logs, queries exact count, and confirms in order',
      () async {
        final events = <String>[];
        final template = _Template();
        final model = _Model(template: template);
        const count = 23;

        await cardTemplateFragmentDeleteCardTemplate<
          _Model,
          _Template,
          _Notetype
        >(
          callbacks: _callbacks(
            events: events,
            model: model,
            isOrdinalPendingAdd: (_, ordinal) {
              expect(ordinal, 3);
              return false;
            },
            queryTemplateUseCount: (ordinal, readNotetype) async {
              events.add('collection-enter');
              final notetype = readNotetype();
              events.add('count-query');
              expect(notetype, same(model.notetype));
              expect(ordinal, 3);
              return count;
            },
            confirmDeleteCards: (actualTemplate, notetype, actualCount) {
              expect(actualTemplate, same(template));
              expect(notetype, same(model.notetype));
              expect(actualCount, count);
            },
          ),
        );

        expect(events, [
          'model',
          'ordinal',
          'template',
          'template-count',
          'orphan-check',
          'pending-add',
          'not-pending-log',
          'collection-enter',
          'notetype',
          'count-query',
          'notetype',
          'confirm',
        ]);
      },
    );

    test(
      'initial reads are ordered and failures stop later effects unchanged',
      () async {
        final failure = StateError('template read failed');
        final events = <String>[];

        await expectLater(
          cardTemplateFragmentDeleteCardTemplate<_Model, _Template, _Notetype>(
            callbacks: _callbacks(
              events: events,
              readTemplate: (_, _) {
                events.add('template');
                throw failure;
              },
            ),
          ),
          throwsA(same(failure)),
        );

        expect(events, ['model', 'ordinal', 'template']);

        final queryFailure = StateError('collection callback failed');
        final queryEvents = <String>[];
        await expectLater(
          cardTemplateFragmentDeleteCardTemplate<_Model, _Template, _Notetype>(
            callbacks: _callbacks(
              events: queryEvents,
              isOrdinalPendingAdd: (_, _) => false,
              queryTemplateUseCount: (_, _) async {
                queryEvents.add('collection-enter');
                throw queryFailure;
              },
            ),
          ),
          throwsA(same(queryFailure)),
        );
        expect(queryEvents, [
          'model',
          'ordinal',
          'template',
          'template-count',
          'orphan-check',
          'pending-add',
          'not-pending-log',
          'collection-enter',
        ]);
      },
    );
  });
}

CardTemplateFragmentDeleteCardTemplateCallbacks<_Model, _Template, _Notetype>
_callbacks({
  required List<String> events,
  _Model? model,
  _Template Function(_Model model, int ordinal)? readTemplate,
  bool Function(_Model model, int ordinal)? isOrdinalPendingAdd,
  Future<bool> Function(_Model model, int ordinal)? deletionWouldOrphanNote,
  Future<int> Function(int ordinal, _Notetype Function() readNotetype)?
  queryTemplateUseCount,
  void Function(_Template template, _Notetype notetype, int count)?
  confirmDeleteCards,
}) =>
    CardTemplateFragmentDeleteCardTemplateCallbacks<
      _Model,
      _Template,
      _Notetype
    >(
      readTemporaryModel: () {
        events.add('model');
        return model ?? _Model();
      },
      readCurrentOrdinal: () {
        events.add('ordinal');
        return 3;
      },
      readTemplate: (actualModel, ordinal) {
        if (readTemplate != null) return readTemplate(actualModel, ordinal);
        events.add('template');
        expect(ordinal, 3);
        return actualModel.template;
      },
      readTemplateCount: (actualModel) {
        events.add('template-count');
        return actualModel.templateCount;
      },
      showCannotDeleteDialog: () => events.add('cannot-delete'),
      deletionWouldOrphanNote: (actualModel, ordinal) {
        events.add('orphan-check');
        expect(ordinal, 3);
        return deletionWouldOrphanNote?.call(actualModel, ordinal) ??
            Future.value(false);
      },
      showOrphanNoteDialog: () => events.add('orphan-dialog'),
      isOrdinalPendingAdd: (actualModel, ordinal) {
        events.add('pending-add');
        return isOrdinalPendingAdd?.call(actualModel, ordinal) ?? true;
      },
      logNotPendingAdd: () => events.add('not-pending-log'),
      readNotetype: (actualModel) {
        events.add('notetype');
        return actualModel.notetype;
      },
      queryTemplateUseCount: (ordinal, readNotetype) =>
          queryTemplateUseCount?.call(ordinal, readNotetype) ?? Future.value(0),
      confirmDeleteCards: (template, notetype, count) {
        events.add('confirm');
        confirmDeleteCards?.call(template, notetype, count);
      },
    );

final class _Model {
  _Model({this.templateCount = 2, _Template? template})
    : template = template ?? _Template();

  final int templateCount;
  final _Template template;
  final _Notetype notetype = _Notetype();
}

final class _Template {}

final class _Notetype {}
