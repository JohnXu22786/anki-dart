// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

enum SearchResultType { cards, notes }

enum RequiredTable { notes, cards, cardsAndNotes, cardsOrNotes }

final RegExp _idListPattern = RegExp(r'^(\p{Nd}+,)*\p{Nd}+$', unicode: true);
final BigInt _minI64 = BigInt.parse('-9223372036854775808');
final BigInt _maxI64 = BigInt.parse('9223372036854775807');
final BigInt _maxU32 = BigInt.parse('4294967295');

extension RequiredTableCombination on RequiredTable {
  RequiredTable combine(RequiredTable other) => switch ((this, other)) {
    (RequiredTable.cardsAndNotes, _) ||
    (_, RequiredTable.cardsAndNotes) => RequiredTable.cardsAndNotes,
    (RequiredTable.cardsOrNotes, final table) => table,
    (final table, RequiredTable.cardsOrNotes) => table,
    (RequiredTable.cards, RequiredTable.notes) ||
    (RequiredTable.notes, RequiredTable.cards) => RequiredTable.cardsAndNotes,
    _ => this,
  };
}

final class CompiledSearchSql {
  const CompiledSearchSql({
    required this.sql,
    required this.arguments,
    required this.requiredTable,
  });

  final String sql;
  final List<String> arguments;
  final RequiredTable requiredTable;
}

/// Timing values needed to compile time-dependent predicates deterministically.
///
/// Values use the same units and ranges as pinned Anki Core: [daysElapsed] is
/// the collection day number, [now] is Unix seconds, and [learnAheadSecs] is
/// the configured learning cutoff in seconds. [nextDayAt], when supplied, is
/// the collection's next-day rollover timestamp in Unix seconds. Day-based
/// predicates require [nextDayAt]; due-state predicates do not.
final class SearchSqlTiming {
  SearchSqlTiming({
    required this.daysElapsed,
    required this.now,
    required this.learnAheadSecs,
    this.nextDayAt,
  });

  final int daysElapsed;
  final BigInt now;
  final int learnAheadSecs;
  final BigInt? nextDayAt;
}

final class UnsupportedSearchSqlNodeException extends UnsupportedError {
  UnsupportedSearchSqlNodeException(Object node)
    : super('Search SQL subset does not support ${node.runtimeType}.');
}

/// Compiles the supported source-compatible portion of Anki search SQL.
///
/// This is an incremental compiler, not complete search execution. Its current
/// subset contains boolean structure, card/note/notetype ID predicates,
/// notetype names, card template ordinals and names, tag predicates, deck IDs
/// without children, flags, state and day predicates, custom-data predicates,
/// and whole-collection queries. Other AST variants throw
/// [UnsupportedSearchSqlNodeException]. Due state predicates require explicit
/// [SearchSqlTiming] values; day predicates additionally require
/// [SearchSqlTiming.nextDayAt]. ID-list nodes must use comma-separated decimal
/// digits accepted by the shared parser; their exact spelling is preserved.
CompiledSearchSql compileSearchSql(
  Node node, {
  SearchResultType resultType = SearchResultType.cards,
  RequiredTable requiredTables = RequiredTable.cardsOrNotes,
  SearchSqlTiming? timing,
}) {
  final itemTable = switch (resultType) {
    SearchResultType.cards => RequiredTable.cards,
    SearchResultType.notes => RequiredTable.notes,
  };
  final table = itemTable
      .combine(requiredTables)
      .combine(_requiredTableForNode(node));
  final select = switch (table) {
    RequiredTable.cards => 'select c.id from cards c where ',
    RequiredTable.notes => 'select n.id from notes n where ',
    RequiredTable.cardsAndNotes => switch (resultType) {
      SearchResultType.cards =>
        'select c.id from cards c, notes n where c.nid=n.id and ',
      SearchResultType.notes =>
        'select distinct n.id from cards c, notes n where c.nid=n.id and ',
    },
    RequiredTable.cardsOrNotes => throw StateError(
      'Result table must resolve to cards, notes, or both.',
    ),
  };
  final noteIdColumn = switch (table) {
    RequiredTable.cards => 'c.nid',
    RequiredTable.notes || RequiredTable.cardsAndNotes => 'n.id',
    RequiredTable.cardsOrNotes => throw StateError(
      'Note ID column requires a resolved result table.',
    ),
  };

  final arguments = <String>[];
  return CompiledSearchSql(
    sql: '$select${_writeNode(node, noteIdColumn, arguments, timing)}',
    arguments: arguments,
    requiredTable: table,
  );
}

RequiredTable _requiredTableForNode(Node node) => switch (node) {
  BooleanNode() => RequiredTable.cardsOrNotes,
  NegatedNode(:final node) => _requiredTableForNode(node),
  GroupNode(:final nodes) => nodes.fold(
    RequiredTable.cardsOrNotes,
    (table, child) => table.combine(_requiredTableForNode(child)),
  ),
  Search(value: final search) => _requiredTableForSearch(search),
};

RequiredTable _requiredTableForSearch(SearchNode node) => switch (node) {
  CardIds() ||
  DeckIdsWithoutChildren() ||
  Flag() ||
  State() ||
  AddedInDays() ||
  IntroducedInDays() => RequiredTable.cards,
  NotetypeIdSearch() ||
  Notetype() ||
  Tag() ||
  EditedInDays() => RequiredTable.notes,
  CustomData() ||
  Property(kind: CustomDataNumberProperty()) ||
  Property(kind: CustomDataStringProperty()) => RequiredTable.cards,
  CardTemplate() => RequiredTable.cardsAndNotes,
  NoteIds() || WholeCollection() => RequiredTable.cardsOrNotes,
  _ => throw UnsupportedSearchSqlNodeException(node),
};

String _writeNode(
  Node node,
  String noteIdColumn,
  List<String> arguments,
  SearchSqlTiming? timing,
) => switch (node) {
  BooleanNode(kind: NodeKind.and) => ' and ',
  BooleanNode(kind: NodeKind.or) => ' or ',
  NegatedNode(:final node) =>
    'not ${_writeNode(node, noteIdColumn, arguments, timing)}',
  GroupNode(:final nodes) =>
    '(${nodes.map((child) => _writeNode(child, noteIdColumn, arguments, timing)).join()})',
  Search(value: final search) => _writeSearch(
    search,
    noteIdColumn,
    arguments,
    timing,
  ),
};

String _writeSearch(
  SearchNode node,
  String noteIdColumn,
  List<String> arguments,
  SearchSqlTiming? timing,
) => switch (node) {
  CardIds(:final ids) => 'c.id in (${_validateIdList(ids)})',
  NoteIds(:final ids) => '$noteIdColumn in (${_validateIdList(ids)})',
  NotetypeIdSearch(:final id) => 'n.mid = $id',
  Notetype(:final name) => _writeNotetype(name, arguments),
  Tag(:final tag, :final mode) => _writeTag(tag, mode, arguments),
  CardTemplate(kind: final kind) => _writeTemplate(kind, arguments),
  DeckIdsWithoutChildren(:final ids) =>
    '(c.did in (${_validateIdList(ids)}) or (c.odid != 0 and '
        'c.odid in (${_validateIdList(ids)})))',
  Flag(:final value) => '(c.flags & 7) == ${_validateFlag(value)}',
  State(:final kind) => _writeState(kind, timing),
  AddedInDays(:final days) =>
    'c.id > ${_previousDayCutoffMillis(days, timing)}',
  EditedInDays(:final days) =>
    'n.mod > ${_previousDayCutoffSeconds(days, timing)}',
  IntroducedInDays(:final days) => _writeIntroduced(days, timing),
  CustomData(:final value) => _writeCustomData(value, arguments),
  Property(
    :final operator,
    kind: CustomDataNumberProperty(:final key, :final value),
  ) =>
    _writeCustomDataNumber(operator, key, value, arguments),
  Property(
    :final operator,
    kind: CustomDataStringProperty(:final key, :final value),
  ) =>
    _writeCustomDataString(operator, key, value, arguments),
  WholeCollection() => 'true',
  _ => throw UnsupportedSearchSqlNodeException(node),
};

String _writeCustomData(String key, List<String> arguments) {
  arguments.add(key);
  return 'extract_custom_data(c.data, ?) is not null';
}

String _writeCustomDataNumber(
  String operator,
  String key,
  double value,
  List<String> arguments,
) {
  _validateCustomDataOperator(operator);
  arguments.add(key);
  return 'cast(extract_custom_data(c.data, ?) as float) $operator '
      '${_formatCustomDataFloat(value)}';
}

String _writeCustomDataString(
  String operator,
  String key,
  String value,
  List<String> arguments,
) {
  _validateCustomDataOperator(operator);
  arguments
    ..add(key)
    ..add(value);
  return 'extract_custom_data(c.data, ?) $operator ?';
}

void _validateCustomDataOperator(String operator) {
  if (!const {'<=', '>=', '!=', '=', '<', '>'}.contains(operator)) {
    throw ArgumentError.value(
      operator,
      'operator',
      'Invalid property operator.',
    );
  }
}

String _formatCustomDataFloat(double value) {
  final float32 = _roundToFloat32(value);
  if (float32.isNaN) return 'NaN';
  if (float32 == double.infinity) return 'inf';
  if (float32 == double.negativeInfinity) return '-inf';

  for (var precision = 1; precision <= 9; precision++) {
    final candidate = float32.toStringAsPrecision(precision);
    final parsed = double.parse(candidate);
    if (_roundToFloat32(parsed) == float32) {
      return _expandFloatExponent(candidate);
    }
  }
  return _expandFloatExponent(float32.toString());
}

double _roundToFloat32(double value) {
  final data = ByteData(4)..setFloat32(0, value);
  return data.getFloat32(0);
}

String _expandFloatExponent(String value) {
  final exponentIndex = value.toLowerCase().indexOf('e');
  if (exponentIndex < 0) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }

  final mantissa = value.substring(0, exponentIndex);
  final exponent = int.parse(value.substring(exponentIndex + 1));
  final negative = mantissa.startsWith('-');
  final unsignedMantissa = negative ? mantissa.substring(1) : mantissa;
  final decimalIndex = unsignedMantissa.indexOf('.');
  final digits = unsignedMantissa.replaceAll('.', '');
  final point =
      (decimalIndex < 0 ? unsignedMantissa.length : decimalIndex) + exponent;
  final expanded = point <= 0
      ? '0.${'0' * -point}$digits'
      : point >= digits.length
      ? '$digits${'0' * (point - digits.length)}'
      : '${digits.substring(0, point)}.${digits.substring(point)}';
  return '${negative ? '-' : ''}$expanded';
}

String _writeState(StateKind kind, SearchSqlTiming? timing) => switch (kind) {
  StateKind.newCard => 'c.type = 0',
  StateKind.review => 'c.type in (2, 3)',
  StateKind.learning => 'c.type in (1, 3)',
  StateKind.buried => 'c.queue in (-2,-3)',
  StateKind.userBuried => 'c.queue = -3',
  StateKind.schedBuried => 'c.queue = -2',
  StateKind.suspended => 'c.queue = -1',
  StateKind.due => _writeDueState(_requireTiming(timing)),
};

String _writeDueState(SearchSqlTiming timing) {
  const maxU32 = 0xffffffff;
  final minI64 = BigInt.parse('-9223372036854775808');
  final maxI64 = BigInt.parse('9223372036854775807');
  if (timing.daysElapsed < 0 || timing.daysElapsed > maxU32) {
    throw RangeError.range(timing.daysElapsed, 0, maxU32, 'daysElapsed');
  }
  if (timing.learnAheadSecs < 0 || timing.learnAheadSecs > maxU32) {
    throw RangeError.range(timing.learnAheadSecs, 0, maxU32, 'learnAheadSecs');
  }
  if (timing.now < minI64 || timing.now > maxI64) {
    throw RangeError('now must be a signed 64-bit Unix timestamp in seconds.');
  }
  final cutoff = timing.now + BigInt.from(timing.learnAheadSecs);
  if (cutoff > maxI64) {
    throw RangeError('now + learnAheadSecs exceeds the signed 64-bit range.');
  }

  return '((c.queue in (2,3) and c.due <= ${timing.daysElapsed}) or '
      '(c.queue in (1,4) and c.due <= '
      '$cutoff))';
}

SearchSqlTiming _requireTiming(SearchSqlTiming? timing) {
  if (timing == null) {
    throw ArgumentError('state:due requires explicit SearchSqlTiming values.');
  }
  return timing;
}

String _writeIntroduced(int days, SearchSqlTiming? timing) {
  final cutoff = _previousDayCutoffMillis(days, timing);
  return '((SELECT coalesce(min(id) > $cutoff, false) FROM revlog '
      'WHERE cid = c.id AND ease != 0) AND c.id IN '
      '(SELECT cid FROM revlog WHERE id > $cutoff))';
}

BigInt _previousDayCutoffSeconds(int days, SearchSqlTiming? timing) {
  _validateDays(days);
  final nextDayAt = _requireNextDayAt(timing);
  if (nextDayAt < _minI64 || nextDayAt > _maxI64) {
    throw RangeError(
      'nextDayAt must be a signed 64-bit Unix timestamp in seconds.',
    );
  }
  final cutoff = nextDayAt - BigInt.from(days) * BigInt.from(86400);
  if (cutoff < _minI64 || cutoff > _maxI64) {
    throw RangeError('previous-day cutoff exceeds the signed 64-bit range.');
  }
  return cutoff;
}

BigInt _previousDayCutoffMillis(int days, SearchSqlTiming? timing) {
  final cutoff = _previousDayCutoffSeconds(days, timing) * BigInt.from(1000);
  if (cutoff < _minI64 || cutoff > _maxI64) {
    throw RangeError(
      'previous-day cutoff milliseconds exceed the signed 64-bit range.',
    );
  }
  return cutoff;
}

void _validateDays(int days) {
  if (days < 0 || BigInt.from(days) > _maxU32) {
    throw RangeError.range(days, 0, 0xffffffff, 'days');
  }
}

BigInt _requireNextDayAt(SearchSqlTiming? timing) {
  if (timing == null) {
    throw ArgumentError(
      'Day predicates require explicit SearchSqlTiming values.',
    );
  }
  final nextDayAt = timing.nextDayAt;
  if (nextDayAt == null) {
    throw ArgumentError('Day predicates require SearchSqlTiming.nextDayAt.');
  }
  return nextDayAt;
}

String _writeNotetype(String name, List<String> arguments) {
  final normalized = unorm.nfc(name);
  if (_isGlob(normalized)) {
    arguments.add('(?i)^${_toRegex(normalized)}\$');
    return 'n.mid in (select id from notetypes where name regexp ?)';
  }
  arguments.add(_toText(normalized));
  return 'n.mid in (select id from notetypes where name = ?)';
}

String _writeTemplate(TemplateKind kind, List<String> arguments) =>
    switch (kind) {
      TemplateOrdinal(:final value) => 'c.ord = $value',
      TemplateName(:final value) => _writeTemplateName(value, arguments),
    };

String _writeTemplateName(String name, List<String> arguments) {
  final normalized = unorm.nfc(name);
  if (_isGlob(normalized)) {
    arguments.add('(?i)^${_toRegex(normalized)}\$');
    return '(n.mid,c.ord) in (select ntid,ord from templates where name regexp ?)';
  }
  arguments.add(_toText(normalized));
  return '(n.mid,c.ord) in (select ntid,ord from templates where name = ?)';
}

String _writeTag(String tag, FieldSearchMode mode, List<String> arguments) {
  final normalized = unorm.nfc(tag);
  if (mode == FieldSearchMode.regex) {
    arguments.add('(?i)$normalized');
    return 'regexp_tags(?${arguments.length}, n.tags)';
  }
  if (normalized == 'none') return "n.tags = ''";
  if (normalized == '*') return 'true';
  if (normalized.contains(' ')) return 'false';

  final text = switch (mode) {
    FieldSearchMode.normal => normalized,
    FieldSearchMode.noCombining => _withoutCombining(normalized),
    FieldSearchMode.regex => throw StateError('Regex tags handled above.'),
  };
  final regex = _toRegex(text, wildcard: r'\S');
  arguments.add('(?i).* $regex(::| ).*');
  return mode == FieldSearchMode.normal
      ? 'n.tags regexp ?'
      : 'coalesce(process_text(n.tags, 1), n.tags) regexp ?';
}

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
final RegExp _combiningMarkPattern = RegExp(r'\p{M}', unicode: true);

String _withoutCombining(String text) =>
    unorm.nfkd(text).replaceAll(_combiningMarkPattern, '').replaceAllMapped(
      RegExp('[${_noCombiningReplacements.keys.join()}]'),
      (match) {
        return _noCombiningReplacements[match[0]]!;
      },
    );

final RegExp _globPattern = RegExp(r'(?:^|[^\\])(?:\\\\)*[*_]');
final RegExp _regexCharacterPattern = RegExp(r'\\?.', unicode: true);

bool _isGlob(String text) => _globPattern.hasMatch(text);

String _toRegex(String text, {String wildcard = '.'}) =>
    text.replaceAllMapped(_regexCharacterPattern, (match) {
      final character = match[0]!;
      return switch (character) {
        r'\\' || r'\*' => character,
        r'\_' => '_',
        '*' => '$wildcard*',
        '_' => wildcard,
        _ => RegExp.escape(character),
      };
    });

final RegExp _escapedTextPattern = RegExp(r'\\(.)');

String _toText(String text) =>
    text.replaceAllMapped(_escapedTextPattern, (match) => match[1]!);

String _validateIdList(String ids) {
  if (!_idListPattern.hasMatch(ids)) {
    throw ArgumentError.value(
      ids,
      'ids',
      'Expected comma-separated decimal IDs.',
    );
  }
  return ids;
}

int _validateFlag(int value) {
  if (value < 0 || value > 7) {
    throw RangeError.range(value, 0, 7, 'value');
  }
  return value;
}
