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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: SingleAxisDetector.kt and BindingMap.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

const _codec = ReviewerBindingCodec();

ReviewerBindingValue _axisBinding(
  int axisValue,
  String threshold, {
  String side = '2',
}) =>
    _codec.decode('1/r◯$axisValue $threshold$side').single;

ReviewerBindingMap _map(
  Iterable<ReviewerBindingValue> bindings, {
  Iterable<ViewerCommand>? actions,
}) =>
    ReviewerBindingMap(
      bindingsByCommand: {ViewerCommand.SHOW_ANSWER: bindings},
      actions: actions,
    );

void main() {
  group('ReviewerAxisButtonDispatcher', () {
    test('fires inclusively at a positive Float32 threshold', () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(0, '0.1')]),
      );
      var callbackCount = 0;
      var requestedAxis = -1;

      final processed = dispatcher.onGenericMotionEvent(
        valueForAxis: (axisValue) {
          requestedAxis = axisValue;
          // Host value is rounded to the MotionEvent Float32 representation.
          return 0.1;
        },
        processor: (_) {
          callbackCount++;
          return false;
        },
      );

      expect(processed, isTrue);
      expect(callbackCount, 1);
      expect(requestedAxis, 0);
    });

    test('fires inclusively at a negative threshold', () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(1, '-0.25')]),
      );
      var callbackCount = 0;

      final processed = dispatcher.onGenericMotionEvent(
        valueForAxis: (_) => -0.25,
        processor: (_) {
          callbackCount++;
          return false;
        },
      );

      expect(processed, isTrue);
      expect(callbackCount, 1);
    });

    test('a zero threshold never fires', () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([
          _axisBinding(0, '0.0'),
          _axisBinding(0, '-0.0'),
        ]),
      );
      var callbackCount = 0;

      for (final value in [0.0, 1.0, -1.0]) {
        expect(
          dispatcher.onGenericMotionEvent(
            valueForAxis: (_) => value,
            processor: (_) {
              callbackCount++;
              return true;
            },
          ),
          isFalse,
        );
      }

      expect(callbackCount, 0);
    });

    test('fires once while qualifying and rearms after a nonqualifying value',
        () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(0, '1.0')]),
      );
      final processed = <bool>[];

      for (final value in [1.0, 1.5, 0.99, 1.0]) {
        processed.add(
          dispatcher.onGenericMotionEvent(
            valueForAxis: (_) => value,
            processor: (_) => false,
          ),
        );
      }

      expect(processed, [true, false, false, true]);
    });

    test('keeps debounce state independent for duplicate axis registrations',
        () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([
          _axisBinding(0, '0.5'),
          _axisBinding(0, '1.0'),
        ]),
      );
      final emittedThresholds = <double>[];
      final processed = <bool>[];

      for (final value in [0.75, 1.25, 0.75, 1.25]) {
        processed.add(
          dispatcher.onGenericMotionEvent(
            valueForAxis: (_) => value,
            processor: (registration) {
              emittedThresholds.add(
                (registration.binding.binding as ReviewerAxisButtonBinding)
                    .threshold,
              );
              return false;
            },
          ),
        );
      }

      expect(processed, [true, true, false, true]);
      expect(emittedThresholds, [0.5, 1.0, 1.0]);
    });

    test(
        'dispatches every triggered detector in order despite callback results',
        () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: ReviewerBindingMap(
          actions: [
            ViewerCommand.ANSWER_GOOD,
            ViewerCommand.SHOW_ANSWER,
            ViewerCommand.ANSWER_EASY,
          ],
          bindingsByCommand: {
            ViewerCommand.SHOW_ANSWER: [_axisBinding(0, '0.5', side: '1')],
            ViewerCommand.ANSWER_GOOD: [_axisBinding(1, '0.5', side: '0')],
            ViewerCommand.ANSWER_EASY: [_axisBinding(2, '0.5')],
          },
        ),
      );
      final requestedAxes = <int>[];
      final commands = <ViewerCommand>[];
      final sides = <ReviewerCardSide>[];

      final processed = dispatcher.onGenericMotionEvent(
        valueForAxis: (axisValue) {
          requestedAxes.add(axisValue);
          return 1.0;
        },
        processor: (registration) {
          commands.add(registration.command);
          sides.add(registration.binding.side);
          return registration.command != ViewerCommand.SHOW_ANSWER;
        },
      );

      expect(processed, isTrue);
      expect(requestedAxes, [1, 0, 2]);
      expect(
        commands,
        [
          ViewerCommand.ANSWER_GOOD,
          ViewerCommand.SHOW_ANSWER,
          ViewerCommand.ANSWER_EASY,
        ],
      );
      expect(
        sides,
        [
          ReviewerCardSide.question,
          ReviewerCardSide.answer,
          ReviewerCardSide.both
        ],
      );
    });

    test('reports a triggered binding even when no processor is supplied', () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(0, '0.5')]),
      );

      expect(
        dispatcher.onGenericMotionEvent(valueForAxis: (_) => 0.5),
        isTrue,
      );
    });

    test('null event preserves state and empty maps do not request axis values',
        () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(0, '0.5')]),
      );
      var requests = 0;
      double valueForAxis(int _) {
        requests++;
        return 0.75;
      }

      expect(
        dispatcher.onGenericMotionEvent(valueForAxis: valueForAxis),
        isTrue,
      );
      expect(
        dispatcher.onGenericMotionEvent(valueForAxis: null),
        isFalse,
      );
      // A null event does not provide a below-threshold sample to rearm.
      expect(
        dispatcher.onGenericMotionEvent(valueForAxis: valueForAxis),
        isFalse,
      );
      expect(requests, 2);

      var emptyMapRequests = 0;
      final emptyDispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map(const []),
      );
      expect(
        emptyDispatcher.onGenericMotionEvent(valueForAxis: (_) {
          emptyMapRequests++;
          return 1.0;
        }),
        isFalse,
      );
      expect(emptyMapRequests, 0);
    });

    test(
        'NaN samples rearm by ordinary comparisons and NaN thresholds do not fire',
        () {
      final dispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(0, '0.5')]),
      );
      final processed = <bool>[];

      for (final value in [0.75, double.nan, 0.75]) {
        processed.add(
          dispatcher.onGenericMotionEvent(valueForAxis: (_) => value),
        );
      }

      final nanThresholdDispatcher = ReviewerAxisButtonDispatcher(
        bindingMap: _map([_axisBinding(0, 'NaN')]),
      );
      final nanThresholdProcessed =
          nanThresholdDispatcher.onGenericMotionEvent(valueForAxis: (_) => 1.0);

      expect(processed, [true, false, true]);
      expect(nanThresholdProcessed, isFalse);
    });
  });
}
