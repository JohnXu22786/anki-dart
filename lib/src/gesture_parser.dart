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
 * Behavioral adaptation of GestureParser.kt and Gesture.kt from AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';
import 'dart:typed_data';

import 'unicode_15_case_data.dart';

/// Reviewer gestures in the order declared by AnkiDroid's `Gesture` enum.
enum Gesture {
  swipeUp,
  swipeDown,
  swipeLeft,
  swipeRight,
  doubleTap,
  tapTopLeft,
  tapTop,
  tapTopRight,
  tapLeft,
  tapCenter,
  tapRight,
  tapBottomLeft,
  tapBottom,
  tapBottomRight,
  twoFingerTap,
  threeFingerTap,
  fourFingerTap,
  shake,
}

/// The tap target layout from AnkiDroid's `TapGestureMode` enum.
enum TapGestureMode { fourPoint, ninePoint }

/// Settings supplied by the host instead of Android preferences and APIs.
///
/// [doubleTapTimeout] is the host's `ViewConfiguration` timeout, converted to
/// a Dart duration. Sensitivity and timeout are deliberately required so this
/// model does not choose platform or preference defaults.
class GestureParserConfig {
  GestureParserConfig({
    required this.isDoubleTapEnabled,
    required this.gestureMode,
    required double swipeSensitivity,
    required this.doubleTapTimeout,
  }) : swipeSensitivity = _float32(swipeSensitivity);

  final bool isDoubleTapEnabled;
  final TapGestureMode gestureMode;
  final double swipeSensitivity;
  final Duration doubleTapTimeout;
}

/// Decoded gesture data passed by the platform bridge.
///
/// Query values are already percent-decoded, as they would be after Android's
/// `Uri.getQueryParameter()` call. Missing or malformed values remain null.
class GestureInput {
  const GestureInput({required this.host, required this.queryParameters});

  final String? host;
  final Map<String, String?> queryParameters;
}

/// The WebView values used by the parser, supplied by its platform adapter.
class GestureViewportState {
  GestureViewportState({
    required double scale,
    required this.scrollX,
    required this.scrollY,
    required this.width,
    required this.height,
  }) : scale = _float32(scale);

  final double scale;
  final int scrollX;
  final int scrollY;
  final int width;
  final int height;

  double getAdjustedTapPosition(int tapPosition, int scrolledDistance) {
    final scaledTap = _float32(_float32(tapPosition.toDouble()) * scale);
    return _float32(scaledTap - _float32(scrolledDistance.toDouble()));
  }

  int getGridRow(GestureData data) => _getGridIndex(data.y, scrollY, height);

  int getGridColumn(GestureData data) => _getGridIndex(data.x, scrollX, width);

  int _getGridIndex(int tapPosition, int scrolledDistance, int dimensionSize) {
    if (dimensionSize == 0) return 0;
    final adjustedTap = getAdjustedTapPosition(tapPosition, scrolledDistance);
    // Kotlin divides these dimensions as integers before doing Float division.
    final cellSize = dimensionSize ~/ 3;
    final index = _floatToKotlinInt(
      _float32(adjustedTap / _float32(cellSize.toDouble())),
    );
    return index.clamp(0, 2).toInt();
  }
}

/// A cancellable delay used for the parser's deferred single-tap callback.
abstract interface class GestureDelayScheduler {
  GestureDelayHandle schedule(Duration duration);
}

/// A scheduled delay that can be cancelled before its callback is dispatched.
abstract interface class GestureDelayHandle {
  Future<void> get completion;

  bool get isCancelled;

  void cancel();
}

/// Converts gesture input into taps, swipes, or multi-finger tap gestures.
///
/// The platform adapter supplies decoded input, current viewport values, and
/// source-equivalent settings. It remains responsible for WebView integration,
/// preferences, and the double-tap timeout. Malformed ordinary gesture data is
/// ignored without invoking [block], matching `GestureData.fromUri()`.
class GestureParser {
  GestureParser({
    required GestureParserConfig config,
    GestureDelayScheduler? scheduler,
  })  : _config = config,
        _scheduler = scheduler ?? const _TimerGestureDelayScheduler(),
        _swipeThresholdBase = _float32(100 / config.swipeSensitivity);

  static const String paramX = 'x';
  static const String paramY = 'y';
  static const String paramDeltaX = 'deltaX';
  static const String paramDeltaY = 'deltaY';
  static const String paramTime = 'time';
  static const String paramScrollDirection = 'scrollDirection';
  static const String paramTouchCount = 'touchCount';
  static const String multiFingerHost = 'multiFingerTap';

  final GestureParserConfig _config;
  final GestureDelayScheduler _scheduler;
  final double _swipeThresholdBase;
  BigInt _lastTapTime = BigInt.zero;
  _GestureSingleTapJob? _singleTapJob;

  void parse(
    GestureInput input,
    GestureViewportState viewport,
    void Function(Gesture?) block,
  ) {
    if (input.host == multiFingerHost) {
      block(_getMultiTouchGesture(input));
      return;
    }

    final data = _gestureDataFromInput(input);
    if (data == null) return;

    final swipeThreshold = _float32(_swipeThresholdBase / viewport.scale);
    final absDeltaX = _float32(_kotlinAbsInt(data.deltaX).toDouble());
    final absDeltaY = _float32(_kotlinAbsInt(data.deltaY).toDouble());
    if (absDeltaX > swipeThreshold || absDeltaY > swipeThreshold) {
      block(_determineSwipeGesture(data));
      return;
    }

    _handleTap(data, viewport, block);
  }

  GestureData? _gestureDataFromInput(GestureInput input) {
    final values = input.queryParameters;
    final x = _parseInt32(values[paramX]);
    final y = _parseInt32(values[paramY]);
    final deltaX = _parseInt32(values[paramDeltaX]);
    final deltaY = _parseInt32(values[paramDeltaY]);
    final time = _parseInt64(values[paramTime]);
    if (x == null ||
        y == null ||
        deltaX == null ||
        deltaY == null ||
        time == null) {
      return null;
    }
    return GestureData(
      x: x,
      y: y,
      deltaX: deltaX,
      deltaY: deltaY,
      time: time,
      scrollDirection: values[paramScrollDirection],
    );
  }

  Gesture? _getMultiTouchGesture(GestureInput input) {
    return switch (_parseInt32(input.queryParameters[paramTouchCount])) {
      2 => Gesture.twoFingerTap,
      3 => Gesture.threeFingerTap,
      4 => Gesture.fourFingerTap,
      _ => null,
    };
  }

  Gesture? _determineSwipeGesture(GestureData data) {
    if (_kotlinAbsInt(data.deltaX) > _kotlinAbsInt(data.deltaY)) {
      if (data.scrollDirection?.contains('h') ?? false) return null;
      return data.deltaX > 0 ? Gesture.swipeRight : Gesture.swipeLeft;
    }
    if (data.scrollDirection?.contains('v') ?? false) return null;
    return data.deltaY > 0 ? Gesture.swipeDown : Gesture.swipeUp;
  }

  void _handleTap(
    GestureData data,
    GestureViewportState viewport,
    void Function(Gesture?) block,
  ) {
    final elapsed = _subtractInt64(data.time, _lastTapTime);
    final isPotentialDoubleTap =
        elapsed < BigInt.from(_config.doubleTapTimeout.inMilliseconds);
    if (_config.isDoubleTapEnabled) {
      _lastTapTime = data.time;
      if (isPotentialDoubleTap) {
        _singleTapJob?.cancel();
        _singleTapJob = null;
        _lastTapTime = BigInt.zero;
        block(Gesture.doubleTap);
      } else {
        final job = _GestureSingleTapJob();
        // As in the source, a later single tap overwrites this field without
        // cancelling an earlier same-side timer.
        _singleTapJob = job;
        job.delay = _scheduler.schedule(_config.doubleTapTimeout);
        unawaited(_completeSingleTap(job, data, viewport, block));
      }
    } else if (!isPotentialDoubleTap) {
      // Ignored taps do not extend the timeout for the next single tap.
      _lastTapTime = data.time;
      block(_getTap(data, viewport));
    }
  }

  Future<void> _completeSingleTap(
    _GestureSingleTapJob job,
    GestureData data,
    GestureViewportState viewport,
    void Function(Gesture?) block,
  ) async {
    final delay = job.delay!;
    await delay.completion;
    if (job.isCancelled || delay.isCancelled) return;
    block(_getTap(data, viewport));
  }

  Gesture _getTap(GestureData data, GestureViewportState viewport) {
    return switch (_config.gestureMode) {
      TapGestureMode.fourPoint => _getFourPointsTap(data, viewport),
      TapGestureMode.ninePoint => _getNinePointsTap(data, viewport),
    };
  }

  Gesture _getFourPointsTap(GestureData data, GestureViewportState state) {
    final normalizedX = _float32(
      state.getAdjustedTapPosition(data.x, state.scrollX) /
          _float32(state.width.toDouble()),
    );
    final normalizedY = _float32(
      state.getAdjustedTapPosition(data.y, state.scrollY) /
          _float32(state.height.toDouble()),
    );
    final isRightOfMainDiagonal = normalizedX > normalizedY;
    final isBelowAntiDiagonal = _float32(normalizedX + normalizedY) > 1;

    if (isRightOfMainDiagonal && isBelowAntiDiagonal) {
      return Gesture.tapRight;
    }
    if (isRightOfMainDiagonal && !isBelowAntiDiagonal) {
      return Gesture.tapTop;
    }
    if (!isRightOfMainDiagonal && isBelowAntiDiagonal) {
      return Gesture.tapBottom;
    }
    return Gesture.tapLeft;
  }

  Gesture _getNinePointsTap(GestureData data, GestureViewportState state) {
    const grid = [
      [Gesture.tapTopLeft, Gesture.tapTop, Gesture.tapTopRight],
      [Gesture.tapLeft, Gesture.tapCenter, Gesture.tapRight],
      [Gesture.tapBottomLeft, Gesture.tapBottom, Gesture.tapBottomRight],
    ];
    return grid[state.getGridRow(data)][state.getGridColumn(data)];
  }
}

/// The parsed primitive data passed into the tap/swipe decision logic.
class GestureData {
  const GestureData({
    required this.x,
    required this.y,
    required this.deltaX,
    required this.deltaY,
    required this.time,
    required this.scrollDirection,
  });

  final int x;
  final int y;
  final int deltaX;
  final int deltaY;
  final BigInt time;
  final String? scrollDirection;
}

class _GestureSingleTapJob {
  bool isCancelled = false;
  GestureDelayHandle? delay;

  void cancel() {
    isCancelled = true;
    delay?.cancel();
  }
}

class _TimerGestureDelayScheduler implements GestureDelayScheduler {
  const _TimerGestureDelayScheduler();

  @override
  GestureDelayHandle schedule(Duration duration) =>
      _TimerGestureDelay(duration);
}

class _TimerGestureDelay implements GestureDelayHandle {
  _TimerGestureDelay(Duration duration) {
    _timer = Timer(duration, _complete);
  }

  final Completer<void> _completer = Completer<void>();
  late final Timer _timer;
  @override
  bool isCancelled = false;

  @override
  Future<void> get completion => _completer.future;

  @override
  void cancel() {
    isCancelled = true;
    _timer.cancel();
    _complete();
  }

  void _complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

double _float32(double value) => Float32List.fromList([value])[0];

int? _parseInt32(String? value) {
  final parsed = _parseKotlinDecimal(
    value,
    positiveLimit: BigInt.from(0x7fffffff),
    negativeLimit: BigInt.from(0x80000000),
  );
  return parsed?.toInt();
}

BigInt? _parseInt64(String? value) {
  return _parseKotlinDecimal(
    value,
    positiveLimit: (BigInt.one << 63) - BigInt.one,
    negativeLimit: BigInt.one << 63,
  );
}

/// Parses a signed 32-bit decimal value with Kotlin `toIntOrNull()` semantics.
int? parseKotlinInt32(String? value) {
  final parsed = _parseKotlinDecimal(
    value,
    positiveLimit: BigInt.from(0x7fffffff),
    negativeLimit: BigInt.from(0x80000000),
  );
  return parsed?.toInt();
}

/// Parses signed decimal input like Kotlin's `toIntOrNull()`/`toLongOrNull()`.
/// Those functions accept BMP Unicode decimal digits through `Char` parsing,
/// while their optional sign remains ASCII `+` or `-`.
BigInt? _parseKotlinDecimal(
  String? value, {
  required BigInt positiveLimit,
  required BigInt negativeLimit,
}) {
  if (value == null || value.isEmpty) return null;

  final codeUnits = value.codeUnits;
  var index = 0;
  var isNegative = false;
  if (codeUnits.first == 0x2b || codeUnits.first == 0x2d) {
    isNegative = codeUnits.first == 0x2d;
    index++;
  }
  if (index == codeUnits.length) return null;

  final limit = isNegative ? negativeLimit : positiveLimit;
  var magnitude = BigInt.zero;
  for (; index < codeUnits.length; index++) {
    final digit = _unicode15DecimalDigitValue(codeUnits[index]);
    if (digit == null) return null;
    magnitude = magnitude * BigInt.from(10) + BigInt.from(digit);
    if (magnitude > limit) return null;
  }
  return isNegative ? -magnitude : magnitude;
}

int? _unicode15DecimalDigitValue(int codeUnit) {
  for (final start in unicode15BmpDecimalDigitBlockStarts) {
    if (codeUnit < start) break;
    if (codeUnit < start + 10) return codeUnit - start;
  }
  return null;
}

int _kotlinAbsInt(int value) => value == -0x80000000 ? value : value.abs();

int _floatToKotlinInt(double value) {
  if (value.isNaN) return 0;
  if (value >= 0x7fffffff) return 0x7fffffff;
  if (value <= -0x80000000) return -0x80000000;
  return value.toInt();
}

BigInt _subtractInt64(BigInt left, BigInt right) {
  final modulus = BigInt.one << 64;
  final signBit = BigInt.one << 63;
  final unsigned = (left - right) & (modulus - BigInt.one);
  return unsigned >= signBit ? unsigned - modulus : unsigned;
}
