// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:sqlite3/common.dart';

import 'lossless_json.dart';

/// Installs Core's card-data extraction functions on a shared SQLite host.
void registerCardDataFunctions(CommonDatabase database) {
  database.createFunction(
    functionName: 'extract_original_position',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    directOnly: false,
    function: (arguments) => extractOriginalPosition(arguments[0]),
  );
  database.createFunction(
    functionName: 'extract_custom_data',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    directOnly: false,
    function: (arguments) => extractCustomData(arguments[0], arguments[1]),
  );
}

/// Extracts compact card-data `pos`, returning null for Core's default value.
int? extractOriginalPosition(Object? cardData) {
  if (cardData is! String) return null;
  if (!_cardDataObjectParses(cardData)) return null;
  final value = cardDataField(cardData, 'pos', 0);
  return switch (value) {
    int() when value >= 0 && value <= 0xffffffff => value,
    BigInt() when value >= BigInt.zero && value <= BigInt.from(0xffffffff) =>
      value.toInt(),
    _ => null,
  };
}

bool _cardDataObjectParses(String cardData) {
  try {
    validateLosslessJson(cardData);
    final decoded = jsonDecode(cardData);
    if (decoded is Map<String, Object?>) {
      return !decoded.containsKey('cd') || decoded['cd'] is String;
    }
    if (decoded is List<Object?>) {
      return decoded.length <= 6 || decoded[6] is String;
    }
    return false;
  } on FormatException {
    return false;
  }
}

/// Extracts a value from the compact card-data `cd` JSON object.
Object? extractCustomData(Object? cardData, Object? key) {
  if (cardData is! String || cardData.isEmpty || key is! String) return null;
  final serializedCustomData = cardDataField(cardData, 'cd', 6);
  if (serializedCustomData is! String || serializedCustomData.isEmpty) {
    return null;
  }
  final Object? customData;
  try {
    customData = parseLosslessJson(serializedCustomData);
  } on FormatException {
    return null;
  }
  if (customData is! Map<String, Object?> || !customData.containsKey(key)) {
    return null;
  }
  final value = customData[key];
  if (value is String) return value;
  try {
    return encodeLosslessJson(value);
  } on FormatException {
    return null;
  }
}

/// Reads a compact `CardData` field from JSON object or sequence storage.
Object? cardDataField(String cardData, String key, int sequenceIndex) {
  try {
    validateLosslessJson(cardData);
    final decoded = jsonDecode(cardData);
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
