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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Previewer mark action effect cases. The pinned ViewModel test
 * verifies the final marked value and persisted tag, not effect ordering.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Previewer mark effects', () {
    test('toggles the current note before reading its marked state', () {
      final effects = previewerToggleMarkEffects();

      expect(effects.map((effect) => effect.runtimeType), [
        PreviewerToggleMarkEffect,
        PreviewerReadMarkOnToggleSuccessEffect,
        PreviewerPublishMarkOnReadSuccessEffect,
      ]);
    });

    test('publishes only as the final read-success-gated effect', () {
      final effects = previewerToggleMarkEffects();

      expect(effects.last, isA<PreviewerPublishMarkOnReadSuccessEffect>());
      expect(effects[1], isA<PreviewerReadMarkOnToggleSuccessEffect>());
    });
  });
}
