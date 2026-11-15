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
 * Source-derived from BottomSheetDialogFragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('bottomSheetDialogFragmentBehavior', () {
    test(
      'resolves dialog and exact view before returning the same behavior',
      () {
        final events = <String>[];
        final fragment = Object();
        final dialog = Object();
        final view = Object();
        final resourceId = Object();
        final behavior = Object();
        var dialogCalls = 0;
        var viewLookupCalls = 0;
        var behaviorCalls = 0;

        final actualBehavior =
            bottomSheetDialogFragmentBehavior<
              Object,
              Object,
              Object,
              Object,
              Object
            >(
              fragment: fragment,
              designBottomSheetResourceId: resourceId,
              requireDialog: (actualFragment) {
                events.add('requireDialog');
                dialogCalls++;
                expect(identical(actualFragment, fragment), isTrue);
                return dialog;
              },
              findViewById: (actualDialog, actualId) {
                events.add('findViewById');
                viewLookupCalls++;
                expect(identical(actualDialog, dialog), isTrue);
                expect(identical(actualId, resourceId), isTrue);
                return view;
              },
              bottomSheetBehaviorFrom: (actualView) {
                events.add('behaviorFrom');
                behaviorCalls++;
                expect(identical(actualView, view), isTrue);
                return behavior;
              },
            );

        expect(events, ['requireDialog', 'findViewById', 'behaviorFrom']);
        expect(dialogCalls, 1);
        expect(viewLookupCalls, 1);
        expect(behaviorCalls, 1);
        expect(identical(actualBehavior, behavior), isTrue);
      },
    );

    test('missing view preserves the null assertion failure', () {
      var behaviorCalls = 0;

      expect(
        () =>
            bottomSheetDialogFragmentBehavior<
              Object,
              Object,
              Object,
              Object,
              Object
            >(
              fragment: Object(),
              designBottomSheetResourceId: Object(),
              requireDialog: (_) => Object(),
              findViewById: (_, _) => null,
              bottomSheetBehaviorFrom: (_) {
                behaviorCalls++;
                return Object();
              },
            ),
        throwsA(isA<TypeError>()),
      );
      expect(behaviorCalls, 0);
    });

    test('requireDialog failure stops view lookup and behavior lookup', () {
      final failure = StateError('dialog failed');
      var viewLookupCalls = 0;
      var behaviorCalls = 0;

      expect(
        () =>
            bottomSheetDialogFragmentBehavior<
              Object,
              Object,
              Object,
              Object,
              Object
            >(
              fragment: Object(),
              designBottomSheetResourceId: Object(),
              requireDialog: (_) => throw failure,
              findViewById: (_, _) {
                viewLookupCalls++;
                return Object();
              },
              bottomSheetBehaviorFrom: (_) {
                behaviorCalls++;
                return Object();
              },
            ),
        throwsA(same(failure)),
      );
      expect(viewLookupCalls, 0);
      expect(behaviorCalls, 0);
    });

    test('view lookup failure stops behavior lookup', () {
      final failure = StateError('view lookup failed');
      var behaviorCalls = 0;

      expect(
        () =>
            bottomSheetDialogFragmentBehavior<
              Object,
              Object,
              Object,
              Object,
              Object
            >(
              fragment: Object(),
              designBottomSheetResourceId: Object(),
              requireDialog: (_) => Object(),
              findViewById: (_, _) => throw failure,
              bottomSheetBehaviorFrom: (_) {
                behaviorCalls++;
                return Object();
              },
            ),
        throwsA(same(failure)),
      );
      expect(behaviorCalls, 0);
    });

    test('behavior lookup failure propagates unchanged', () {
      final failure = StateError('behavior lookup failed');

      expect(
        () =>
            bottomSheetDialogFragmentBehavior<
              Object,
              Object,
              Object,
              Object,
              Object
            >(
              fragment: Object(),
              designBottomSheetResourceId: Object(),
              requireDialog: (_) => Object(),
              findViewById: (_, _) => Object(),
              bottomSheetBehaviorFrom: (_) => throw failure,
            ),
        throwsA(same(failure)),
      );
    });
  });
}
