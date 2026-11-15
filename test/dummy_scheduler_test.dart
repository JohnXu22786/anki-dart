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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DummyScheduler', () {
    test('retains the exact collection reference in col', () {
      final collection = <String, Object>{'marker': Object()};
      final scheduler = DummyScheduler<Object, Object, Object>(collection);

      expect(identical(scheduler.col, collection), isTrue);
    });

    test('card is always null', () {
      final scheduler = DummyScheduler<Object, Object, Object>(Object());

      expect(scheduler.card, isNull);
    });

    test('answerCard always throws the source Exception and message', () {
      final scheduler = DummyScheduler<Object, Object, Object>(Object());
      final expectedType = Exception(
        'v1/v2 scheduler not supported',
      ).runtimeType;

      for (final (card, rating) in <(Object, Object)>[
        (Object(), Object()),
        ('opaque card', 17),
        (const <int>[1, 2], const <String>{'rating'}),
      ]) {
        expect(
          () => scheduler.answerCard(card, rating),
          throwsA(
            predicate(
              (error) =>
                  error.runtimeType == expectedType &&
                  error.toString() ==
                      'Exception: v1/v2 scheduler not supported',
            ),
          ),
        );
      }
    });
  });
}
