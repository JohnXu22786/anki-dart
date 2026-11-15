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
 * Source-derived from View.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('onGlobalLayout', () {
    test(
      'destroyed lifecycle returns before creating or registering observers',
      () {
        final access = _Access(state: _State.destroyed);

        onGlobalLayout(access.view, access.owner, () {}, access);

        expect(access.events, ['read currentState', 'check destroyed']);
        expect(access.currentStateReads, 1);
      },
    );

    test(
      'registers callback listener before lifecycle observer with exact tokens',
      () {
        final access = _Access(state: _State.started);
        var actionCalls = 0;
        void action() => actionCalls++;

        onGlobalLayout(access.view, access.owner, action, access);

        expect(access.events, [
          'read currentState',
          'check destroyed',
          'create listener',
          'read viewTreeObserver',
          'add listener',
          'create lifecycle observer',
          'add lifecycle observer',
        ]);
        expect(access.currentStateReads, 1);
        expect(access.addedListener, same(access.listener));
        expect(access.addedTreeObserver, same(access.initialTreeObserver));
        expect(access.addedOwner, same(access.owner));
        expect(access.addedLifecycleObserver, same(access.lifecycleObserver));
        expect(access.listener!.action, same(action));

        access.listener!.action();
        expect(actionCalls, 1);
      },
    );

    test(
      'destroy reads the current observer and removes the same listener only if alive',
      () {
        for (final isAlive in [true, false]) {
          final access = _Access(state: _State.started, isAlive: isAlive);
          onGlobalLayout(access.view, access.owner, () {}, access);
          access.events.clear();
          final currentTreeObserver = _Token('current observer');
          access.currentTreeObserver = currentTreeObserver;

          access.lifecycleObserver!.onDestroy(_Token('destroy callback owner'));

          expect(access.events, [
            'read viewTreeObserver',
            'check observer alive',
            if (isAlive) 'remove listener',
          ]);
          expect(access.treeObserverReads, 2);
          expect(access.addedTreeObserver, same(access.initialTreeObserver));
          expect(access.checkedTreeObserver, same(currentTreeObserver));
          expect(access.removedListeners, hasLength(isAlive ? 1 : 0));
          expect(access.removedTreeObservers, hasLength(isAlive ? 1 : 0));
          if (isAlive) {
            expect(
              identical(access.removedListeners.single, access.listener),
              isTrue,
            );
            expect(
              identical(
                access.removedTreeObservers.single,
                currentTreeObserver,
              ),
              isTrue,
            );
          }
        }
      },
    );

    test(
      'host failures propagate unchanged and stop later registration or destroy work',
      () {
        for (final failedStage in [
          'read currentState',
          'check destroyed',
          'create listener',
          'read viewTreeObserver',
          'add listener',
          'create lifecycle observer',
          'add lifecycle observer',
        ]) {
          final access = _Access(
            state: _State.started,
            failedStage: failedStage,
          );

          expect(
            () => onGlobalLayout(access.view, access.owner, () {}, access),
            throwsA(same(access.failure)),
            reason: failedStage,
          );
          expect(access.events.last, failedStage, reason: failedStage);
          expect(access.events, _registrationEventsThrough(failedStage));
        }

        for (final failedStage in [
          'read viewTreeObserver',
          'check observer alive',
          'remove listener',
        ]) {
          final access = _Access(state: _State.started);
          onGlobalLayout(access.view, access.owner, () {}, access);
          access.events.clear();
          access.failedStage = failedStage;

          expect(
            () => access.lifecycleObserver!.onDestroy(access.owner),
            throwsA(same(access.failure)),
            reason: 'destroy: $failedStage',
          );
          const stages = [
            'read viewTreeObserver',
            'check observer alive',
            'remove listener',
          ];
          expect(
            access.events,
            stages.take(stages.indexOf(failedStage) + 1).toList(),
            reason: 'destroy: $failedStage',
          );
        }
      },
    );
  });
}

List<String> _registrationEventsThrough(String failedStage) {
  const stages = [
    'read currentState',
    'check destroyed',
    'create listener',
    'read viewTreeObserver',
    'add listener',
    'create lifecycle observer',
    'add lifecycle observer',
  ];
  return stages.take(stages.indexOf(failedStage) + 1).toList();
}

enum _State { started, destroyed }

final class _Token {
  _Token(this.name);

  final String name;
}

final class _GlobalLayoutListener {
  _GlobalLayoutListener(this.action);

  final void Function() action;
}

final class _LifecycleObserver {
  _LifecycleObserver(this.onDestroy);

  final void Function(_Token owner) onDestroy;
}

final class _Access
    implements
        ViewOnGlobalLayoutAccess<
          _Token,
          _Token,
          _State,
          _GlobalLayoutListener,
          _Token,
          _LifecycleObserver
        > {
  _Access({required this.state, this.isAlive = true, this.failedStage});

  final _State state;
  final bool isAlive;
  String? failedStage;
  final failure = StateError('host operation failed');
  final view = _Token('view');
  final owner = _Token('owner');
  final initialTreeObserver = _Token('initial observer');
  _Token? currentTreeObserver;
  _GlobalLayoutListener? listener;
  _LifecycleObserver? lifecycleObserver;
  final events = <String>[];
  int currentStateReads = 0;
  int treeObserverReads = 0;
  _GlobalLayoutListener? addedListener;
  _Token? addedTreeObserver;
  _Token? addedOwner;
  _LifecycleObserver? addedLifecycleObserver;
  _Token? checkedTreeObserver;
  final removedListeners = <_GlobalLayoutListener>[];
  final removedTreeObservers = <_Token>[];

  void _event(String name) {
    events.add(name);
    if (failedStage == name) throw failure;
  }

  @override
  _State readLifecycleCurrentState(_Token lifecycleOwner) {
    currentStateReads++;
    _event('read currentState');
    expect(lifecycleOwner, same(owner));
    return state;
  }

  @override
  bool isDestroyedState(_State state) {
    _event('check destroyed');
    return state == _State.destroyed;
  }

  @override
  _GlobalLayoutListener createGlobalLayoutListener(void Function() action) {
    _event('create listener');
    return listener = _GlobalLayoutListener(action);
  }

  @override
  _Token readViewTreeObserver(_Token view) {
    treeObserverReads++;
    _event('read viewTreeObserver');
    expect(view, same(this.view));
    return currentTreeObserver ?? initialTreeObserver;
  }

  @override
  void addGlobalLayoutListener(
    _Token observer,
    _GlobalLayoutListener listener,
  ) {
    _event('add listener');
    addedTreeObserver = observer;
    addedListener = listener;
  }

  @override
  _LifecycleObserver createDefaultLifecycleObserver(
    void Function(_Token owner) onDestroy,
  ) {
    _event('create lifecycle observer');
    return lifecycleObserver = _LifecycleObserver(onDestroy);
  }

  @override
  void addLifecycleObserver(
    _Token lifecycleOwner,
    _LifecycleObserver observer,
  ) {
    _event('add lifecycle observer');
    addedOwner = lifecycleOwner;
    addedLifecycleObserver = observer;
  }

  @override
  bool isViewTreeObserverAlive(_Token observer) {
    _event('check observer alive');
    checkedTreeObserver = observer;
    return isAlive;
  }

  @override
  void removeGlobalLayoutListener(
    _Token observer,
    _GlobalLayoutListener listener,
  ) {
    _event('remove listener');
    removedTreeObservers.add(observer);
    removedListeners.add(listener);
  }
}
