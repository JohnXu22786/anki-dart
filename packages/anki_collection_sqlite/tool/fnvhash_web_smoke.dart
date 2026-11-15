// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/fnvhash.dart';

void main() {
  final actual = fnvHashSqlArguments([
    BigInt.parse('9223372036854775807'),
    BigInt.parse('-9223372036854775808'),
  ]);
  if (actual != BigInt.parse('3258221292563947997')) {
    throw StateError('Web fnvhash returned unexpected output: $actual');
  }
  if (fnvHashSqlArguments([BigInt.parse('9007199254740993')]) !=
      BigInt.parse('-8486486863911627580')) {
    throw StateError('Web fnvhash lost integer precision above 2^53');
  }
}
