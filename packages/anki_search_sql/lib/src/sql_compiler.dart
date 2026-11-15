// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
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

/// Field visibility supplied by the host for one notetype's unqualified
/// regex search context.
final class RegexNotetypeSearchContext {
  const RegexNotetypeSearchContext({
    required this.notetypeId,
    required this.totalFieldsInNote,
    required this.includedFieldIndices,
  });

  final BigInt notetypeId;
  final int totalFieldsInNote;
  final List<int> includedFieldIndices;
}

/// Source-derived field visibility for unqualified regex searches.
///
/// Pass `null` to [compileSearchSql] when no notetypes exclude fields from
/// search. A non-null value emits one regex clause per context in list order.
final class RegexFieldsByNotetype {
  const RegexFieldsByNotetype(this.contexts);

  final List<RegexNotetypeSearchContext> contexts;
}

/// One ordered source range of fields that can be searched. [end] is
/// exclusive, matching Rust's `Range<u32>` in the pinned writer.
final class SearchableFieldRange {
  const SearchableFieldRange(this.start, this.end);

  final int start;
  final int end;
}

/// Searchable-field layout for one notetype, resolved by the host.
final class TextNotetypeSearchContext {
  const TextNotetypeSearchContext({
    required this.notetypeId,
    required this.totalFieldsInNote,
    required this.sortFieldExcluded,
    required this.fieldRangesToSearch,
  });

  final BigInt notetypeId;
  final int totalFieldsInNote;
  final bool sortFieldExcluded;
  final List<SearchableFieldRange> fieldRangesToSearch;
}

/// Collection settings and host-resolved fields for unqualified text searches.
/// A null [fieldsByNotetype] means Core found no excluded fields and falls back
/// to searching both `sfld` and `flds` for every note.
final class SearchSqlTextContext {
  const SearchSqlTextContext({
    this.ignoreAccentsInSearch = false,
    this.fieldsByNotetype,
    this.clozeNotetypeIds = const [],
  });

  final bool ignoreAccentsInSearch;
  final List<TextNotetypeSearchContext>? fieldsByNotetype;
  final List<BigInt> clozeNotetypeIds;
}

/// A field record from one host-provided notetype snapshot.
final class SearchSqlField {
  const SearchSqlField({required this.name, this.ordinal});

  final String name;
  final int? ordinal;
}

/// Notetype field metadata used to resolve source field-name globs in Dart.
final class SearchSqlNotetypeFields {
  const SearchSqlNotetypeFields({
    required this.notetypeId,
    required this.fields,
  });

  final BigInt notetypeId;
  final List<SearchSqlField> fields;
}

/// Source snapshot used to resolve `SingleFieldSearch` field names.
///
/// The host supplies notetype and field names/ordinals; the compiler applies
/// Core's exact Unicode equality, glob escaping, and field-range rules.
final class SearchSqlFieldContext {
  const SearchSqlFieldContext(this.notetypes);

  final List<SearchSqlNotetypeFields> notetypes;
}

final class UnsupportedSearchSqlNodeException extends UnsupportedError {
  UnsupportedSearchSqlNodeException(Object node)
    : super('Search SQL subset does not support ${node.runtimeType}.');
}

/// Compiles the supported source-compatible portion of Anki search SQL.
///
/// This is an incremental compiler, not complete search execution. Its current
/// subset contains boolean structure, card/note/notetype ID predicates,
/// notetype names, card template ordinals and names, tag predicates, deck names,
/// IDs with or without children, presets, flags, state and day predicates,
/// scalar, rated and FSRS properties, custom-data predicates, regex and
/// whole-collection queries. Other
/// AST variants throw [UnsupportedSearchSqlNodeException]. Due state
/// predicates require explicit [SearchSqlTiming] values; day predicates and
/// due properties additionally require [SearchSqlTiming.nextDayAt]. ID-list
/// nodes must use comma-separated decimal digits accepted by the shared
/// parser; their exact spelling is preserved. [currentDeckName], when supplied,
/// is the current deck's native name with path components separated by U+001F.
/// [deckIdsWithChildren] supplies resolved deck ID expansions from the host;
/// an absent key means the deck could not be resolved. [deckIdsByPreset]
/// supplies exact-name preset resolution from the host; an absent key means
/// the preset did not resolve. [regexFieldsByNotetype] supplies the host's
/// source-derived notetype field visibility for regex searches; when omitted,
/// the generic `n.flds` fallback is used. [normalizeNoteText] enables NFC
/// normalization of regex patterns to match the collection configuration.
/// [textSearchContext] provides collection settings and notetype search-field
/// visibility for unqualified text predicates. When omitted, accent folding
/// is disabled and all note fields are searched.
/// [fieldSearchContext] supplies ordered notetype fields for Dart to resolve
/// field-qualified query names and Anki globs.
CompiledSearchSql compileSearchSql(
  Node node, {
  SearchResultType resultType = SearchResultType.cards,
  RequiredTable requiredTables = RequiredTable.cardsOrNotes,
  SearchSqlTiming? timing,
  String? currentDeckName,
  Map<BigInt, List<BigInt>> deckIdsWithChildren = const {},
  Map<String, List<BigInt>> deckIdsByPreset = const {},
  RegexFieldsByNotetype? regexFieldsByNotetype,
  bool normalizeNoteText = false,
  SearchSqlTextContext? textSearchContext,
  SearchSqlFieldContext? fieldSearchContext,
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
    sql:
        '$select${_writeNode(node, noteIdColumn, arguments, timing, currentDeckName, deckIdsWithChildren, deckIdsByPreset, regexFieldsByNotetype, normalizeNoteText, textSearchContext, fieldSearchContext)}',
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
  Deck() ||
  DeckIdsWithoutChildren() ||
  DeckIdWithChildren() ||
  Preset() ||
  Flag() ||
  State() ||
  AddedInDays() ||
  IntroducedInDays() => RequiredTable.cards,
  NotetypeIdSearch() ||
  Notetype() ||
  RegexSearch() ||
  WordBoundary() ||
  SingleFieldSearch() ||
  TextSearch() ||
  NoCombining() ||
  StripClozes() ||
  Tag() ||
  EditedInDays() => RequiredTable.notes,
  Rated() ||
  Property(kind: DueProperty()) ||
  Property(kind: PositionProperty()) ||
  Property(kind: IntervalProperty()) ||
  Property(kind: RepsProperty()) ||
  Property(kind: LapsesProperty()) ||
  Property(kind: EaseProperty()) ||
  Property(kind: RatedProperty()) => RequiredTable.cards,
  Property(kind: StabilityProperty()) ||
  Property(kind: DifficultyProperty()) ||
  Property(kind: RetrievabilityProperty()) => RequiredTable.cards,
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
  String? currentDeckName,
  Map<BigInt, List<BigInt>> deckIdsWithChildren,
  Map<String, List<BigInt>> deckIdsByPreset,
  RegexFieldsByNotetype? regexFieldsByNotetype,
  bool normalizeNoteText,
  SearchSqlTextContext? textSearchContext,
  SearchSqlFieldContext? fieldSearchContext,
) => switch (node) {
  BooleanNode(kind: NodeKind.and) => ' and ',
  BooleanNode(kind: NodeKind.or) => ' or ',
  NegatedNode(:final node) =>
    'not ${_writeNode(node, noteIdColumn, arguments, timing, currentDeckName, deckIdsWithChildren, deckIdsByPreset, regexFieldsByNotetype, normalizeNoteText, textSearchContext, fieldSearchContext)}',
  GroupNode(:final nodes) =>
    '(${nodes.map((child) => _writeNode(child, noteIdColumn, arguments, timing, currentDeckName, deckIdsWithChildren, deckIdsByPreset, regexFieldsByNotetype, normalizeNoteText, textSearchContext, fieldSearchContext)).join()})',
  Search(value: final search) => _writeSearch(
    search,
    noteIdColumn,
    arguments,
    timing,
    currentDeckName,
    deckIdsWithChildren,
    deckIdsByPreset,
    regexFieldsByNotetype,
    normalizeNoteText,
    textSearchContext,
    fieldSearchContext,
  ),
};

String _writeSearch(
  SearchNode node,
  String noteIdColumn,
  List<String> arguments,
  SearchSqlTiming? timing,
  String? currentDeckName,
  Map<BigInt, List<BigInt>> deckIdsWithChildren,
  Map<String, List<BigInt>> deckIdsByPreset,
  RegexFieldsByNotetype? regexFieldsByNotetype,
  bool normalizeNoteText,
  SearchSqlTextContext? textSearchContext,
  SearchSqlFieldContext? fieldSearchContext,
) => switch (node) {
  CardIds(:final ids) => 'c.id in (${_validateIdList(ids)})',
  NoteIds(:final ids) => '$noteIdColumn in (${_validateIdList(ids)})',
  Deck(:final name) => _writeDeck(name, arguments, currentDeckName),
  DeckIdWithChildren(:final id) => _writeDeckIdWithChildren(
    id,
    deckIdsWithChildren,
  ),
  Preset(:final name) => _writeDeckPreset(name, deckIdsByPreset),
  NotetypeIdSearch(:final id) => 'n.mid = $id',
  Notetype(:final name) => _writeNotetype(name, arguments),
  Tag(:final tag, :final mode) => _writeTag(tag, mode, arguments),
  SingleFieldSearch(:final field, :final text, :final mode) =>
    _writeSingleFieldSearch(
      field,
      text,
      mode,
      arguments,
      fieldSearchContext,
      normalizeNoteText,
    ),
  RegexSearch(:final pattern) => _writeRegex(
    pattern,
    arguments,
    regexFieldsByNotetype,
    normalizeNoteText,
  ),
  WordBoundary(:final text) => _writeWordBoundary(
    text,
    arguments,
    regexFieldsByNotetype,
    textSearchContext?.ignoreAccentsInSearch ?? false,
    normalizeNoteText,
  ),
  TextSearch(:final text) => _writeUnqualified(
    text,
    arguments,
    textSearchContext,
    normalizeNoteText: normalizeNoteText,
  ),
  NoCombining(:final text) => _writeUnqualified(
    text,
    arguments,
    textSearchContext,
    noCombining: true,
    normalizeNoteText: normalizeNoteText,
  ),
  StripClozes(:final text) => _writeUnqualified(
    text,
    arguments,
    textSearchContext ??
        (throw ArgumentError(
          'StripClozes requires explicit SearchSqlTextContext values.',
        )),
    stripClozes: true,
    normalizeNoteText: normalizeNoteText,
  ),
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
  Rated(:final days, :final ease) => _writeRated(
    '>',
    -BigInt.from(_validateRatedDays(days, ease)),
    ease,
    timing,
  ),
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
  Property(:final operator, kind: RatedProperty(:final days, :final rating)) =>
    _writeRated(
      operator,
      BigInt.from(_validateRatedPropertyDays(days)),
      rating,
      timing,
    ),
  Property(:final operator, kind: DueProperty(:final value)) =>
    _writeDueProperty(operator, value, timing),
  Property(:final operator, kind: PositionProperty(:final value)) =>
    _writePositionProperty(operator, value),
  Property(:final operator, kind: IntervalProperty(:final value)) =>
    _writeIntegerProperty(operator, 'ivl', value),
  Property(:final operator, kind: RepsProperty(:final value)) =>
    _writeIntegerProperty(operator, 'reps', value),
  Property(:final operator, kind: LapsesProperty(:final value)) =>
    _writeIntegerProperty(operator, 'lapses', value),
  Property(:final operator, kind: EaseProperty(:final value)) =>
    _writeEaseProperty(operator, value),
  Property(:final operator, kind: StabilityProperty(:final value)) =>
    _writeFsrsVariableProperty(operator, 's', value),
  Property(:final operator, kind: DifficultyProperty(:final value)) =>
    _writeDifficultyProperty(operator, value),
  Property(:final operator, kind: RetrievabilityProperty(:final value)) =>
    _writeRetrievabilityProperty(operator, value, timing),
  WholeCollection() => 'true',
  _ => throw UnsupportedSearchSqlNodeException(node),
};

const _propertyOperators = {'<=', '>=', '!=', '=', '<', '>'};

void _validatePropertyOperator(String operator) {
  if (!_propertyOperators.contains(operator)) {
    throw ArgumentError.value(
      operator,
      'operator',
      'Invalid property operator.',
    );
  }
}

String _writeDueProperty(String operator, int days, SearchSqlTiming? timing) {
  _validatePropertyOperator(operator);
  if (days < -0x80000000 || days > 0x7fffffff) {
    throw RangeError.range(days, -0x80000000, 0x7fffffff, 'days');
  }
  final resolvedTiming = _requirePropertyTiming(timing);
  final daysElapsed = resolvedTiming.daysElapsed;
  if (daysElapsed < 0 || daysElapsed > 0xffffffff) {
    throw RangeError.range(daysElapsed, 0, 0xffffffff, 'daysElapsed');
  }
  final nextDayAt = resolvedTiming.nextDayAt!;
  _validateI64(nextDayAt, 'nextDayAt');
  final elapsedAsI32 = (daysElapsed & 0xffffffff).toSigned(32);
  final reviewDay = (days + elapsedAsI32).toSigned(32);
  const originalDue = '(case when c.odue != 0 then c.odue else c.due end)';
  return '((c.queue in (2,3) and $originalDue $operator $reviewDay) or '
      '(c.queue in (1,4) and (($originalDue - $nextDayAt) / 86400) '
      '$operator $days))';
}

SearchSqlTiming _requirePropertyTiming(SearchSqlTiming? timing) {
  if (timing == null) {
    throw ArgumentError(
      'Due properties require explicit SearchSqlTiming values.',
    );
  }
  if (timing.nextDayAt == null) {
    throw ArgumentError('Due properties require SearchSqlTiming.nextDayAt.');
  }
  return timing;
}

String _writePositionProperty(String operator, int position) {
  _validatePropertyOperator(operator);
  _validateU32Property(position, 'position');
  return '(c.type = 0 and (case when c.odue != 0 then c.odue else c.due end) '
      '$operator $position)';
}

String _writeIntegerProperty(String operator, String column, int value) {
  _validatePropertyOperator(operator);
  _validateU32Property(value, column);
  return '$column $operator $value';
}

void _validateU32Property(int value, String name) {
  if (value < 0 || value > 0xffffffff) {
    throw RangeError.range(value, 0, 0xffffffff, name);
  }
}

String _writeEaseProperty(String operator, double ease) {
  _validatePropertyOperator(operator);
  final factor = _roundToFloat32(_roundToFloat32(ease) * 1000.0);
  final unsignedFactor = factor.isNaN || factor <= 0
      ? 0
      : factor >= 4294967296.0
      ? 0xffffffff
      : factor.toInt();
  return 'factor $operator $unsignedFactor';
}

String _writeFsrsVariableProperty(String operator, String key, double value) {
  _validatePropertyOperator(operator);
  return 'extract_fsrs_variable(c.data, \'$key\') $operator '
      '${_formatCustomDataFloat(value)}';
}

String _writeDifficultyProperty(String operator, double difficulty) {
  _validatePropertyOperator(operator);
  final float32 = _roundToFloat32(difficulty);
  final transformed = _roundToFloat32(_roundToFloat32(float32 * 9.0) + 1.0);
  return 'extract_fsrs_variable(c.data, \'d\') $operator '
      '${_formatCustomDataFloat(transformed)}';
}

String _writeRetrievabilityProperty(
  String operator,
  double value,
  SearchSqlTiming? timing,
) {
  _validatePropertyOperator(operator);
  final resolvedTiming = _requireFsrsPropertyTiming(timing);
  final daysElapsed = resolvedTiming.daysElapsed;
  if (daysElapsed < 0 || BigInt.from(daysElapsed) > _maxU32) {
    throw RangeError.range(daysElapsed, 0, 0xffffffff, 'daysElapsed');
  }
  final nextDayAt = _validateI64(resolvedTiming.nextDayAt!, 'nextDayAt');
  final now = _validateI64(resolvedTiming.now, 'now');
  return 'case when c.type = 0 then false else '
      '(extract_fsrs_retrievability(c.data, '
      'case when c.odue !=0 then c.odue else c.due end, c.ivl, '
      '$daysElapsed, $nextDayAt, $now) $operator '
      '${_formatCustomDataFloat(value)}) end';
}

SearchSqlTiming _requireFsrsPropertyTiming(SearchSqlTiming? timing) {
  if (timing == null) {
    throw ArgumentError(
      'Retrievability properties require explicit SearchSqlTiming values.',
    );
  }
  if (timing.nextDayAt == null) {
    throw ArgumentError(
      'Retrievability properties require SearchSqlTiming.nextDayAt.',
    );
  }
  return timing;
}

String _writeCustomData(String key, List<String> arguments) {
  arguments.add(key);
  return 'extract_custom_data(c.data, ?) is not null';
}

String _writeRated(
  String operator,
  BigInt days,
  RatingKind rating,
  SearchSqlTiming? timing,
) {
  if (!const {'<=', '>=', '!=', '=', '<', '>'}.contains(operator)) {
    throw ArgumentError.value(
      operator,
      'operator',
      'Invalid property operator.',
    );
  }
  final nextDayAt = _requireNextDayAt(timing);
  if (nextDayAt < _minI64 || nextDayAt > _maxI64) {
    throw RangeError(
      'nextDayAt must be a signed 64-bit Unix timestamp in seconds.',
    );
  }

  final secondsPerDay = BigInt.from(86400);
  final targetCutoff = _ratedCutoffMillis(nextDayAt + secondsPerDay * days);
  final dayBeforeCutoff = _ratedCutoffMillis(
    nextDayAt + secondsPerDay * (days - BigInt.one),
  );
  final dayBeforeTarget = switch (operator) {
    '>' => ' >= $targetCutoff',
    '>=' => ' >= $dayBeforeCutoff',
    '<' => ' < $dayBeforeCutoff',
    '<=' => ' < $targetCutoff',
    '=' =>
      ' between $dayBeforeCutoff and ${_validateI64(targetCutoff - BigInt.one, 'rated cutoff')}',
    '!=' =>
      ' not between $dayBeforeCutoff and ${_validateI64(targetCutoff - BigInt.one, 'rated cutoff')}',
    _ => throw StateError('Validated rated operator became invalid.'),
  };
  final easeClause = switch (rating) {
    AnswerButton(:final value) when value >= 1 && value <= 4 =>
      ' and ease = $value',
    AnyAnswerButton() => ' and ease > 0',
    ManualReschedule() => ' and ease = 0',
    AnswerButton(:final value) => throw RangeError.range(value, 1, 4, 'button'),
  };
  return 'c.id in (select cid from revlog where id$dayBeforeTarget$easeClause)';
}

BigInt _ratedCutoffMillis(BigInt seconds) {
  _validateI64(seconds, 'rated cutoff seconds');
  return _validateI64(seconds * BigInt.from(1000), 'rated cutoff milliseconds');
}

BigInt _validateI64(BigInt value, String name) {
  if (value < _minI64 || value > _maxI64) {
    throw RangeError('$name exceeds the signed 64-bit range.');
  }
  return value;
}

int _validateRatedDays(int days, RatingKind rating) {
  if (days < 0 || BigInt.from(days) > _maxU32) {
    throw RangeError.range(days, 0, 0xffffffff, 'days');
  }
  return days == 0 && rating is! ManualReschedule ? 1 : days;
}

int _validateRatedPropertyDays(int days) {
  if (days < -0x80000000 || days > 0x7fffffff) {
    throw RangeError.range(days, -0x80000000, 0x7fffffff, 'days');
  }
  return days;
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

String _writeDeck(
  String name,
  List<String> arguments,
  String? currentDeckName,
) {
  if (name == '*') return 'true';
  if (name == 'filtered') return 'c.odid != 0';

  final nativeRegex = name == 'current'
      ? RegExp.escape(currentDeckName ?? 'Default')
      : _nativeDeckName(_toRegex(unorm.nfc(name)));
  arguments.add('(?i)^$nativeRegex(\$|\x1f)');
  final argumentIndex = arguments.length;
  return '(c.did in (select id from decks where name regexp ?$argumentIndex) '
      'or (c.odid != 0 and c.odid in '
      '(select id from decks where name regexp ?$argumentIndex)))';
}

String _writeDeckIdWithChildren(
  Int64 id,
  Map<BigInt, List<BigInt>> deckIdsWithChildren,
) {
  // Parsing the decimal string avoids precision loss in JavaScript's number type.
  final ids = deckIdsWithChildren[BigInt.parse(id.toString())];
  return ids == null ? 'false' : 'c.did in (${ids.join(',')})';
}

String _writeDeckPreset(
  String name,
  Map<String, List<BigInt>> deckIdsByPreset,
) {
  if (!deckIdsByPreset.containsKey(name)) return 'false';
  final ids = deckIdsByPreset[name]!.join(',');
  return '(c.did in ($ids) or c.odid in ($ids))';
}

String _nativeDeckName(String name) => name
    .split('::')
    .map((component) {
      final withoutControls = component.replaceAll(
        RegExp(r'[\x00-\x1f\x7f]'),
        '',
      );
      final codePoints = withoutControls.runes.toList();
      var start = 0;
      var end = codePoints.length;
      while (start < end && _isDeckNameEdge(codePoints[start])) {
        start++;
      }
      while (end > start && _isDeckNameEdge(codePoints[end - 1])) {
        end--;
      }
      final trimmed = String.fromCharCodes(codePoints.sublist(start, end));
      return trimmed.isEmpty ? 'blank' : unorm.nfc(trimmed);
    })
    .join('\x1f');

bool _isDeckNameEdge(int codePoint) =>
    codePoint == 0x3a ||
    codePoint >= 0x9 && codePoint <= 0xd ||
    codePoint == 0x20 ||
    codePoint == 0x85 ||
    codePoint == 0xa0 ||
    codePoint == 0x1680 ||
    codePoint >= 0x2000 && codePoint <= 0x200a ||
    codePoint == 0x2028 ||
    codePoint == 0x2029 ||
    codePoint == 0x202f ||
    codePoint == 0x205f ||
    codePoint == 0x3000;

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

String _writeRegex(
  String pattern,
  List<String> arguments,
  RegexFieldsByNotetype? fieldsByNotetype,
  bool normalizeNoteText, {
  bool noCombining = false,
}) {
  var regex = normalizeNoteText ? unorm.nfc(pattern) : pattern;
  if (noCombining) regex = _withoutCombining(regex);
  arguments.add('(?i)$regex');
  final argumentIndex = arguments.length;
  final fieldsExpression = noCombining
      ? 'coalesce(process_text(n.flds, 1), n.flds)'
      : 'n.flds';
  final contexts = fieldsByNotetype?.contexts;
  if (contexts == null) {
    return '$fieldsExpression regexp ?$argumentIndex';
  }

  final clauses = contexts.map((context) {
    final fieldClause =
        context.includedFieldIndices.length == context.totalFieldsInNote
        ? '$fieldsExpression regexp ?$argumentIndex'
        : 'regexp_fields(?$argumentIndex, $fieldsExpression, '
              '${context.includedFieldIndices.join(',')})';
    return '(n.mid = ${context.notetypeId} and $fieldClause)';
  });
  return '(${clauses.join(' or ')})';
}

String _writeWordBoundary(
  String text,
  List<String> arguments,
  RegexFieldsByNotetype? fieldsByNotetype,
  bool noCombining,
  bool normalizeNoteText,
) {
  final normalized = normalizeNoteText ? unorm.nfc(text) : text;
  final regex = r'\b' + _toRegex(normalized) + r'\b';
  return _writeRegex(
    regex,
    arguments,
    fieldsByNotetype,
    false,
    noCombining: noCombining,
  );
}

String _writeUnqualified(
  String rawText,
  List<String> arguments,
  SearchSqlTextContext? context, {
  bool noCombining = false,
  bool stripClozes = false,
  bool normalizeNoteText = false,
}) {
  var text = normalizeNoteText ? unorm.nfc(rawText) : rawText;
  text = _toSql(text);
  if (noCombining || context?.ignoreAccentsInSearch == true) {
    text = _withoutCombining(text);
  }
  arguments.add('%$text%');
  final argumentIndex = arguments.length;

  final flags =
      (noCombining || context?.ignoreAccentsInSearch == true ? 1 : 0) |
      (stripClozes ? 2 : 0);
  final sfldExpression = flags == 0
      ? 'n.sfld'
      : 'coalesce(process_text(cast(n.sfld as text), $flags), n.sfld)';
  final fieldsExpression = flags == 0
      ? 'n.flds'
      : 'coalesce(process_text(n.flds, $flags), n.flds)';

  final clozeClause = stripClozes
      ? '(${(context?.clozeNotetypeIds ?? const <BigInt>[]).map((id) => 'n.mid = $id').join(' or ')}) and '
      : '';
  final fieldContexts = context?.fieldsByNotetype;
  final searchClause = fieldContexts == null
      ? "($sfldExpression like ?$argumentIndex escape '\\' or "
            "$fieldsExpression like ?$argumentIndex escape '\\')"
      : '(${fieldContexts.map((fieldContext) {
          final fieldClause = <String>[];
          for (final range in fieldContext.fieldRangesToSearch) {
            if (range.start < 0 || range.end <= range.start || range.end > fieldContext.totalFieldsInNote) {
              throw RangeError('Searchable field ranges must be non-empty and within the note field count.');
            }
            final pattern = List<String>.generate(fieldContext.totalFieldsInNote, (index) {
              if (index == range.start) return "' || ?$argumentIndex || '";
              if (range.start < index && index < range.end) return '';
              return '%';
            }).join('\u001f');
            fieldClause.add("$fieldsExpression like '$pattern' escape '\\'");
          }
          if (!fieldContext.sortFieldExcluded) {
            fieldClause.add("$sfldExpression like ?$argumentIndex escape '\\'");
          }
          return '(n.mid = ${fieldContext.notetypeId} and '
              '(${fieldClause.join(' or ')}))';
        }).join(' or ')})';

  return '$clozeClause$searchClause';
}

String _writeSingleFieldSearch(
  String rawFieldName,
  String rawText,
  FieldSearchMode mode,
  List<String> arguments,
  SearchSqlFieldContext? context,
  bool normalizeNoteText,
) {
  final fieldName = unorm.nfc(rawFieldName);
  final text = normalizeNoteText ? unorm.nfc(rawText) : rawText;
  const allFields = {'*', '_*', '*_'};
  if (allFields.contains(fieldName)) {
    if (mode == FieldSearchMode.regex) {
      arguments.add('(?i)$text');
    } else {
      arguments.add('(?is)^${_toRegex(text)}\$');
    }
    return 'regexp_fields(?${arguments.length}, n.flds)';
  }
  if (context == null) {
    throw ArgumentError(
      'SingleFieldSearch requires explicit SearchSqlFieldContext values.',
    );
  }

  final matches =
      <
        ({
          SearchSqlNotetypeFields notetype,
          List<int> indices,
          List<SearchableFieldRange> ranges,
        })
      >[];
  final matchIsGlob = _isGlob(fieldName);
  final matchPattern = matchIsGlob
      ? RegExp('^${_toRegex(fieldName)}\$', caseSensitive: false, unicode: true)
      : null;
  final exactName = matchIsGlob ? null : _toText(fieldName);
  final exactNamePattern = exactName == null
      ? null
      : RegExp(
          '^${RegExp.escape(exactName)}\$',
          caseSensitive: false,
          unicode: true,
        );
  final matchNonEmpty = const {'*', '_*', '*_'}.contains(text);
  for (final notetype in context.notetypes) {
    final indices = <int>[];
    for (final field in notetype.fields) {
      final fieldMatches = matchPattern != null
          ? matchPattern.hasMatch(field.name)
          : exactNamePattern!.hasMatch(field.name);
      if (fieldMatches) indices.add(field.ordinal ?? 0);
    }
    if (indices.isEmpty) continue;
    final ranges = mode == FieldSearchMode.regex
        ? const <SearchableFieldRange>[]
        : _collectFieldRanges(indices, join: !matchNonEmpty);
    matches.add((notetype: notetype, indices: indices, ranges: ranges));
  }
  matches.sort(
    (left, right) =>
        left.notetype.notetypeId.compareTo(right.notetype.notetypeId),
  );
  if (matches.isEmpty) return 'false';

  if (mode == FieldSearchMode.regex) {
    arguments.add('(?i)$text');
    final argumentIndex = arguments.length;
    final clauses = matches.map((match) {
      final indices = match.indices.join(', ');
      return '(n.mid = ${match.notetype.notetypeId} and '
          'regexp_fields(?$argumentIndex, n.flds, $indices))';
    });
    return '(${clauses.join(' or ')})';
  }

  var patternText = _toSql(text);
  final noCombining = mode == FieldSearchMode.noCombining;
  if (noCombining) patternText = _withoutCombining(patternText);
  arguments.add(patternText);
  final argumentIndex = arguments.length;
  final fieldsExpression = noCombining
      ? 'coalesce(process_text(n.flds, 1), n.flds)'
      : 'n.flds';
  final fieldIndexText = "' || ?$argumentIndex || '";
  final clauses = matches.map((match) {
    final fieldClauses = match.ranges.map((range) {
      final segments = List<String>.generate(match.notetype.fields.length, (
        index,
      ) {
        if (index == range.start) return fieldIndexText;
        if (range.start < index && index < range.end) return '';
        return '%';
      }).join('\u001f');
      return "$fieldsExpression like '$segments' escape '\\'";
    });
    return '(n.mid = ${match.notetype.notetypeId} and '
        '(${fieldClauses.join(' or ')}))';
  });
  return '(${clauses.join(' or ')})';
}

List<SearchableFieldRange> _collectFieldRanges(
  List<int> indices, {
  required bool join,
}) {
  if (indices.isEmpty) return const [];
  final ranges = <SearchableFieldRange>[];
  var start = indices.first;
  var end = start + 1;
  for (final index in indices.skip(1)) {
    if (join && index == end) {
      end++;
    } else {
      ranges.add(SearchableFieldRange(start, end));
      start = index;
      end = index + 1;
    }
  }
  ranges.add(SearchableFieldRange(start, end));
  return ranges;
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

final RegExp _sqlWildcardPattern = RegExp(r'\\[\\*]|[*%]');

String _toSql(String text) => text.replaceAllMapped(
  _sqlWildcardPattern,
  (match) => switch (match[0]) {
    r'\\' => r'\\',
    r'\*' => '*',
    '*' => '%',
    '%' => r'\%',
    _ => throw StateError('Unexpected SQL wildcard match.'),
  },
);

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
