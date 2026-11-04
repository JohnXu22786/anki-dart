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
 * Source-derived adapter cases for Collection.undoStatus(); see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionUndoStatus', () {
    test('reads one host status in source order and projects its fields', () {
      final calls = <String>[];
      final status = _HostUndoStatus(
        undo: '',
        redo: ' ',
        lastStep: -17,
        onRead: calls.add,
      );

      final result = collectionUndoStatus(
        CollectionUndoStatusCallbacks<_HostUndoStatus>(
          getUndoStatus: () {
            calls.add('getUndoStatus');
            return status;
          },
          getUndo: (value) => value.undo,
          getRedo: (value) => value.redo,
          getLastStep: (value) => value.lastStep,
        ),
      );

      expect(result, const UndoStatus(undo: null, redo: ' ', lastStep: -17));
      expect(calls, ['getUndoStatus', 'undo', 'redo', 'lastStep']);
    });

    test(
      'propagates callback and field failures and short-circuits later reads',
      () {
        final cases = <({String failureAt, List<String> expectedCalls})>[
          (failureAt: 'getUndoStatus', expectedCalls: ['getUndoStatus']),
          (failureAt: 'undo', expectedCalls: ['getUndoStatus', 'undo']),
          (failureAt: 'redo', expectedCalls: ['getUndoStatus', 'undo', 'redo']),
          (
            failureAt: 'lastStep',
            expectedCalls: ['getUndoStatus', 'undo', 'redo', 'lastStep'],
          ),
        ];

        for (final testCase in cases) {
          final calls = <String>[];
          final failure = StateError('${testCase.failureAt} failed');
          final status = _HostUndoStatus(
            undo: 'undo',
            redo: 'redo',
            lastStep: 1,
            onRead: (field) {
              calls.add(field);
              if (field == testCase.failureAt) throw failure;
            },
          );

          expect(
            () => collectionUndoStatus(
              CollectionUndoStatusCallbacks<_HostUndoStatus>(
                getUndoStatus: () {
                  calls.add('getUndoStatus');
                  if (testCase.failureAt == 'getUndoStatus') throw failure;
                  return status;
                },
                getUndo: (value) => value.undo,
                getRedo: (value) => value.redo,
                getLastStep: (value) => value.lastStep,
              ),
            ),
            throwsA(same(failure)),
            reason: 'failure from ${testCase.failureAt} must be preserved',
          );
          expect(calls, testCase.expectedCalls);
        }
      },
    );
  });
}

final class _HostUndoStatus {
  _HostUndoStatus({
    required String undo,
    required String redo,
    required int lastStep,
    required this.onRead,
  }) : _undo = undo,
       _redo = redo,
       _lastStep = lastStep;

  final String _undo;
  final String _redo;
  final int _lastStep;
  final void Function(String field) onRead;

  String get undo {
    onRead('undo');
    return _undo;
  }

  String get redo {
    onRead('redo');
    return _redo;
  }

  int get lastStep {
    onRead('lastStep');
    return _lastStep;
  }
}
