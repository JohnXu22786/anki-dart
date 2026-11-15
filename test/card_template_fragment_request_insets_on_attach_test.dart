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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
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
  group('cardTemplateFragmentRequestInsetsOnAttach', () {
    test('resolves the root once and defers the exact attached view', () {
      final root = Object();
      final attachedView = Object();
      final calls = <String>[];
      var rootReads = 0;
      void Function(Object view)? onAttach;

      cardTemplateFragmentRequestInsetsOnAttach<Object>(
        root: () {
          rootReads++;
          calls.add('root');
          return root;
        },
        doOnAttach: (view, callback) {
          expect(view, same(root));
          calls.add('register');
          onAttach = callback;
        },
        requestApplyInsets: (view) {
          expect(view, same(attachedView));
          calls.add('request');
        },
      );

      expect(rootReads, 1);
      expect(calls, ['root', 'register']);
      onAttach!(attachedView);
      expect(calls, ['root', 'register', 'request']);
    });

    test('propagates requestApplyInsets failures unchanged', () {
      final failure = StateError('requestApplyInsets failed');
      void Function(Object view)? onAttach;
      cardTemplateFragmentRequestInsetsOnAttach<Object>(
        root: Object.new,
        doOnAttach: (view, callback) => onAttach = callback,
        requestApplyInsets: (view) => throw failure,
      );

      expect(() => onAttach!(Object()), throwsA(same(failure)));
    });
  });
}
