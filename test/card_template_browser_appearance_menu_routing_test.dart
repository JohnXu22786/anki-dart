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
 * Source-derived from CardTemplateBrowserAppearanceEditor.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browser appearance menu routing', () {
    test('confirm invokes save-and-exit and returns true', () {
      final calls = <String>[];

      final result = routeBrowserAppearanceMenuAction(
        action: BrowserAppearanceMenuAction.confirm,
        saveAndExit: () => calls.add('save'),
        showRestoreDefaultDialog: () => calls.add('restore'),
        hasChanges: () => throw StateError('hasChanges must be lazy'),
        showDiscardChangesDialog: () => calls.add('discard'),
        finish: () => calls.add('finish'),
        superOnOptionsItemSelected: () {
          calls.add('super');
          return false;
        },
      );

      expect(result, isTrue);
      expect(calls, ['save']);
    });

    test('restore-default shows its dialog and returns true', () {
      final calls = <String>[];

      final result = routeBrowserAppearanceMenuAction(
        action: BrowserAppearanceMenuAction.restoreDefault,
        saveAndExit: () => calls.add('save'),
        showRestoreDefaultDialog: () => calls.add('restore'),
        hasChanges: () => throw StateError('hasChanges must be lazy'),
        showDiscardChangesDialog: () => calls.add('discard'),
        finish: () => calls.add('finish'),
        superOnOptionsItemSelected: () {
          calls.add('super');
          return false;
        },
      );

      expect(result, isTrue);
      expect(calls, ['restore']);
    });

    test('home with changes checks once and shows discard dialog', () {
      final calls = <String>[];
      var hasChangesCalls = 0;

      final result = routeBrowserAppearanceMenuAction(
        action: BrowserAppearanceMenuAction.home,
        saveAndExit: () => calls.add('save'),
        showRestoreDefaultDialog: () => calls.add('restore'),
        hasChanges: () {
          hasChangesCalls++;
          calls.add('hasChanges');
          return true;
        },
        showDiscardChangesDialog: () => calls.add('discard'),
        finish: () => calls.add('finish'),
        superOnOptionsItemSelected: () {
          calls.add('super');
          return false;
        },
      );

      expect(result, isTrue);
      expect(hasChangesCalls, 1);
      expect(calls, ['hasChanges', 'discard']);
    });

    test('home without changes checks once and finishes', () {
      final calls = <String>[];
      var hasChangesCalls = 0;

      final result = routeBrowserAppearanceMenuAction(
        action: BrowserAppearanceMenuAction.home,
        saveAndExit: () => calls.add('save'),
        showRestoreDefaultDialog: () => calls.add('restore'),
        hasChanges: () {
          hasChangesCalls++;
          calls.add('hasChanges');
          return false;
        },
        showDiscardChangesDialog: () => calls.add('discard'),
        finish: () => calls.add('finish'),
        superOnOptionsItemSelected: () {
          calls.add('super');
          return false;
        },
      );

      expect(result, isTrue);
      expect(hasChangesCalls, 1);
      expect(calls, ['hasChanges', 'finish']);
    });

    test('other actions return the superclass boolean unchanged', () {
      for (final fallbackResult in [false, true]) {
        final calls = <String>[];
        var fallbackCalls = 0;

        final result = routeBrowserAppearanceMenuAction(
          action: BrowserAppearanceMenuAction.other,
          saveAndExit: () => calls.add('save'),
          showRestoreDefaultDialog: () => calls.add('restore'),
          hasChanges: () => throw StateError('hasChanges must be lazy'),
          showDiscardChangesDialog: () => calls.add('discard'),
          finish: () => calls.add('finish'),
          superOnOptionsItemSelected: () {
            fallbackCalls++;
            calls.add('super');
            return fallbackResult;
          },
        );

        expect(result, fallbackResult);
        expect(fallbackCalls, 1);
        expect(calls, ['super']);
      }
    });

    test('hasChanges exception propagates before either home effect', () {
      final exception = StateError('change check failed');
      final calls = <String>[];

      expect(
        () => routeBrowserAppearanceMenuAction(
          action: BrowserAppearanceMenuAction.home,
          saveAndExit: () => calls.add('save'),
          showRestoreDefaultDialog: () => calls.add('restore'),
          hasChanges: () {
            calls.add('hasChanges');
            throw exception;
          },
          showDiscardChangesDialog: () => calls.add('discard'),
          finish: () => calls.add('finish'),
          superOnOptionsItemSelected: () {
            calls.add('super');
            return false;
          },
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['hasChanges']);
    });

    test('discard-dialog exception propagates without finishing', () {
      final exception = StateError('discard dialog failed');
      final calls = <String>[];

      expect(
        () => routeBrowserAppearanceMenuAction(
          action: BrowserAppearanceMenuAction.home,
          saveAndExit: () => calls.add('save'),
          showRestoreDefaultDialog: () => calls.add('restore'),
          hasChanges: () {
            calls.add('hasChanges');
            return true;
          },
          showDiscardChangesDialog: () {
            calls.add('discard');
            throw exception;
          },
          finish: () => calls.add('finish'),
          superOnOptionsItemSelected: () {
            calls.add('super');
            return false;
          },
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['hasChanges', 'discard']);
    });
  });
}
