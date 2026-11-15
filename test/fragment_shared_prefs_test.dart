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
 * Source-derived from Fragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('fragmentSharedPrefs', () {
    test(
      'resolves one context before delegating and returns the same prefs',
      () {
        final events = <String>[];
        final fragment = Object();
        final context = Object();
        final preferences = Object();
        var contextCalls = 0;
        var delegateCalls = 0;

        final actualPreferences = fragmentSharedPrefs<Object, Object, Object>(
          fragment: fragment,
          requireContext: (actualFragment) {
            events.add('context');
            contextCalls++;
            expect(identical(actualFragment, fragment), isTrue);
            return context;
          },
          sharedPrefs: (actualContext) {
            events.add('sharedPrefs');
            delegateCalls++;
            expect(identical(actualContext, context), isTrue);
            return preferences;
          },
        );

        expect(events, ['context', 'sharedPrefs']);
        expect(contextCalls, 1);
        expect(delegateCalls, 1);
        expect(identical(actualPreferences, preferences), isTrue);
      },
    );

    test('context lookup failure propagates and skips delegate', () {
      final failure = StateError('context failed');
      var contextCalls = 0;
      var delegateCalls = 0;

      expect(
        () => fragmentSharedPrefs<Object, Object, Object>(
          fragment: Object(),
          requireContext: (_) {
            contextCalls++;
            throw failure;
          },
          sharedPrefs: (_) {
            delegateCalls++;
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(contextCalls, 1);
      expect(delegateCalls, 0);
    });

    test('preference delegate failure propagates after one context lookup', () {
      final failure = StateError('shared preferences failed');
      var contextCalls = 0;
      var delegateCalls = 0;

      expect(
        () => fragmentSharedPrefs<Object, Object, Object>(
          fragment: Object(),
          requireContext: (_) {
            contextCalls++;
            return Object();
          },
          sharedPrefs: (_) {
            delegateCalls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(contextCalls, 1);
      expect(delegateCalls, 1);
    });
  });
}
