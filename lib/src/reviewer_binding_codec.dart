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
 * Behavioral reference: MappableBinding.kt, ReviewerBinding.kt, Binding.kt,
 * Axis.kt, BaseCompat.kt, and CardSide.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:math' as math;
import 'dart:typed_data';

import 'gesture_parser.dart';
import 'unicode_15_case_data.dart';

/// Card side suffixes serialized by AnkiDroid's `ReviewerBinding`.
enum ReviewerCardSide { question, answer, both }

/// The subset of serialized bindings exposed by this preference codec.
enum ReviewerBindingKind { gesture, nonGesture, unknown }

/// A decoded reviewer preference entry.
///
/// Gesture entries expose [gesture] for routing. Non-gesture entries retain
/// their serialized binding payload but are not interpreted as Android key,
/// display, or axis behavior. Unknown entries model `Binding.UnknownBinding`
/// and are omitted when written.
class ReviewerBindingValue {
  const ReviewerBindingValue._({
    required this.kind,
    required this.side,
    required String? serializedBinding,
    this.gesture,
  }) : _serializedBinding = serializedBinding;

  /// Constructs a serializable gesture binding.
  factory ReviewerBindingValue.forGesture(
    Gesture gesture, {
    ReviewerCardSide side = ReviewerCardSide.both,
  }) =>
      ReviewerBindingValue._(
        kind: ReviewerBindingKind.gesture,
        side: side,
        gesture: gesture,
        serializedBinding:
            '${ReviewerBindingCodec.gesturePrefix}${ReviewerBindingCodec._gestureName(gesture)}',
      );

  final ReviewerBindingKind kind;
  final ReviewerCardSide side;
  final Gesture? gesture;
  final String? _serializedBinding;

  bool get isValid => kind != ReviewerBindingKind.unknown;

  /// The ReviewerBinding list item, or null for an invalid/empty binding.
  String? toPreferenceString() {
    final serializedBinding = _serializedBinding;
    if (!isValid || serializedBinding == null || serializedBinding.isEmpty) {
      return null;
    }
    return '${ReviewerBindingCodec.reviewerPrefix}$serializedBinding${_sideSuffix(side)}';
  }
}

/// Encodes and decodes the `1/` list of serialized AnkiDroid reviewer bindings.
///
/// Preference lookup is deliberately supplied by the caller. Gesture bindings
/// are decoded exactly; known key, Unicode, and axis prefixes are recognized
/// enough to identify valid non-gesture entries, while Android key events,
/// display, and MotionEvent axis handling remain outside this model.
class ReviewerBindingCodec {
  const ReviewerBindingCodec();

  static const versionPrefix = '1/';
  static const separator = '|';
  static const reviewerPrefix = 'r';
  static const gesturePrefix = '\u235D';
  static const keyPrefix = '\u2328';
  static const unicodePrefix = '\u2705';
  static const axisPrefix = '◯';

  /// Decodes a versioned preference value. Empty, null, and unknown-version
  /// values produce an empty list, matching `getPreferenceSubstrings()`.
  List<ReviewerBindingValue> decode(String? preferenceValue) {
    if (preferenceValue == null || preferenceValue.isEmpty) {
      return const [];
    }
    if (!preferenceValue.startsWith(versionPrefix)) {
      return const [];
    }

    final entries =
        preferenceValue.substring(versionPrefix.length).split(separator);
    return List.unmodifiable([
      for (final entry in entries)
        if (entry.isNotEmpty) _decodeEntry(entry),
    ]);
  }

  /// Encodes the valid entries with the source version prefix and separator.
  /// If every entry is invalid, the source still writes `1/`.
  String encode(Iterable<ReviewerBindingValue> bindings) {
    final entries = <String>[];
    for (final binding in bindings) {
      final value = binding.toPreferenceString();
      if (value != null) entries.add(value);
    }
    return '$versionPrefix${entries.join(separator)}';
  }

  ReviewerBindingValue _decodeEntry(String entry) {
    // Kotlin String.length/subString and String.last() operate on UTF-16 code
    // units, so remove exactly one unit for the side suffix.
    final sideUnit = entry.codeUnitAt(entry.length - 1);
    final bindingWithOptionalReviewerPrefix =
        entry.substring(0, entry.length - 1);
    final binding = bindingWithOptionalReviewerPrefix.startsWith(reviewerPrefix)
        ? bindingWithOptionalReviewerPrefix.substring(reviewerPrefix.length)
        : bindingWithOptionalReviewerPrefix;
    final side = switch (sideUnit) {
      0x30 => ReviewerCardSide.question,
      0x31 => ReviewerCardSide.answer,
      _ => ReviewerCardSide.both,
    };

    if (binding.isEmpty) return _unknown(side);

    if (binding.startsWith(gesturePrefix)) {
      final gesture = _gestureFromName(binding.substring(gesturePrefix.length));
      if (gesture == null) return _unknown(side);
      return ReviewerBindingValue._(
        kind: ReviewerBindingKind.gesture,
        side: side,
        gesture: gesture,
        serializedBinding: '$gesturePrefix${_gestureName(gesture)}',
      );
    }

    final nonGestureBinding = _canonicalNonGestureBinding(binding);
    if (nonGestureBinding != null) {
      return ReviewerBindingValue._(
        kind: ReviewerBindingKind.nonGesture,
        side: side,
        serializedBinding: nonGestureBinding,
      );
    }

    return _unknown(side);
  }

  static ReviewerBindingValue _unknown(ReviewerCardSide side) =>
      ReviewerBindingValue._(
        kind: ReviewerBindingKind.unknown,
        side: side,
        serializedBinding: null,
      );

  static String? _canonicalNonGestureBinding(String binding) {
    if (binding.startsWith(keyPrefix)) {
      return _canonicalKeyBinding(binding);
    }
    if (binding.startsWith(unicodePrefix)) {
      return _canonicalUnicodeBinding(binding);
    }
    final axisBinding = _validAxisBinding(binding);
    if (axisBinding != null) return axisBinding;
    return null;
  }

  static String? _validAxisBinding(String binding) {
    if (!binding.startsWith(axisPrefix)) return null;
    final parts = binding.substring(axisPrefix.length).split(' ');
    if (parts.length < 2) return null;
    final axisValue = _parseKotlinInt32(parts[0]);
    if (axisValue == null || !_axisMotionEventValues.contains(axisValue)) {
      return null;
    }

    // AxisButtonBinding.from() reads only the first two tokens; its serializer
    // canonicalizes both the axis ID and Float value when writing the entry.
    final threshold = _parseJavaFloat(parts[1]);
    if (threshold == null) return null;
    return '$axisPrefix$axisValue ${_javaFloatToString(threshold)}';
  }

  static String? _canonicalKeyBinding(String binding) {
    final parts = _parseModifiers(binding.substring(keyPrefix.length));
    final keyCode = _parseKotlinInt32(parts.value);
    if (keyCode == null) return null;
    return '$keyPrefix${_modifierString(parts)}$keyCode';
  }

  static int? _parseKotlinInt32(String value) {
    if (value.isEmpty) return null;
    final codeUnits = value.codeUnits;
    var index = 0;
    var isNegative = false;
    if (codeUnits.first == 0x2b || codeUnits.first == 0x2d) {
      isNegative = codeUnits.first == 0x2d;
      index++;
    }
    if (index == codeUnits.length) return null;

    final limit = BigInt.from(isNegative ? 0x80000000 : 0x7fffffff);
    var magnitude = BigInt.zero;
    for (; index < codeUnits.length; index++) {
      final digit = _unicode15DecimalDigitValue(codeUnits[index]);
      if (digit == null) return null;
      magnitude = magnitude * BigInt.from(10) + BigInt.from(digit);
      if (magnitude > limit) return null;
    }
    return (isNegative ? -magnitude : magnitude).toInt();
  }

  static int? _unicode15DecimalDigitValue(int codeUnit) {
    for (final start in unicode15BmpDecimalDigitBlockStarts) {
      if (codeUnit < start) break;
      if (codeUnit < start + 10) return codeUnit - start;
    }
    return null;
  }

  static double? _parseJavaFloat(String value) {
    final text = _trimJavaFloatWhitespace(value);
    if (RegExp(r'^[+-]?(?:NaN|Infinity)$').hasMatch(text)) {
      return double.tryParse(text);
    }

    final withoutSuffix = text.replaceFirst(RegExp(r'[fFdD]$'), '');
    if (RegExp(
      r'^[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?)|(?:\.[0-9]+))'
      r'(?:[eE][+-]?[0-9]+)?$',
    ).hasMatch(withoutSuffix)) {
      return _parseJavaDecimalFloat(withoutSuffix);
    }

    if (!RegExp(
      r'^[+-]?0[xX](?:(?:[0-9a-fA-F]+(?:\.[0-9a-fA-F]*)?)|(?:\.[0-9a-fA-F]+))'
      r'[pP][+-]?[0-9]+$',
    ).hasMatch(withoutSuffix)) {
      return null;
    }
    return _parseHexFloat(withoutSuffix);
  }

  static String _trimJavaFloatWhitespace(String value) {
    var start = 0;
    var end = value.length;
    while (start < end && value.codeUnitAt(start) <= 0x20) {
      start++;
    }
    while (end > start && value.codeUnitAt(end - 1) <= 0x20) {
      end--;
    }
    return value.substring(start, end);
  }

  static double? _parseJavaDecimalFloat(String text) {
    var unsigned = text;
    var negative = false;
    if (unsigned.startsWith('+') || unsigned.startsWith('-')) {
      negative = unsigned.startsWith('-');
      unsigned = unsigned.substring(1);
    }

    final exponentIndex = unsigned.indexOf(RegExp('[eE]'));
    final mantissa =
        exponentIndex < 0 ? unsigned : unsigned.substring(0, exponentIndex);
    final decimalExponent = exponentIndex < 0
        ? BigInt.zero
        : BigInt.tryParse(unsigned.substring(exponentIndex + 1));
    if (decimalExponent == null) return null;

    final pointIndex = mantissa.indexOf('.');
    final fractionalDigits =
        pointIndex < 0 ? 0 : mantissa.length - pointIndex - 1;
    var digits = mantissa.replaceAll('.', '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return negative ? -0.0 : 0.0;
    final trailingZeros =
        digits.length - digits.replaceFirst(RegExp(r'0+$'), '').length;
    if (trailingZeros > 0) {
      digits = digits.substring(0, digits.length - trailingZeros);
    }

    final significand = BigInt.tryParse(digits);
    if (significand == null) return null;
    final powerOfTen = decimalExponent -
        BigInt.from(fractionalDigits) +
        BigInt.from(trailingZeros);
    final decimalOrder = powerOfTen + BigInt.from(digits.length - 1);
    if (decimalOrder > BigInt.from(50)) {
      return negative ? double.negativeInfinity : double.infinity;
    }
    if (decimalOrder < BigInt.from(-60)) return negative ? -0.0 : 0.0;

    final power = powerOfTen.toInt();
    final numerator =
        power >= 0 ? significand * BigInt.from(10).pow(power) : significand;
    final denominator = power >= 0 ? BigInt.one : BigInt.from(10).pow(-power);
    return _roundRationalToFloat32(numerator, denominator, negative);
  }

  static double _roundRationalToFloat32(
    BigInt numerator,
    BigInt denominator,
    bool negative,
  ) {
    if (numerator == BigInt.zero) return negative ? -0.0 : 0.0;

    var topExponent = numerator.bitLength - denominator.bitLength;
    if (topExponent >= 0) {
      if (numerator < (denominator << topExponent)) topExponent--;
    } else if ((numerator << -topExponent) < denominator) {
      topExponent--;
    }
    if (topExponent > 127) {
      return negative ? double.negativeInfinity : double.infinity;
    }
    if (topExponent < -150) return negative ? -0.0 : 0.0;

    late final double rounded;
    if (topExponent >= -126) {
      final significandShift = 23 - topExponent;
      final scaledNumerator =
          significandShift >= 0 ? numerator << significandShift : numerator;
      final scaledDenominator = significandShift >= 0
          ? denominator
          : denominator << -significandShift;
      var significand = _roundRatioToEven(scaledNumerator, scaledDenominator);
      if (significand.bitLength > 24) {
        significand >>= 1;
        topExponent++;
      }
      if (topExponent > 127) {
        return negative ? double.negativeInfinity : double.infinity;
      }
      rounded = significand.toDouble() * math.pow(2.0, topExponent - 23);
    } else {
      final subnormalSignificand = _roundRatioToEven(
        numerator << 149,
        denominator,
      );
      rounded = subnormalSignificand.toDouble() * math.pow(2.0, -149);
    }
    return negative ? -rounded : rounded;
  }

  static BigInt _roundRatioToEven(BigInt numerator, BigInt denominator) {
    var quotient = numerator ~/ denominator;
    final remainder = numerator - quotient * denominator;
    final twiceRemainder = remainder * BigInt.from(2);
    if (twiceRemainder > denominator ||
        (twiceRemainder == denominator && quotient.isOdd)) {
      quotient += BigInt.one;
    }
    return quotient;
  }

  static double? _parseHexFloat(String text) {
    var unsigned = text;
    var negative = false;
    if (unsigned.startsWith('+') || unsigned.startsWith('-')) {
      negative = unsigned.startsWith('-');
      unsigned = unsigned.substring(1);
    }
    final exponentIndex = unsigned.indexOf(RegExp('[pP]'));
    final significandText = unsigned.substring(2, exponentIndex);
    final exponent = BigInt.tryParse(unsigned.substring(exponentIndex + 1));
    if (exponent == null) return null;

    final pointIndex = significandText.indexOf('.');
    final fractionalDigits =
        pointIndex < 0 ? 0 : significandText.length - pointIndex - 1;
    final hexDigits = significandText.replaceAll('.', '');
    final significand = BigInt.tryParse(hexDigits, radix: 16);
    if (significand == null) return null;
    if (significand == BigInt.zero) return negative ? -0.0 : 0.0;

    // Java's Float.parseFloat rounds the parsed value directly to binary32.
    // Round the integer significand exactly so very large exponents, tiny
    // subnormals, and halfway cases do not pass through a binary64 double-round.
    final shift = exponent - BigInt.from(fractionalDigits * 4);
    final topExponent = shift + BigInt.from(significand.bitLength - 1);
    if (topExponent > BigInt.from(127)) {
      return negative ? double.negativeInfinity : double.infinity;
    }
    if (topExponent < BigInt.from(-150)) return negative ? -0.0 : 0.0;

    late final double rounded;
    if (topExponent >= BigInt.from(-126)) {
      final discardedBits = significand.bitLength - 24;
      var roundedSignificand = discardedBits > 0
          ? _roundRightToEven(significand, discardedBits)
          : significand << -discardedBits;
      var roundedShift = shift + BigInt.from(discardedBits);
      if (roundedSignificand.bitLength > 24) {
        roundedSignificand >>= 1;
        roundedShift += BigInt.one;
      }
      rounded =
          roundedSignificand.toDouble() * math.pow(2.0, roundedShift.toInt());
    } else {
      final subnormalShift = shift + BigInt.from(149);
      late final BigInt subnormalSignificand;
      if (subnormalShift >= BigInt.zero) {
        subnormalSignificand = significand << subnormalShift.toInt();
      } else {
        final discardedBits = -subnormalShift;
        subnormalSignificand =
            discardedBits > BigInt.from(significand.bitLength)
                ? BigInt.zero
                : _roundRightToEven(significand, discardedBits.toInt());
      }
      rounded = subnormalSignificand.toDouble() * math.pow(2.0, -149);
    }
    return negative ? -rounded : rounded;
  }

  static BigInt _roundRightToEven(BigInt value, int bitCount) {
    final truncated = value >> bitCount;
    final remainder = value - (truncated << bitCount);
    final halfway = BigInt.one << (bitCount - 1);
    if (remainder > halfway || (remainder == halfway && truncated.isOdd)) {
      return truncated + BigInt.one;
    }
    return truncated;
  }

  static double _float32(double value) => Float32List.fromList([value])[0];

  static String _javaFloatToString(double value) {
    final floatValue = _float32(value);
    if (floatValue.isNaN) return 'NaN';
    if (floatValue.isInfinite)
      return floatValue.isNegative ? '-Infinity' : 'Infinity';
    if (floatValue == 0) return floatValue.isNegative ? '-0.0' : '0.0';

    final bits = _float32Bits(floatValue);
    final absolute = floatValue.abs();
    var decimalExponent =
        int.parse(absolute.toStringAsExponential(1).split('e').last);
    while (absolute < math.pow(10.0, decimalExponent)) {
      decimalExponent--;
    }
    while (absolute >= math.pow(10.0, decimalExponent + 1)) {
      decimalExponent++;
    }
    // Java's Float.toString scientific form keeps at least one fractional
    // digit. Starting at two significant digits preserves values such as
    // Float.MIN_VALUE as `1.4E-45`, rather than collapsing them to `1.0E-45`.
    final firstPrecision = decimalExponent < -3 || decimalExponent >= 7 ? 2 : 1;
    var shortest = '';
    for (var precision = firstPrecision; precision <= 9; precision++) {
      final candidate = _roundedFloatCandidate(
        floatValue,
        bits,
        decimalExponent,
        precision,
      );
      final parsed = double.tryParse(candidate);
      if (parsed != null && _float32Bits(_float32(parsed)) == bits) {
        shortest = candidate;
        break;
      }
    }
    if (shortest.isEmpty) {
      shortest = _roundedFloatCandidate(floatValue, bits, decimalExponent, 9);
    }
    return _formatJavaFloatCandidate(shortest);
  }

  static String _roundedFloatCandidate(
    double value,
    int bits,
    int decimalExponent,
    int precision,
  ) {
    final exponentBits = (bits >> 23) & 0xff;
    final fraction = bits & 0x7fffff;
    final significand = exponentBits == 0 ? fraction : (0x800000 | fraction);
    final binaryExponent = exponentBits == 0 ? -149 : exponentBits - 127 - 23;

    var numerator = BigInt.from(significand);
    var denominator = BigInt.one;
    if (binaryExponent >= 0) {
      numerator <<= binaryExponent;
    } else {
      denominator <<= -binaryExponent;
    }
    final decimalScale = precision - 1 - decimalExponent;
    if (decimalScale >= 0) {
      numerator *= BigInt.from(10).pow(decimalScale);
    } else {
      denominator *= BigInt.from(10).pow(-decimalScale);
    }

    var rounded = numerator ~/ denominator;
    final remainder = numerator - rounded * denominator;
    final twiceRemainder = remainder * BigInt.from(2);
    if (twiceRemainder > denominator ||
        (twiceRemainder == denominator && rounded.isOdd)) {
      rounded += BigInt.one;
    }
    var exponent = decimalExponent;
    var digits = rounded.toString();
    if (digits.length > precision) {
      rounded ~/= BigInt.from(10);
      exponent++;
      digits = rounded.toString();
    }
    digits = digits.padLeft(precision, '0');

    final sign = value.isNegative ? '-' : '';
    final fractionDigits = digits.substring(1);
    final significandText =
        fractionDigits.isEmpty ? digits[0] : '${digits[0]}.$fractionDigits';
    return '$sign$significandText' 'e$exponent';
  }

  static int _float32Bits(double value) {
    final bytes = ByteData(4)..setFloat32(0, value, Endian.big);
    return bytes.getUint32(0, Endian.big);
  }

  static String _formatJavaFloatCandidate(String candidate) {
    var text = candidate.toLowerCase();
    var negative = false;
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    }
    final exponentIndex = text.indexOf('e');
    final exponentPart =
        exponentIndex < 0 ? '0' : text.substring(exponentIndex + 1);
    final decimalExponent = int.parse(exponentPart);
    final significand =
        exponentIndex < 0 ? text : text.substring(0, exponentIndex);
    final pointIndex = significand.indexOf('.');
    final digitsBeforePoint = pointIndex < 0 ? significand.length : pointIndex;
    final digits = significand.replaceAll('.', '');
    final firstNonZero = digits.indexOf(RegExp('[1-9]'));
    final adjustedExponent =
        decimalExponent + digitsBeforePoint - firstNonZero - 1;
    var significantDigits = digits.substring(firstNonZero);
    significantDigits = significantDigits.replaceFirst(RegExp(r'0+$'), '');
    if (significantDigits.isEmpty) significantDigits = '0';

    late final String formatted;
    if (adjustedExponent < -3 || adjustedExponent >= 7) {
      final tail =
          significantDigits.length == 1 ? '0' : significantDigits.substring(1);
      formatted = '${significantDigits[0]}.$tail'
          'E$adjustedExponent';
    } else if (adjustedExponent >= 0) {
      final integerDigits = adjustedExponent + 1;
      if (significantDigits.length <= integerDigits) {
        formatted = '${significantDigits.padRight(integerDigits, '0')}.0';
      } else {
        formatted = '${significantDigits.substring(0, integerDigits)}.'
            '${significantDigits.substring(integerDigits)}';
      }
    } else {
      final leadingZeros = List.filled(-adjustedExponent - 1, '0').join();
      formatted = '0.$leadingZeros$significantDigits';
    }
    return negative ? '-$formatted' : formatted;
  }

  static String? _canonicalUnicodeBinding(String binding) {
    final parts = _parseModifiers(binding.substring(unicodePrefix.length));
    if (parts.value.isEmpty) return null;
    // Binding.fromString() takes char[0], i.e. one UTF-16 code unit.
    final codeUnit = parts.value.codeUnitAt(0);
    return '$unicodePrefix${_modifierString(parts)}${String.fromCharCode(codeUnit)}';
  }

  static ({bool ctrl, bool alt, bool shift, String value}) _parseModifiers(
    String input,
  ) {
    final plusIndex = input.lastIndexOf('+');
    final modifierText = plusIndex < 0 ? '' : input.substring(0, plusIndex + 1);
    return (
      ctrl: modifierText.contains('Ctrl'),
      alt: modifierText.contains('Alt'),
      shift: modifierText.contains('Shift'),
      value: plusIndex < 0 ? input : input.substring(plusIndex + 1),
    );
  }

  static String _modifierString(
          ({bool ctrl, bool alt, bool shift, String value}) parts) =>
      '${parts.ctrl ? 'Ctrl+' : ''}'
      '${parts.alt ? 'Alt+' : ''}'
      '${parts.shift ? 'Shift+' : ''}';

  static const _axisMotionEventValues = <int>{
    0, // X
    1, // Y
    2, // PRESSURE
    8, // ORIENTATION
    10, // H_SCROLL
    11, // Z
    12, // RX
    13, // RY
    14, // RZ
    15, // HAT_X
    16, // HAT_Y
    17, // L_TRIGGER
    18, // R_TRIGGER
    20, // RUDDER
    22, // GAS
    23, // BRAKE
    24, // DISTANCE
    27, // RELATIVE_X
    28, // RELATIVE_Y
    32, // GENERIC_1
    33, // GENERIC_2
    34, // GENERIC_3
    35, // GENERIC_4
    36, // GENERIC_5
    37, // GENERIC_6
    38, // GENERIC_7
    39, // GENERIC_8
    40, // GENERIC_9
    41, // GENERIC_10
    42, // GENERIC_11
    43, // GENERIC_12
    44, // GENERIC_13
    45, // GENERIC_14
    46, // GENERIC_15
    47, // GENERIC_16
    48, // AXIS_GESTURE_X_OFFSET
    49, // AXIS_GESTURE_Y_OFFSET
    50, // AXIS_GESTURE_SCROLL_X_DISTANCE
    51, // AXIS_GESTURE_SCROLL_Y_DISTANCE
    52, // AXIS_GESTURE_PINCH_SCALE_FACTOR
  };

  static Gesture? _gestureFromName(String name) => _gesturesByName[name];

  static String _gestureName(Gesture gesture) => _gestureNames[gesture]!;

  static const _gestureNames = <Gesture, String>{
    Gesture.swipeUp: 'SWIPE_UP',
    Gesture.swipeDown: 'SWIPE_DOWN',
    Gesture.swipeLeft: 'SWIPE_LEFT',
    Gesture.swipeRight: 'SWIPE_RIGHT',
    Gesture.doubleTap: 'DOUBLE_TAP',
    Gesture.tapTopLeft: 'TAP_TOP_LEFT',
    Gesture.tapTop: 'TAP_TOP',
    Gesture.tapTopRight: 'TAP_TOP_RIGHT',
    Gesture.tapLeft: 'TAP_LEFT',
    Gesture.tapCenter: 'TAP_CENTER',
    Gesture.tapRight: 'TAP_RIGHT',
    Gesture.tapBottomLeft: 'TAP_BOTTOM_LEFT',
    Gesture.tapBottom: 'TAP_BOTTOM',
    Gesture.tapBottomRight: 'TAP_BOTTOM_RIGHT',
    Gesture.twoFingerTap: 'TWO_FINGER_TAP',
    Gesture.threeFingerTap: 'THREE_FINGER_TAP',
    Gesture.fourFingerTap: 'FOUR_FINGER_TAP',
    Gesture.shake: 'SHAKE',
  };

  static const _gesturesByName = <String, Gesture>{
    'SWIPE_UP': Gesture.swipeUp,
    'SWIPE_DOWN': Gesture.swipeDown,
    'SWIPE_LEFT': Gesture.swipeLeft,
    'SWIPE_RIGHT': Gesture.swipeRight,
    'DOUBLE_TAP': Gesture.doubleTap,
    'TAP_TOP_LEFT': Gesture.tapTopLeft,
    'TAP_TOP': Gesture.tapTop,
    'TAP_TOP_RIGHT': Gesture.tapTopRight,
    'TAP_LEFT': Gesture.tapLeft,
    'TAP_CENTER': Gesture.tapCenter,
    'TAP_RIGHT': Gesture.tapRight,
    'TAP_BOTTOM_LEFT': Gesture.tapBottomLeft,
    'TAP_BOTTOM': Gesture.tapBottom,
    'TAP_BOTTOM_RIGHT': Gesture.tapBottomRight,
    'TWO_FINGER_TAP': Gesture.twoFingerTap,
    'THREE_FINGER_TAP': Gesture.threeFingerTap,
    'FOUR_FINGER_TAP': Gesture.fourFingerTap,
    'SHAKE': Gesture.shake,
  };
}

String _sideSuffix(ReviewerCardSide side) => switch (side) {
      ReviewerCardSide.question => '0',
      ReviewerCardSide.answer => '1',
      ReviewerCardSide.both => '2',
    };
