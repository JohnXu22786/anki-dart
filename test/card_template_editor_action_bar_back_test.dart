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
  group('Card Template Editor action-bar Back', () {
    test('changed note type shows discard dialog and returns true', () {
      final calls = <String>[];
      var changeChecks = 0;

      final result = cardTemplateEditorActionBarBackPressed(
        noteTypeHasChanged: () {
          changeChecks++;
          calls.add('noteTypeHasChanged');
          return true;
        },
        showDiscardChangesDialog: () => calls.add('showDiscardChangesDialog'),
        finish: () => calls.add('finish'),
      );

      expect(result, isTrue);
      expect(changeChecks, 1);
      expect(calls, ['noteTypeHasChanged', 'showDiscardChangesDialog']);
    });

    test('unchanged note type finishes and returns true', () {
      final calls = <String>[];
      var changeChecks = 0;

      final result = cardTemplateEditorActionBarBackPressed(
        noteTypeHasChanged: () {
          changeChecks++;
          calls.add('noteTypeHasChanged');
          return false;
        },
        showDiscardChangesDialog: () => calls.add('showDiscardChangesDialog'),
        finish: () => calls.add('finish'),
      );

      expect(result, isTrue);
      expect(changeChecks, 1);
      expect(calls, ['noteTypeHasChanged', 'finish']);
    });

    test('note-type check failure propagates before either host action', () {
      final failure = StateError('note-type check failed');
      final calls = <String>[];

      expect(
        () => cardTemplateEditorActionBarBackPressed(
          noteTypeHasChanged: () {
            calls.add('noteTypeHasChanged');
            throw failure;
          },
          showDiscardChangesDialog: () => calls.add('showDiscardChangesDialog'),
          finish: () => calls.add('finish'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['noteTypeHasChanged']);
    });

    test('discard-dialog failure propagates without finishing', () {
      final failure = StateError('discard dialog failed');
      final calls = <String>[];

      expect(
        () => cardTemplateEditorActionBarBackPressed(
          noteTypeHasChanged: () {
            calls.add('noteTypeHasChanged');
            return true;
          },
          showDiscardChangesDialog: () {
            calls.add('showDiscardChangesDialog');
            throw failure;
          },
          finish: () => calls.add('finish'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['noteTypeHasChanged', 'showDiscardChangesDialog']);
    });

    test('finish failure propagates unchanged', () {
      final failure = StateError('finish failed');
      final calls = <String>[];

      expect(
        () => cardTemplateEditorActionBarBackPressed(
          noteTypeHasChanged: () {
            calls.add('noteTypeHasChanged');
            return false;
          },
          showDiscardChangesDialog: () => calls.add('showDiscardChangesDialog'),
          finish: () {
            calls.add('finish');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['noteTypeHasChanged', 'finish']);
    });
  });
}
