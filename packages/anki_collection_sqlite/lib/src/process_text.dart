// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:sqlite3/common.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

const _stripClozesFlag = 1 << 1;
const _noCombiningFlag = 1;
final _clozePattern = RegExp(r'\{\{c[\d,]+::(.*?)(::.*?)?\}\}', dotAll: true);
final _combiningMarks = RegExp(r'\p{M}', unicode: true);

const _noCombiningReplacements = <String, String>{
  '€': 'E',
  'Æ': 'AE',
  'Ð': 'D',
  'Ø': 'O',
  'Þ': 'TH',
  'ß': 's',
  'æ': 'ae',
  'ð': 'd',
  'ø': 'o',
  'þ': 'th',
  'Đ': 'D',
  'đ': 'd',
  'Ħ': 'H',
  'ħ': 'h',
  'ı': 'i',
  'ĸ': 'k',
  'Ł': 'L',
  'ł': 'l',
  'Ŋ': 'N',
  'ŋ': 'n',
  'Œ': 'OE',
  'œ': 'oe',
  'Ŧ': 'T',
  'ŧ': 't',
  'Ə': 'E',
  'ǝ': 'e',
  'ɑ': 'a',
};

/// Installs Core's deterministic text normalizer on a shared SQLite host.
void registerProcessTextFunction(CommonDatabase database) {
  database.createFunction(
    functionName: 'process_text',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    directOnly: false,
    function: (arguments) {
      if (arguments[0] is! String) {
        throw ArgumentError.value(arguments[0], 'text', 'must be text');
      }
      return processSearchText(arguments[0]! as String, arguments[1]);
    },
  );
}

/// Applies Core `process_text` flags: strip cloze wrappers, then NFKD and
/// remove combining marks plus Core's fixed transliteration replacements.
String processSearchText(String text, Object? flagsValue) {
  final flags = _flagsAsLowByte(flagsValue);
  var result = text;
  if ((flags & _stripClozesFlag) != 0) {
    result = result.replaceAllMapped(_clozePattern, (match) => match[1]!);
  }
  if ((flags & _noCombiningFlag) != 0) {
    result = unorm.nfkd(result).replaceAll(_combiningMarks, '');
    result = result.runes
        .map(String.fromCharCode)
        .map((char) => _noCombiningReplacements[char] ?? char)
        .join();
  }
  return result;
}

int _flagsAsLowByte(Object? value) => switch (value) {
  int() => value & 0xff,
  BigInt() => (value & BigInt.from(0xff)).toInt(),
  _ => throw ArgumentError.value(
    value,
    'flags',
    'must be a signed 64-bit integer',
  ),
};
