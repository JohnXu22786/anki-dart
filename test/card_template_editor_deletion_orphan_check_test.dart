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
 * Source-derived from CardTemplateEditor.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('deletionWouldOrphanNote', () {
    test(
      'pending-add positions stop before delete ordinals and collection query',
      () async {
        final model = Object();
        final events = <String>[];

        final orphaned = await cardTemplateEditorDeletionWouldOrphanNote(
          tempModel: model,
          position: 3,
          noteTypeId: 19,
          isOrdinalPendingAdd: (actualModel, position) {
            events.add('pending:$actualModel:$position');
            return true;
          },
          getDeleteDbOrds: (_, _) {
            events.add('delete ordinals');
            return <int>[2];
          },
          queryCardIds: (_, _) async {
            events.add('query');
            return <int>[];
          },
        );

        expect(orphaned, isFalse);
        expect(events, ['pending:$model:3']);
      },
    );

    test(
      'calculates delete ordinals once before querying with the same values',
      () async {
        final model = Object();
        final ordinals = <int>[0, 2, 5];
        final events = <String>[];
        final actualModels = <Object?>[];
        List<int>? receivedOrdinals;
        int? receivedNoteTypeId;

        final orphaned = await cardTemplateEditorDeletionWouldOrphanNote(
          tempModel: model,
          position: 4,
          noteTypeId: 19,
          isOrdinalPendingAdd: (actualModel, position) {
            events.add('pending:$position');
            actualModels.add(actualModel);
            return false;
          },
          getDeleteDbOrds: (actualModel, position) {
            events.add('ordinals:$position');
            actualModels.add(actualModel);
            return ordinals;
          },
          queryCardIds: (noteTypeId, currentDeletes) async {
            events.add('query');
            receivedNoteTypeId = noteTypeId;
            receivedOrdinals = currentDeletes;
            return <int>[100, 101];
          },
        );

        expect(orphaned, isFalse);
        expect(events, ['pending:4', 'ordinals:4', 'query']);
        expect(actualModels, everyElement(same(model)));
        expect(receivedNoteTypeId, 19);
        expect(receivedOrdinals, same(ordinals));
      },
    );

    test('returns true only when the query result is null', () async {
      Future<bool> check(List<int>? result) =>
          cardTemplateEditorDeletionWouldOrphanNote(
            tempModel: Object(),
            position: 1,
            noteTypeId: 2,
            isOrdinalPendingAdd: (_, _) => false,
            getDeleteDbOrds: (_, _) => <int>[0],
            queryCardIds: (_, _) async => result,
          );

      expect(await check(null), isTrue);
      expect(await check(<int>[]), isFalse);
      expect(await check(<int>[12]), isFalse);
    });

    test(
      'preserves the host null assertion and stops later callbacks',
      () async {
        final failure = ArgumentError.notNull('tempModel');
        final events = <String>[];

        await expectLater(
          cardTemplateEditorDeletionWouldOrphanNote(
            tempModel: null,
            position: 1,
            noteTypeId: 2,
            isOrdinalPendingAdd: (model, _) {
              events.add('pending');
              expect(model, isNull);
              throw failure;
            },
            getDeleteDbOrds: (_, _) {
              events.add('ordinals');
              return <int>[];
            },
            queryCardIds: (_, _) async {
              events.add('query');
              return null;
            },
          ),
          throwsA(same(failure)),
        );
        expect(events, ['pending']);
      },
    );

    test('propagates delete-ordinal failure and prevents the query', () async {
      final failure = StateError('delete ordinals failed');
      final events = <String>[];

      await expectLater(
        cardTemplateEditorDeletionWouldOrphanNote(
          tempModel: Object(),
          position: 1,
          noteTypeId: 2,
          isOrdinalPendingAdd: (_, _) {
            events.add('pending');
            return false;
          },
          getDeleteDbOrds: (_, _) {
            events.add('ordinals');
            throw failure;
          },
          queryCardIds: (_, _) async {
            events.add('query');
            return null;
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['pending', 'ordinals']);
    });

    test('propagates the query failure unchanged', () async {
      final failure = StateError('collection query failed');

      await expectLater(
        cardTemplateEditorDeletionWouldOrphanNote(
          tempModel: Object(),
          position: 1,
          noteTypeId: 2,
          isOrdinalPendingAdd: (_, _) => false,
          getDeleteDbOrds: (_, _) => <int>[0],
          queryCardIds: (_, _) async => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
