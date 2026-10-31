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
 * Source-derived from MediaCheckViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Media Check trash actions', () {
    test(
      'deletes trash inside unlabeled progress and collection host',
      () async {
        final plan = planMediaCheckTrashAction(MediaCheckTrashAction.delete);
        final calls = <String>[];

        await plan.run(
          withProgress: ({required message, required action}) async {
            calls.add('progress:$message');
            await action();
          },
          withCollection: (action) async {
            calls.add('collection');
            await action();
          },
          emptyTrash: () async => calls.add('emptyTrash'),
          restoreTrash: () async => calls.add('restoreTrash'),
        );

        expect(plan.progressMessage, isNull);
        expect(calls, ['progress:null', 'collection', 'emptyTrash']);
      },
    );

    test(
      'restores trash inside unlabeled progress and collection host',
      () async {
        final plan = planMediaCheckTrashAction(MediaCheckTrashAction.restore);
        final calls = <String>[];

        await plan.run(
          withProgress: ({required message, required action}) async {
            calls.add('progress:$message');
            await action();
          },
          withCollection: (action) async {
            calls.add('collection');
            await action();
          },
          emptyTrash: () async => calls.add('emptyTrash'),
          restoreTrash: () async => calls.add('restoreTrash'),
        );

        expect(plan.progressMessage, isNull);
        expect(calls, ['progress:null', 'collection', 'restoreTrash']);
      },
    );

    test(
      'propagates trash operation failure through both host callbacks',
      () async {
        final plan = planMediaCheckTrashAction(MediaCheckTrashAction.delete);
        final error = StateError('empty trash failed');
        var collectionCompleted = false;
        var progressCompleted = false;

        await expectLater(
          plan.run(
            withProgress: ({required message, required action}) async {
              try {
                await action();
              } finally {
                progressCompleted = true;
              }
            },
            withCollection: (action) async {
              try {
                await action();
              } finally {
                collectionCompleted = true;
              }
            },
            emptyTrash: () async => throw error,
            restoreTrash: () async {},
          ),
          throwsA(same(error)),
        );

        expect(collectionCompleted, isTrue);
        expect(progressCompleted, isTrue);
      },
    );
  });
}
