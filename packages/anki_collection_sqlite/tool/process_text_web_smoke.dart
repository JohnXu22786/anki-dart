// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/process_text.dart';

void main() {
  const input = 'Über {{c1::café::hint}}';
  final actual = processSearchText(input, 3);
  if (actual != 'Uber cafe') {
    throw StateError('Web process_text returned unexpected output: $actual');
  }
  final bigIntFlags = processSearchText(
    input,
    BigInt.parse('9223372036854775807'),
  );
  if (bigIntFlags != 'Uber cafe') {
    throw StateError('Web BigInt process_text flags returned: $bigIntFlags');
  }
  if (processSearchText('{{c١::arabic digit}}', 2) != 'arabic digit') {
    throw StateError('Web process_text did not strip Unicode cloze digits');
  }
}
