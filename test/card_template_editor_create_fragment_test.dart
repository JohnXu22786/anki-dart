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

final class _Fragment {}

void main() {
  group('cardTemplateEditorCreateFragment', () {
    test(
      'looks up once and forwards the mapped view ID and original values',
      () {
        final events = <String>[];
        final noteId = Object();
        final fragment = _Fragment();
        final mappedIds = {-2: 71};
        final callbacks =
            CardTemplateEditorCreateFragmentCallbacks<Object, int, _Fragment>(
              readTabToViewId: (position) {
                events.add('lookup:$position');
                return mappedIds[position];
              },
              createFragment: (position, note, viewId) {
                events.add('create:$position:$viewId');
                expect(identical(note, noteId), isTrue);
                return fragment;
              },
            );

        final result = cardTemplateEditorCreateFragment(
          position: -2,
          noteId: noteId,
          frontEditViewId: 11,
          callbacks: callbacks,
        );

        expect(identical(result, fragment), isTrue);
        expect(events, ['lookup:-2', 'create:-2:71']);
      },
    );

    test('missing and null mappings use the supplied front ID', () {
      for (final mapping in <Map<int, int?>>[
        {},
        {4: null},
      ]) {
        final events = <String>[];
        final callbacks =
            CardTemplateEditorCreateFragmentCallbacks<Object, int, _Fragment>(
              readTabToViewId: (position) {
                events.add('lookup:$position');
                return mapping[position];
              },
              createFragment: (position, _, viewId) {
                events.add('create:$position:$viewId');
                return _Fragment();
              },
            );

        cardTemplateEditorCreateFragment(
          position: 4,
          noteId: Object(),
          frontEditViewId: 11,
          callbacks: callbacks,
        );

        expect(events, ['lookup:4', 'create:4:11']);
      }
    });

    test('callback failures propagate in source order and stop later work', () {
      for (final failAt in ['lookup', 'create']) {
        final failure = StateError(failAt);
        final events = <String>[];
        final callbacks =
            CardTemplateEditorCreateFragmentCallbacks<Object, int, _Fragment>(
              readTabToViewId: (position) {
                events.add('lookup:$position');
                if (failAt == 'lookup') throw failure;
                return null;
              },
              createFragment: (position, _, viewId) {
                events.add('create:$position:$viewId');
                if (failAt == 'create') throw failure;
                return _Fragment();
              },
            );

        expect(
          () => cardTemplateEditorCreateFragment(
            position: 6,
            noteId: Object(),
            frontEditViewId: 11,
            callbacks: callbacks,
          ),
          throwsA(same(failure)),
        );
        expect(
          events,
          failAt == 'lookup' ? ['lookup:6'] : ['lookup:6', 'create:6:11'],
        );
      }
    });
  });
}
