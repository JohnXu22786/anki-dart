// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:sqlite3/common.dart';

import 'lossless_json.dart';

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
  final value = _losslessCardDataField(cardData, key, sequenceIndex);
  return losslessJsonFloat32(value);
}

Object? _losslessCardDataField(String source, String key, int sequenceIndex) {
  try {
    final decoded = parseLosslessJson(source);
    if (decoded is Map<String, Object?>) {
      if (decoded.containsKey('cd') && decoded['cd'] is! String) return null;
      return decoded[key];
    }
    if (decoded is List<Object?>) {
      if (decoded.length > 6 && decoded[6] is! String) return null;
      if (decoded.length > sequenceIndex) return decoded[sequenceIndex];
    }
    return null;
  } on FormatException {
    return null;
  }
}
