// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:sqlite3/common.dart';

final _fnvOffsetBasis = BigInt.parse('14695981039346656037');
final _fnvPrime = BigInt.parse('1099511628211');
final _mask64 = (BigInt.one << 64) - BigInt.one;
final _signBit64 = BigInt.one << 63;
final _minI64 = -_signBit64;
final _maxI64 = _signBit64 - BigInt.one;

/// Installs Core's variadic deterministic SQLite `fnvhash` function.
void registerFnvHashFunction(CommonDatabase database) {
  database.createFunction(
    functionName: 'fnvhash',
    argumentCount: const AllowedArgumentCount.any(),
    deterministic: true,
    directOnly: false,
    function: fnvHashSqlArguments,
  );
}

/// Hashes signed SQLite integers like Core's `fnv::FnvHasher::write_i64`.
///
/// Each value is fed in host-native byte order as Rust's default
/// `Hasher::write_i64` does. The unsigned FNV-1a result is returned as the
/// corresponding signed i64.
BigInt fnvHashSqlArguments(List<Object?> arguments, {Endian? endian}) {
  final byteOrder = endian ?? Endian.host;
  var hash = _fnvOffsetBasis;
  for (var index = 0; index < arguments.length; index++) {
    final value = _signedI64(arguments[index], index);
    for (var byteIndex = 0; byteIndex < 8; byteIndex++) {
      final shift =
          (byteOrder == Endian.little ? byteIndex : 7 - byteIndex) * 8;
      final byte = (value >> shift) & BigInt.from(0xff);
      hash = ((hash ^ byte) * _fnvPrime) & _mask64;
    }
  }
  return hash >= _signBit64 ? hash - (_mask64 + BigInt.one) : hash;
}

BigInt _signedI64(Object? value, int index) {
  final integer = switch (value) {
    int() => BigInt.from(value),
    BigInt() => value,
    _ => throw ArgumentError.value(
      value,
      'argument[$index]',
      'must be a signed 64-bit integer',
    ),
  };
  if (integer < _minI64 || integer > _maxI64) {
    throw ArgumentError.value(
      integer,
      'argument[$index]',
      'must be a signed 64-bit integer',
    );
  }
  return integer;
}
