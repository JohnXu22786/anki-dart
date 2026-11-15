// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/card_data_functions.dart';

void main() {
  if (extractOriginalPosition('{"pos":4294967295}') != 4294967295) {
    throw StateError('Web card-data position lost unsigned 32-bit value');
  }
  if (extractOriginalPosition('{"pos":4294967296}') != null) {
    throw StateError('Web card-data position accepted value above u32');
  }
  if (extractCustomData('{"cd":"{\\"z\\":1,\\"a\\":2}"}', 'a') != '2') {
    throw StateError('Web card-data custom JSON lookup failed');
  }
  if (extractCustomData('{"cd":"{\\"n\\":9007199254740993}"}', 'n') !=
      '9007199254740993') {
    throw StateError('Web custom JSON integer lost precision beyond 2^53');
  }
}
