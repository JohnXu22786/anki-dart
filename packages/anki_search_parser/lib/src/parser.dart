// SPDX-License-Identifier: AGPL-3.0-or-later
// Port of Anki Core rslib/src/search/parser.rs.
import 'dart:typed_data';

import 'search_ast.dart';
import 'search_error.dart';
import 'package:fixnum/fixnum.dart';

/// Parse an Anki search expression into its ordered AST nodes.
List<Node> parse(String input) {
  final parser = _Parser(input.trim());
  if (parser.done) return const [Search(WholeCollection())];
  final nodes = parser.groupInner();
  parser.skipSpace();
  if (!parser.done) parser.fail(SearchErrorCode.unopenedGroup);
  return nodes;
}

final class _Parser {
  _Parser(String input) : chars = input.runes.map(String.fromCharCode).toList();
  final List<String> chars;
  int at = 0;
  bool get done => at >= chars.length;
  String rest([int? from]) => chars.skip(from ?? at).join();
  String charAt([int? pos]) =>
      (pos ?? at) < chars.length ? chars[pos ?? at] : '';
  Never fail(SearchErrorCode code,
          {String? provided,
          String? context,
          String? info,
          int? remainingAt}) =>
      throw SearchParseException(code,
          provided: provided,
          context: context,
          info: info,
          remaining: rest(remainingAt));
  bool get _space => charAt() == ' ' || charAt() == '\u3000';
  void skipSpace() {
    while (_space) at++;
  }

  List<Node> groupInner() {
    final start = at;
    final nodes = <Node>[];
    while (true) {
      skipSpace();
      if (done || charAt() == ')') break;
      final node = _node();
      if (nodes.length.isEven) {
        if (node is BooleanNode && node.kind == NodeKind.and)
          fail(SearchErrorCode.misplacedAnd, remainingAt: start);
        if (node is BooleanNode && node.kind == NodeKind.or)
          fail(SearchErrorCode.misplacedOr, remainingAt: start);
      } else if (node is! BooleanNode) {
        nodes.add(const BooleanNode(NodeKind.and));
      }
      nodes.add(node);
    }
    if (nodes.isNotEmpty && nodes.last is BooleanNode) {
      fail(
          (nodes.last as BooleanNode).kind == NodeKind.and
              ? SearchErrorCode.misplacedAnd
              : SearchErrorCode.misplacedOr,
          remainingAt: start);
    }
    return nodes;
  }

  Node _node() {
    skipSpace();
    if (charAt() == '-') {
      if (charAt(at + 1).isEmpty ||
          charAt(at + 1) == ' ' ||
          charAt(at + 1) == '\u3000' ||
          charAt(at + 1) == ')') {
        return _text();
      }
      at++;
      if (charAt() == '(') return NegatedNode(_group());
      return NegatedNode(_text());
    }
    if (charAt() == '(') return _group();
    return _text();
  }

  Node _group() {
    final opening = at++;
    final items = groupInner();
    if (charAt() != ')')
      fail(SearchErrorCode.unclosedGroup, remainingAt: opening);
    at++;
    if (items.isEmpty) fail(SearchErrorCode.emptyGroup, remainingAt: opening);
    return GroupNode(items);
  }

  Node _text() {
    final tokenStart = at;
    if (charAt() == '"') {
      final term = _quoted();
      return Search(_searchNode(term));
    }
    // key:"quoted value" has distinct tokenization from a fully quoted term.
    final colon = _partialQuoteColon();
    if (colon != null) {
      final key = chars.sublist(at, colon).join();
      if (key.isEmpty) fail(SearchErrorCode.missingKey, remainingAt: at);
      at = colon + 1;
      final value = _quoted();
      return Search(_withArgument(key, value));
    }
    final term = _unquoted();
    if (term.isEmpty) {
      if (!done && charAt() == ')')
        fail(SearchErrorCode.unopenedGroup, remainingAt: at);
      fail(SearchErrorCode.other, remainingAt: tokenStart);
    }
    if (term.toLowerCase() == 'and') return const BooleanNode(NodeKind.and);
    if (term.toLowerCase() == 'or') return const BooleanNode(NodeKind.or);
    return Search(_searchNode(term));
  }

  int? _partialQuoteColon() {
    var i = at;
    while (i < chars.length) {
      final c = chars[i];
      if (c == ':')
        return i + 1 < chars.length && chars[i + 1] == '"' ? i : null;
      if (c == '"' || c == '(' || c == ')' || c == ' ' || c == '\u3000')
        return null;
      if (c == '\\') {
        if (i + 1 >= chars.length ||
            chars[i + 1] == ' ' ||
            chars[i + 1] == '\u3000') return null;
        i += 2;
      } else {
        i++;
      }
    }
    return null;
  }

  String _quoted() {
    final opening = at;
    at++; // quote
    final out = <String>[];
    while (!done) {
      final c = charAt();
      if (c == '"') {
        at++;
        if (out.isEmpty) fail(SearchErrorCode.emptyQuote, remainingAt: opening);
        return out.join();
      }
      if (c == '\\') {
        if (at + 1 >= chars.length)
          fail(SearchErrorCode.unclosedQuote, remainingAt: opening);
        out
          ..add(c)
          ..add(chars[at + 1]);
        at += 2;
      } else {
        out.add(c);
        at++;
      }
    }
    fail(SearchErrorCode.unclosedQuote, remainingAt: opening);
  }

  String _unquoted() {
    final out = <String>[];
    while (!done) {
      final c = charAt();
      if (c == '"' || c == '(' || c == ')' || c == ' ' || c == '\u3000') break;
      if (c == '\\') {
        if (at + 1 >= chars.length)
          fail(SearchErrorCode.unknownEscape, provided: '\\', remainingAt: at);
        final next = chars[at + 1];
        if (next == ' ' || next == '\u3000')
          fail(SearchErrorCode.unknownEscape, provided: '\\', remainingAt: at);
        out
          ..add(c)
          ..add(next);
        at += 2;
      } else {
        out.add(c);
        at++;
      }
    }
    return out.join();
  }

  SearchNode _searchNode(String value) {
    var escaped = false;
    for (var i = 0; i < value.length; i++) {
      if (escaped) {
        escaped = false;
        continue;
      }
      if (value[i] == '\\') {
        escaped = true;
        continue;
      }
      if (value[i] == ':') {
        if (i == 0) fail(SearchErrorCode.missingKey, remainingAt: 0);
        return _withArgument(
            _unescape(value.substring(0, i)), value.substring(i + 1));
      }
    }
    return TextSearch(_unescape(value));
  }

  SearchNode _withArgument(String key, String val) {
    switch (key.toLowerCase()) {
      case 'deck':
        return Deck(_unescape(val));
      case 'note':
        return Notetype(_unescape(val));
      case 'tag':
        return _tag(val);
      case 'card':
        return CardTemplate(_template(val));
      case 'flag':
        return Flag(_flag(val));
      case 'resched':
        return Rated(
            days: _uint(val, 'resched:'), ease: const ManualReschedule());
      case 'prop':
        return _property(val);
      case 'added':
        return AddedInDays(_uint(val, 'added:').clamp(1, 0xffffffff));
      case 'edited':
        return EditedInDays(_uint(val, 'edited:').clamp(1, 0xffffffff));
      case 'introduced':
        return IntroducedInDays(_uint(val, 'introduced:').clamp(1, 0xffffffff));
      case 'rated':
        return _rated(val);
      case 'is':
        return State(_state(val));
      case 'did':
        _checkIds(val, key);
        return DeckIdsWithoutChildren(val);
      case 'mid':
        return NotetypeIdSearch(_int64(val, 'mid:'));
      case 'nid':
        _checkIds(val, key);
        return NoteIds(val);
      case 'cid':
        _checkIds(val, key);
        return CardIds(val);
      case 're':
        return RegexSearch(_unescapeQuotes(val));
      case 'nc':
        return NoCombining(_unescape(val));
      case 'sc':
        return StripClozes(_unescape(val));
      case 'w':
        return WordBoundary(_unescape(val));
      case 'dupe':
        return _dupe(val);
      case 'has-cd':
        return CustomData(_unescape(val));
      case 'preset':
        return Preset(val);
      default:
        return _singleField(key, val);
    }
  }

  SearchNode _tag(String value) {
    if (value.startsWith('re:'))
      return Tag(
          tag: _unescapeQuotes(value.substring(3)),
          mode: FieldSearchMode.regex);
    if (value.startsWith('nc:'))
      return Tag(
          tag: _unescape(value.substring(3)),
          mode: FieldSearchMode.noCombining);
    return Tag(tag: _unescape(value), mode: FieldSearchMode.normal);
  }

  TemplateKind _template(String value) {
    final n = int.tryParse(value);
    if (n != null && !value.startsWith('-') && n >= 0 && n <= 65535)
      return TemplateOrdinal((n < 1 ? 1 : n) - 1);
    return TemplateName(_unescape(value));
  }

  int _flag(String value) {
    final n = RegExp(r'^\+?\d+$').hasMatch(value) ? int.tryParse(value) : null;
    if (n == null || n < 0 || n > 7)
      fail(SearchErrorCode.invalidFlag, remainingAt: 0);
    return n;
  }

  SearchNode _property(String clause) {
    final match = RegExp(
            r'^(ivl|due|reps|lapses|ease|pos|rated|resched|s|d|r|cdn:[\p{L}\p{N}]+|cds:[\p{L}\p{N}]+)',
            unicode: true)
        .firstMatch(clause);
    if (match == null)
      fail(SearchErrorCode.invalidPropProperty,
          provided: clause, remainingAt: 0);
    final property = match.group(0)!;
    final tail = clause.substring(match.end);
    final opMatch = RegExp(r'^(<=|>=|!=|=|<|>)').firstMatch(tail);
    if (opMatch == null)
      fail(SearchErrorCode.invalidPropOperator,
          provided: property, remainingAt: 0);
    final op = opMatch.group(0)!;
    final num = tail.substring(op.length);
    PropertyKind kind;
    switch (property) {
      case 'ease':
        kind = EaseProperty(_float(num, clause));
        break;
      case 'due':
        kind = DueProperty(_int32(num, clause));
        break;
      case 'rated':
        kind = _propRated(num, clause);
        break;
      case 'resched':
        kind = RatedProperty(
            _negativeInt32(num, clause), const ManualReschedule());
        break;
      case 'ivl':
        kind = IntervalProperty(_uint(num, clause));
        break;
      case 'reps':
        kind = RepsProperty(_uint(num, clause));
        break;
      case 'lapses':
        kind = LapsesProperty(_uint(num, clause));
        break;
      case 'pos':
        kind = PositionProperty(_uint(num, clause));
        break;
      case 's':
        kind = StabilityProperty(_float(num, clause));
        break;
      case 'd':
        kind = DifficultyProperty(_float(num, clause));
        break;
      case 'r':
        kind = RetrievabilityProperty(_float(num, clause));
        break;
      default:
        if (property.startsWith('cdn:')) {
          kind = CustomDataNumberProperty(
              key: property.substring(4), value: _float(num, clause));
        } else {
          kind =
              CustomDataStringProperty(key: property.substring(4), value: num);
        }
    }
    return Property(operator: op, kind: kind);
  }

  int _uint(String num, String context) {
    final n = RegExp(r'^\+?\d+$').hasMatch(num) ? int.tryParse(num) : null;
    if (n == null || n < 0 || n > 0xffffffff)
      fail(SearchErrorCode.invalidPositiveWholeNumber,
          context: context, provided: num, remainingAt: 0);
    return n;
  }

  int _int32(String num, String context) {
    final n = int.tryParse(num);
    if (n == null || n < -0x80000000 || n > 0x7fffffff)
      fail(SearchErrorCode.invalidWholeNumber,
          context: context, provided: num, remainingAt: 0);
    return n;
  }

  int _negativeInt32(String num, String context) {
    final n = int.tryParse(num);
    if (n == null || n < -0x80000000 || n > 0 || n > 0x7fffffff)
      fail(SearchErrorCode.invalidNegativeWholeNumber,
          context: context, provided: num, remainingAt: 0);
    return n;
  }

  double _float(String num, String context) {
    final n = double.tryParse(num);
    if (n == null)
      fail(SearchErrorCode.invalidNumber,
          context: context, provided: num, remainingAt: 0);
    return (Float32List(1)..[0] = n)[0];
  }

  BigInt _bigInt(String value, String context) {
    final n = BigInt.tryParse(value);
    if (n == null ||
        n < -(BigInt.one << 63) ||
        n > (BigInt.one << 63) - BigInt.one)
      fail(SearchErrorCode.invalidWholeNumber,
          context: context, provided: value, remainingAt: 0);
    return n;
  }

  Int64 _int64(String value, String context) =>
      _toInt64(_bigInt(value, context));

  SearchNode _rated(String value) {
    final parts = value.split(':');
    final days = _uint(parts.first, 'rated:');
    return Rated(
        days: days < 1 ? 1 : days,
        ease: _answer(parts.length > 1 ? parts[1] : null, value));
  }

  PropertyKind _propRated(String value, String context) {
    final parts = value.split(':');
    return RatedProperty(_negativeInt32(parts.first, context),
        _answer(parts.length > 1 ? parts[1] : null, context));
  }

  RatingKind _answer(String? value, String context) {
    if (value == null) return const AnyAnswerButton();
    final n = int.tryParse(value);
    if (n == null || n < 1 || n > 4)
      fail(SearchErrorCode.invalidAnswerButton,
          context: context, provided: value, remainingAt: 0);
    return AnswerButton(n);
  }

  StateKind _state(String value) => switch (value) {
        'new' => StateKind.newCard,
        'review' => StateKind.review,
        'learn' => StateKind.learning,
        'due' => StateKind.due,
        'buried' => StateKind.buried,
        'buried-manually' => StateKind.userBuried,
        'buried-sibling' => StateKind.schedBuried,
        'suspended' => StateKind.suspended,
        _ => _invalidState(value),
      };
  StateKind _invalidState(String value) {
    fail(SearchErrorCode.invalidState, provided: value, remainingAt: 0);
  }

  void _checkIds(String value, String context) {
    if (!RegExp(r'^(\d+,)*\d+$').hasMatch(value))
      fail(SearchErrorCode.other,
          info: 'expected only digits and commas in $context:', remainingAt: 0);
  }

  SearchNode _dupe(String value) {
    final comma = value.indexOf(',');
    final idText = comma < 0 ? value : value.substring(0, comma);
    final id = _int64(idText, value);
    if (comma < 0)
      fail(SearchErrorCode.other,
          info: "invalid 'dupe:' search", remainingAt: 0);
    return Duplicates(
        notetypeId: id,
        text: _unescapeQuotesAndBackslashes(value.substring(comma + 1)));
  }

  SearchNode _singleField(String key, String value) {
    if (value.startsWith('re:'))
      return SingleFieldSearch(
          field: _unescape(key),
          text: _unescapeQuotes(value.substring(3)),
          mode: FieldSearchMode.regex);
    if (value.startsWith('nc:'))
      return SingleFieldSearch(
          field: _unescape(key),
          text: _unescapeQuotes(value.substring(3)),
          mode: FieldSearchMode.noCombining);
    return SingleFieldSearch(
        field: _unescape(key),
        text: _unescape(value),
        mode: FieldSearchMode.normal);
  }
}

// fixnum is imported lazily here to keep all 64-bit values exact on JS.
Int64 _toInt64(BigInt value) => Int64.parseInt(value.toString());

String _unescapeQuotes(String value) =>
    value.contains('"') ? value.replaceAll(r'\"', '"') : value;
String _unescapeQuotesAndBackslashes(String value) =>
    value.contains('"') || value.contains('\\')
        ? value.replaceAll(r'\"', '"').replaceAll(r'\\', r'\')
        : value;
String _unescape(String value) {
  final runes = value.runes.toList();
  final out = StringBuffer();
  for (var i = 0; i < runes.length; i++) {
    final c = runes[i];
    if (c == 92) {
      if (i + 1 >= runes.length)
        throw SearchParseException(SearchErrorCode.unknownEscape,
            provided: r'\', remaining: value);
      final next = runes[i + 1];
      if (![92, 34, 58, 40, 41, 45].contains(next)) {
        // *, _, and - are valid regex/glob escapes as in the upstream grammar.
        if (![42, 95, 58, 40, 41, 45, 34].contains(next))
          throw SearchParseException(SearchErrorCode.unknownEscape,
              provided: '\\${String.fromCharCode(next)}', remaining: value);
        out
          ..writeCharCode(c)
          ..writeCharCode(next);
      } else if (next == 92) {
        out
          ..writeCharCode(c)
          ..writeCharCode(next);
      } else {
        out.writeCharCode(next);
      }
      i++;
    } else {
      out.writeCharCode(c);
    }
  }
  return out.toString();
}
