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
 * Behavioral reference: NotificationId.kt, UniqueWorkNames.kt, and
 * ConstantUniquenessTest.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test('notification IDs preserve source order, values, and uniqueness', () {
    const ids = [NotificationId.SYNC, NotificationId.SYNC_MEDIA];

    expect(ids, [101, 123]);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('unique work names preserve source order, values, and uniqueness', () {
    const names = [UniqueWorkNames.SYNC, UniqueWorkNames.SYNC_MEDIA];

    expect(names, ['sync', 'syncMedia']);
    expect(names.toSet(), hasLength(names.length));
  });
}
