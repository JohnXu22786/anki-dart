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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('onWindowFocusChanged', () {
    test(
      'creates and registers the exact listener before lifecycle observer',
      () {
        final host = _Host();
        final action = (bool _) {};

        onWindowFocusChanged<
          Object,
          Object,
          Object,
          Object,
          Object,
          Object,
          Object
        >(
          fragment: host.fragment,
          action: action,
          createWindowFocusChangeListener: host.createWindowFocusChangeListener,
          requireView: host.requireView,
          readViewTreeObserver: host.readViewTreeObserver,
          addWindowFocusChangeListener: host.addWindowFocusChangeListener,
          readViewLifecycleOwner: host.readViewLifecycleOwner,
          readLifecycle: host.readLifecycle,
          createDefaultLifecycleObserver: host.createDefaultLifecycleObserver,
          addLifecycleObserver: host.addLifecycleObserver,
          readCurrentView: host.readCurrentView,
          readCurrentViewTreeObserver: host.readCurrentViewTreeObserver,
          isViewTreeObserverAlive: host.isViewTreeObserverAlive,
          removeWindowFocusChangeListener: host.removeWindowFocusChangeListener,
        );

        expect(host.events, [
          'createListener',
          'requireView',
          'readInitialObserver',
          'addFocusListener',
          'readOwner',
          'readLifecycle',
          'createLifecycleObserver',
          'addLifecycleObserver',
        ]);
        expect(identical(host.createdAction, action), isTrue);
        expect(identical(host.addedFocusListener, host.focusListener), isTrue);
        expect(identical(host.registeredLifecycle, host.lifecycle), isTrue);
        expect(
          identical(host.registeredLifecycleObserver, host.lifecycleObserver),
          isTrue,
        );
      },
    );

    test(
      'destroy callback reads the current view and observer and removes exact listener when alive',
      () {
        final host = _Host();
        _register(host);
        final oldView = host.view;
        final currentView = Object();
        final currentObserver = Object();
        host.currentView = currentView;
        host.currentObserver = currentObserver;

        host.onDestroy!(Object());

        expect(host.events.skip(8), [
          'readCurrentView',
          'readCurrentObserver',
          'readAlive',
          'removeFocusListener',
        ]);
        expect(identical(host.lastCurrentView, currentView), isTrue);
        expect(identical(host.lastAliveObserver, currentObserver), isTrue);
        expect(identical(host.removedObserver, currentObserver), isTrue);
        expect(
          identical(host.removedFocusListener, host.focusListener),
          isTrue,
        );
        expect(identical(oldView, host.view), isTrue);
        expect(host.aliveReads, 1);
      },
    );

    test(
      'destroy callback short-circuits missing current view or observer and dead observers',
      () {
        final noView = _Host()..currentView = null;
        _register(noView);
        noView.onDestroy!(Object());
        expect(noView.events.skip(8), ['readCurrentView']);
        expect(noView.aliveReads, 0);

        final noObserver = _Host()..currentObserver = null;
        _register(noObserver);
        noObserver.onDestroy!(Object());
        expect(noObserver.events.skip(8), [
          'readCurrentView',
          'readCurrentObserver',
        ]);
        expect(noObserver.aliveReads, 0);

        final deadObserver = _Host()..alive = false;
        _register(deadObserver);
        deadObserver.onDestroy!(Object());
        expect(deadObserver.events.skip(8), [
          'readCurrentView',
          'readCurrentObserver',
          'readAlive',
        ]);
        expect(deadObserver.aliveReads, 1);
        expect(deadObserver.events, isNot(contains('removeFocusListener')));
      },
    );

    test(
      'setup failures propagate and prevent later calls without rollback',
      () {
        for (final stage in [
          'createListener',
          'requireView',
          'readInitialObserver',
          'addFocusListener',
          'readOwner',
          'readLifecycle',
          'createLifecycleObserver',
          'addLifecycleObserver',
        ]) {
          final host = _Host()..failureAt = stage;
          final failure = StateError(stage);
          host.failure = failure;

          expect(() => _register(host), throwsA(same(failure)), reason: stage);
          expect(host.events.last, stage, reason: stage);
          expect(
            host.events.length,
            host.events.indexOf(stage) + 1,
            reason: stage,
          );
          if (host.events.contains('addFocusListener') &&
              stage != 'addFocusListener') {
            expect(
              identical(host.addedFocusListener, host.focusListener),
              isTrue,
              reason: stage,
            );
            expect(host.removedFocusListener, isNull, reason: stage);
          }
        }
      },
    );

    test(
      'destroy callback failures propagate and stop subsequent operations',
      () {
        for (final stage in [
          'readCurrentView',
          'readCurrentObserver',
          'readAlive',
          'removeFocusListener',
        ]) {
          final host = _Host()..failureAt = stage;
          final failure = StateError(stage);
          host.failure = failure;
          _register(host);
          host.failureAt = stage;

          expect(
            () => host.onDestroy!(Object()),
            throwsA(same(failure)),
            reason: stage,
          );
          expect(host.events.last, stage, reason: stage);
          expect(
            host.events.skip(8).length,
            host.events.skip(8).toList().indexOf(stage) + 1,
            reason: stage,
          );
        }
      },
    );
  });
}

class _Host {
  final fragment = Object();
  Object view = Object();
  Object initialObserver = Object();
  Object? currentView = Object();
  Object? currentObserver = Object();
  final owner = Object();
  final lifecycle = Object();
  final focusListener = Object();
  final lifecycleObserver = Object();
  final events = <String>[];
  Object? failure;
  String? failureAt;
  Object? createdAction;
  Object? addedFocusListener;
  Object? registeredLifecycle;
  Object? registeredLifecycleObserver;
  Object? lastCurrentView;
  Object? lastAliveObserver;
  Object? removedObserver;
  Object? removedFocusListener;
  void Function(Object)? onDestroy;
  bool alive = true;
  int aliveReads = 0;

  Object createWindowFocusChangeListener(void Function(bool) action) {
    _hit('createListener');
    createdAction = action;
    return focusListener;
  }

  void _hit(String stage) {
    events.add(stage);
    if (failureAt == stage) throw failure!;
  }

  Object requireView(Object actualFragment) {
    _hit('requireView');
    expect(identical(actualFragment, fragment), isTrue);
    return view;
  }

  Object readViewTreeObserver(Object actualView) {
    _hit('readInitialObserver');
    expect(identical(actualView, view), isTrue);
    return initialObserver;
  }

  void addWindowFocusChangeListener(Object observer, Object listener) {
    _hit('addFocusListener');
    expect(identical(observer, initialObserver), isTrue);
    addedFocusListener = listener;
  }

  Object readViewLifecycleOwner(Object actualFragment) {
    _hit('readOwner');
    expect(identical(actualFragment, fragment), isTrue);
    return owner;
  }

  Object readLifecycle(Object actualOwner) {
    _hit('readLifecycle');
    expect(identical(actualOwner, owner), isTrue);
    return lifecycle;
  }

  Object createDefaultLifecycleObserver(void Function(Object) callback) {
    _hit('createLifecycleObserver');
    onDestroy = callback;
    return lifecycleObserver;
  }

  void addLifecycleObserver(Object actualLifecycle, Object observer) {
    _hit('addLifecycleObserver');
    registeredLifecycle = actualLifecycle;
    registeredLifecycleObserver = observer;
  }

  Object? readCurrentView(Object actualFragment) {
    _hit('readCurrentView');
    expect(identical(actualFragment, fragment), isTrue);
    lastCurrentView = currentView;
    return currentView;
  }

  Object? readCurrentViewTreeObserver(Object actualView) {
    _hit('readCurrentObserver');
    lastCurrentView = actualView;
    return currentObserver;
  }

  bool isViewTreeObserverAlive(Object observer) {
    _hit('readAlive');
    aliveReads++;
    lastAliveObserver = observer;
    return alive;
  }

  void removeWindowFocusChangeListener(Object observer, Object listener) {
    _hit('removeFocusListener');
    removedObserver = observer;
    removedFocusListener = listener;
  }
}

void _register(_Host host) {
  onWindowFocusChanged<Object, Object, Object, Object, Object, Object, Object>(
    fragment: host.fragment,
    action: (_) {},
    createWindowFocusChangeListener: host.createWindowFocusChangeListener,
    requireView: host.requireView,
    readViewTreeObserver: host.readViewTreeObserver,
    addWindowFocusChangeListener: host.addWindowFocusChangeListener,
    readViewLifecycleOwner: host.readViewLifecycleOwner,
    readLifecycle: host.readLifecycle,
    createDefaultLifecycleObserver: host.createDefaultLifecycleObserver,
    addLifecycleObserver: host.addLifecycleObserver,
    readCurrentView: host.readCurrentView,
    readCurrentViewTreeObserver: host.readCurrentViewTreeObserver,
    isViewTreeObserverAlive: host.isViewTreeObserverAlive,
    removeWindowFocusChangeListener: host.removeWindowFocusChangeListener,
  );
}
