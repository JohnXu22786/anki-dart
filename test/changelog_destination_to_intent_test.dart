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
 * Source-derived from ChangelogDestination.kt and InfoDestination.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ChangelogDestination.toIntent', () {
    test('exposes one singleton instance', () {
      expect(
        identical(ChangelogDestination.instance, ChangelogDestination.instance),
        isTrue,
      );
    });

    test(
      'delegates exact host tokens once and returns the callback Intent',
      () {
        final context = Object();
        final infoActivity = Object();
        final intent = Object();
        final contexts = <Object>[];
        final targets = <Object>[];

        final result = ChangelogDestination.instance
            .toIntent<Object, Object, Object>(
              context: context,
              infoActivity: infoActivity,
              callbacks:
                  ChangelogDestinationIntentCallbacks<Object, Object, Object>(
                    createIntent: (actualContext, actualTarget) {
                      contexts.add(actualContext);
                      targets.add(actualTarget);
                      return intent;
                    },
                  ),
            );

        expect(contexts, hasLength(1));
        expect(contexts.single, same(context));
        expect(targets, hasLength(1));
        expect(targets.single, same(infoActivity));
        expect(result, same(intent));
      },
    );

    test('propagates the host callback failure unchanged', () {
      final failure = StateError('Intent creation failed');
      var calls = 0;

      expect(
        () => ChangelogDestination.instance.toIntent<Object, Object, Object>(
          context: Object(),
          infoActivity: Object(),
          callbacks:
              ChangelogDestinationIntentCallbacks<Object, Object, Object>(
                createIntent: (_, _) {
                  calls++;
                  throw failure;
                },
              ),
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });
  });
}
