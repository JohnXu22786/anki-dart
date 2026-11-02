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
  group('fragmentWindow', () {
    test('looks up the activity once before reading its window once', () {
      final events = <String>[];
      final fragment = Object();
      final activity = Object();
      final window = Object();
      final windows = <Object>[];
      var activityCalls = 0;

      final actualWindow = fragmentWindow<Object, Object, Object>(
        fragment: fragment,
        requireActivity: (actualFragment) {
          events.add('activity');
          activityCalls++;
          expect(identical(actualFragment, fragment), isTrue);
          return activity;
        },
        window: (actualActivity) {
          events.add('window');
          expect(identical(actualActivity, activity), isTrue);
          windows.add(window);
          return window;
        },
      );

      expect(events, ['activity', 'window']);
      expect(activityCalls, 1);
      expect(windows, hasLength(1));
      expect(identical(actualWindow, window), isTrue);
    });

    test('activity lookup failure propagates and prevents window read', () {
      final failure = StateError('activity failed');
      var activityCalls = 0;
      var windowCalls = 0;

      expect(
        () => fragmentWindow<Object, Object, Object>(
          fragment: Object(),
          requireActivity: (_) {
            activityCalls++;
            throw failure;
          },
          window: (_) {
            windowCalls++;
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(activityCalls, 1);
      expect(windowCalls, 0);
    });

    test('window read failure propagates after one activity lookup', () {
      final failure = StateError('window failed');
      var activityCalls = 0;
      var windowCalls = 0;

      expect(
        () => fragmentWindow<Object, Object, Object>(
          fragment: Object(),
          requireActivity: (_) {
            activityCalls++;
            return Object();
          },
          window: (_) {
            windowCalls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(activityCalls, 1);
      expect(windowCalls, 1);
    });
  });
}
