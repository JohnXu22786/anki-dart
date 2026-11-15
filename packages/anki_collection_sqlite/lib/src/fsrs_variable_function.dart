// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:sqlite3/common.dart';

import 'card_data_functions.dart';

/// Installs Core's `extract_fsrs_variable(card_data, key)` SQLite function.
void registerFsrsVariableFunction(CommonDatabase database) {
  database.createFunction(
    functionName: 'extract_fsrs_variable',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    directOnly: false,
    function: (arguments) => extractFsrsVariable(arguments[0], arguments[1]),
  );
}

/// Extracts Core's FSRS `s`, `d`, or `dr` value with its stored f32 precision.
double? extractFsrsVariable(Object? cardData, Object? key) {
  if (cardData is! String || cardData.isEmpty || key is! String) return null;
  final sequenceIndex = switch (key) {
    's' => 1,
    'd' => 2,
    'dr' => 3,
    _ => throw StateError('invalid key: $key'),
  };
  final value = cardDataField(cardData, key, sequenceIndex);
  if (value is! num) return null;
  final data = ByteData(4)..setFloat32(0, value.toDouble());
  final rounded = data.getFloat32(0);
  return rounded.isFinite ? rounded : null;
}
