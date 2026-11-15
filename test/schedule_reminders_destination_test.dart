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
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ScheduleRemindersDestination.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduleRemindersDestination.toIntent', () {
    test('forwards exact context and fresh deck-specific scopes unchanged', () {
      for (final deckId in [0, -17, 9223372036854775807]) {
        final context = Object();
        final results = [Object(), Object()];
        final calls = <(Object, ReviewReminderScope)>[];
        var callIndex = 0;
        final destination = ScheduleRemindersDestination(deckId);

        final first = destination.toIntent<Object, Object>(context, (
          actualContext,
          scope,
        ) {
          calls.add((actualContext, scope));
          return results[callIndex++];
        });
        final second = destination.toIntent<Object, Object>(context, (
          actualContext,
          scope,
        ) {
          calls.add((actualContext, scope));
          return results[callIndex++];
        });

        expect(destination.deckId, deckId);
        expect(first, same(results[0]));
        expect(second, same(results[1]));
        expect(calls, hasLength(2));
        expect(identical(calls[0].$1, context), isTrue);
        expect(identical(calls[1].$1, context), isTrue);
        expect(calls[0].$2, DeckSpecificReminderScope(deckId));
        expect(calls[1].$2, DeckSpecificReminderScope(deckId));
        expect(identical(calls[0].$2, calls[1].$2), isFalse);
      }
    });

    test('host callback failure propagates unchanged without retry', () {
      final failure = StateError('getIntent failed');
      var calls = 0;
      final destination = ScheduleRemindersDestination(-3);

      expect(
        () => destination.toIntent<Object, Object>(Object(), (_, _) {
          calls++;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });
  });
}
