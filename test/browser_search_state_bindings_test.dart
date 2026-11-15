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
 * Source-derived callback binding cases for CardBrowserSearchViewModel.kt,
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser saved-state flow bindings', () {
    test(
      'calls typed factories in source order with exact key/default pairs',
      () {
        final calls = <(String, Object)>[];

        final bindings = bindBrowserSearchStateFlows<Object, Object>(
          getBooleanStateFlow: (key, defaultValue) {
            calls.add((key, defaultValue));
            return Object();
          },
          getStringStateFlow: (key, defaultValue) {
            calls.add((key, defaultValue));
            return Object();
          },
        );

        expect(calls, [
          ('advancedSearch', false),
          ('advancedSearchText', ''),
          ('basicSearchText', ''),
          ('historyExpanded', false),
        ]);
        expect(bindings, isA<BrowserSearchStateFlowBindings<Object, Object>>());
      },
    );

    test('returns every opaque callback token unchanged', () {
      final advancedSearch = Object();
      final advancedText = Object();
      final basicText = Object();
      final historyExpanded = Object();
      var booleanCall = 0;
      var stringCall = 0;

      final bindings = bindBrowserSearchStateFlows<Object, Object>(
        getBooleanStateFlow: (_, _) =>
            [advancedSearch, historyExpanded][booleanCall++],
        getStringStateFlow: (_, _) => [advancedText, basicText][stringCall++],
      );

      expect(identical(bindings.advancedSearch, advancedSearch), isTrue);
      expect(identical(bindings.advancedSearchText, advancedText), isTrue);
      expect(identical(bindings.basicSearchText, basicText), isTrue);
      expect(identical(bindings.historyExpanded, historyExpanded), isTrue);
    });

    test('propagates the first factory failure and skips later calls', () {
      final error = StateError('flow factory failed');
      final calls = <String>[];

      expect(
        () => bindBrowserSearchStateFlows<Object, Object>(
          getBooleanStateFlow: (key, _) {
            calls.add(key);
            return Object();
          },
          getStringStateFlow: (key, _) {
            calls.add(key);
            throw error;
          },
        ),
        throwsA(same(error)),
      );
      expect(calls, ['advancedSearch', 'advancedSearchText']);
    });
  });
}
