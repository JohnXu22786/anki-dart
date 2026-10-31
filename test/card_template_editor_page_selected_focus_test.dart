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
  group('cardTemplateEditorPageSelected', () {
    test('looks up the selected fragment then focuses its edit field once', () {
      final events = <String>[];
      final fragment = Object();
      final binding = Object();
      final editText = Object();
      final position = -7;

      cardTemplateEditorPageSelected(
        position: position,
        templateFragment: (selectedPosition) {
          events.add('fragment:$selectedPosition');
          expect(selectedPosition, position);
          return fragment;
        },
        binding: (selectedFragment) {
          events.add('binding:${identical(selectedFragment, fragment)}');
          return binding;
        },
        editText: (selectedBinding) {
          events.add('editText:${identical(selectedBinding, binding)}');
          return editText;
        },
        requestFocus: (selectedEditText) {
          events.add('focus:${identical(selectedEditText, editText)}');
        },
      );

      expect(events, [
        'fragment:$position',
        'binding:true',
        'editText:true',
        'focus:true',
      ]);
    });

    test('a missing fragment skips binding, edit field, and focus', () {
      final events = <String>[];

      cardTemplateEditorPageSelected(
        position: 4,
        templateFragment: (position) {
          events.add('fragment:$position');
          return null;
        },
        binding: (_) {
          events.add('binding');
          return Object();
        },
        editText: (_) {
          events.add('editText');
          return Object();
        },
        requestFocus: (_) => events.add('focus'),
      );

      expect(events, ['fragment:4']);
    });

    test('a missing binding skips edit-field lookup and focus', () {
      final events = <String>[];

      cardTemplateEditorPageSelected(
        position: 4,
        templateFragment: (position) {
          events.add('fragment:$position');
          return Object();
        },
        binding: (fragment) {
          events.add('binding');
          return null;
        },
        editText: (_) {
          events.add('editText');
          return Object();
        },
        requestFocus: (_) => events.add('focus'),
      );

      expect(events, ['fragment:4', 'binding']);
    });

    test('a missing edit field skips the focus request', () {
      final events = <String>[];

      cardTemplateEditorPageSelected(
        position: 4,
        templateFragment: (position) {
          events.add('fragment:$position');
          return Object();
        },
        binding: (_) {
          events.add('binding');
          return Object();
        },
        editText: (_) {
          events.add('editText');
          return null;
        },
        requestFocus: (_) => events.add('focus'),
      );

      expect(events, ['fragment:4', 'binding', 'editText']);
    });

    test('callback failures propagate unchanged and stop later callbacks', () {
      final callbacks = <String>['fragment', 'binding', 'editText', 'focus'];
      for (
        var failingIndex = 0;
        failingIndex < callbacks.length;
        failingIndex++
      ) {
        final failure = StateError('failure $failingIndex');
        final events = <String>[];
        final fragment = Object();
        final binding = Object();
        final editText = Object();
        void invoke(String callback) {
          events.add(callback);
          if (callbacks[failingIndex] == callback) throw failure;
        }

        expect(
          () => cardTemplateEditorPageSelected(
            position: 12,
            templateFragment: (position) {
              invoke('fragment');
              return fragment;
            },
            binding: (value) {
              expect(identical(value, fragment), isTrue);
              invoke('binding');
              return binding;
            },
            editText: (value) {
              expect(identical(value, binding), isTrue);
              invoke('editText');
              return editText;
            },
            requestFocus: (value) {
              expect(identical(value, editText), isTrue);
              invoke('focus');
            },
          ),
          throwsA(same(failure)),
        );
        expect(events, callbacks.take(failingIndex + 1));
      }
    });
  });
}
