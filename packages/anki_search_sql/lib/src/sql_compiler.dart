// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_search_parser/anki_search_parser.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

enum SearchResultType { cards, notes }

enum RequiredTable { notes, cards, cardsAndNotes, cardsOrNotes }

final RegExp _idListPattern = RegExp(r'^(\p{Nd}+,)*\p{Nd}+$', unicode: true);

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

final class UnsupportedSearchSqlNodeException extends UnsupportedError {
  UnsupportedSearchSqlNodeException(Object node)
    : super('Search SQL subset does not support ${node.runtimeType}.');
}

/// Compiles the supported source-compatible portion of Anki search SQL.
///
/// This is an incremental compiler, not complete search execution. Its current
/// subset contains boolean structure, card/note/notetype ID predicates,
/// notetype names, card template ordinals and names, tag predicates, deck IDs
/// without children, flags, and whole-collection queries. Other AST variants
/// throw [UnsupportedSearchSqlNodeException]. ID-list nodes must use
/// comma-separated decimal digits accepted by the shared parser; their exact
/// spelling is preserved.
CompiledSearchSql compileSearchSql(
  Node node, {
  SearchResultType resultType = SearchResultType.cards,
  RequiredTable requiredTables = RequiredTable.cardsOrNotes,
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
    sql: '$select${_writeNode(node, noteIdColumn, arguments)}',
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
  CardIds() || DeckIdsWithoutChildren() || Flag() => RequiredTable.cards,
  NotetypeIdSearch() || Notetype() || Tag() => RequiredTable.notes,
  CardTemplate() => RequiredTable.cardsAndNotes,
  NoteIds() || WholeCollection() => RequiredTable.cardsOrNotes,
  _ => throw UnsupportedSearchSqlNodeException(node),
};

String _writeNode(
  Node node,
  String noteIdColumn,
  List<String> arguments,
) => switch (node) {
  BooleanNode(kind: NodeKind.and) => ' and ',
  BooleanNode(kind: NodeKind.or) => ' or ',
  NegatedNode(:final node) =>
    'not ${_writeNode(node, noteIdColumn, arguments)}',
  GroupNode(:final nodes) =>
    '(${nodes.map((child) => _writeNode(child, noteIdColumn, arguments)).join()})',
  Search(value: final search) => _writeSearch(search, noteIdColumn, arguments),
};

String _writeSearch(
  SearchNode node,
  String noteIdColumn,
  List<String> arguments,
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
  WholeCollection() => 'true',
  _ => throw UnsupportedSearchSqlNodeException(node),
};

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
