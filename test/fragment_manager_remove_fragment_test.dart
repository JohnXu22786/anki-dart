/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from FragmentManager.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('removeFragmentFromContainer', () {
    test('looks up once and removes the same fragment in source order', () {
      final fragment = Object();
      final commitResult = Object();
      final events = <String>[];
      final transaction = _Transaction(
        events: events,
        commitResult: commitResult,
      );
      final manager = _Manager(
        fragment: fragment,
        transaction: transaction,
        events: events,
      );

      removeFragmentFromContainer(manager, 42);

      expect(events, ['find:42', 'begin', 'remove', 'commit']);
      expect(identical(transaction.removedFragment, fragment), isTrue);
      expect(identical(transaction.commitResult, commitResult), isTrue);
    });

    test(
      'missing fragment throws the exact source error before transaction',
      () {
        final events = <String>[];
        final manager = _Manager(
          transaction: _Transaction(events: events),
          events: events,
        );

        expect(
          () => removeFragmentFromContainer(manager, 7),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'could not find fragment',
            ),
          ),
        );
        expect(events, ['find:7']);
      },
    );

    test('each callback failure propagates unchanged and stops later work', () {
      final findFailure = StateError('find failed');
      final findEvents = <String>[];
      final findManager = _Manager(
        transaction: _Transaction(events: findEvents),
        events: findEvents,
        findFailure: findFailure,
      );
      expect(
        () => removeFragmentFromContainer(findManager, 1),
        throwsA(same(findFailure)),
      );
      expect(findEvents, ['find:1']);

      final beginFailure = StateError('begin failed');
      final beginEvents = <String>[];
      final beginManager = _Manager(
        fragment: Object(),
        transaction: _Transaction(events: beginEvents),
        events: beginEvents,
        beginFailure: beginFailure,
      );
      expect(
        () => removeFragmentFromContainer(beginManager, 2),
        throwsA(same(beginFailure)),
      );
      expect(beginEvents, ['find:2', 'begin']);

      final removeFailure = StateError('remove failed');
      final removeEvents = <String>[];
      final removeManager = _Manager(
        fragment: Object(),
        transaction: _Transaction(
          events: removeEvents,
          removeFailure: removeFailure,
        ),
        events: removeEvents,
      );
      expect(
        () => removeFragmentFromContainer(removeManager, 3),
        throwsA(same(removeFailure)),
      );
      expect(removeEvents, ['find:3', 'begin', 'remove']);

      final commitFailure = StateError('commit failed');
      final commitEvents = <String>[];
      final commitManager = _Manager(
        fragment: Object(),
        transaction: _Transaction(
          events: commitEvents,
          commitFailure: commitFailure,
        ),
        events: commitEvents,
      );
      expect(
        () => removeFragmentFromContainer(commitManager, 4),
        throwsA(same(commitFailure)),
      );
      expect(commitEvents, ['find:4', 'begin', 'remove', 'commit']);
    });

    test('exposes a void result corresponding to Kotlin Unit', () {
      final void Function(FragmentManagerAccess<Object>, int) remove =
          removeFragmentFromContainer<Object>;
      final events = <String>[];
      final manager = _Manager(
        fragment: Object(),
        transaction: _Transaction(events: events, commitResult: 99),
        events: events,
      );

      remove(manager, 9);

      expect(events, ['find:9', 'begin', 'remove', 'commit']);
    });
  });
}

final class _Manager implements FragmentManagerAccess<Object> {
  _Manager({
    this.fragment,
    required this.transaction,
    required this.events,
    this.findFailure,
    this.beginFailure,
  });

  final Object? fragment;
  final _Transaction transaction;
  final List<String> events;
  final Object? findFailure;
  final Object? beginFailure;

  @override
  Object? findFragmentById(int containerViewId) {
    events.add('find:$containerViewId');
    if (findFailure case final failure?) throw failure;
    return fragment;
  }

  @override
  FragmentTransactionAccess<Object> beginTransaction() {
    events.add('begin');
    if (beginFailure case final failure?) throw failure;
    return transaction;
  }
}

final class _Transaction implements FragmentTransactionAccess<Object> {
  _Transaction({
    required this.events,
    this.commitResult,
    this.removeFailure,
    this.commitFailure,
  });

  final List<String> events;
  final Object? commitResult;
  final Object? removeFailure;
  final Object? commitFailure;
  Object? removedFragment;

  @override
  FragmentTransactionAccess<Object> remove(Object fragment) {
    events.add('remove');
    if (removeFailure case final failure?) throw failure;
    removedFragment = fragment;
    return this;
  }

  @override
  Object? commit() {
    events.add('commit');
    if (commitFailure case final failure?) throw failure;
    return commitResult;
  }
}
