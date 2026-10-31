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
 * SPDX-FileCopyrightText: 2026 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ExportReadyViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Export-ready request state', () {
    test('starts with no request and clearing leaves it empty', () {
      final state = ExportReadyRequestState();

      expect(state.exportReadyDestination, isNull);

      state.clearExportReadyRequest();

      expect(state.exportReadyDestination, isNull);
    });

    test('registration retains the same params and exact path', () {
      final state = ExportReadyRequestState();
      const params = ExportReadyParams(
        exportPath: '  content://provider/a%2Fb.apkg  ',
      );

      state.registerExportReadyRequest(params);

      expect(state.exportReadyDestination, same(params));
      expect(
        state.exportReadyDestination!.exportPath,
        '  content://provider/a%2Fb.apkg  ',
      );
    });

    test('asText defaults to false and preserves an explicit true value', () {
      const defaultParams = ExportReadyParams(exportPath: '/exports/deck.apkg');
      const textParams = ExportReadyParams(
        exportPath: '/exports/deck.txt',
        asText: true,
      );

      expect(defaultParams.asText, isFalse);
      expect(textParams.asText, isTrue);
    });
  });
}
