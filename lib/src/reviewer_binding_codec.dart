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

import 'gesture_parser.dart';
import 'java_float_format.dart';
import 'unicode_15_case_data.dart';

/// Card side suffixes serialized by AnkiDroid's `ReviewerBinding`.
enum ReviewerCardSide {
  question,
  answer,
  both;

  /// Mirrors `CardSide.fromAnswer()`.
  static ReviewerCardSide fromAnswer(bool displayingAnswer) =>
      displayingAnswer ? ReviewerCardSide.answer : ReviewerCardSide.question;
}

/// The subset of serialized bindings exposed by this preference codec.
enum ReviewerBindingKind { gesture, nonGesture, unknown }

/// A decoded source `Binding` that can be serialized without Android runtime.
sealed class ReviewerBindingContent {
  const ReviewerBindingContent();

  bool get isValid => true;
  bool get isKey => false;
  String toBindingString();

  @override
  String toString() => toBindingString();
}

/// A source `Binding.GestureInput`.
final class ReviewerGestureBinding extends ReviewerBindingContent {
  const ReviewerGestureBinding(this.gesture);

  final Gesture gesture;

  @override
  String toBindingString() =>
      '${ReviewerBindingCodec.gesturePrefix}${ReviewerBindingCodec._gestureName(gesture)}';

  @override
  bool operator ==(Object other) =>
      other is ReviewerGestureBinding && other.gesture == gesture;

  @override
  int get hashCode => gesture.hashCode;
}

/// The Ctrl/Alt/Shift matching contract used by source `Binding.ModifierKeys`.
class ReviewerModifierKeys {
  const ReviewerModifierKeys({
    this.shift = false,
    this.ctrl = false,
    this.alt = false,
  });

  final bool shift;
  final bool ctrl;
  final bool alt;

  bool shiftMatches(bool shiftPressed) => shift == shiftPressed;

  @override
  String toString() =>
      '${ctrl ? 'Ctrl+' : ''}${alt ? 'Alt+' : ''}${shift ? 'Shift+' : ''}';

  /// Source-compatible parser: only the text before the last `+` is treated
  /// as modifiers, and each modifier name is recognized by case-sensitive
  /// substring matching.
  static ({ReviewerModifierKeys modifierKeys, String value}) parse(
    String input,
  ) {
    final plusIndex = input.lastIndexOf('+');
    if (plusIndex < 0) {
      return (modifierKeys: none, value: input);
    }
    return (
      modifierKeys: fromString(input.substring(0, plusIndex + 1)),
      value: input.substring(plusIndex + 1),
    );
  }

  static ReviewerModifierKeys fromString(String value) => ReviewerModifierKeys(
        shift: value.contains('Shift'),
        ctrl: value.contains('Ctrl'),
        alt: value.contains('Alt'),
      );

  static const ReviewerModifierKeys none = ReviewerModifierKeys();
  static const ReviewerModifierKeys control = ReviewerModifierKeys(ctrl: true);
  static const ReviewerModifierKeys shiftOnly =
      ReviewerModifierKeys(shift: true);
  static const ReviewerModifierKeys altOnly = ReviewerModifierKeys(alt: true);

  bool _semiStructurallyEquals(ReviewerModifierKeys other) {
    if (alt != other.alt || ctrl != other.ctrl) return false;
    return shiftMatches(true) == other.shiftMatches(true) ||
        shiftMatches(false) == other.shiftMatches(false);
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewerModifierKeys && _semiStructurallyEquals(other);

  @override
  int get hashCode => _javaObjectsHash([
        _javaBooleanHash(ctrl),
        _javaBooleanHash(alt),
        _javaBooleanHash(shiftMatches(true)),
      ]);
}

/// Default keyboard bindings may ignore shift when the source device is
/// unknown. This matching wildcard is distinct from a parsed no-modifier value.
final class ReviewerAppDefinedModifierKeys extends ReviewerModifierKeys {
  const ReviewerAppDefinedModifierKeys._() : super();

  static const ReviewerAppDefinedModifierKeys _instance =
      ReviewerAppDefinedModifierKeys._();

  static ReviewerAppDefinedModifierKeys allowShift() => _instance;

  @override
  bool shiftMatches(bool shiftPressed) => true;
}

/// A source `Binding.KeyCode`. Its equality includes modifiers while its
/// source hash intentionally uses only the key code.
final class ReviewerKeyCodeBinding extends ReviewerBindingContent {
  factory ReviewerKeyCodeBinding({
    required int keyCode,
    ReviewerModifierKeys modifierKeys = ReviewerModifierKeys.none,
  }) {
    if (keyCode < -0x80000000 || keyCode > 0x7FFFFFFF) {
      throw RangeError.range(keyCode, -0x80000000, 0x7FFFFFFF, 'keyCode');
    }
    return ReviewerKeyCodeBinding._(
      keyCode: keyCode,
      modifierKeys: modifierKeys,
    );
  }

  const ReviewerKeyCodeBinding._({
    required this.keyCode,
    required this.modifierKeys,
  });

  final int keyCode;
  final ReviewerModifierKeys modifierKeys;

  @override
  bool get isKey => true;

  @override
  String toBindingString() =>
      '${ReviewerBindingCodec.keyPrefix}$modifierKeys$keyCode';

  @override
  bool operator ==(Object other) =>
      other is ReviewerKeyCodeBinding &&
      other.keyCode == keyCode &&
      other.modifierKeys == modifierKeys;

  @override
  int get hashCode => _javaObjectsHash([keyCode]);
}

/// A source `Binding.UnicodeCharacter`, represented as one UTF-16 code unit.
/// Its source equality includes modifiers while its hash omits them.
final class ReviewerUnicodeCharacterBinding extends ReviewerBindingContent {
  factory ReviewerUnicodeCharacterBinding({
    required int codeUnit,
    ReviewerModifierKeys modifierKeys =
        ReviewerAppDefinedModifierKeys._instance,
  }) {
    if (codeUnit < 0 || codeUnit > 0xFFFF) {
      throw RangeError.range(codeUnit, 0, 0xFFFF, 'codeUnit');
    }
    return ReviewerUnicodeCharacterBinding._(
      codeUnit: codeUnit,
      modifierKeys: modifierKeys,
    );
  }

  const ReviewerUnicodeCharacterBinding._({
    required this.codeUnit,
    required this.modifierKeys,
  });

  final int codeUnit;
  final ReviewerModifierKeys modifierKeys;

  @override
  bool get isKey => true;

  @override
  String toBindingString() =>
      '${ReviewerBindingCodec.unicodePrefix}$modifierKeys${String.fromCharCode(codeUnit)}';

  @override
  bool operator ==(Object other) =>
      other is ReviewerUnicodeCharacterBinding &&
      other.codeUnit == codeUnit &&
      other.modifierKeys == modifierKeys;

  @override
  int get hashCode => _javaObjectsHash([codeUnit]);
}

/// An axis binding is parsed and serialized, while MotionEvent interpretation
/// remains outside this platform-independent codec.
final class ReviewerAxisButtonBinding extends ReviewerBindingContent {
  const ReviewerAxisButtonBinding._({
    required this.axisValue,
    required this.threshold,
  });

  final int axisValue;
  final double threshold;

  @override
  String toBindingString() => '${ReviewerBindingCodec.axisPrefix}$axisValue '
      '${javaFloatToString(threshold)}';

  @override
  bool operator ==(Object other) =>
      other is ReviewerAxisButtonBinding &&
      other.axisValue == axisValue &&
      float32Bits(other.threshold) == float32Bits(threshold);

  @override
  int get hashCode => Object.hash(axisValue, float32Bits(threshold));
}

/// The source `Binding.UnknownBinding`; invalid reviewer bindings are omitted
/// when preference values are written.
final class ReviewerUnknownBinding extends ReviewerBindingContent {
  const ReviewerUnknownBinding();

  @override
  bool get isValid => false;

  @override
  String toBindingString() => '';

  @override
  bool operator ==(Object other) => other is ReviewerUnknownBinding;

  @override
  int get hashCode =>
      0x554E4B4E; // Stable hash for source `data object` semantics.
}

/// A decoded reviewer preference entry.
///
/// Gesture entries expose [gesture] for routing. Key-code and Unicode entries
/// expose their serialized fields and source modifier semantics; axis entries
/// retain the parsed ID and threshold. Android input, display, and runtime axis
/// handling remain outside this value model. Unknown entries model
/// `Binding.UnknownBinding` and are omitted when written.
class ReviewerBindingValue {
  const ReviewerBindingValue._({
    required this.binding,
    required this.side,
  });

  /// Constructs a serializable gesture binding.
  factory ReviewerBindingValue.forGesture(
    Gesture gesture, {
    ReviewerCardSide side = ReviewerCardSide.both,
  }) =>
      ReviewerBindingValue._(
        binding: ReviewerGestureBinding(gesture),
        side: side,
      );

  /// Constructs a source `Binding.KeyCode` value.
  factory ReviewerBindingValue.forKeyCode(
    int keyCode, {
    ReviewerModifierKeys modifierKeys = ReviewerModifierKeys.none,
    ReviewerCardSide side = ReviewerCardSide.both,
  }) =>
      ReviewerBindingValue._(
        binding: ReviewerKeyCodeBinding(
          keyCode: keyCode,
          modifierKeys: modifierKeys,
        ),
        side: side,
      );

  /// Constructs a source `Binding.unicode` value. The factory defaults to
  /// shift-tolerant app-defined modifiers and rejects the list separator `|`.
  factory ReviewerBindingValue.forUnicodeCharacter(
    int codeUnit, {
    ReviewerModifierKeys? modifierKeys,
    ReviewerCardSide side = ReviewerCardSide.both,
  }) =>
      ReviewerBindingValue._(
        binding: codeUnit == ReviewerBindingCodec.separator.codeUnitAt(0)
            ? const ReviewerUnknownBinding()
            : ReviewerUnicodeCharacterBinding(
                codeUnit: codeUnit,
                modifierKeys:
                    modifierKeys ?? ReviewerAppDefinedModifierKeys.allowShift(),
              ),
        side: side,
      );

  final ReviewerBindingContent binding;
  final ReviewerCardSide side;

  ReviewerBindingKind get kind => switch (binding) {
        ReviewerGestureBinding() => ReviewerBindingKind.gesture,
        ReviewerUnknownBinding() => ReviewerBindingKind.unknown,
        _ => ReviewerBindingKind.nonGesture,
      };

  Gesture? get gesture => switch (binding) {
        ReviewerGestureBinding(:final gesture) => gesture,
        _ => null,
      };

  bool get isValid => binding.isValid;

  bool get isKey => binding.isKey;

  /// The ReviewerBinding list item, or null for an invalid/empty binding.
  String? toPreferenceString() {
    final serializedBinding = binding.toBindingString();
    if (!isValid || serializedBinding.isEmpty) {
      return null;
    }
    return '${ReviewerBindingCodec.reviewerPrefix}$serializedBinding${_sideSuffix(side)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReviewerBindingValue || binding != other.binding)
      return false;
    return side == ReviewerCardSide.both ||
        other.side == ReviewerCardSide.both ||
        side == other.side;
  }

  @override
  int get hashCode => _javaObjectsHash([
        binding.hashCode,
        ReviewerBindingCodec.reviewerPrefix.codeUnitAt(0),
      ]);
}

/// Encodes and decodes the `1/` list of serialized AnkiDroid reviewer bindings.
///
/// Preference lookup is deliberately supplied by the caller. Gesture bindings
/// are decoded exactly. Key-code, Unicode, and axis values retain their
/// source-serialized fields, while Android key events, display, and MotionEvent
/// axis handling remain outside this model.
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

    return ReviewerBindingValue._(binding: decodeBinding(binding), side: side);
  }

  /// Decodes one serialized source `Binding` without the reviewer side suffix.
  /// This boundary permits direct testing of valid binding strings containing
  /// the preference list separator, which cannot appear unescaped in a list.
  ReviewerBindingContent decodeBinding(String serializedBinding) {
    if (serializedBinding.isEmpty) return const ReviewerUnknownBinding();
    try {
      if (serializedBinding.startsWith(gesturePrefix)) {
        final gesture = _gestureFromName(
          serializedBinding.substring(gesturePrefix.length),
        );
        return gesture == null
            ? const ReviewerUnknownBinding()
            : ReviewerGestureBinding(gesture);
      }
      if (serializedBinding.startsWith(keyPrefix)) {
        final parts = ReviewerModifierKeys.parse(
          serializedBinding.substring(keyPrefix.length),
        );
        final keyCode = _parseKotlinInt32(parts.value);
        return keyCode == null
            ? const ReviewerUnknownBinding()
            : ReviewerKeyCodeBinding(
                keyCode: keyCode,
                modifierKeys: parts.modifierKeys,
              );
      }
      if (serializedBinding.startsWith(unicodePrefix)) {
        final parts = ReviewerModifierKeys.parse(
          serializedBinding.substring(unicodePrefix.length),
        );
        if (parts.value.isEmpty) return const ReviewerUnknownBinding();
        // `Binding.fromString()` uses Char indexing, which selects one UTF-16
        // code unit even when the remaining text begins with a surrogate pair.
        return ReviewerUnicodeCharacterBinding(
          codeUnit: parts.value.codeUnitAt(0),
          modifierKeys: parts.modifierKeys,
        );
      }
      final axis = _parseAxisBinding(serializedBinding);
      return axis ?? const ReviewerUnknownBinding();
    } on Object {
      // Binding.fromString() catches malformed input and returns UnknownBinding.
      return const ReviewerUnknownBinding();
    }
  }

  static ReviewerAxisButtonBinding? _parseAxisBinding(String binding) {
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
    return ReviewerAxisButtonBinding._(
      axisValue: axisValue,
      threshold: threshold,
    );
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
      if (roundedShift + BigInt.from(roundedSignificand.bitLength - 1) >
          BigInt.from(127)) {
        return negative ? double.negativeInfinity : double.infinity;
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

int _javaBooleanHash(bool value) => value ? 1231 : 1237;

int _javaObjectsHash(List<int> values) {
  var result = 1;
  for (final value in values) {
    result = (31 * result + value) & 0xFFFFFFFF;
  }
  return result >= 0x80000000 ? result - 0x100000000 : result;
}

String _sideSuffix(ReviewerCardSide side) => switch (side) {
      ReviewerCardSide.question => '0',
      ReviewerCardSide.answer => '1',
      ReviewerCardSide.both => '2',
    };
