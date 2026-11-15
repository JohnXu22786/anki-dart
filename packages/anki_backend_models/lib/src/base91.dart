// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';

/// Convert an unsigned 64-bit integer to the alphabet used by Anki note GUIDs.
///
/// This matches `anki_base91()` in the pinned Anki Core source. Zero is the
/// empty string, as in the Rust implementation.
String base91U64(BigInt value) {
  if (value < BigInt.zero || value >= (BigInt.one << 64)) {
    throw ArgumentError.value(
      value,
      'value',
      'must be an unsigned 64-bit integer',
    );
  }
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#\$%&()*+,-./:;<=>?@[]^_`{|}~';
  if (value == BigInt.zero) return '';

  final base = BigInt.from(alphabet.length);
  var remaining = value;
  final output = <String>[];
  while (remaining > BigInt.zero) {
    final quotient = remaining ~/ base;
    final remainder = (remaining % base).toInt();
    output.add(alphabet[remainder]);
    remaining = quotient;
  }
  return output.reversed.join();
}

/// Interpret an unsigned random 64-bit value as the corresponding int64 bits.
Int64 int64FromRandomU64(BigInt value) {
  if (value < BigInt.zero || value >= (BigInt.one << 64)) {
    throw ArgumentError.value(
      value,
      'value',
      'must be an unsigned 64-bit integer',
    );
  }
  final signed =
      value >= (BigInt.one << 63) ? value - (BigInt.one << 64) : value;
  return Int64.parseInt(signed.toString());
}
