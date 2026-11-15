/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FragmentResult.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('fragmentActivitySetFragmentResultListener', () {
    test('looks up manager once and forwards source arguments by identity', () {
      final events = <String>[];
      final activity = Object();
      final manager = Object();
      final requestKey = 'request';
      void Function(String, Object) listener = (_, _) {};
      var managerLookups = 0;
      Object? registeredManager;
      String? registeredRequestKey;
      Object? registeredOwner;
      Object? registeredListener;

      final void Function() register = () {
        fragmentActivitySetFragmentResultListener<
          Object,
          Object,
          void Function(String, Object)
        >(
          fragmentActivity: activity,
          supportFragmentManager: (receiver) {
            events.add('manager');
            managerLookups++;
            expect(identical(receiver, activity), isTrue);
            return manager;
          },
          requestKey: requestKey,
          listener: listener,
          registerFragmentResultListener:
              (actualManager, actualRequestKey, owner, actualListener) {
                events.add('register');
                registeredManager = actualManager;
                registeredRequestKey = actualRequestKey;
                registeredOwner = owner;
                registeredListener = actualListener;
              },
        );
      };

      register();

      expect(events, ['manager', 'register']);
      expect(managerLookups, 1);
      expect(identical(registeredManager, manager), isTrue);
      expect(identical(registeredRequestKey, requestKey), isTrue);
      expect(identical(registeredOwner, activity), isTrue);
      expect(identical(registeredListener, listener), isTrue);
    });

    test('manager lookup failure propagates and prevents registration', () {
      final failure = StateError('manager failed');
      final events = <String>[];

      expect(
        () =>
            fragmentActivitySetFragmentResultListener<
              Object,
              Object,
              void Function(String, Object)
            >(
              fragmentActivity: Object(),
              supportFragmentManager: (_) {
                events.add('manager');
                throw failure;
              },
              requestKey: 'request',
              listener: (_, _) {},
              registerFragmentResultListener: (_, _, _, _) {
                events.add('register');
              },
            ),
        throwsA(same(failure)),
      );
      expect(events, ['manager']);
    });

    test('registration failure propagates unchanged after manager lookup', () {
      final failure = StateError('registration failed');
      final events = <String>[];

      expect(
        () =>
            fragmentActivitySetFragmentResultListener<
              Object,
              Object,
              void Function(String, Object)
            >(
              fragmentActivity: Object(),
              supportFragmentManager: (_) {
                events.add('manager');
                return Object();
              },
              requestKey: 'request',
              listener: (_, _) {},
              registerFragmentResultListener: (_, _, _, _) {
                events.add('register');
                throw failure;
              },
            ),
        throwsA(same(failure)),
      );
      expect(events, ['manager', 'register']);
    });
  });
}
