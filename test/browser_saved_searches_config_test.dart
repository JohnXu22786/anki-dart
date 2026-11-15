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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SavedSearches.kt and SavedSearchesTest.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser saved-search config orchestration', () {
    test(
      'load and save invoke the matching callback once with original lists',
      () {
        final calls = <String>[];
        final loaded = <BrowserSavedSearch>[
          const BrowserSavedSearch(name: 'A', query: 'first'),
        ];
        final saved = <BrowserSavedSearch>[
          const BrowserSavedSearch(name: 'b', query: 'second'),
        ];
        final config = BrowserSavedSearchesConfig(
          load: () {
            calls.add('load');
            return loaded;
          },
          save: (values) {
            calls.add('save');
            expect(identical(values, saved), isTrue);
          },
        );

        expect(identical(config.loadFromConfig(), loaded), isTrue);
        config.saveToConfig(saved);

        expect(calls, ['load', 'save']);
      },
    );

    test(
      'byName loads once and returns the first exact case-sensitive name',
      () {
        final calls = <String>[];
        final first = const BrowserSavedSearch(name: 'A', query: 'first');
        final lowercase = const BrowserSavedSearch(
          name: 'a',
          query: 'lowercase',
        );
        final config = BrowserSavedSearchesConfig(
          load: () {
            calls.add('load');
            return [
              first,
              const BrowserSavedSearch(name: 'A', query: 'second'),
              lowercase,
            ];
          },
          save: (_) => calls.add('save'),
        );

        expect(identical(config.byName('A'), first), isTrue);
        expect(identical(config.byName('a'), lowercase), isTrue);
        expect(config.byName('missing'), isNull);
        expect(calls, ['load', 'load', 'load']);
      },
    );

    test(
      'add loads, saves normalized value, reloads and returns reloaded list',
      () {
        final calls = <String>[];
        final original = <BrowserSavedSearch>[
          const BrowserSavedSearch(name: 'existing', query: 'old'),
        ];
        final reloaded = <BrowserSavedSearch>[
          ...original,
          const BrowserSavedSearch(name: 'new', query: 'query'),
        ];
        final config = BrowserSavedSearchesConfig(
          load: () {
            calls.add('load');
            return calls.length == 1 ? original : reloaded;
          },
          save: (values) {
            calls.add('save');
            expect(values, [
              ...original,
              const BrowserSavedSearch(name: 'new', query: 'query'),
            ]);
          },
        );

        final (changed, values) = config.add(
          const BrowserSavedSearch(name: 'new', query: ' \tquery\n'),
        );

        expect(changed, isTrue);
        expect(identical(values, reloaded), isTrue);
        expect(calls, ['load', 'save', 'load']);
      },
    );

    test('duplicate add returns original list without saving or reloading', () {
      final calls = <String>[];
      final original = <BrowserSavedSearch>[
        const BrowserSavedSearch(name: 'A', query: 'first'),
      ];
      final config = BrowserSavedSearchesConfig(
        load: () {
          calls.add('load');
          return original;
        },
        save: (_) => calls.add('save'),
      );

      final (changed, values) = config.add(
        const BrowserSavedSearch(name: 'A', query: 'replacement'),
      );

      expect(changed, isFalse);
      expect(identical(values, original), isTrue);
      expect(calls, ['load']);
    });

    test(
      'remove returns original on miss and saves filtered list without reload',
      () {
        final calls = <String>[];
        final original = <BrowserSavedSearch>[
          const BrowserSavedSearch(name: 'A', query: 'upper'),
          const BrowserSavedSearch(name: 'a', query: 'lower'),
        ];
        final savedLists = <List<BrowserSavedSearch>>[];
        final config = BrowserSavedSearchesConfig(
          load: () {
            calls.add('load');
            return original;
          },
          save: (values) {
            calls.add('save');
            savedLists.add(values);
          },
        );

        final (missingChanged, missingValues) = config.removeByName('absent');
        expect(missingChanged, isFalse);
        expect(identical(missingValues, original), isTrue);
        expect(calls, ['load']);

        calls.clear();
        final (changed, values) = config.removeByName('A');
        expect(changed, isTrue);
        expect(values, [const BrowserSavedSearch(name: 'a', query: 'lower')]);
        expect(identical(values, savedLists.single), isTrue);
        expect(calls, ['load', 'save']);
      },
    );

    test('clear saves one empty list', () {
      final calls = <String>[];
      final config = BrowserSavedSearchesConfig(
        load: () {
          calls.add('load');
          return const [];
        },
        save: (values) {
          calls.add('save');
          expect(values, isEmpty);
        },
      );

      config.clear();

      expect(calls, ['save']);
    });

    test('callback errors propagate unchanged and stop later callbacks', () {
      final loadFailure = StateError('load failed');
      final loadCalls = <String>[];
      final failingLoad = BrowserSavedSearchesConfig(
        load: () {
          loadCalls.add('load');
          throw loadFailure;
        },
        save: (_) => loadCalls.add('save'),
      );

      expect(
        () => failingLoad.add(const BrowserSavedSearch(name: 'x', query: 'y')),
        throwsA(same(loadFailure)),
      );
      expect(loadCalls, ['load']);

      final saveFailure = ArgumentError('save failed');
      final saveCalls = <String>[];
      final failingSave = BrowserSavedSearchesConfig(
        load: () {
          saveCalls.add('load');
          return const [];
        },
        save: (_) {
          saveCalls.add('save');
          throw saveFailure;
        },
      );

      expect(
        () => failingSave.add(const BrowserSavedSearch(name: 'x', query: 'y')),
        throwsA(same(saveFailure)),
      );
      expect(saveCalls, ['load', 'save']);
    });
  });
}
