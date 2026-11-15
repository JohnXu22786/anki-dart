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
 * Source-derived from DeckPickerViewModel.kt:502–505 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('disableDeckAndChildrenShortcuts', () {
    test('emits empty once when the host lookup has no due tree result', () {
      var lookups = 0;
      var conversions = 0;
      final emissions = <List<String>>[];

      final result = disableDeckAndChildrenShortcuts<_Node>(
        deckId: 9007199254740993,
        findDeckAndChildren: (deckId) {
          lookups++;
          expect(deckId, 9007199254740993);
          return null;
        },
        didOf: (_) {
          conversions++;
          return 1;
        },
        emit: emissions.add,
      );

      expect(lookups, 1);
      expect(conversions, 0);
      expect(emissions, hasLength(1));
      expect(emissions.single, isEmpty);
      expect(identical(result, emissions.single), isTrue);
    });

    test(
      'forwards the ID once and preserves subtree order, duplicates, and strings',
      () {
        const deckId = 9007199254740993;
        var lookups = 0;
        final emissions = <List<String>>[];
        final nodes = [_Node(9007199254740993), _Node(7), _Node(7), _Node(-2)];

        final result = disableDeckAndChildrenShortcuts<_Node>(
          deckId: deckId,
          findDeckAndChildren: (id) {
            lookups++;
            expect(id, deckId);
            return nodes;
          },
          didOf: (node) => node.did,
          emit: emissions.add,
        );

        expect(lookups, 1);
        expect(result, ['9007199254740993', '7', '7', '-2']);
        expect(emissions, hasLength(1));
        expect(emissions.single, ['9007199254740993', '7', '7', '-2']);
        expect(identical(result, emissions.single), isTrue);
      },
    );

    test('finishes ordered ID conversion before emitting the same list', () {
      final conversions = <String>[];
      final nodes = [
        _Node(_TracingId('first', conversions)),
        _Node(_TracingId('second', conversions)),
      ];
      final emissions = <List<String>>[];

      final result = disableDeckAndChildrenShortcuts<_Node>(
        deckId: 4,
        findDeckAndChildren: (_) => nodes,
        didOf: (node) => node.did,
        emit: (ids) {
          expect(conversions, ['first', 'second']);
          expect(ids, ['first', 'second']);
          emissions.add(ids);
        },
      );

      expect(conversions, ['first', 'second']);
      expect(emissions, hasLength(1));
      expect(identical(result, emissions.single), isTrue);
    });

    test('propagates lookup or ID conversion failures without emitting', () {
      final emissions = <List<String>>[];
      final lookupFailure = StateError('lookup failed');
      expect(
        () => disableDeckAndChildrenShortcuts<_Node>(
          deckId: 4,
          findDeckAndChildren: (_) => throw lookupFailure,
          didOf: (node) => node.did,
          emit: emissions.add,
        ),
        throwsA(same(lookupFailure)),
      );
      expect(emissions, isEmpty);

      final conversionFailure = StateError('conversion failed');
      expect(
        () => disableDeckAndChildrenShortcuts<_Node>(
          deckId: 4,
          findDeckAndChildren: (_) => [_Node(_FailingId(conversionFailure))],
          didOf: (node) => node.did,
          emit: emissions.add,
        ),
        throwsA(same(conversionFailure)),
      );
      expect(emissions, isEmpty);
    });
  });
}

final class _Node {
  const _Node(this.did);

  final Object? did;
}

final class _TracingId {
  const _TracingId(this.label, this.conversions);

  final String label;
  final List<String> conversions;

  @override
  String toString() {
    conversions.add(label);
    return label;
  }
}

final class _FailingId {
  const _FailingId(this.failure);

  final Object failure;

  @override
  String toString() => throw failure;
}
