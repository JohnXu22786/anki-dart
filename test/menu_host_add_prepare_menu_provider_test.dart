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
 * Source-derived from MenuHost.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('menuHostAddPrepareMenuProvider', () {
    test(
      'creates then registers one provider with identical host and token',
      () {
        final events = <String>[];
        final host = Object();
        final provider = _Provider();
        var factoryCalls = 0;
        var registrationCalls = 0;
        Object? registeredHost;
        _Provider? registeredProvider;

        menuHostAddPrepareMenuProvider<
          Object,
          Object,
          Object,
          Object,
          _Provider
        >(
          menuHost: host,
          onPrepare: (_) {},
          createMenuProvider:
              (onCreateMenu, onPrepareMenu, onMenuItemSelected) {
                events.add('create');
                factoryCalls++;
                provider.callbacks = (
                  onCreateMenu,
                  onPrepareMenu,
                  onMenuItemSelected,
                );
                return provider;
              },
          addMenuProvider: (actualHost, actualProvider) {
            events.add('register');
            registrationCalls++;
            registeredHost = actualHost;
            registeredProvider = actualProvider;
          },
        );

        expect(events, ['create', 'register']);
        expect(factoryCalls, 1);
        expect(registrationCalls, 1);
        expect(identical(registeredHost, host), isTrue);
        expect(identical(registeredProvider, provider), isTrue);
      },
    );

    test(
      'create is a no-op, prepare forwards once, selection returns false',
      () {
        final events = <String>[];
        final menu = Object();
        final inflater = Object();
        final item = Object();
        final provider = _Provider();
        var prepareCalls = 0;

        menuHostAddPrepareMenuProvider<
          Object,
          Object,
          Object,
          Object,
          _Provider
        >(
          menuHost: Object(),
          onPrepare: (actualMenu) {
            events.add('prepare');
            prepareCalls++;
            expect(identical(actualMenu, menu), isTrue);
          },
          createMenuProvider:
              (onCreateMenu, onPrepareMenu, onMenuItemSelected) {
                provider.callbacks = (
                  onCreateMenu,
                  onPrepareMenu,
                  onMenuItemSelected,
                );
                return provider;
              },
          addMenuProvider: (_, __) {},
        );

        provider.callbacks.$1(menu, inflater);
        expect(events, isEmpty);
        expect(provider.callbacks.$3(item), isFalse);
        expect(events, isEmpty);
        expect(prepareCalls, 0);
        provider.callbacks.$2(menu);
        expect(events, ['prepare']);
        expect(prepareCalls, 1);
        expect(provider.callbacks.$3(item), isFalse);
        expect(events, ['prepare']);
        expect(prepareCalls, 1);
      },
    );

    test('factory, registration, and prepare failures propagate unchanged', () {
      final factoryFailure = StateError('factory');
      final factoryEvents = <String>[];
      expect(
        () =>
            menuHostAddPrepareMenuProvider<
              Object,
              Object,
              Object,
              Object,
              _Provider
            >(
              menuHost: Object(),
              onPrepare: (_) {},
              createMenuProvider: (_, __, ___) {
                factoryEvents.add('create');
                throw factoryFailure;
              },
              addMenuProvider: (_, __) => factoryEvents.add('register'),
            ),
        throwsA(same(factoryFailure)),
      );
      expect(factoryEvents, ['create']);

      final registrationFailure = StateError('registration');
      final registrationEvents = <String>[];
      final provider = _Provider();
      expect(
        () =>
            menuHostAddPrepareMenuProvider<
              Object,
              Object,
              Object,
              Object,
              _Provider
            >(
              menuHost: Object(),
              onPrepare: (_) {},
              createMenuProvider:
                  (onCreateMenu, onPrepareMenu, onMenuItemSelected) {
                    registrationEvents.add('create');
                    provider.callbacks = (
                      onCreateMenu,
                      onPrepareMenu,
                      onMenuItemSelected,
                    );
                    return provider;
                  },
              addMenuProvider: (_, __) {
                registrationEvents.add('register');
                throw registrationFailure;
              },
            ),
        throwsA(same(registrationFailure)),
      );
      expect(registrationEvents, ['create', 'register']);

      final prepareFailure = StateError('prepare');
      final prepareEvents = <String>[];
      final callbackProvider = _Provider();
      menuHostAddPrepareMenuProvider<Object, Object, Object, Object, _Provider>(
        menuHost: Object(),
        onPrepare: (_) {
          prepareEvents.add('prepare');
          throw prepareFailure;
        },
        createMenuProvider: (onCreateMenu, onPrepareMenu, onMenuItemSelected) {
          callbackProvider.callbacks = (
            onCreateMenu,
            onPrepareMenu,
            onMenuItemSelected,
          );
          return callbackProvider;
        },
        addMenuProvider: (_, __) => prepareEvents.add('register'),
      );
      expect(
        () => callbackProvider.callbacks.$2(Object()),
        throwsA(same(prepareFailure)),
      );
      expect(prepareEvents, ['register', 'prepare']);
    });
  });
}

final class _Provider {
  late (
    void Function(Object menu, Object inflater),
    void Function(Object menu),
    bool Function(Object item),
  )
  callbacks;
}
