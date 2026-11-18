// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/src/core_random_position.dart';
import 'package:test/test.dart';

void main() {
  test('random card positions match pinned Anki Core fixtures', () {
    expect(coreRandomPosition(5), 180);
    expect(coreRandomPosition(500), 13);
    expect(coreRandomPosition(5001), 3731);
  });
}
