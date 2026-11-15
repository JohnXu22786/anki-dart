// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki_backend_protocol.dart';

void main() {
  final encoded = Int32(val: -2147483648).writeToBuffer();
  final decoded = Int32.fromBuffer(encoded);
  if (decoded.val != -2147483648) {
    throw StateError('Protocol codec failed to round-trip a signed boundary.');
  }
}
