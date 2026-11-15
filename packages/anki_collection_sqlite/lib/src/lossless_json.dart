// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

/// Parses JSON while retaining integer literals that JavaScript numbers round.
Object? parseLosslessJson(String source) => _Parser(source).parse();

/// Validates a full JSON document with serde_json-compatible number bounds.
void validateLosslessJson(String source) {
  parseLosslessJson(source);
}

/// Renders JSON like Core's `serde_json::Value`, including sorted object keys.
String encodeLosslessJson(Object? value) => switch (value) {
  _RawNumber() => value.encode(),
  String() || bool() || num() || null => jsonEncode(value),
  Map<String, Object?>() => _encodeObject(value),
  List<Object?>() => '[${value.map(encodeLosslessJson).join(',')}]',
  _ => throw StateError('Unexpected JSON value: $value'),
};

String _encodeObject(Map<String, Object?> value) {
  final keys = value.keys.toList()..sort(_compareUnicodeScalars);
  return '{${keys.map((key) => '${jsonEncode(key)}:${encodeLosslessJson(value[key])}').join(',')}}';
}

int _compareUnicodeScalars(String left, String right) {
  final leftRunes = left.runes.iterator;
  final rightRunes = right.runes.iterator;
  while (true) {
    final hasLeft = leftRunes.moveNext();
    final hasRight = rightRunes.moveNext();
    if (!hasLeft || !hasRight) {
      if (hasLeft) return 1;
      if (hasRight) return -1;
      return 0;
    }
    final comparison = leftRunes.current.compareTo(rightRunes.current);
    if (comparison != 0) return comparison;
  }
}

final class _RawNumber {
  const _RawNumber(this.lexeme);

  final String lexeme;

  String encode() {
    if (!lexeme.contains(RegExp(r'[.eE]'))) {
      final integer = BigInt.parse(lexeme);
      final minI64 = -(BigInt.one << 63);
      final maxU64 = (BigInt.one << 64) - BigInt.one;
      if (integer >= minI64 && integer <= maxU64) return integer.toString();
    }
    final floatingPoint = double.parse(lexeme);
    if (!floatingPoint.isFinite) {
      throw FormatException('JSON number is outside serde_json range', lexeme);
    }
    return _encodeRyuCompatibleFloat(floatingPoint);
  }
}

String _encodeRyuCompatibleFloat(double value) {
  final match = RegExp(
    r'^(-?)([0-9])(?:\.([0-9]+))?e([+-])([0-9]+)$',
  ).firstMatch(value.toStringAsExponential())!;
  final sign = match.group(1)!;
  final leadingDigit = match.group(2)!;
  final fraction = match.group(3) ?? '';
  final exponent = int.parse('${match.group(4)}${match.group(5)}');
  final digits = '$leadingDigit$fraction';

  if (exponent < -5 || exponent >= 16) {
    final mantissa = fraction.isEmpty
        ? leadingDigit
        : '$leadingDigit.$fraction';
    final exponentSign = exponent < 0 ? '-' : '+';
    return '$sign$mantissa'
        'e$exponentSign${exponent.abs()}';
  }

  final decimalPosition = exponent + 1;
  if (decimalPosition <= 0) {
    return '$sign'
        '0.${''.padLeft(-decimalPosition, '0')}$digits';
  }
  if (decimalPosition >= digits.length) {
    return '$sign'
        '$digits${''.padLeft(decimalPosition - digits.length, '0')}.0';
  }
  return '$sign'
      '${digits.substring(0, decimalPosition)}.'
      '${digits.substring(decimalPosition)}';
}

final class _Parser {
  _Parser(this.source);

  final String source;
  int index = 0;

  Object? parse() {
    final value = _parseValue();
    _skipWhitespace();
    if (index != source.length) {
      throw FormatException('Unexpected trailing JSON text', source, index);
    }
    return value;
  }

  Object? _parseValue() {
    _skipWhitespace();
    if (index >= source.length) {
      throw FormatException('Expected JSON value', source, index);
    }
    final character = source[index];
    if (character == '"') return _parseString();
    if (character == '{') return _parseObject();
    if (character == '[') return _parseArray();
    if (character == 't') return _parseLiteral('true', true);
    if (character == 'f') return _parseLiteral('false', false);
    if (character == 'n') return _parseLiteral('null', null);
    final codeUnit = character.codeUnitAt(0);
    if (character == '-' || (codeUnit >= 0x30 && codeUnit <= 0x39)) {
      return _parseNumber();
    }
    throw FormatException('Invalid JSON value', source, index);
  }

  Map<String, Object?> _parseObject() {
    index++;
    final result = <String, Object?>{};
    _skipWhitespace();
    if (_consume('}')) return result;
    while (true) {
      _skipWhitespace();
      if (index >= source.length || source[index] != '"') {
        throw FormatException('Expected object key', source, index);
      }
      final key = _parseString();
      _skipWhitespace();
      if (!_consume(':'))
        throw FormatException('Expected colon', source, index);
      result[key] = _parseValue();
      _skipWhitespace();
      if (_consume('}')) return result;
      if (!_consume(','))
        throw FormatException('Expected comma', source, index);
    }
  }

  List<Object?> _parseArray() {
    index++;
    final result = <Object?>[];
    _skipWhitespace();
    if (_consume(']')) return result;
    while (true) {
      result.add(_parseValue());
      _skipWhitespace();
      if (_consume(']')) return result;
      if (!_consume(','))
        throw FormatException('Expected comma', source, index);
    }
  }

  String _parseString() {
    final start = index++;
    while (index < source.length) {
      final unit = source.codeUnitAt(index++);
      if (unit == 0x22)
        return jsonDecode(source.substring(start, index)) as String;
      if (unit == 0x5c) {
        if (index >= source.length) break;
        index++;
      } else if (unit < 0x20) {
        throw FormatException(
          'Control character in JSON string',
          source,
          index - 1,
        );
      }
    }
    throw FormatException('Unterminated JSON string', source, start);
  }

  _RawNumber _parseNumber() {
    final match = RegExp(
      r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
    ).matchAsPrefix(source, index);
    if (match == null)
      throw FormatException('Invalid JSON number', source, index);
    index = match.end;
    final number = _RawNumber(match.group(0)!);
    number.encode(); // serde_json validates every value while parsing.
    return number;
  }

  Object? _parseLiteral(String literal, Object? value) {
    if (!source.startsWith(literal, index)) {
      throw FormatException('Invalid JSON literal', source, index);
    }
    index += literal.length;
    return value;
  }

  void _skipWhitespace() {
    while (index < source.length) {
      final unit = source.codeUnitAt(index);
      if (unit != 0x20 && unit != 0x09 && unit != 0x0a && unit != 0x0d) break;
      index++;
    }
  }

  bool _consume(String character) {
    if (index >= source.length || source[index] != character) return false;
    index++;
    return true;
  }
}
