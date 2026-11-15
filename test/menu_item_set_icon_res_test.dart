/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from MenuItem.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('menuItemSetIconRes', () {
    test('a null drawable stops after resource lookup', () {
      final context = Object();
      final menuItem = Object();
      final events = <String>[];
      var getDrawableCount = 0;

      menuItemSetIconRes(
        context: context,
        menuItem: menuItem,
        resId: 41,
        getDrawable: (receivedContext, resId) {
          events.add('getDrawable');
          getDrawableCount++;
          expect(identical(receivedContext, context), isTrue);
          expect(resId, 41);
          return null;
        },
        mutate: (_) => fail('mutate must not run for a null drawable'),
        getLayoutDirection: (_) => fail('direction lookup must not run'),
        setLayoutDirection: (_, _) => fail('direction set must not run'),
        setIcon: (_, _) => fail('menu icon set must not run'),
      );

      expect(getDrawableCount, 1);
      expect(events, ['getDrawable']);
    });

    test('success preserves order, arguments, and mutated token identity', () {
      final context = Object();
      final menuItem = Object();
      final drawable = Object();
      final mutatedDrawable = Object();
      const layoutDirection = 2;
      const resId = 41;
      final events = <String>[];
      var getDrawableCount = 0;
      var mutateCount = 0;
      var directionCount = 0;
      var setDirectionCount = 0;
      var setIconCount = 0;

      menuItemSetIconRes(
        context: context,
        menuItem: menuItem,
        resId: resId,
        getDrawable: (receivedContext, receivedResId) {
          events.add('getDrawable');
          getDrawableCount++;
          expect(identical(receivedContext, context), isTrue);
          expect(receivedResId, resId);
          return drawable;
        },
        mutate: (receivedDrawable) {
          events.add('mutate');
          mutateCount++;
          expect(identical(receivedDrawable, drawable), isTrue);
          return mutatedDrawable;
        },
        getLayoutDirection: (receivedContext) {
          events.add('getLayoutDirection');
          directionCount++;
          expect(identical(receivedContext, context), isTrue);
          return layoutDirection;
        },
        setLayoutDirection: (receivedDrawable, receivedDirection) {
          events.add('setLayoutDirection');
          setDirectionCount++;
          expect(identical(receivedDrawable, mutatedDrawable), isTrue);
          expect(receivedDirection, layoutDirection);
        },
        setIcon: (receivedMenuItem, receivedDrawable) {
          events.add('setIcon');
          setIconCount++;
          expect(identical(receivedMenuItem, menuItem), isTrue);
          expect(identical(receivedDrawable, mutatedDrawable), isTrue);
        },
      );

      expect(getDrawableCount, 1);
      expect(mutateCount, 1);
      expect(directionCount, 1);
      expect(setDirectionCount, 1);
      expect(setIconCount, 1);
      expect(events, [
        'getDrawable',
        'mutate',
        'getLayoutDirection',
        'setLayoutDirection',
        'setIcon',
      ]);
    });

    test('mutate failure propagates and stops later operations', () {
      final failure = StateError('mutate failed');
      final events = <String>[];

      expect(
        () => menuItemSetIconRes(
          context: Object(),
          menuItem: Object(),
          resId: 41,
          getDrawable: (_, _) {
            events.add('getDrawable');
            return Object();
          },
          mutate: (_) {
            events.add('mutate');
            throw failure;
          },
          getLayoutDirection: (_) => fail('direction lookup must not run'),
          setLayoutDirection: (_, _) => fail('direction set must not run'),
          setIcon: (_, _) => fail('menu icon set must not run'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['getDrawable', 'mutate']);
    });

    test('drawable and direction lookup failures stop later operations', () {
      final drawableFailure = StateError('drawable lookup failed');
      final drawableEvents = <String>[];

      expect(
        () => menuItemSetIconRes(
          context: Object(),
          menuItem: Object(),
          resId: 41,
          getDrawable: (_, _) {
            drawableEvents.add('getDrawable');
            throw drawableFailure;
          },
          mutate: (_) => fail('mutate must not run'),
          getLayoutDirection: (_) => fail('direction lookup must not run'),
          setLayoutDirection: (_, _) => fail('direction set must not run'),
          setIcon: (_, _) => fail('menu icon set must not run'),
        ),
        throwsA(same(drawableFailure)),
      );
      expect(drawableEvents, ['getDrawable']);

      final failure = StateError('direction lookup failed');
      final events = <String>[];

      expect(
        () => menuItemSetIconRes(
          context: Object(),
          menuItem: Object(),
          resId: 41,
          getDrawable: (_, _) {
            events.add('getDrawable');
            return Object();
          },
          mutate: (_) {
            events.add('mutate');
            return Object();
          },
          getLayoutDirection: (_) {
            events.add('getLayoutDirection');
            throw failure;
          },
          setLayoutDirection: (_, _) => fail('direction set must not run'),
          setIcon: (_, _) => fail('menu icon set must not run'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['getDrawable', 'mutate', 'getLayoutDirection']);
    });

    test('direction set failure propagates before menu icon set', () {
      final failure = StateError('direction set failed');
      final events = <String>[];

      expect(
        () => menuItemSetIconRes(
          context: Object(),
          menuItem: Object(),
          resId: 41,
          getDrawable: (_, _) {
            events.add('getDrawable');
            return Object();
          },
          mutate: (_) {
            events.add('mutate');
            return Object();
          },
          getLayoutDirection: (_) {
            events.add('getLayoutDirection');
            return 2;
          },
          setLayoutDirection: (_, _) {
            events.add('setLayoutDirection');
            throw failure;
          },
          setIcon: (_, _) => fail('menu icon set must not run'),
        ),
        throwsA(same(failure)),
      );
      expect(events, [
        'getDrawable',
        'mutate',
        'getLayoutDirection',
        'setLayoutDirection',
      ]);
    });

    test('menu icon set failure propagates after prior operations', () {
      final failure = StateError('menu icon set failed');
      final events = <String>[];

      expect(
        () => menuItemSetIconRes(
          context: Object(),
          menuItem: Object(),
          resId: 41,
          getDrawable: (_, _) {
            events.add('getDrawable');
            return Object();
          },
          mutate: (_) {
            events.add('mutate');
            return Object();
          },
          getLayoutDirection: (_) {
            events.add('getLayoutDirection');
            return 2;
          },
          setLayoutDirection: (_, _) => events.add('setLayoutDirection'),
          setIcon: (_, _) {
            events.add('setIcon');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, [
        'getDrawable',
        'mutate',
        'getLayoutDirection',
        'setLayoutDirection',
        'setIcon',
      ]);
    });
  });
}
