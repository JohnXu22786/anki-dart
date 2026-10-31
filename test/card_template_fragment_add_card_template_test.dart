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
 * Source-derived from CardTemplateFragment.addCardTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('add card template', () {
    test('cloze logs and returns before all remaining host reads', () {
      final events = <String>[];
      final model = Object();

      cardTemplateFragmentAddCardTemplate<Object, Object, Object>(
        callbacks:
            CardTemplateFragmentAddCardTemplateCallbacks<
              Object,
              Object,
              Object
            >(
              readTemporaryModel: () {
                events.add('model');
                return model;
              },
              isCloze: (actualModel) {
                events.add('cloze');
                expect(actualModel, same(model));
                return true;
              },
              warn: events.add,
              readCurrentOrdinal: () {
                events.add('ordinal');
                return 0;
              },
              isOrdinalPendingAdd: (_, _) {
                events.add('pending-add');
                return false;
              },
              readCollection: () {
                events.add('collection');
                return Object();
              },
              readNotetype: (_) {
                events.add('notetype');
                return Object();
              },
              queryTemplateUseCount: (_, _, _) {
                events.add('template-use-count');
                return 1;
              },
              confirmAddCards: (_, _) => events.add('confirm'),
            ),
      );

      expect(events, [
        'model',
        'cloze',
        'addCardTemplate attempted on cloze note type',
      ]);
    });

    test('pending add confirms with zero and skips collection query', () {
      final events = <String>[];
      final model = Object();
      final notetype = Object();

      cardTemplateFragmentAddCardTemplate<Object, Object, Object>(
        callbacks:
            CardTemplateFragmentAddCardTemplateCallbacks<
              Object,
              Object,
              Object
            >(
              readTemporaryModel: () {
                events.add('model');
                return model;
              },
              isCloze: (_) {
                events.add('cloze');
                return false;
              },
              warn: events.add,
              readCurrentOrdinal: () {
                events.add('ordinal');
                return 4;
              },
              isOrdinalPendingAdd: (actualModel, ordinal) {
                events.add('pending-add');
                expect(actualModel, same(model));
                expect(ordinal, 4);
                return true;
              },
              readCollection: () {
                events.add('collection');
                return Object();
              },
              readNotetype: (actualModel) {
                events.add('notetype');
                expect(actualModel, same(model));
                return notetype;
              },
              queryTemplateUseCount: (_, _, _) {
                events.add('template-use-count');
                return 8;
              },
              confirmAddCards: (actualNotetype, count) {
                events.add('confirm');
                expect(actualNotetype, same(notetype));
                expect(count, 0);
              },
            ),
      );

      expect(events, [
        'model',
        'cloze',
        'model',
        'ordinal',
        'pending-add',
        'model',
        'notetype',
        'confirm',
      ]);
    });

    test('ordinary template forwards exact count and callback values', () {
      final events = <String>[];
      final modelForCloze = Object();
      final modelForPending = Object();
      final modelForQuery = Object();
      final modelForConfirm = Object();
      final collection = Object();
      final notetypeForQuery = Object();
      final notetypeForConfirm = Object();
      const count = 17;
      var ordinalReads = 0;
      var modelReads = 0;

      cardTemplateFragmentAddCardTemplate<Object, Object, Object>(
        callbacks:
            CardTemplateFragmentAddCardTemplateCallbacks<
              Object,
              Object,
              Object
            >(
              readTemporaryModel: () {
                events.add('model');
                return [
                  modelForCloze,
                  modelForPending,
                  modelForQuery,
                  modelForConfirm,
                ][modelReads++];
              },
              isCloze: (actualModel) {
                events.add('cloze');
                expect(actualModel, same(modelForCloze));
                return false;
              },
              warn: events.add,
              readCurrentOrdinal: () {
                events.add('ordinal');
                ordinalReads++;
                return ordinalReads == 1 ? 2 : 9;
              },
              isOrdinalPendingAdd: (actualModel, ordinal) {
                events.add('pending-add');
                expect(actualModel, same(modelForPending));
                expect(ordinal, 2);
                return false;
              },
              readCollection: () {
                events.add('collection');
                return collection;
              },
              readNotetype: (actualModel) {
                events.add('notetype');
                if (modelReads == 3) {
                  expect(actualModel, same(modelForQuery));
                  return notetypeForQuery;
                }
                expect(actualModel, same(modelForConfirm));
                return notetypeForConfirm;
              },
              queryTemplateUseCount:
                  (actualCollection, actualNotetype, ordinal) {
                    events.add('template-use-count');
                    expect(actualCollection, same(collection));
                    expect(actualNotetype, same(notetypeForQuery));
                    expect(ordinal, 9);
                    return count;
                  },
              confirmAddCards: (actualNotetype, actualCount) {
                events.add('confirm');
                expect(actualNotetype, same(notetypeForConfirm));
                expect(actualCount, count);
              },
            ),
      );

      expect(events, [
        'model',
        'cloze',
        'model',
        'ordinal',
        'pending-add',
        'collection',
        'model',
        'notetype',
        'ordinal',
        'template-use-count',
        'model',
        'notetype',
        'confirm',
      ]);
    });

    test('callback failure propagates unchanged and stops later reads', () {
      final failure = StateError('pending check failed');
      final events = <String>[];

      expect(
        () => cardTemplateFragmentAddCardTemplate<Object, Object, Object>(
          callbacks:
              CardTemplateFragmentAddCardTemplateCallbacks<
                Object,
                Object,
                Object
              >(
                readTemporaryModel: () {
                  events.add('model');
                  return Object();
                },
                isCloze: (_) {
                  events.add('cloze');
                  return false;
                },
                warn: events.add,
                readCurrentOrdinal: () {
                  events.add('ordinal');
                  return 1;
                },
                isOrdinalPendingAdd: (_, _) {
                  events.add('pending-add');
                  throw failure;
                },
                readCollection: () {
                  events.add('collection');
                  return Object();
                },
                readNotetype: (_) => Object(),
                queryTemplateUseCount: (_, _, _) => 0,
                confirmAddCards: (_, _) => events.add('confirm'),
              ),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['model', 'cloze', 'model', 'ordinal', 'pending-add']);
    });
  });
}
