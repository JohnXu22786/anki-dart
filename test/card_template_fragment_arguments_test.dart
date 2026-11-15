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

void main() {
  group('createCardTemplateFragment', () {
    test(
      'preserves source creation, typed write, assignment, and return order',
      () {
        final fragment = Object();
        final bundle = Object();
        final events = <(String, Object?, Object?)>[];
        final result = createCardTemplateFragment(
          cardIndex: 17,
          noteId: 0x123456789,
          viewId: 29,
          cardIndexKey: 'card-index',
          noteIdKey: 'note-id',
          viewIdKey: 'view-id',
          callbacks: CardTemplateFragmentArgumentCallbacks<Object, Object>(
            createFragment: () {
              events.add(('fragment', null, null));
              return fragment;
            },
            createBundle: () {
              events.add(('bundle', null, null));
              return bundle;
            },
            putInt: (target, key, value) {
              events.add(('putInt', target, (key, value)));
            },
            putLong: (target, key, value) {
              events.add(('putLong', target, (key, value)));
            },
            assignArguments: (target, arguments) {
              events.add(('arguments', target, arguments));
            },
          ),
        );

        expect(result, same(fragment));
        expect(events, [
          ('fragment', null, null),
          ('bundle', null, null),
          ('putInt', bundle, ('card-index', 17)),
          ('putLong', bundle, ('note-id', 0x123456789)),
          ('putInt', bundle, ('view-id', 29)),
          ('arguments', fragment, bundle),
        ]);
      },
    );

    test('propagates each callback failure and stops later source actions', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'fragment', reached: ['fragment']),
        (stage: 'bundle', reached: ['fragment', 'bundle']),
        (stage: 'cardIndex', reached: ['fragment', 'bundle', 'cardIndex']),
        (
          stage: 'noteId',
          reached: ['fragment', 'bundle', 'cardIndex', 'noteId'],
        ),
        (
          stage: 'viewId',
          reached: ['fragment', 'bundle', 'cardIndex', 'noteId', 'viewId'],
        ),
        (
          stage: 'arguments',
          reached: [
            'fragment',
            'bundle',
            'cardIndex',
            'noteId',
            'viewId',
            'arguments',
          ],
        ),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        T invoke<T>(String stage, T Function() action) {
          reached.add(stage);
          if (testCase.stage == stage) {
            throw failure;
          }
          return action();
        }

        expect(
          () => createCardTemplateFragment(
            cardIndex: 17,
            noteId: 0x123456789,
            viewId: 29,
            cardIndexKey: 'card-index',
            noteIdKey: 'note-id',
            viewIdKey: 'view-id',
            callbacks: CardTemplateFragmentArgumentCallbacks<Object, Object>(
              createFragment: () => invoke('fragment', Object.new),
              createBundle: () => invoke('bundle', Object.new),
              putInt: (bundle, key, value) {
                invoke<void>(
                  key == 'card-index' ? 'cardIndex' : 'viewId',
                  () {},
                );
              },
              putLong: (bundle, key, value) {
                invoke<void>('noteId', () {});
              },
              assignArguments: (fragment, bundle) {
                invoke<void>('arguments', () {});
              },
            ),
          ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.stage} should propagate',
        );
        expect(reached, testCase.reached, reason: testCase.stage);
      }
    });
  });
}
