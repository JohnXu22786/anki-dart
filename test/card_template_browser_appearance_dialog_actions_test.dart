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
  group('browser appearance discard dialog action', () {
    test('confirmation finishes exactly once', () {
      var finishCalls = 0;

      completeBrowserAppearanceDiscardDialog(
        confirmed: true,
        finish: () => finishCalls++,
      );

      expect(finishCalls, 1);
    });

    test('cancellation or dismissal does not finish', () {
      var finishCalls = 0;

      completeBrowserAppearanceDiscardDialog(
        confirmed: false,
        finish: () => finishCalls++,
      );

      expect(finishCalls, 0);
    });

    test('finish failure propagates', () {
      final exception = StateError('finish failed');

      expect(
        () => completeBrowserAppearanceDiscardDialog(
          confirmed: true,
          finish: () => throw exception,
        ),
        throwsA(same(exception)),
      );
    });
  });

  group('browser appearance restore-default dialog action', () {
    test('confirmation restores and closes exactly once', () {
      var restoreCalls = 0;

      completeBrowserAppearanceRestoreDefaultDialog(
        confirmed: true,
        restoreDefaultAndClose: () => restoreCalls++,
      );

      expect(restoreCalls, 1);
    });

    test('cancellation does not restore or close', () {
      var restoreCalls = 0;

      completeBrowserAppearanceRestoreDefaultDialog(
        confirmed: false,
        restoreDefaultAndClose: () => restoreCalls++,
      );

      expect(restoreCalls, 0);
    });

    test('restore-and-close failure propagates', () {
      final exception = StateError('restore failed');

      expect(
        () => completeBrowserAppearanceRestoreDefaultDialog(
          confirmed: true,
          restoreDefaultAndClose: () => throw exception,
        ),
        throwsA(same(exception)),
      );
    });
  });
}
