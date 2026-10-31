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
  group('cardTemplateFragmentScheduleInitialFocus', () {
    test('checks page once and does nothing for a non-current page', () {
      final calls = <String>[];

      cardTemplateFragmentScheduleInitialFocus(
        isCurrentPage: () {
          calls.add('current page');
          return false;
        },
        editText: () {
          calls.add('edit text');
          return Object();
        },
        post: (_, _) => calls.add('post'),
        requestFocus: (_) => calls.add('focus'),
      );

      expect(calls, ['current page']);
    });

    test('posts to the first edit field and resolves it again when run', () {
      final calls = <String>[];
      final firstEditText = Object();
      final currentEditText = Object();
      void Function()? postedAction;
      var editTextReads = 0;
      var pageChecks = 0;

      cardTemplateFragmentScheduleInitialFocus(
        isCurrentPage: () {
          calls.add('current page');
          pageChecks++;
          return true;
        },
        editText: () {
          calls.add('edit text');
          return switch (editTextReads++) {
            0 => firstEditText,
            _ => currentEditText,
          };
        },
        post: (view, action) {
          calls.add('post');
          expect(view, same(firstEditText));
          postedAction = action;
        },
        requestFocus: (view) {
          calls.add('focus');
          expect(view, same(currentEditText));
        },
      );

      expect(calls, ['current page', 'edit text', 'post']);
      expect(pageChecks, 1);
      expect(editTextReads, 1);
      final action = postedAction!;
      action();
      expect(calls, [
        'current page',
        'edit text',
        'post',
        'edit text',
        'focus',
      ]);
      expect(pageChecks, 1);
      expect(editTextReads, 2);
    });

    test('posting failure propagates and prevents focus-time lookups', () {
      final failure = StateError('post failed');
      final calls = <String>[];

      expect(
        () => cardTemplateFragmentScheduleInitialFocus(
          isCurrentPage: () => true,
          editText: () {
            calls.add('edit text');
            return Object();
          },
          post: (_, _) {
            calls.add('post');
            throw failure;
          },
          requestFocus: (_) => calls.add('focus'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['edit text', 'post']);
    });

    test('focus-time lookup and focus failures propagate unchanged', () {
      for (final failingCall in ['edit text', 'focus']) {
        final failure = StateError('$failingCall failed');
        final calls = <String>[];
        void Function()? postedAction;

        cardTemplateFragmentScheduleInitialFocus(
          isCurrentPage: () => true,
          editText: () {
            calls.add('edit text');
            if (calls.where((call) => call == 'edit text').length == 2 &&
                failingCall == 'edit text') {
              throw failure;
            }
            return Object();
          },
          post: (_, action) {
            calls.add('post');
            postedAction = action;
          },
          requestFocus: (_) {
            calls.add('focus');
            if (failingCall == 'focus') throw failure;
          },
        );

        expect(() => postedAction!(), throwsA(same(failure)));
        expect(
          calls,
          failingCall == 'edit text'
              ? ['edit text', 'post', 'edit text']
              : ['edit text', 'post', 'edit text', 'focus'],
        );
      }
    });
  });
}
