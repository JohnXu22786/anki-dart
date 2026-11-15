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
 * Behavioral reference: BackendUndo.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('UndoStatus adaptation', () {
    test('maps empty actions to null and retains whitespace and last step', () {
      expect(
        undoStatusFromFields(undo: '', redo: '', lastStep: -12),
        const UndoStatus(undo: null, redo: null, lastStep: -12),
      );
      expect(
        undoStatusFromFields(undo: ' ', redo: '\t', lastStep: 2147483647),
        const UndoStatus(undo: ' ', redo: '\t', lastStep: 2147483647),
      );
    });

    test('uses structural equality and Kotlin data-class hash values', () {
      const status = UndoStatus(undo: 'A', redo: null, lastStep: 7);
      const equalStatus = UndoStatus(undo: 'A', redo: null, lastStep: 7);

      expect(status, equalStatus);
      expect(status.hashCode, equalStatus.hashCode);
      expect(status.hashCode, 62472);
      expect(
        status,
        isNot(const UndoStatus(undo: null, redo: null, lastStep: 7)),
      );
      expect(status, isNot(const UndoStatus(undo: 'A', redo: '', lastStep: 7)));
      expect(
        status,
        isNot(const UndoStatus(undo: 'A', redo: null, lastStep: 8)),
      );
    });
  });

  group('undo and redo availability', () {
    test('reads status once per call and checks only the requested action', () {
      var undoReads = 0;
      var redoReads = 0;

      expect(
        undoAvailable(
          readStatus: () {
            undoReads++;
            return const UndoStatus(undo: 'review', redo: null, lastStep: 0);
          },
        ),
        isTrue,
      );
      expect(
        redoAvailable(
          readStatus: () {
            redoReads++;
            return const UndoStatus(undo: null, redo: null, lastStep: 0);
          },
        ),
        isFalse,
      );
      expect(undoReads, 1);
      expect(redoReads, 1);
    });
  });

  group('undo and redo labels', () {
    test('reads once before localizing the matching action once', () {
      final calls = <String>[];

      expect(
        undoLabel(
          readStatus: () {
            calls.add('status');
            return const UndoStatus(undo: 'suspend', redo: 'bury', lastStep: 0);
          },
          localize: (action) {
            calls.add('undo:$action');
            return 'Undo $action';
          },
        ),
        'Undo suspend',
      );
      expect(calls, ['status', 'undo:suspend']);

      calls.clear();
      expect(
        redoLabel(
          readStatus: () {
            calls.add('status');
            return const UndoStatus(undo: 'suspend', redo: 'bury', lastStep: 0);
          },
          localize: (action) {
            calls.add('redo:$action');
            return 'Redo $action';
          },
        ),
        'Redo bury',
      );
      expect(calls, ['status', 'redo:bury']);
    });

    test(
      'returns null without localization when the matching action is null',
      () {
        var undoLocalizationCalls = 0;
        var redoLocalizationCalls = 0;
        var statusReads = 0;

        expect(
          undoLabel(
            readStatus: () {
              statusReads++;
              return const UndoStatus(undo: null, redo: 'redo', lastStep: 0);
            },
            localize: (_) {
              undoLocalizationCalls++;
              return 'unexpected';
            },
          ),
          isNull,
        );
        expect(
          redoLabel(
            readStatus: () {
              statusReads++;
              return const UndoStatus(undo: 'undo', redo: null, lastStep: 0);
            },
            localize: (_) {
              redoLocalizationCalls++;
              return 'unexpected';
            },
          ),
          isNull,
        );
        expect(statusReads, 2);
        expect(undoLocalizationCalls, 0);
        expect(redoLocalizationCalls, 0);
      },
    );

    test('propagates status and localization failures without later calls', () {
      final statusError = StateError('status failed');
      final localizationError = StateError('translation failed');
      var localizationCalls = 0;

      expect(
        () => undoLabel(
          readStatus: () => throw statusError,
          localize: (_) {
            localizationCalls++;
            return 'unexpected';
          },
        ),
        throwsA(same(statusError)),
      );
      expect(localizationCalls, 0);

      expect(
        () => redoLabel(
          readStatus: () =>
              const UndoStatus(undo: null, redo: 'redo', lastStep: 0),
          localize: (_) => throw localizationError,
        ),
        throwsA(same(localizationError)),
      );
    });
  });
}
