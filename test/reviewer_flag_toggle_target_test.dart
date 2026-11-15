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
 * Source-derived Reviewer flag target cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer flag toggle target', () {
    test('same current and requested flag clears to NONE', () {
      expect(
        reviewerFlagToggleTarget(PreviewerFlag.red, PreviewerFlag.red),
        PreviewerFlag.none,
      );
    });

    test('different current and requested flags select the requested flag', () {
      expect(
        reviewerFlagToggleTarget(PreviewerFlag.red, PreviewerFlag.green),
        PreviewerFlag.green,
      );
    });

    test('same NONE values remain NONE', () {
      expect(
        reviewerFlagToggleTarget(PreviewerFlag.none, PreviewerFlag.none),
        PreviewerFlag.none,
      );
    });

    test('requested NONE clears a different current flag', () {
      expect(
        reviewerFlagToggleTarget(PreviewerFlag.blue, PreviewerFlag.none),
        PreviewerFlag.none,
      );
    });
  });
}
