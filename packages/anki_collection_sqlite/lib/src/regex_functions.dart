// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:collection';

import 'package:sqlite3/common.dart';

import 'unicode_case_folding.dart';

/// Installs Core's regex-backed collection SQLite functions.
void registerRegexFunctions(CommonDatabase database) {
  database.createFunction(
    functionName: 'regexp',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    directOnly: false,
    function: (arguments) => _compileCoreRegex(
      _requireText(arguments[0], 'pattern'),
    ).hasMatch(_requireText(arguments[1], 'text')),
  );
  database.createFunction(
    functionName: 'regexp_fields',
    argumentCount: const AllowedArgumentCount.any(),
    deterministic: true,
    directOnly: false,
    function: _regexpFields,
  );
  database.createFunction(
    functionName: 'regexp_tags',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    directOnly: false,
    function: (arguments) {
      final regex = _compileCoreRegex(_requireText(arguments[0], 'pattern'));
      return _requireText(arguments[1], 'tags').split(' ').any(regex.hasMatch);
    },
  );
}

/// Returns whether a Core-style regex matches [text].
bool coreRegexHasMatch(String pattern, String text) =>
    _compileCoreRegex(pattern).hasMatch(text);

final LinkedHashMap<String, RegExp> _regexCache = LinkedHashMap();
const _regexCacheCapacity = 64;

bool _regexpFields(List<Object?> arguments) {
  if (arguments.length < 2) {
    throw ArgumentError('regexp_fields requires at least two arguments');
  }
  final regex = _compileCoreRegex(_requireText(arguments[0], 'pattern'));
  final fields = _requireText(arguments[1], 'fields').split('\x1f');
  final indices = <int>{
    for (var index = 2; index < arguments.length; index++)
      _requireFieldIndex(arguments[index]),
  };
  for (var index = 0; index < fields.length; index++) {
    if ((indices.isEmpty || indices.contains(index)) &&
        regex.hasMatch(fields[index])) {
      return true;
    }
  }
  return false;
}

String _requireText(Object? value, String name) {
  if (value is String) return value;
  throw ArgumentError('$name must be text');
}

int _requireFieldIndex(Object? value) {
  if (value is int && value >= 0) return value;
  if (value is BigInt &&
      value >= BigInt.zero &&
      value <= BigInt.parse('9223372036854775807')) {
    return value.toInt();
  }
  throw ArgumentError('field index must be a non-negative integer');
}

RegExp _compileCoreRegex(String source) {
  final cached = _regexCache.remove(source);
  if (cached != null) {
    _regexCache[source] = cached;
    return cached;
  }

  _rejectUnsupportedRustSyntax(source);
  final translatedPattern = _translateRustRegexSyntax(source);
  final compiled = RegExp(
    translatedPattern,
    caseSensitive: true,
    multiLine: false,
    dotAll: false,
    unicode: true,
  );
  _regexCache[source] = compiled;
  if (_regexCache.length > _regexCacheCapacity) {
    _regexCache.remove(_regexCache.keys.first);
  }
  return compiled;
}

const _rustWordClassContents =
    r'\p{Alphabetic}\p{Mark}\p{Nd}\p{Pc}\u200c\u200d';
const _rustWordClass = '[$_rustWordClassContents]';

String _translateRustPerlClasses(String pattern) {
  final output = StringBuffer();
  var inCharacterClass = false;
  var escaped = false;
  for (var index = 0; index < pattern.length; index++) {
    final character = pattern[index];
    if (escaped) {
      if (inCharacterClass) {
        switch (character) {
          case 'd':
            output.write(r'\p{Nd}');
          case 'D':
            output.write(r'\P{Nd}');
          case 's':
            output.write(r'\p{White_Space}');
          case 'S':
            output.write(r'\P{White_Space}');
          case 'w':
            output.write(_rustWordClassContents);
          case 'W':
            throw FormatException(
              r'\W inside a character class is not supported',
              pattern,
            );
          default:
            output
              ..write(r'\')
              ..write(character);
        }
      } else {
        switch (character) {
          case 'd':
            output.write(r'\p{Nd}');
          case 'D':
            output.write(r'\P{Nd}');
          case 's':
            output.write(r'\p{White_Space}');
          case 'S':
            output.write(r'\P{White_Space}');
          case 'w':
            output.write(_rustWordClass);
          case 'W':
            output.write('(?!(?:$_rustWordClass))[\\s\\S]');
          case 'b':
            output.write(
              '(?:(?<=$_rustWordClass)(?!$_rustWordClass)|'
              '(?<!$_rustWordClass)(?=$_rustWordClass))',
            );
          case 'B':
            output.write(
              '(?:(?<=$_rustWordClass)(?=$_rustWordClass)|'
              '(?<!$_rustWordClass)(?!$_rustWordClass))',
            );
          case 'A':
            output.write(r'(?<![\s\S])');
          case 'z':
            output.write(r'(?![\s\S])');
          default:
            output
              ..write(r'\')
              ..write(character);
        }
      }
      escaped = false;
      continue;
    }
    if (character == r'\') {
      escaped = true;
      continue;
    }
    if (character == '[') {
      final end = _characterClassEnd(pattern, index);
      if (end != null) {
        final contents = pattern.substring(index + 1, end);
        final translated = _translateCharacterClass(contents, pattern);
        output.write(translated);
        index = end;
        continue;
      }
      inCharacterClass = true;
    }
    if (character == ']') inCharacterClass = false;
    output.write(character);
  }
  if (escaped) output.write(r'\');
  return output.toString();
}

String _translateRustRegexSyntax(String pattern) {
  // Rust regex uses `\\b{start}` and `\\b{end}` for directional word
  // boundaries. Dart's ECMAScript engine has no equivalent token.
  final withFlags = _translateInlineCaseFlags(pattern);
  final withDirectionalBoundaries = withFlags
      .replaceAll(r'\b{start-half}', '(?<!$_rustWordClass)')
      .replaceAll(r'\b{end-half}', '(?!$_rustWordClass)')
      .replaceAll(r'\b{start}', '(?<!$_rustWordClass)(?=$_rustWordClass)')
      .replaceAll(r'\b{end}', '(?<=$_rustWordClass)(?!$_rustWordClass)');
  var translated = _translateRustPerlClasses(withDirectionalBoundaries);
  translated = translated.replaceAllMapped(RegExp(r'\\([pP])\{([^}]+)\}'), (
    match,
  ) {
    final kind = match.group(1)!;
    final property = match.group(2)!;
    if (_ecmaPropertyNames.contains(property) || property.contains('=')) {
      return '\\' + kind + '{' + property + '}';
    }
    return '\\' + kind + '{Script=' + property + '}';
  });
  translated = translated.replaceAllMapped(RegExp(r'\\([pP])([LMNPSZC])'), (
    match,
  ) {
    return '\\' + match.group(1)! + '{' + match.group(2)! + '}';
  });
  // Rust's named-capture spelling is `(?P<name>...)`; ECMAScript uses
  // `(?<name>...)`.
  translated = translated.replaceAll(r'(?P<', '(?<');
  return translated;
}

String _translateInlineCaseFlags(String pattern) {
  final output = StringBuffer();
  final groupFlags = <(bool, bool, bool, bool, bool, bool)>[];
  var caseInsensitive = false;
  var multiLine = false;
  var dotAll = false;
  var crlf = false;
  var ungreedy = false;
  var extended = false;
  var inComment = false;
  var inCharacterClass = false;
  var escaped = false;
  for (var index = 0; index < pattern.length; index++) {
    final character = pattern[index];
    if (inComment) {
      if (character == '\n') inComment = false;
      continue;
    }
    if (!inCharacterClass && character == '(') {
      final namedCaptureStart = pattern.startsWith('(?P<', index)
          ? index + 4
          : pattern.startsWith('(?<', index)
          ? index + 3
          : null;
      if (namedCaptureStart != null) {
        final nameEnd = pattern.indexOf('>', namedCaptureStart);
        if (nameEnd >= 0) {
          groupFlags.add((
            caseInsensitive,
            multiLine,
            dotAll,
            crlf,
            ungreedy,
            extended,
          ));
          output.write(pattern.substring(index, nameEnd + 1));
          index = nameEnd;
          continue;
        }
      }
      final inlineFlags = RegExp(
        r'^\(\?(-?[imsURx]+)(?:-([imsURx]+))?([:)])',
      ).firstMatch(pattern.substring(index));
      if (inlineFlags != null) {
        final specification = inlineFlags.group(1)!;
        final scoped = inlineFlags.group(3) == ':';
        final disabled = <String>{
          if (specification.startsWith('-'))
            ...specification.substring(1).split(''),
          ...?inlineFlags.group(2)?.split(''),
        };
        final enabled = specification.startsWith('-')
            ? <String>{}
            : specification.split('').toSet();
        if (scoped) {
          groupFlags.add((
            caseInsensitive,
            multiLine,
            dotAll,
            crlf,
            ungreedy,
            extended,
          ));
        }
        for (final flag in {...enabled, ...disabled}) {
          final isEnabled = enabled.contains(flag);
          switch (flag) {
            case 'i':
              caseInsensitive = isEnabled;
            case 'm':
              multiLine = isEnabled;
            case 's':
              dotAll = isEnabled;
            case 'R':
              crlf = isEnabled;
            case 'U':
              ungreedy = isEnabled;
            case 'x':
              extended = isEnabled;
          }
        }
        if (scoped) output.write('(?:');
        index += inlineFlags.end - 1;
        continue;
      }
    }
    if (escaped) {
      if ((character == 'p' || character == 'P') &&
          index + 1 < pattern.length) {
        final end = pattern[index + 1] == '{'
            ? pattern.indexOf('}', index + 2)
            : RegExp(r'[A-Za-z]').hasMatch(pattern[index + 1])
            ? index + 1
            : -1;
        if (end >= 0) {
          output.write(pattern.substring(index - 1, end + 1));
          index = end;
          escaped = false;
          continue;
        }
      }
      if (character == 'b' && pattern.startsWith('{', index + 1)) {
        final end = pattern.indexOf('}', index + 2);
        if (end >= 0) {
          output.write(pattern.substring(index - 1, end + 1));
          index = end;
          escaped = false;
          continue;
        }
      }
      if (character == 'x' && index + 1 < pattern.length) {
        final hexEnd = pattern[index + 1] == '{'
            ? pattern.indexOf('}', index + 2)
            : index + 2;
        if (hexEnd > index) {
          final digits = pattern.substring(
            pattern[index + 1] == '{' ? index + 2 : index + 1,
            hexEnd,
          );
          final codePoint = int.tryParse(digits, radix: 16);
          if (codePoint != null &&
              (pattern[index + 1] == '{' || digits.length == 2)) {
            if (codePoint > 0x10ffff ||
                (codePoint >= 0xd800 && codePoint <= 0xdfff)) {
              throw FormatException(
                'invalid Unicode scalar in Core regex',
                pattern,
              );
            }
            output.write(
              caseInsensitive
                  ? _caseFoldClass(codePoint)
                  : String.fromCharCode(codePoint),
            );
            index = hexEnd;
            escaped = false;
            continue;
          }
        }
      }
      output
        ..write(r'\')
        ..write(character);
      escaped = false;
      continue;
    }
    if (character == r'\') {
      escaped = true;
      continue;
    }
    if (character == '[' && !inCharacterClass) {
      final end = _characterClassEnd(pattern, index);
      if (end != null) {
        final contents = pattern.substring(index + 1, end);
        output
          ..write('[')
          ..write(
            caseInsensitive ? _caseFoldCharacterClass(contents) : contents,
          )
          ..write(']');
        index = end;
        continue;
      }
    }
    if (character == '[') inCharacterClass = true;
    if (character == ']') inCharacterClass = false;
    if (character == '(' && !inCharacterClass) {
      groupFlags.add((
        caseInsensitive,
        multiLine,
        dotAll,
        crlf,
        ungreedy,
        extended,
      ));
    }
    if (character == ')' && !inCharacterClass && groupFlags.isNotEmpty) {
      final (previousI, previousM, previousS, previousR, previousU, previousX) =
          groupFlags.removeLast();
      caseInsensitive = previousI;
      multiLine = previousM;
      dotAll = previousS;
      crlf = previousR;
      ungreedy = previousU;
      extended = previousX;
    }
    if (extended && character == '#') {
      inComment = true;
      continue;
    }
    if (extended && RegExp(r'\s').hasMatch(character)) continue;
    if (!inCharacterClass &&
        ungreedy &&
        (character == '*' || character == '+' || character == '?') &&
        !(character == '?' && index > 0 && pattern[index - 1] == '(')) {
      output.write(character);
      if (index + 1 < pattern.length && pattern[index + 1] == '?') {
        index++;
      } else {
        output.write('?');
      }
      continue;
    }
    if (!inCharacterClass && ungreedy && character == '{') {
      final quantifier = RegExp(
        r'^\{\d+(?:,\d*)?\}',
      ).firstMatch(pattern.substring(index));
      if (quantifier != null) {
        output.write(quantifier.group(0));
        index += quantifier.end - 1;
        if (index + 1 < pattern.length && pattern[index + 1] == '?') {
          index++;
        } else {
          output.write('?');
        }
        continue;
      }
    }
    if (!inCharacterClass && character == '^') {
      output.write(
        multiLine
            ? (crlf
                  ? r'(?:(?<![\s\S])|(?<=\n)|(?=\r\n))'
                  : r'(?:(?<![\s\S])|(?<=\n))')
            : r'(?<![\s\S])',
      );
    } else if (!inCharacterClass && character == r'$') {
      output.write(
        multiLine
            ? (crlf
                  ? r'(?:(?![\s\S])|(?=\r\n)|(?<=\n))'
                  : r'(?:(?![\s\S])|(?=\n))')
            : r'(?![\s\S])',
      );
    } else if (!inCharacterClass && character == '.' && dotAll) {
      output.write(r'[\s\S]');
    } else if (!inCharacterClass && character == '.') {
      output.write(crlf && multiLine ? r'[^\r\n]' : r'[^\n]');
    } else if (!inCharacterClass && caseInsensitive) {
      final first = pattern.codeUnitAt(index);
      if (first >= 0xd800 && first <= 0xdbff && index + 1 < pattern.length) {
        final second = pattern.codeUnitAt(index + 1);
        if (second >= 0xdc00 && second <= 0xdfff) {
          final codePoint =
              0x10000 + ((first - 0xd800) << 10) + second - 0xdc00;
          output.write(_caseFoldClass(codePoint));
          index++;
        } else {
          output.write(character);
        }
      } else {
        output.write(_caseFoldClass(first));
      }
    } else {
      output.write(character);
    }
  }
  if (escaped) output.write(r'\');
  return output.toString();
}

String _caseFoldClass(int codePoint) {
  final members = rustUnicodeSimpleCaseFoldByCodePoint[codePoint];
  if (members == null) return String.fromCharCode(codePoint);
  return '[${members.map(_escapeClassCodePoint).join()}]';
}

String _escapeClassCodePoint(int codePoint) {
  if (codePoint >= 0x21 &&
      codePoint <= 0x7e &&
      !r'-[]^\\'.contains(String.fromCharCode(codePoint))) {
    return String.fromCharCode(codePoint);
  }
  return r'\u{' + codePoint.toRadixString(16) + '}';
}

String _caseFoldCharacterClass(String contents) {
  final output = StringBuffer(contents);
  for (var index = 0; index < contents.length;) {
    final start = _readClassCodePoint(contents, index);
    if (start == null) {
      index = _skipClassEscape(contents, index);
      continue;
    }
    if (start.codePoint == 0x2d) {
      index = start.end;
      continue;
    }
    if (start.end < contents.length && contents[start.end] == '-') {
      final end = _readClassCodePoint(contents, start.end + 1);
      if (end != null && start.codePoint <= end.codePoint) {
        for (final group in rustUnicodeSimpleCaseFoldGroups) {
          if (group.any(
            (member) => member >= start.codePoint && member <= end.codePoint,
          )) {
            for (final member in group) {
              if (member < start.codePoint || member > end.codePoint) {
                output.write(_escapeClassCodePoint(member));
              }
            }
          }
        }
        index = end.end;
        continue;
      }
    }
    final members = rustUnicodeSimpleCaseFoldByCodePoint[start.codePoint];
    if (members != null) {
      for (final member in members) {
        if (member != start.codePoint)
          output.write(_escapeClassCodePoint(member));
      }
    }
    index = start.end;
  }
  return output.toString();
}

({int codePoint, int end})? _readClassCodePoint(String source, int start) {
  if (start >= source.length) return null;
  if (source[start] == r'\') {
    if (start + 1 >= source.length) return null;
    final escaped = source[start + 1];
    if (escaped == 'x' && start + 2 < source.length) {
      final end = source[start + 2] == '{'
          ? source.indexOf('}', start + 3)
          : start + 3;
      if (end > start) {
        final digits = source.substring(
          source[start + 2] == '{' ? start + 3 : start + 2,
          end,
        );
        final codePoint = int.tryParse(digits, radix: 16);
        if (codePoint != null) return (codePoint: codePoint, end: end + 1);
      }
    }
    if ((escaped == 'p' || escaped == 'P') &&
        start + 2 < source.length &&
        source[start + 2] == '{') {
      final end = source.indexOf('}', start + 3);
      if (end >= 0) return null;
    }
    if (RegExp(r'[dDsSwW]').hasMatch(escaped)) return null;
    return (codePoint: escaped.codeUnitAt(0), end: start + 2);
  }
  final first = source.codeUnitAt(start);
  if (first >= 0xd800 && first <= 0xdbff && start + 1 < source.length) {
    final second = source.codeUnitAt(start + 1);
    if (second >= 0xdc00 && second <= 0xdfff) {
      return (
        codePoint: 0x10000 + ((first - 0xd800) << 10) + second - 0xdc00,
        end: start + 2,
      );
    }
  }
  return (codePoint: first, end: start + 1);
}

int _skipClassEscape(String source, int start) {
  if (start + 1 >= source.length) return start + 1;
  final escaped = source[start + 1];
  if ((escaped == 'p' || escaped == 'P') &&
      start + 2 < source.length &&
      source[start + 2] == '{') {
    final end = source.indexOf('}', start + 3);
    if (end >= 0) return end + 1;
  }
  return start + 2;
}

const _ecmaPropertyNames = {
  'ASCII',
  'Any',
  'Assigned',
  'Alphabetic',
  'White_Space',
  'Lowercase',
  'Uppercase',
  'ID_Start',
  'ID_Continue',
  'Emoji',
  'Emoji_Presentation',
  'Emoji_Modifier',
  'Emoji_Modifier_Base',
  'Emoji_Component',
  'L',
  'Letter',
  'LC',
  'Cased_Letter',
  'Lu',
  'Uppercase_Letter',
  'Ll',
  'Lowercase_Letter',
  'Lt',
  'Titlecase_Letter',
  'Lm',
  'Modifier_Letter',
  'Lo',
  'Other_Letter',
  'M',
  'Mark',
  'Mn',
  'Nonspacing_Mark',
  'Mc',
  'Spacing_Mark',
  'Me',
  'Enclosing_Mark',
  'N',
  'Number',
  'Nd',
  'Decimal_Number',
  'Nl',
  'Letter_Number',
  'No',
  'Other_Number',
  'P',
  'Punctuation',
  'Pc',
  'Connector_Punctuation',
  'Pd',
  'Dash_Punctuation',
  'Ps',
  'Open_Punctuation',
  'Pe',
  'Close_Punctuation',
  'Pi',
  'Initial_Punctuation',
  'Pf',
  'Final_Punctuation',
  'Po',
  'Other_Punctuation',
  'S',
  'Symbol',
  'Sm',
  'Math_Symbol',
  'Sc',
  'Currency_Symbol',
  'Sk',
  'Modifier_Symbol',
  'So',
  'Other_Symbol',
  'Z',
  'Separator',
  'Zs',
  'Space_Separator',
  'Zl',
  'Line_Separator',
  'Zp',
  'Paragraph_Separator',
  'C',
  'Other',
  'Cc',
  'Control',
  'Cf',
  'Format',
  'Cs',
  'Surrogate',
  'Co',
  'Private_Use',
  'Cn',
  'Unassigned',
};

int? _characterClassEnd(String pattern, int start) {
  var escaped = false;
  var nested = 0;
  for (var index = start + 1; index < pattern.length; index++) {
    final character = pattern[index];
    if (escaped) {
      escaped = false;
    } else if (character == r'\') {
      escaped = true;
    } else if (character == '[') {
      nested++;
    } else if (character == ']') {
      if (nested > 0) {
        nested--;
        continue;
      }
      return index;
    }
  }
  return null;
}

String _translateCharacterClass(String contents, String source) {
  final (terms, operators) = _splitCharacterClassOperators(contents);
  if (operators.isNotEmpty) {
    final output = StringBuffer();
    output.write('(?=${_classTermExpression(terms.first, source)})');
    for (var index = 0; index < operators.length; index++) {
      final expression = _classTermExpression(terms[index + 1], source);
      output.write(
        operators[index] == '&&' ? '(?=$expression)' : '(?!$expression)',
      );
    }
    output.write(r'[\s\S]');
    return output.toString();
  }
  final hasNonWord = RegExp(r'\\W').hasMatch(contents);
  if (!hasNonWord) {
    final negated = contents.startsWith('^');
    final body = negated ? contents.substring(1) : contents;
    final translated = _translateClassAtoms(body);
    return negated ? '[^$translated]' : '[$translated]';
  }
  final negated = contents.startsWith('^');
  final body = negated ? contents.substring(1) : contents;
  final ordinary = body.replaceAll(r'\W', '');
  final ordinaryClass = ordinary.isEmpty
      ? null
      : '[${_translateClassAtoms(ordinary)}]';
  final nonWord = '(?!$_rustWordClass)[\\s\\S]';
  final union = ordinaryClass == null ? nonWord : '(?:$ordinaryClass|$nonWord)';
  if (!negated) return union;
  return '(?!$union)[\\s\\S]';
}

(List<String>, List<String>) _splitCharacterClassOperators(String contents) {
  final terms = <String>[];
  final operators = <String>[];
  var nested = 0;
  var escaped = false;
  var start = 0;
  for (var index = 0; index < contents.length; index++) {
    final character = contents[index];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (character == r'\') {
      escaped = true;
      continue;
    }
    if (character == '[') nested++;
    if (character == ']') nested--;
    if (nested == 0 && index + 1 < contents.length) {
      final pair = contents.substring(index, index + 2);
      if (pair == '&&' || pair == '--') {
        terms.add(contents.substring(start, index));
        operators.add(pair);
        index++;
        start = index + 1;
      }
    }
  }
  if (operators.isEmpty) return ([contents], const []);
  terms.add(contents.substring(start));
  return (terms, operators);
}

String _classTermExpression(String term, String source) {
  if (term.startsWith('[') && term.endsWith(']')) {
    return _translateCharacterClass(term.substring(1, term.length - 1), source);
  }
  return '[${_translateClassAtoms(term)}]';
}

String _translateClassAtoms(String contents) {
  final output = StringBuffer();
  var escaped = false;
  for (var index = 0; index < contents.length; index++) {
    final character = contents[index];
    if (escaped) {
      switch (character) {
        case 'd':
          output.write(r'\p{Nd}');
        case 'D':
          output.write(r'\P{Nd}');
        case 's':
          output.write(r'\p{White_Space}');
        case 'S':
          output.write(r'\P{White_Space}');
        case 'w':
          output.write(_rustWordClassContents);
        case 'W':
          output.write(r'\P{Alphabetic}\P{Mark}\P{Nd}\P{Pc}\u200c\u200d');
        case 'x':
          final token = _readClassCodePoint(contents, index - 1);
          if (token == null) {
            output
              ..write(r'\')
              ..write(character);
          } else {
            output.write(_escapeClassCodePoint(token.codePoint));
            index = token.end - 1;
          }
        default:
          output
            ..write(r'\')
            ..write(character);
      }
      escaped = false;
    } else if (character == r'\') {
      escaped = true;
    } else {
      output.write(character);
    }
  }
  if (escaped) output.write(r'\');
  return output.toString();
}

void _rejectUnsupportedRustSyntax(String pattern) {
  var inCharacterClass = false;
  var escaped = false;
  for (var index = 0; index < pattern.length; index++) {
    final character = pattern[index];
    if (escaped) {
      if (!inCharacterClass &&
          (RegExp(r'[1-9]').hasMatch(character) ||
              (character == 'k' &&
                  index + 1 < pattern.length &&
                  pattern[index + 1] == '<'))) {
        throw FormatException('backreferences are not supported by Core regex');
      }
      escaped = false;
      continue;
    }
    if (character == r'\') {
      escaped = true;
      continue;
    }
    if (character == '[') {
      inCharacterClass = true;
      continue;
    }
    if (character == ']') {
      inCharacterClass = false;
      continue;
    }
    if (!inCharacterClass &&
        character == '(' &&
        index + 2 < pattern.length &&
        pattern[index + 1] == '?' &&
        (pattern[index + 2] == '=' ||
            pattern[index + 2] == '!' ||
            (pattern[index + 2] == '<' &&
                index + 3 < pattern.length &&
                (pattern[index + 3] == '=' || pattern[index + 3] == '!')))) {
      throw FormatException('lookaround is not supported by Core regex');
    }
  }
}
