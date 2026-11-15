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
 * Source-derived from DatabaseCheck.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectDatabaseCheckProgress', () {
    test('does not project an absent event', () {
      expect(projectDatabaseCheckProgress(null), isNull);
    });

    test('keeps stage and clears amount for a present zero total', () {
      final projection = projectDatabaseCheckProgress(
        DatabaseCheckProgressEvent(
          stage: '  checking…\n',
          stageCurrent: 8,
          stageTotal: 0,
        ),
      );

      expect(projection, isNotNull);
      expect(projection!.stage, '  checking…\n');
      expect(projection.amount, isNull);
    });

    test('preserves the exact stage and raw positive-total values', () {
      final projection = projectDatabaseCheckProgress(
        const DatabaseCheckProgressEvent(
          stage: 'repairing',
          stageCurrent: -4,
          stageTotal: 2,
        ),
      );

      expect(projection!.stage, 'repairing');
      expect(projection.amount, (-4, 2));
    });

    test('uses no amount for negative totals without validating current', () {
      final projection = projectDatabaseCheckProgress(
        const DatabaseCheckProgressEvent(
          stage: 'scanning',
          stageCurrent: -11,
          stageTotal: -5,
        ),
      );

      expect(projection!.stage, 'scanning');
      expect(projection.amount, isNull);
    });
  });

  group('databaseCheckResultMessage', () {
    test('joins every problem in order without requesting localization', () {
      var localizationCalls = 0;

      final message = databaseCheckResultMessage(
        problems: ['first', '', '  third  '],
        databaseCheckRebuilt: () {
          localizationCalls++;
          return 'localized';
        },
      );

      expect(message, 'first\n\n  third  ');
      expect(localizationCalls, 0);
    });

    test('returns empty-problem localization unchanged after one call', () {
      var localizationCalls = 0;

      final message = databaseCheckResultMessage(
        problems: const [],
        databaseCheckRebuilt: () {
          localizationCalls++;
          return '  rebuilt\n';
        },
      );

      expect(message, '  rebuilt\n');
      expect(localizationCalls, 1);
    });

    test('propagates localization failure unchanged', () {
      final failure = StateError('localized text unavailable');

      expect(
        () => databaseCheckResultMessage(
          problems: const [],
          databaseCheckRebuilt: () => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
