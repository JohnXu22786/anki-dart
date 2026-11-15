/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Deck.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('libAnkiDeckOrderToDisplayString', () {
    test('calls exactly the source-mapped translation for each order', () {
      final calls = <String>[];
      final values = <String, String>{
        for (final name in _translationNames)
          name: StringBuffer(name).toString(),
      };
      final translations = _translations(calls, values);
      final expected = <LibAnkiDeckOrder, String>{
        LibAnkiDeckOrder.oldestReviewedFirst: 'decksOldestSeenFirst',
        LibAnkiDeckOrder.random: 'decksRandom',
        LibAnkiDeckOrder.intervalsAscending: 'decksIncreasingIntervals',
        LibAnkiDeckOrder.intervalsDescending: 'decksDecreasingIntervals',
        LibAnkiDeckOrder.lapses: 'decksMostLapses',
        LibAnkiDeckOrder.added: 'decksOrderAdded',
        LibAnkiDeckOrder.due: 'decksOrderDue',
        LibAnkiDeckOrder.reverseAdded: 'decksLatestAddedFirst',
        LibAnkiDeckOrder.retrievabilityAscending:
            'deckConfigSortOrderRetrievabilityAscending',
        LibAnkiDeckOrder.retrievabilityDescending:
            'deckConfigSortOrderRetrievabilityDescending',
        LibAnkiDeckOrder.relativeOverdueness: 'decksRelativeOverdueness',
      };

      for (final entry in expected.entries) {
        calls.clear();

        final result = libAnkiDeckOrderToDisplayString(
          order: entry.key,
          translations: translations,
        );

        expect(calls, [entry.value]);
        expect(identical(result, values[entry.value]), isTrue);
        expect(result, entry.value);
      }
    });

    test('propagates a selected translation failure unchanged', () {
      final failure = StateError('translation unavailable');
      final calls = <String>[];
      final translations = _translations(
        calls,
        {},
        failOn: 'decksOrderDue',
        failure: failure,
      );

      expect(
        () => libAnkiDeckOrderToDisplayString(
          order: LibAnkiDeckOrder.due,
          translations: translations,
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['decksOrderDue']);
    });

    test('unknown order throws the source message without translating', () {
      final calls = <String>[];

      expect(
        () => libAnkiDeckOrderToDisplayString(
          order: LibAnkiDeckOrder.unrecognized,
          translations: _translations(calls, {}),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            "Can't display an unknown enum value.",
          ),
        ),
      );
      expect(calls, isEmpty);
    });
  });
}

const _translationNames = [
  'decksOldestSeenFirst',
  'decksRandom',
  'decksIncreasingIntervals',
  'decksDecreasingIntervals',
  'decksMostLapses',
  'decksOrderAdded',
  'decksOrderDue',
  'decksLatestAddedFirst',
  'deckConfigSortOrderRetrievabilityAscending',
  'deckConfigSortOrderRetrievabilityDescending',
  'decksRelativeOverdueness',
];

LibAnkiDeckOrderDisplayTranslations _translations(
  List<String> calls,
  Map<String, String> values, {
  String? failOn,
  Object? failure,
}) => LibAnkiDeckOrderDisplayTranslations(
  decksOldestSeenFirst: () =>
      _translate('decksOldestSeenFirst', calls, values, failOn, failure),
  decksRandom: () => _translate('decksRandom', calls, values, failOn, failure),
  decksIncreasingIntervals: () =>
      _translate('decksIncreasingIntervals', calls, values, failOn, failure),
  decksDecreasingIntervals: () =>
      _translate('decksDecreasingIntervals', calls, values, failOn, failure),
  decksMostLapses: () =>
      _translate('decksMostLapses', calls, values, failOn, failure),
  decksOrderAdded: () =>
      _translate('decksOrderAdded', calls, values, failOn, failure),
  decksOrderDue: () =>
      _translate('decksOrderDue', calls, values, failOn, failure),
  decksLatestAddedFirst: () =>
      _translate('decksLatestAddedFirst', calls, values, failOn, failure),
  deckConfigSortOrderRetrievabilityAscending: () => _translate(
    'deckConfigSortOrderRetrievabilityAscending',
    calls,
    values,
    failOn,
    failure,
  ),
  deckConfigSortOrderRetrievabilityDescending: () => _translate(
    'deckConfigSortOrderRetrievabilityDescending',
    calls,
    values,
    failOn,
    failure,
  ),
  decksRelativeOverdueness: () =>
      _translate('decksRelativeOverdueness', calls, values, failOn, failure),
);

String _translate(
  String name,
  List<String> calls,
  Map<String, String> values,
  String? failOn,
  Object? failure,
) {
  calls.add(name);
  if (name == failOn) throw failure!;
  return values[name] ?? name;
}
