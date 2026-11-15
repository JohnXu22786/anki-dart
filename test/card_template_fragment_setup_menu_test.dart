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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentSetupMenu', () {
    test('registers one deferred provider at RESUMED in source order', () {
      final harness = _Harness();

      cardTemplateFragmentSetupMenu(callbacks: harness.callbacks);

      expect(harness.events, [
        'require activity',
        'cast menu host',
        'create provider',
        'read view lifecycle owner',
        'read resumed state',
        'register provider',
      ]);
      expect(harness.registeredHost, same(harness.host));
      expect(harness.registeredProvider, same(harness.provider));
      expect(harness.registeredOwner, same(harness.owner));
      expect(harness.registeredState, same(harness.resumed));

      final menu = _Handle('menu');
      final inflater = _Handle('inflater');
      harness.provider!.onCreateMenu(menu, inflater);
      expect(harness.events, [
        'require activity',
        'cast menu host',
        'create provider',
        'read view lifecycle owner',
        'read resumed state',
        'register provider',
        'read menu resource',
        'inflate',
        'setup common menu',
      ]);
      expect(harness.inflatedMenu, same(menu));
      expect(harness.inflatedInflater, same(inflater));
      expect(harness.inflatedResource, same(harness.resource));
      expect(harness.commonMenu, same(menu));

      final item = _Handle('item');
      expect(harness.provider!.onMenuItemSelected(item), isTrue);
      expect(harness.selectedItem, same(item));
      expect(harness.events.last, 'handle item');
      harness.selectedResult = false;
      expect(harness.provider!.onMenuItemSelected(item), isFalse);
      expect(harness.events.last, 'handle item');
    });

    test('propagates failures unchanged and stops later source work', () {
      for (final failedStage in [
        'require activity',
        'cast menu host',
        'create provider',
        'read view lifecycle owner',
        'read resumed state',
        'register provider',
      ]) {
        final harness = _Harness(failedStage: failedStage);
        final failure = harness.failure;

        expect(
          () => cardTemplateFragmentSetupMenu(callbacks: harness.callbacks),
          throwsA(same(failure)),
          reason: failedStage,
        );
        expect(harness.events, [
          'require activity',
          if (failedStage != 'require activity') 'cast menu host',
          if (failedStage == 'create provider' ||
              failedStage == 'read view lifecycle owner' ||
              failedStage == 'read resumed state' ||
              failedStage == 'register provider')
            'create provider',
          if (failedStage == 'read view lifecycle owner' ||
              failedStage == 'read resumed state' ||
              failedStage == 'register provider')
            'read view lifecycle owner',
          if (failedStage == 'read resumed state' ||
              failedStage == 'register provider')
            'read resumed state',
          if (failedStage == 'register provider') 'register provider',
        ], reason: failedStage);
        if (failedStage == 'cast menu host') {
          expect(harness.provider, isNull);
        }
      }

      final deferred = _Harness(failedStage: 'inflate');
      cardTemplateFragmentSetupMenu(callbacks: deferred.callbacks);
      final deferredFailure = deferred.failure;
      expect(
        () => deferred.provider!.onCreateMenu(
          _Handle('menu'),
          _Handle('inflater'),
        ),
        throwsA(same(deferredFailure)),
      );
      expect(deferred.events, [
        'require activity',
        'cast menu host',
        'create provider',
        'read view lifecycle owner',
        'read resumed state',
        'register provider',
        'read menu resource',
        'inflate',
      ]);

      final resourceFailure = _Harness(failedStage: 'read menu resource');
      cardTemplateFragmentSetupMenu(callbacks: resourceFailure.callbacks);
      final deferredResourceFailure = resourceFailure.failure;
      expect(
        () => resourceFailure.provider!.onCreateMenu(
          _Handle('menu'),
          _Handle('inflater'),
        ),
        throwsA(same(deferredResourceFailure)),
      );
      expect(resourceFailure.events, [
        'require activity',
        'cast menu host',
        'create provider',
        'read view lifecycle owner',
        'read resumed state',
        'register provider',
        'read menu resource',
      ]);
    });
  });
}

final class _Harness {
  _Harness({this.failedStage}) {
    failure = StateError('$failedStage failed');
    provider = null;
    callbacks =
        CardTemplateFragmentSetupMenuCallbacks<
          _Handle,
          _MenuHost,
          _Handle,
          _Handle,
          _Handle,
          _Handle,
          _Handle,
          _Handle,
          _MenuProvider
        >(
          requireActivity: () {
            events.add('require activity');
            if (failedStage == 'require activity') throw failure;
            return activity;
          },
          castMenuHost: (actualActivity) {
            events.add('cast menu host');
            expect(actualActivity, same(activity));
            if (failedStage == 'cast menu host') throw failure;
            return host;
          },
          createMenuProvider: (onCreateMenu, onMenuItemSelected) {
            events.add('create provider');
            if (failedStage == 'create provider') throw failure;
            return provider = _MenuProvider(onCreateMenu, onMenuItemSelected);
          },
          addMenuProvider:
              (actualHost, actualProvider, actualOwner, actualState) {
                events.add('register provider');
                if (failedStage == 'register provider') throw failure;
                registeredHost = actualHost;
                registeredProvider = actualProvider;
                registeredOwner = actualOwner;
                registeredState = actualState;
              },
          readViewLifecycleOwner: () {
            events.add('read view lifecycle owner');
            if (failedStage == 'read view lifecycle owner') throw failure;
            return owner;
          },
          readResumedLifecycleState: () {
            events.add('read resumed state');
            if (failedStage == 'read resumed state') throw failure;
            return resumed;
          },
          readCardTemplateEditorMenuResource: () {
            events.add('read menu resource');
            if (failedStage == 'read menu resource') throw failure;
            return resource;
          },
          inflateMenu: (actualInflater, actualResource, actualMenu) {
            events.add('inflate');
            inflatedInflater = actualInflater;
            inflatedResource = actualResource;
            inflatedMenu = actualMenu;
            if (failedStage == 'inflate') throw failure;
          },
          setupCommonMenu: (actualMenu) {
            events.add('setup common menu');
            commonMenu = actualMenu;
            if (failedStage == 'setup common menu') throw failure;
          },
          handleCommonMenuItemSelected: (actualItem) {
            events.add('handle item');
            selectedItem = actualItem;
            if (failedStage == 'handle item') throw failure;
            return selectedResult;
          },
        );
  }

  final failedStage;
  final events = <String>[];
  final activity = _Handle('activity');
  final host = _MenuHost();
  final owner = _Handle('owner');
  final resumed = _Handle('Lifecycle.State.RESUMED');
  final resource = _Handle('R.menu.card_template_editor');
  late final StateError failure;
  late final CardTemplateFragmentSetupMenuCallbacks<
    _Handle,
    _MenuHost,
    _Handle,
    _Handle,
    _Handle,
    _Handle,
    _Handle,
    _Handle,
    _MenuProvider
  >
  callbacks;
  _MenuProvider? provider;
  _MenuHost? registeredHost;
  _MenuProvider? registeredProvider;
  _Handle? registeredOwner;
  _Handle? registeredState;
  _Handle? inflatedMenu;
  _Handle? inflatedInflater;
  _Handle? inflatedResource;
  _Handle? commonMenu;
  _Handle? selectedItem;
  bool selectedResult = true;
}

final class _MenuProvider {
  _MenuProvider(this.onCreateMenu, this.onMenuItemSelected);

  final void Function(_Handle menu, _Handle inflater) onCreateMenu;
  final bool Function(_Handle menuItem) onMenuItemSelected;
}

final class _MenuHost {}

final class _Handle {
  const _Handle(this.label);

  final String label;
}
