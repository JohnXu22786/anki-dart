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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentInitialSelectedTab', () {
    test('mapped ID skips arguments and is assigned once unchanged', () {
      final events = <String>[];
      var cardIndexReads = 0;
      final callbacks = CardTemplateFragmentInitialSelectedTabCallbacks<Object>(
        readCardIndex: () {
          cardIndexReads++;
          events.add('cardIndex');
          return 3;
        },
        readTabToViewId: (index) {
          events.add('tabToViewId:$index');
          return 0;
        },
        requireArguments: () {
          events.add('requireArguments');
          throw StateError('fallback must be skipped');
        },
        readEditorViewId: (_) => throw StateError('fallback must be skipped'),
        setSelectedItemId: (id) => events.add('selectedItemId:$id'),
      );

      cardTemplateFragmentInitialSelectedTab(callbacks: callbacks);

      expect(cardIndexReads, 1);
      expect(events, ['cardIndex', 'tabToViewId:3', 'selectedItemId:0']);
    });

    test('missing and null mappings read arguments lazily in source order', () {
      for (final mappings in <Map<int, int?>>[
        {},
        {-6: null},
      ]) {
        final events = <String>[];
        var cardIndexReads = 0;
        final arguments = Object();
        final callbacks =
            CardTemplateFragmentInitialSelectedTabCallbacks<Object>(
              readCardIndex: () {
                cardIndexReads++;
                events.add('cardIndex');
                return -6;
              },
              readTabToViewId: (index) {
                events.add('tabToViewId:$index');
                return mappings[index];
              },
              requireArguments: () {
                events.add('requireArguments');
                return arguments;
              },
              readEditorViewId: (value) {
                expect(identical(value, arguments), isTrue);
                events.add('getInt');
                return -9;
              },
              setSelectedItemId: (id) => events.add('selectedItemId:$id'),
            );

        cardTemplateFragmentInitialSelectedTab(callbacks: callbacks);

        expect(cardIndexReads, 1);
        expect(events, [
          'cardIndex',
          'tabToViewId:-6',
          'requireArguments',
          'getInt',
          'selectedItemId:-9',
        ]);
      }
    });

    test('callback failures propagate and stop later work', () {
      for (final failAt in ['cardIndex', 'lookup', 'arguments', 'getInt']) {
        final failure = StateError(failAt);
        final events = <String>[];
        final callbacks =
            CardTemplateFragmentInitialSelectedTabCallbacks<Object>(
              readCardIndex: () {
                events.add('cardIndex');
                if (failAt == 'cardIndex') throw failure;
                return 2;
              },
              readTabToViewId: (index) {
                events.add('lookup');
                if (failAt == 'lookup') throw failure;
                return null;
              },
              requireArguments: () {
                events.add('arguments');
                if (failAt == 'arguments') throw failure;
                return Object();
              },
              readEditorViewId: (_) {
                events.add('getInt');
                if (failAt == 'getInt') throw failure;
                return 4;
              },
              setSelectedItemId: (_) => events.add('set'),
            );

        expect(
          () => cardTemplateFragmentInitialSelectedTab(callbacks: callbacks),
          throwsA(same(failure)),
        );
        expect(events, switch (failAt) {
          'cardIndex' => ['cardIndex'],
          'lookup' => ['cardIndex', 'lookup'],
          'arguments' => ['cardIndex', 'lookup', 'arguments'],
          _ => ['cardIndex', 'lookup', 'arguments', 'getInt'],
        });
      }
    });
  });
}
