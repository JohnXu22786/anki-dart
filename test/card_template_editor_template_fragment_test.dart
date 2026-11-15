/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

final class _TemplateFragment {}

void main() {
  group('cardTemplateEditorTemplateFragment', () {
    test('null adapter returns null without reading its ID or the manager', () {
      final events = <String>[];
      final callbacks =
          CardTemplateEditorTemplateFragmentCallbacks<
            Object,
            _TemplateFragment
          >(
            readPagerAdapter: () {
              events.add('adapter');
              return null;
            },
            getItemId: (_, position) {
              events.add('itemId:$position');
              return BigInt.from(10);
            },
            findFragmentByTag: (tag) {
              events.add('find:$tag');
              return _TemplateFragment();
            },
          );

      expect(
        cardTemplateEditorTemplateFragment(position: -8, callbacks: callbacks),
        isNull,
      );
      expect(events, ['adapter']);
    });

    test(
      'reads adapter and item ID once, preserving position and decimal tag',
      () {
        final events = <String>[];
        final adapter = Object();
        final fragment = _TemplateFragment();
        final ids = [
          BigInt.parse('-9223372036854775808'),
          BigInt.parse('9223372036854775807'),
        ];
        var idReads = 0;
        final callbacks =
            CardTemplateEditorTemplateFragmentCallbacks<
              Object,
              _TemplateFragment
            >(
              readPagerAdapter: () {
                events.add('adapter');
                return adapter;
              },
              getItemId: (value, position) {
                expect(identical(value, adapter), isTrue);
                events.add('itemId:$position');
                return ids[idReads++];
              },
              findFragmentByTag: (tag) {
                events.add('find:$tag');
                return fragment;
              },
            );

        final result = cardTemplateEditorTemplateFragment(
          position: -4,
          callbacks: callbacks,
        );
        final secondResult = cardTemplateEditorTemplateFragment(
          position: -4,
          callbacks: callbacks,
        );

        expect(identical(result, fragment), isTrue);
        expect(identical(secondResult, fragment), isTrue);
        expect(events, [
          'adapter',
          'itemId:-4',
          'find:f-9223372036854775808',
          'adapter',
          'itemId:-4',
          'find:f9223372036854775807',
        ]);
      },
    );

    test('missing and wrong-type fragments return null', () {
      final adapter = Object();
      final tags = <String>[];
      final callbacks =
          CardTemplateEditorTemplateFragmentCallbacks<
            Object,
            _TemplateFragment
          >(
            readPagerAdapter: () => adapter,
            getItemId: (_, position) => BigInt.from(position),
            findFragmentByTag: (tag) {
              tags.add(tag);
              return tags.length == 1 ? null : Object();
            },
          );

      expect(
        cardTemplateEditorTemplateFragment(position: 3, callbacks: callbacks),
        isNull,
      );
      expect(
        cardTemplateEditorTemplateFragment(position: 3, callbacks: callbacks),
        isNull,
      );
      expect(tags, ['f3', 'f3']);
    });

    test('callback failures propagate in source order and stop later work', () {
      final callbackNames = ['adapter', 'itemId', 'find'];
      for (
        var failingIndex = 0;
        failingIndex < callbackNames.length;
        failingIndex++
      ) {
        final failure = StateError('failure $failingIndex');
        final events = <String>[];
        void run(String name) {
          events.add(name);
          if (callbackNames[failingIndex] == name) throw failure;
        }

        final callbacks =
            CardTemplateEditorTemplateFragmentCallbacks<
              Object,
              _TemplateFragment
            >(
              readPagerAdapter: () {
                run('adapter');
                return Object();
              },
              getItemId: (_, _) {
                run('itemId');
                return BigInt.from(7);
              },
              findFragmentByTag: (_) {
                run('find');
                return _TemplateFragment();
              },
            );

        expect(
          () => cardTemplateEditorTemplateFragment(
            position: 5,
            callbacks: callbacks,
          ),
          throwsA(same(failure)),
        );
        expect(events, callbackNames.take(failingIndex + 1));
      }
    });
  });
}
