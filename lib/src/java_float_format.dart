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
 * Internal formatting support for source-compatible serialized Float values.
 */

import 'dart:math' as math;
import 'dart:typed_data';

/// Formats [value] as a Java/Kotlin Float after narrowing it to binary32.
String javaFloatToString(double value) {
  final floatValue = _float32(value);
  if (floatValue.isNaN) return 'NaN';
  if (floatValue.isInfinite) {
    return floatValue.isNegative ? '-Infinity' : 'Infinity';
  }
  if (floatValue == 0) return floatValue.isNegative ? '-0.0' : '0.0';

  final bits = float32Bits(floatValue);
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
  // Float.MIN_VALUE as `1.4E-45`, rather than collapsing it to `1.0E-45`.
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
    if (parsed != null && float32Bits(_float32(parsed)) == bits) {
      shortest = candidate;
      break;
    }
  }
  if (shortest.isEmpty) {
    shortest = _roundedFloatCandidate(floatValue, bits, decimalExponent, 9);
  }
  return _formatJavaFloatCandidate(shortest);
}

/// Binary32 bits used by the Float formatter and binding value semantics.
int float32Bits(double value) {
  final bytes = ByteData(4)..setFloat32(0, value, Endian.big);
  return bytes.getUint32(0, Endian.big);
}

double _float32(double value) => Float32List.fromList([value])[0];

String _roundedFloatCandidate(
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

String _formatJavaFloatCandidate(String candidate) {
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
    formatted = '${significantDigits[0]}.$tail' 'E$adjustedExponent';
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
