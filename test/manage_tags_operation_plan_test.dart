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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for ManageTagsViewModel.removeTag(), renameTag(),
 * clearUnusedTags(), and launchTagOpAndRefresh(); see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Manage Tags operation plan', () {
    test('selects the matching operation and count-bearing message', () async {
      final events = <ManageTagsUserMessage>[];
      final operations = <String>[];
      final callbacks = ManageTagsOperationCallbacks(
        removeTag: () async {
          operations.add('remove');
          return 2;
        },
        renameTag: () async {
          operations.add('rename');
          return 3;
        },
        clearUnusedTags: () async {
          operations.add('clear');
          return 4;
        },
      );

      for (final (action, expectedOperation, expectedMessage) in [
        (
          ManageTagsOperationAction.remove,
          'remove',
          const ManageTagsTagRemoved(2),
        ),
        (
          ManageTagsOperationAction.rename,
          'rename',
          const ManageTagsTagRenamed(3),
        ),
        (
          ManageTagsOperationAction.clearUnused,
          'clear',
          const ManageTagsClearedUnusedTags(4),
        ),
      ]) {
        final plan = _prepare(action, callbacks);
        await plan.run(
          sendMessage: (message) async {
            events.add(message);
          },
          reloadTags: (_) async {},
          publishError: (_) => fail('unexpected error'),
          isCancellation: (_) => false,
        );
        expect(operations.last, expectedOperation);
        expect(events.last, expectedMessage);
      }

      expect(operations, ['remove', 'rename', 'clear']);
      expect(events, [
        const ManageTagsTagRemoved(2),
        const ManageTagsTagRenamed(3),
        const ManageTagsClearedUnusedTags(4),
      ]);
    });

    test('captures the Content query before synchronously setting Loading', () {
      String? currentQuery = 'saved search';
      final plan = prepareManageTagsOperation(
        action: ManageTagsOperationAction.remove,
        contentSearchQuery: currentQuery,
        setLoading: () => currentQuery = null,
        operations: _callbacks(),
      );

      expect(currentQuery, isNull);
      expect(plan.searchQuery, 'saved search');
    });

    test('uses an empty query when the prior state was not Content', () {
      var loadingSet = false;
      final plan = prepareManageTagsOperation(
        action: ManageTagsOperationAction.clearUnused,
        contentSearchQuery: null,
        setLoading: () => loadingSet = true,
        operations: _callbacks(),
      );

      expect(loadingSet, isTrue);
      expect(plan.searchQuery, '');
    });

    test('orders Loading, operation, event send, then reload', () async {
      final sequence = <String>[];
      final callbacks = ManageTagsOperationCallbacks(
        removeTag: () async {
          sequence.add('operation');
          return 7;
        },
        renameTag: () async => 0,
        clearUnusedTags: () async => 0,
      );
      final plan = prepareManageTagsOperation(
        action: ManageTagsOperationAction.remove,
        contentSearchQuery: 'query',
        setLoading: () => sequence.add('loading'),
        operations: callbacks,
      );

      expect(sequence, ['loading']);
      await plan.run(
        sendMessage: (message) async {
          expect(message, const ManageTagsTagRemoved(7));
          sequence.add('event');
        },
        reloadTags: (query) async {
          expect(query, 'query');
          sequence.add('reload');
        },
        publishError: (_) => fail('unexpected error'),
        isCancellation: (_) => false,
      );

      expect(sequence, ['loading', 'operation', 'event', 'reload']);
    });

    test(
      'publishes ordinary failures but rethrows cancellation at every stage',
      () async {
        for (final stage in ['operation', 'event', 'reload']) {
          final failure = FormatException('$stage failed');
          final sequence = <String>[];
          final plan = prepareManageTagsOperation(
            action: ManageTagsOperationAction.remove,
            contentSearchQuery: null,
            setLoading: () {},
            operations: ManageTagsOperationCallbacks(
              removeTag: () async {
                sequence.add('operation');
                if (stage == 'operation') throw failure;
                return 1;
              },
              renameTag: () async => 1,
              clearUnusedTags: () async => 1,
            ),
          );
          Exception? published;
          await plan.run(
            sendMessage: (_) async {
              sequence.add('event');
              if (stage == 'event') throw failure;
            },
            reloadTags: (_) async {
              sequence.add('reload');
              if (stage == 'reload') throw failure;
            },
            publishError: (error) => published = error,
            isCancellation: (_) => false,
          );

          expect(published, same(failure));
          expect(sequence, switch (stage) {
            'operation' => ['operation'],
            'event' => ['operation', 'event'],
            _ => ['operation', 'event', 'reload'],
          });
        }

        for (final stage in ['operation', 'event', 'reload']) {
          final cancellation = _TestCancellation(stage);
          final plan = prepareManageTagsOperation(
            action: ManageTagsOperationAction.remove,
            contentSearchQuery: null,
            setLoading: () {},
            operations: ManageTagsOperationCallbacks(
              removeTag: () async {
                if (stage == 'operation') throw cancellation;
                return 1;
              },
              renameTag: () async => 1,
              clearUnusedTags: () async => 1,
            ),
          );
          Object? published;
          await expectLater(
            plan.run(
              sendMessage: (_) async {
                if (stage == 'event') throw cancellation;
              },
              reloadTags: (_) async {
                if (stage == 'reload') throw cancellation;
              },
              publishError: (error) => published = error,
              isCancellation: (error) => error is _TestCancellation,
            ),
            throwsA(same(cancellation)),
          );
          expect(published, isNull);
        }
      },
    );
  });
}

ManageTagsOperationPlan _prepare(
  ManageTagsOperationAction action,
  ManageTagsOperationCallbacks callbacks,
) => prepareManageTagsOperation(
  action: action,
  contentSearchQuery: null,
  setLoading: () {},
  operations: callbacks,
);

ManageTagsOperationCallbacks _callbacks() => ManageTagsOperationCallbacks(
  removeTag: () async => 1,
  renameTag: () async => 1,
  clearUnusedTags: () async => 1,
);

final class _TestCancellation implements Exception {
  const _TestCancellation(this.stage);

  final String stage;
}
