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
 * SPDX-FileCopyrightText: 2025 Rakshita Chauhan <chauhanrakshita64@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from TabLayout.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('doOnTabSelected', () {
    test('registers and returns the identical listener before returning', () {
      final events = <String>[];
      OnTabSelectedListener<Object>? registered;
      final listener = doOnTabSelected<Object>(
        action: (_) {},
        addOnTabSelectedListener: (value) {
          events.add('register');
          registered = value;
        },
      );

      expect(events, ['register']);
      expect(identical(registered, listener), isTrue);
    });

    test('selected callback forwards the same tab once', () {
      final tab = Object();
      final selected = <Object>[];
      final listener = doOnTabSelected<Object>(
        action: selected.add,
        addOnTabSelectedListener: (_) {},
      );

      listener.onTabSelected(tab);

      expect(selected, hasLength(1));
      expect(identical(selected.single, tab), isTrue);
    });

    test('unselected and reselected callbacks do not invoke the action', () {
      var calls = 0;
      final listener = doOnTabSelected<Object>(
        action: (_) => calls++,
        addOnTabSelectedListener: (_) {},
      );
      final tab = Object();

      listener.onTabUnselected(tab);
      listener.onTabReselected(tab);

      expect(calls, 0);
    });

    test('registration failure propagates unchanged', () {
      final failure = StateError('registration failed');

      expect(
        () => doOnTabSelected<Object>(
          action: (_) {},
          addOnTabSelectedListener: (_) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });

    test('selected action failure propagates unchanged', () {
      final failure = StateError('selection failed');
      final listener = doOnTabSelected<Object>(
        action: (_) => throw failure,
        addOnTabSelectedListener: (_) {},
      );

      expect(() => listener.onTabSelected(Object()), throwsA(same(failure)));
    });
  });
}
