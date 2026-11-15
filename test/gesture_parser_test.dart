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
 * Behavioral reference: GestureParserTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GestureParser', () {
    test('maps two, three, and four finger taps and ignores other counts', () {
      final parser = _parser();
      final actual = <Gesture?>[];

      for (final (touchCount, expected) in <(String?, Gesture?)>[
        ('2', Gesture.twoFingerTap),
        ('3', Gesture.threeFingerTap),
        ('4', Gesture.fourFingerTap),
        ('5', null),
        ('0', null),
        (null, null),
        ('bad', null),
      ]) {
        final input = touchCount == '2'
            ? const GestureInput(
                host: GestureParser.multiFingerHost,
                queryParameters: {GestureParser.paramTouchCount: '2'},
              )
            : _input(
                host: GestureParser.multiFingerHost,
                touchCount: touchCount,
              );
        parser.parse(
          input,
          _viewport(),
          actual.add,
        );
        expect(actual.removeLast(), expected);
      }
    });

    test('malformed normal input is ignored but invalid multitap emits null',
        () {
      final parser = _parser();
      final actual = <Gesture?>[];

      parser.parse(_input(y: null), _viewport(), actual.add);
      parser.parse(
          _input(time: '9223372036854775808'), _viewport(), actual.add);
      parser.parse(_input(x: '2147483648'), _viewport(), actual.add);
      expect(actual, isEmpty);

      parser.parse(
        _input(host: GestureParser.multiFingerHost, touchCount: '5'),
        _viewport(),
        actual.add,
      );
      expect(actual, [null]);
    });

    test('parses decimal digits like Kotlin UTF-16 integer parsing', () {
      final parser = _parser();
      final multiFinger = <Gesture?>[];
      parser.parse(
        const GestureInput(
          host: GestureParser.multiFingerHost,
          queryParameters: {GestureParser.paramTouchCount: '٢'},
        ),
        _viewport(),
        multiFinger.add,
      );
      expect(multiFinger, [Gesture.twoFingerTap]);

      final normalInput = GestureInput(
        host: 'tapOrSwipe',
        queryParameters: {
          GestureParser.paramX: '٤٥٠',
          GestureParser.paramY: '١٢٥٠',
          GestureParser.paramDeltaX: '٠',
          GestureParser.paramDeltaY: '٠',
          GestureParser.paramTime: '١٠٠٠٠',
        },
      );
      final actual = <Gesture?>[];
      parser.parse(normalInput, _viewport(), actual.add);
      expect(actual, [Gesture.tapBottom]);

      final supplementaryDigits = <Gesture?>[];
      parser.parse(
        const GestureInput(
          host: GestureParser.multiFingerHost,
          queryParameters: {GestureParser.paramTouchCount: '𝟚'},
        ),
        _viewport(),
        supplementaryDigits.add,
      );
      expect(supplementaryDigits, [null]);

      final outOfRangeValues = <Gesture?>[];
      parser.parse(
        _input(x: '٢١٤٧٤٨٣٦٤٨'),
        _viewport(),
        outOfRangeValues.add,
      );
      parser.parse(
        _input(time: '٩٢٢٣٣٧٢٠٣٦٨٥٤٧٧٥٨٠٨'),
        _viewport(),
        outOfRangeValues.add,
      );
      expect(outOfRangeValues, isEmpty);
    });

    test(
        'maps the nine grid targets and assigns exact cell boundaries down/right',
        () {
      final cases = <(int, int, Gesture)>[
        (150, 250, Gesture.tapTopLeft),
        (450, 250, Gesture.tapTop),
        (750, 250, Gesture.tapTopRight),
        (150, 750, Gesture.tapLeft),
        (450, 750, Gesture.tapCenter),
        (750, 750, Gesture.tapRight),
        (150, 1250, Gesture.tapBottomLeft),
        (450, 1250, Gesture.tapBottom),
        (750, 1250, Gesture.tapBottomRight),
        (300, 500, Gesture.tapCenter),
        (600, 1000, Gesture.tapBottomRight),
      ];

      for (final (x, y, expected) in cases) {
        expect(
          _parse(_parser(), _input(x: '$x', y: '$y')),
          [expected],
          reason: 'tap at ($x, $y)',
        );
      }
    });

    test('four point regions preserve diagonal equality behavior', () {
      final cases = <(int, int, Gesture)>[
        (750, 100, Gesture.tapTop),
        (900, 750, Gesture.tapRight),
        (250, 900, Gesture.tapBottom),
        (100, 250, Gesture.tapLeft),
        (500, 500, Gesture.tapLeft),
        (510, 490, Gesture.tapTop),
        (500, 501, Gesture.tapBottom),
      ];

      for (final (x, y, expected) in cases) {
        expect(
          _parse(
            _parser(mode: TapGestureMode.fourPoint),
            _input(x: '$x', y: '$y'),
            viewport: _viewport(width: 1000, height: 1000),
          ),
          [expected],
          reason: 'tap at ($x, $y)',
        );
      }
    });

    test('scale and scroll adjust the tap position before grid mapping', () {
      expect(
        _parse(
          _parser(),
          _input(x: '550', y: '950'),
          viewport: _viewport(scrollX: 100, scrollY: 200),
        ),
        [Gesture.tapCenter],
      );
      expect(
        _parse(
          _parser(),
          _input(x: '225', y: '375'),
          viewport: _viewport(scale: 2, width: 900, height: 1500),
        ),
        [Gesture.tapCenter],
      );
      expect(
        _parse(
          _parser(),
          _input(x: '850', y: '1450'),
          viewport: _viewport(width: 0, height: 0),
        ),
        [Gesture.tapTopLeft],
      );
    });

    test(
        'swipe uses strict scaled threshold, dominant direction, and scroll guard',
        () {
      expect(_parse(_parser(), _input(deltaX: '100')), [Gesture.tapTopLeft]);
      expect(_parse(_parser(), _input(deltaX: '101')), [Gesture.swipeRight]);
      expect(
        _parse(_parser(), _input(deltaX: '-2147483648')),
        [Gesture.tapTopLeft],
      );
      expect(
        _parse(_parser(), _input(deltaX: '150', deltaY: '150')),
        [Gesture.swipeDown],
      );
      expect(
        _parse(
          _parser(),
          _input(deltaX: '16777217', deltaY: '16777216'),
        ),
        [Gesture.swipeRight],
      );
      expect(
        _parse(_parser(), _input(deltaX: '100'), viewport: _viewport(scale: 2)),
        [Gesture.swipeRight],
      );
      expect(
        _parse(
          _parser(sensitivity: 0.2),
          _input(deltaY: '-150', x: '450', y: '0'),
        ),
        [Gesture.tapTop],
      );
      expect(
        _parse(_parser(sensitivity: 1.8), _input(deltaY: '-90')),
        [Gesture.swipeUp],
      );
      expect(
        _parse(_parser(), _input(deltaX: '150', scrollDirection: 'hv')),
        [null],
      );
      expect(
        _parse(_parser(), _input(deltaX: '150', scrollDirection: 'v')),
        [Gesture.swipeRight],
      );
    });

    test('disabled double taps are ignored without extending the timeout', () {
      final parser = _parser();
      final actual = <Gesture?>[];
      for (final (elapsed, accepted) in <(int, bool)>[
        (0, true),
        (100, false),
        (150, false),
        (199, false),
        (200, true),
        (201, false),
        (399, false),
        (400, true),
      ]) {
        final before = actual.length;
        parser.parse(
          _input(x: '450', y: '1250', time: '${10000 + elapsed}'),
          _viewport(),
          actual.add,
        );
        expect(actual.length - before, accepted ? 1 : 0);
        if (accepted) expect(actual.last, Gesture.tapBottom);
      }

      final zeroTimeParser = _parser();
      expect(_parse(zeroTimeParser, _input(x: '450', y: '1250', time: '0')),
          isEmpty);

      final wrappingParser = _parser();
      final wrappingActual = <Gesture?>[];
      wrappingParser.parse(
        _input(x: '450', y: '1250', time: '9223372036854775797'),
        _viewport(),
        wrappingActual.add,
      );
      wrappingParser.parse(
        _input(x: '450', y: '1250', time: '-9223372036854775798'),
        _viewport(),
        wrappingActual.add,
      );
      expect(wrappingActual, [Gesture.tapBottom]);
    });

    test('enabled double tap cancels the pending single tap and dispatches now',
        () async {
      final earlyScheduler = _FakeGestureScheduler();
      final earlyParser = _parser(
        doubleTapEnabled: true,
        scheduler: earlyScheduler,
      );
      final earlyActual = <Gesture?>[];
      earlyParser.parse(
        _input(x: '450', y: '1250', time: '100'),
        _viewport(),
        earlyActual.add,
      );
      expect(earlyActual, [Gesture.doubleTap]);
      expect(earlyScheduler.handles, isEmpty);

      final scheduler = _FakeGestureScheduler();
      final parser = _parser(doubleTapEnabled: true, scheduler: scheduler);
      final actual = <Gesture?>[];

      parser.parse(
          _input(x: '450', y: '1250', time: '10000'), _viewport(), actual.add);
      expect(actual, isEmpty);
      expect(
          scheduler.handles.single.duration, const Duration(milliseconds: 200));

      parser.parse(
          _input(x: '450', y: '1250', time: '10199'), _viewport(), actual.add);
      expect(actual, [Gesture.doubleTap]);
      expect(scheduler.handles.single.isCancelled, isTrue);

      await scheduler.complete(0);
      expect(actual, [Gesture.doubleTap]);
    });

    test('canceling the scheduled single tap suppresses its callback',
        () async {
      final scheduler = _FakeGestureScheduler();
      final parser = _parser(doubleTapEnabled: true, scheduler: scheduler);
      final actual = <Gesture?>[];

      parser.parse(
        _input(x: '450', y: '1250', time: '10000'),
        _viewport(),
        actual.add,
      );
      scheduler.handles.single.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(actual, isEmpty);
    });

    test(
        'enabled single tap waits for timeout and equality starts another timer',
        () async {
      final scheduler = _FakeGestureScheduler();
      final parser = _parser(doubleTapEnabled: true, scheduler: scheduler);
      final actual = <Gesture?>[];

      parser.parse(
          _input(x: '450', y: '1250', time: '10000'), _viewport(), actual.add);
      expect(actual, isEmpty);
      await scheduler.complete(0);
      expect(actual, [Gesture.tapBottom]);

      parser.parse(
          _input(x: '450', y: '1250', time: '20000'), _viewport(), actual.add);
      parser.parse(
          _input(x: '450', y: '1250', time: '20200'), _viewport(), actual.add);
      expect(scheduler.handles.length, 3);
      expect(scheduler.handles[1].isCancelled, isFalse);
      await scheduler.complete(1);
      await scheduler.complete(2);
      expect(actual, [Gesture.tapBottom, Gesture.tapBottom, Gesture.tapBottom]);

      final overwrittenScheduler = _FakeGestureScheduler();
      final overwrittenParser = _parser(
        doubleTapEnabled: true,
        scheduler: overwrittenScheduler,
      );
      final overwrittenActual = <Gesture?>[];

      overwrittenParser.parse(
        _input(x: '450', y: '1250', time: '10000'),
        _viewport(),
        overwrittenActual.add,
      );
      overwrittenParser.parse(
        _input(x: '450', y: '1250', time: '10200'),
        _viewport(),
        overwrittenActual.add,
      );
      overwrittenParser.parse(
        _input(x: '450', y: '1250', time: '10250'),
        _viewport(),
        overwrittenActual.add,
      );

      expect(overwrittenActual, [Gesture.doubleTap]);
      expect(overwrittenScheduler.handles[0].isCancelled, isFalse);
      expect(overwrittenScheduler.handles[1].isCancelled, isTrue);
      await overwrittenScheduler.complete(0);
      await overwrittenScheduler.complete(1);
      expect(overwrittenActual, [Gesture.doubleTap, Gesture.tapBottom]);
    });
  });
}

GestureParser _parser({
  TapGestureMode mode = TapGestureMode.ninePoint,
  double sensitivity = 1,
  bool doubleTapEnabled = false,
  Duration doubleTapTimeout = const Duration(milliseconds: 200),
  GestureDelayScheduler? scheduler,
}) =>
    GestureParser(
      config: GestureParserConfig(
        isDoubleTapEnabled: doubleTapEnabled,
        gestureMode: mode,
        swipeSensitivity: sensitivity,
        doubleTapTimeout: doubleTapTimeout,
      ),
      scheduler: scheduler,
    );

GestureInput _input({
  String? host = 'tapOrSwipe',
  String? x = '100',
  String? y = '100',
  String? deltaX = '0',
  String? deltaY = '0',
  String? time = '10000',
  String? touchCount = '1',
  String? scrollDirection,
}) =>
    GestureInput(
      host: host,
      queryParameters: {
        GestureParser.paramX: x,
        GestureParser.paramY: y,
        GestureParser.paramDeltaX: deltaX,
        GestureParser.paramDeltaY: deltaY,
        GestureParser.paramTime: time,
        GestureParser.paramTouchCount: touchCount,
        GestureParser.paramScrollDirection: scrollDirection,
      },
    );

GestureViewportState _viewport({
  double scale = 1,
  int scrollX = 0,
  int scrollY = 0,
  int width = 900,
  int height = 1500,
}) =>
    GestureViewportState(
      scale: scale,
      scrollX: scrollX,
      scrollY: scrollY,
      width: width,
      height: height,
    );

List<Gesture?> _parse(
  GestureParser parser,
  GestureInput input, {
  GestureViewportState? viewport,
}) {
  final actual = <Gesture?>[];
  parser.parse(input, viewport ?? _viewport(), actual.add);
  return actual;
}

class _FakeGestureScheduler implements GestureDelayScheduler {
  final List<_FakeGestureDelay> handles = [];

  @override
  GestureDelayHandle schedule(Duration duration) {
    final handle = _FakeGestureDelay(duration);
    handles.add(handle);
    return handle;
  }

  Future<void> complete(int index) async {
    handles[index].complete();
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeGestureDelay implements GestureDelayHandle {
  _FakeGestureDelay(this.duration);

  final Duration duration;
  final Completer<void> _completer = Completer<void>();
  bool isCancelled = false;

  @override
  Future<void> get completion => _completer.future;

  @override
  void cancel() {
    isCancelled = true;
    complete();
  }

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
