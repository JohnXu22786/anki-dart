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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FragmentActivity.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _Callback = void Function(Object, Object, Object, Object?);

void main() {
  group('onAllFragmentsLoaded', () {
    test(
      'reads manager before creating and recursively registers one callback',
      () {
        final events = <String>[];
        final initialManager = Object();
        final registered = <Object>[];
        final managers = <Object>[];
        _Callback? callback;

        onAllFragmentsLoaded<Object, Object, Object, Object, _Callback>(
          supportFragmentManager: () {
            events.add('manager');
            return initialManager;
          },
          createLifecycleCallbacks: (onFragmentViewCreated) {
            events.add('create');
            callback = onFragmentViewCreated;
            return onFragmentViewCreated;
          },
          registerFragmentLifecycleCallbacks:
              (manager, actualCallback, {required recursive}) {
                events.add('register');
                managers.add(manager);
                registered.add(actualCallback);
                expect(recursive, isTrue);
              },
          unregisterFragmentLifecycleCallbacks: (_, _) {},
          superOnFragmentViewCreated: (_, _, _, _) {},
          allFragmentViewsCreated: (_) => false,
          block: () {},
        );

        expect(events, ['manager', 'create', 'register']);
        expect(managers, hasLength(1));
        expect(identical(managers.single, initialManager), isTrue);
        expect(registered, hasLength(1));
        expect(identical(registered.single, callback), isTrue);
      },
    );

    test('super runs first and false predicate has no block or unregister', () {
      final events = <String>[];
      final initialManager = Object();
      final eventManager = Object();
      final fragment = Object();
      final view = Object();
      final savedState = Object();
      final callbackObject = Object();
      late _Callback callback;
      final managers = [initialManager, eventManager];

      onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
        supportFragmentManager: () => managers.removeAt(0),
        createLifecycleCallbacks: (onFragmentViewCreated) {
          callback = onFragmentViewCreated;
          return callbackObject;
        },
        registerFragmentLifecycleCallbacks: (_, actual, {required recursive}) {
          expect(identical(actual, callbackObject), isTrue);
        },
        unregisterFragmentLifecycleCallbacks: (_, _) =>
            events.add('unregister'),
        superOnFragmentViewCreated:
            (fm, actualFragment, actualView, actualSavedState) {
              events.add('super');
              expect(identical(fm, eventManager), isTrue);
              expect(identical(actualFragment, fragment), isTrue);
              expect(identical(actualView, view), isTrue);
              expect(identical(actualSavedState, savedState), isTrue);
            },
        allFragmentViewsCreated: (manager) {
          events.add('predicate');
          expect(identical(manager, eventManager), isTrue);
          return false;
        },
        block: () => events.add('block'),
      );

      callback(eventManager, fragment, view, savedState);

      expect(events, ['super', 'predicate']);
      expect(managers, isEmpty);
    });

    test(
      'true predicate runs block then unregisters identical callback using a fresh manager',
      () {
        final events = <String>[];
        final initialManager = Object();
        final predicateManager = Object();
        final unregisterManager = Object();
        final fragment = Object();
        final view = Object();
        final savedState = Object();
        final callbackObject = Object();
        late _Callback callback;
        final managers = [initialManager, predicateManager, unregisterManager];
        final unregisteredManagers = <Object>[];
        final unregisteredCallbacks = <Object>[];

        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () => managers.removeAt(0),
          createLifecycleCallbacks: (onFragmentViewCreated) {
            callback = onFragmentViewCreated;
            return callbackObject;
          },
          registerFragmentLifecycleCallbacks:
              (_, actual, {required recursive}) {
                expect(identical(actual, callbackObject), isTrue);
              },
          unregisterFragmentLifecycleCallbacks: (manager, actual) {
            events.add('unregister');
            unregisteredManagers.add(manager);
            unregisteredCallbacks.add(actual);
          },
          superOnFragmentViewCreated: (_, _, _, _) => events.add('super'),
          allFragmentViewsCreated: (manager) {
            events.add('predicate');
            expect(identical(manager, predicateManager), isTrue);
            return true;
          },
          block: () => events.add('block'),
        );

        callback(Object(), fragment, view, savedState);

        expect(events, ['super', 'predicate', 'block', 'unregister']);
        expect(managers, isEmpty);
        expect(unregisteredManagers, hasLength(1));
        expect(
          identical(unregisteredManagers.single, unregisterManager),
          isTrue,
        );
        expect(identical(unregisteredCallbacks.single, callbackObject), isTrue);
      },
    );

    test(
      'false then true repeated events preserve per-event checks without one-shot guard',
      () {
        final events = <String>[];
        final managers = <Object>[Object()];
        final predicateResults = <bool>[false, true, true];
        final callbackObject = Object();
        late _Callback callback;
        final registrations = <Object>[];
        final unregistrations = <Object>[];

        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () => managers.removeAt(0),
          createLifecycleCallbacks: (onFragmentViewCreated) {
            callback = onFragmentViewCreated;
            return callbackObject;
          },
          registerFragmentLifecycleCallbacks:
              (_, actual, {required recursive}) => registrations.add(actual),
          unregisterFragmentLifecycleCallbacks: (_, actual) =>
              unregistrations.add(actual),
          superOnFragmentViewCreated: (_, _, _, _) => events.add('super'),
          allFragmentViewsCreated: (_) {
            events.add('predicate');
            return predicateResults.removeAt(0);
          },
          block: () => events.add('block'),
        );

        for (var i = 0; i < 3; i++) {
          managers.addAll([Object(), Object()]);
          callback(Object(), Object(), Object(), null);
        }

        expect(events, [
          'super',
          'predicate',
          'super',
          'predicate',
          'block',
          'super',
          'predicate',
          'block',
        ]);
        expect(registrations, hasLength(1));
        expect(identical(registrations.single, callbackObject), isTrue);
        expect(unregistrations, hasLength(2));
        expect(
          unregistrations.every((value) => identical(value, callbackObject)),
          isTrue,
        );
      },
    );

    test(
      'event manager lookup and all-views failures skip block and unregister',
      () {
        final managerFailure = StateError('manager');
        var supportManagerCalls = 0;
        var blockCalls = 0;
        var unregisterCalls = 0;
        late _Callback managerFailureCallback;

        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () {
            supportManagerCalls++;
            if (supportManagerCalls == 1) return Object();
            throw managerFailure;
          },
          createLifecycleCallbacks: (onFragmentViewCreated) {
            managerFailureCallback = onFragmentViewCreated;
            return Object();
          },
          registerFragmentLifecycleCallbacks: (_, _, {required recursive}) {},
          unregisterFragmentLifecycleCallbacks: (_, _) => unregisterCalls++,
          superOnFragmentViewCreated: (_, _, _, _) {},
          allFragmentViewsCreated: (_) => true,
          block: () => blockCalls++,
        );

        expect(
          () => managerFailureCallback(Object(), Object(), Object(), null),
          throwsA(same(managerFailure)),
        );
        expect(supportManagerCalls, 2);
        expect(blockCalls, 0);
        expect(unregisterCalls, 0);

        final predicateFailure = StateError('predicate');
        var lookups = 0;
        late _Callback predicateFailureCallback;
        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () {
            lookups++;
            return Object();
          },
          createLifecycleCallbacks: (onFragmentViewCreated) {
            predicateFailureCallback = onFragmentViewCreated;
            return Object();
          },
          registerFragmentLifecycleCallbacks: (_, _, {required recursive}) {},
          unregisterFragmentLifecycleCallbacks: (_, _) => unregisterCalls++,
          superOnFragmentViewCreated: (_, _, _, _) {},
          allFragmentViewsCreated: (_) => throw predicateFailure,
          block: () => blockCalls++,
        );

        expect(
          () => predicateFailureCallback(Object(), Object(), Object(), null),
          throwsA(same(predicateFailure)),
        );
        expect(lookups, 2);
        expect(blockCalls, 0);
        expect(unregisterCalls, 0);
      },
    );

    test(
      'block failure still unregisters and remains the failure when cleanup succeeds',
      () {
        final blockFailure = StateError('block');
        final managers = <Object>[Object()];
        var unregisterCalls = 0;
        late _Callback callback;

        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () => managers.removeAt(0),
          createLifecycleCallbacks: (onFragmentViewCreated) {
            callback = onFragmentViewCreated;
            return Object();
          },
          registerFragmentLifecycleCallbacks: (_, _, {required recursive}) {},
          unregisterFragmentLifecycleCallbacks: (_, _) => unregisterCalls++,
          superOnFragmentViewCreated: (_, _, _, _) {},
          allFragmentViewsCreated: (_) => true,
          block: () => throw blockFailure,
        );
        managers.addAll([Object(), Object()]);

        expect(
          () => callback(Object(), Object(), Object(), null),
          throwsA(same(blockFailure)),
        );
        expect(unregisterCalls, 1);
      },
    );

    test('unregister manager lookup failure replaces a block failure', () {
      final blockFailure = StateError('block');
      final lookupFailure = StateError('unregister manager');
      var lookups = 0;
      late _Callback callback;

      onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
        supportFragmentManager: () {
          lookups++;
          if (lookups < 3) return Object();
          throw lookupFailure;
        },
        createLifecycleCallbacks: (onFragmentViewCreated) {
          callback = onFragmentViewCreated;
          return Object();
        },
        registerFragmentLifecycleCallbacks: (_, _, {required recursive}) {},
        unregisterFragmentLifecycleCallbacks: (_, _) {},
        superOnFragmentViewCreated: (_, _, _, _) {},
        allFragmentViewsCreated: (_) => true,
        block: () => throw blockFailure,
      );

      expect(
        () => callback(Object(), Object(), Object(), null),
        throwsA(same(lookupFailure)),
      );
      expect(lookups, 3);
    });

    test(
      'pre-try failures skip block and unregister; finally failures propagate',
      () {
        final superFailure = StateError('super');
        var blockCalls = 0;
        var unregisterCalls = 0;
        late _Callback callback;
        final initialManager = Object();

        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () => initialManager,
          createLifecycleCallbacks: (onFragmentViewCreated) {
            callback = onFragmentViewCreated;
            return Object();
          },
          registerFragmentLifecycleCallbacks: (_, _, {required recursive}) {},
          unregisterFragmentLifecycleCallbacks: (_, _) => unregisterCalls++,
          superOnFragmentViewCreated: (_, _, _, _) => throw superFailure,
          allFragmentViewsCreated: (_) => true,
          block: () => blockCalls++,
        );

        expect(
          () => callback(Object(), Object(), Object(), null),
          throwsA(same(superFailure)),
        );
        expect(blockCalls, 0);
        expect(unregisterCalls, 0);

        final blockFailure = StateError('block');
        final unregisterFailure = StateError('unregister');
        final managers = <Object>[initialManager];
        late _Callback secondCallback;
        onAllFragmentsLoaded<Object, Object, Object, Object, Object>(
          supportFragmentManager: () {
            if (managers.isEmpty) throw unregisterFailure;
            return managers.removeAt(0);
          },
          createLifecycleCallbacks: (onFragmentViewCreated) {
            secondCallback = onFragmentViewCreated;
            return Object();
          },
          registerFragmentLifecycleCallbacks: (_, _, {required recursive}) {},
          unregisterFragmentLifecycleCallbacks: (_, _) =>
              throw unregisterFailure,
          superOnFragmentViewCreated: (_, _, _, _) {},
          allFragmentViewsCreated: (_) => true,
          block: () => throw blockFailure,
        );
        managers.addAll([Object(), Object()]);
        expect(
          () => secondCallback(Object(), Object(), Object(), null),
          throwsA(same(unregisterFailure)),
        );
        expect(blockCalls, 0);
      },
    );
  });
}
