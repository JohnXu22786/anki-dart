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
 * Source-derived Note.ephemeralCard orchestration tests; rendering remains
 * host-side. See ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note.ephemeralCard orchestration', () {
    test('selects the standard template and renders the exact Card once', () {
      final note = Object();
      final collection = Object();
      final model = Object();
      final template0 = Object();
      final template1 = Object();
      final templates = [template0, template1];
      final card = _HostCard();
      final output = Object();
      final calls = <String>[];

      final result =
          libankiNoteEphemeralCard<
            Object,
            Object,
            _HostCard,
            Object,
            Object,
            Object
          >(
            collection: collection,
            note: note,
            ord: 1,
            deckId: 17,
            fillEmpty: true,
            createCard: (actualCollection, {required id}) {
              calls.add('createCard');
              expect(actualCollection, same(collection));
              expect(id, isNull);
              return card;
            },
            setCardOrd: (actualCard, value) {
              calls.add('setCardOrd:$value');
              expect(actualCard, same(card));
              actualCard.ord = value;
            },
            setCardDid: (actualCard, value) {
              calls.add('setCardDid:$value');
              expect(actualCard, same(card));
              actualCard.did = value;
            },
            getNoteType: () {
              calls.add('noteType');
              return model;
            },
            getIsStd: (actualModel) {
              calls.add('isStd');
              expect(actualModel, same(model));
              return true;
            },
            getTemplates: (actualModel) {
              calls.add('templates');
              expect(actualModel, same(model));
              return templates;
            },
            deepCloneTemplate: (_) => fail('no custom template to clone'),
            getCardOrd: (actualCard) {
              calls.add('getCardOrd:${actualCard.ord}');
              return actualCard.ord!;
            },
            setTemplateOrd: (actualTemplate, value) {
              calls.add('setTemplateOrd:$value');
              expect(actualTemplate, same(template1));
            },
            render:
                (
                  actualNote,
                  actualCard,
                  actualModel,
                  actualTemplate,
                  actualFillEmpty,
                  actualCollection,
                ) {
                  calls.add('render');
                  expect(actualNote, same(note));
                  expect(actualCard, same(card));
                  expect(actualModel, same(model));
                  expect(actualTemplate, same(template1));
                  expect(actualFillEmpty, isTrue);
                  expect(actualCollection, same(collection));
                  return output;
                },
            setCardRenderOutput: (actualCard, actualOutput) {
              calls.add('setRenderOutput');
              expect(actualCard, same(card));
              expect(actualOutput, same(output));
              actualCard.renderOutput = actualOutput;
            },
            setCardNote: (actualCard, actualNote) {
              calls.add('setNote');
              expect(actualCard, same(card));
              expect(actualNote, same(note));
              actualCard.note = actualNote;
            },
          );

      expect(calls, [
        'createCard',
        'setCardOrd:1',
        'setCardDid:17',
        'noteType',
        'isStd',
        'templates',
        'getCardOrd:1',
        'setTemplateOrd:1',
        'render',
        'setRenderOutput',
        'setNote',
      ]);
      expect(card.id, isNull);
      expect(card.ord, 1);
      expect(card.did, 17);
      expect(card.renderOutput, same(output));
      expect(card.note, same(note));
      expect(result, same(card));
    });

    test('clones a custom template and skips Note.notetype and selection', () {
      final note = Object();
      final collection = Object();
      final model = Object();
      final sourceTemplate = Object();
      final clonedTemplate = Object();
      final card = _HostCard();
      final output = Object();
      final calls = <String>[];

      final result =
          libankiNoteEphemeralCard<
            Object,
            Object,
            _HostCard,
            Object,
            Object,
            Object
          >(
            collection: collection,
            note: note,
            ord: 6,
            deckId: 21,
            customNoteType: model,
            customTemplate: sourceTemplate,
            createCard: (actualCollection, {required id}) {
              calls.add('createCard');
              expect(actualCollection, same(collection));
              expect(id, isNull);
              return card;
            },
            setCardOrd: (actualCard, value) {
              calls.add('setCardOrd');
              actualCard.ord = value;
            },
            setCardDid: (actualCard, value) {
              calls.add('setCardDid');
              actualCard.did = value;
            },
            getNoteType: () =>
                fail('custom note type must avoid Note.notetype'),
            getIsStd: (_) => fail('custom template must avoid model.isStd'),
            getTemplates: (_) =>
                fail('custom template must avoid model.templates'),
            deepCloneTemplate: (actualTemplate) {
              calls.add('deepClone');
              expect(actualTemplate, same(sourceTemplate));
              return clonedTemplate;
            },
            getCardOrd: (actualCard) {
              calls.add('getCardOrd');
              return actualCard.ord!;
            },
            setTemplateOrd: (actualTemplate, value) {
              calls.add('setTemplateOrd');
              expect(actualTemplate, same(clonedTemplate));
              expect(value, 6);
            },
            render:
                (
                  actualNote,
                  actualCard,
                  actualModel,
                  actualTemplate,
                  actualFillEmpty,
                  actualCollection,
                ) {
                  calls.add('render');
                  expect(actualNote, same(note));
                  expect(actualCard, same(card));
                  expect(actualModel, same(model));
                  expect(actualTemplate, same(clonedTemplate));
                  expect(actualFillEmpty, isFalse);
                  expect(actualCollection, same(collection));
                  return output;
                },
            setCardRenderOutput: (actualCard, actualOutput) {
              calls.add('setRenderOutput');
              actualCard.renderOutput = actualOutput;
            },
            setCardNote: (actualCard, actualNote) {
              calls.add('setNote');
              actualCard.note = actualNote;
            },
          );

      expect(calls, [
        'createCard',
        'setCardOrd',
        'setCardDid',
        'deepClone',
        'getCardOrd',
        'setTemplateOrd',
        'render',
        'setRenderOutput',
        'setNote',
      ]);
      expect(result, same(card));
      expect(card.renderOutput, same(output));
      expect(card.note, same(note));
    });

    test(
      'propagates render failure after Card ord and did, before later writes',
      () {
        final note = Object();
        final collection = Object();
        final model = Object();
        final template = Object();
        final failure = StateError('render failed');
        final card = _HostCard();
        final calls = <String>[];

        expect(
          () =>
              libankiNoteEphemeralCard<
                Object,
                Object,
                _HostCard,
                Object,
                Object,
                Object
              >(
                collection: collection,
                note: note,
                ord: 3,
                deckId: 9,
                customNoteType: model,
                customTemplate: template,
                createCard: (_, {required id}) => card,
                setCardOrd: (actualCard, value) => actualCard.ord = value,
                setCardDid: (actualCard, value) => actualCard.did = value,
                getNoteType: () =>
                    fail('custom note type must avoid Note.notetype'),
                getIsStd: (_) => fail('custom template must avoid model.isStd'),
                getTemplates: (_) =>
                    fail('custom template must avoid model.templates'),
                deepCloneTemplate: (_) => template,
                getCardOrd: (actualCard) => actualCard.ord!,
                setTemplateOrd: (_, __) => calls.add('setTemplateOrd'),
                render: (_, __, ___, ____, _____, ______) {
                  calls.add('render');
                  throw failure;
                },
                setCardRenderOutput: (_, __) => calls.add('setRenderOutput'),
                setCardNote: (_, __) => calls.add('setNote'),
              ),
          throwsA(same(failure)),
        );

        expect(calls, ['setTemplateOrd', 'render']);
        expect(card.ord, 3);
        expect(card.did, 9);
        expect(card.renderOutput, isNull);
        expect(card.note, isNull);
      },
    );
  });
}

final class _HostCard {
  int? id;
  int? ord;
  int? did;
  Object? renderOutput;
  Object? note;
}
