// SPDX-License-Identifier: AGPL-3.0-or-later
// Port of Anki Core rslib/src/search/writer.rs.
import 'dart:typed_data';

import 'parser.dart';
import 'search_ast.dart';

/// Serialize a sequence of parsed nodes using Anki's canonical query syntax.
String writeNodes(List<Node> nodes) => nodes.map(writeNode).join();

/// Serialize one parsed node using Anki's canonical query syntax.
String writeNode(Node node) => switch (node) {
      BooleanNode(kind: NodeKind.and) => ' ',
      BooleanNode(kind: NodeKind.or) => ' OR ',
      NegatedNode(:final node) => '-${writeNode(node)}',
      GroupNode(:final nodes) => '(${writeNodes(nodes)})',
      Search(:final value) => _writeSearchNode(value),
    };

/// Parse and rewrite a search query in canonical syntax.
String normalizeSearch(String input) => writeNodes(parse(input));

/// Replace every node with the same search kind as [replacement], including
/// nodes nested in negations and groups, then serialize the resulting query.
String replaceSearchNode(List<Node> existing, Node replacement) {
  if (replacement is Search) {
    Node update(Node old) => switch (old) {
          NegatedNode(:final node) => NegatedNode(update(node)),
          GroupNode(:final nodes) => GroupNode(nodes.map(update).toList()),
          Search(:final value)
              when value.runtimeType == replacement.value.runtimeType =>
            replacement,
          _ => old,
        };
    return writeNodes(existing.map(update).toList());
  }
  return writeNodes(existing);
}

/// Create a deck search term with Anki wildcard and backslash escaping.
String deckSearch(String name) =>
    writeNode(Search(Deck(_escapeAnkiWildcards(name))));

String _writeSearchNode(SearchNode node) => switch (node) {
      TextSearch(:final text) => _maybeQuote(text.replaceAll(':', r'\:')),
      SingleFieldSearch(:final field, :final text, :final mode) =>
        _writeSingleField(field, text, mode),
      AddedInDays(:final days) => 'added:$days',
      EditedInDays(:final days) => 'edited:$days',
      IntroducedInDays(:final days) => 'introduced:$days',
      CardTemplate(:final kind) => _writeTemplate(kind),
      Deck(:final name) => _maybeQuote('deck:$name'),
      DeckIdsWithoutChildren(:final ids) => 'did:$ids',
      DeckIdWithChildren() => '',
      NotetypeIdSearch(:final id) => 'mid:$id',
      Notetype(:final name) => _maybeQuote('note:$name'),
      Rated(:final days, :final ease) => _writeRated(days, ease),
      Tag(:final tag, :final mode) => _writeSingleField('tag', tag, mode),
      Duplicates(:final notetypeId, :final text) =>
        _writeDuplicate(notetypeId.toString(), text),
      State(:final kind) => 'is:${_stateName(kind)}',
      Flag(:final value) => 'flag:$value',
      NoteIds(:final ids) => 'nid:$ids',
      CardIds(:final ids) => 'cid:$ids',
      Property(:final operator, :final kind) => _writeProperty(operator, kind),
      WholeCollection() => 'deck:*',
      RegexSearch(:final pattern) => _maybeQuote('re:$pattern'),
      NoCombining(:final text) => _maybeQuote('nc:$text'),
      StripClozes(:final text) => _maybeQuote('sc:$text'),
      WordBoundary(:final text) => _maybeQuote('w:$text'),
      CustomData(:final value) => _maybeQuote('has-cd:$value'),
      Preset(:final name) => _maybeQuote('preset:$name'),
    };

String _maybeQuote(String text) {
  final escaped = text.replaceAll('"', r'\"');
  return _needsQuotation(text) ? '"$escaped"' : escaped;
}

bool _needsQuotation(String text) =>
    RegExp(r'^(and|or)$|^-.| |\u3000|\(|\)', caseSensitive: false)
        .hasMatch(text);

String _writeSingleField(String field, String text, FieldSearchMode mode) {
  final prefix = switch (mode) {
    FieldSearchMode.normal => '',
    FieldSearchMode.regex => 're:',
    FieldSearchMode.noCombining => 'nc:',
  };
  final escapedText = mode == FieldSearchMode.normal &&
          (text.startsWith('re:') || text.startsWith('nc:'))
      ? text.replaceFirst(':', r'\:')
      : text;
  return _maybeQuote('${field.replaceAll(':', r'\:')}:$prefix$escapedText');
}

String _writeTemplate(TemplateKind template) => switch (template) {
      TemplateOrdinal(:final value) => 'card:${value + 1}',
      TemplateName(:final value) => _maybeQuote('card:$value'),
    };

String _writeRated(int days, RatingKind ease) => switch (ease) {
      AnswerButton(:final value) => 'rated:$days:$value',
      AnyAnswerButton() => 'rated:$days',
      ManualReschedule() => 'resched:$days',
    };

String _writeDuplicate(String notetypeId, String text) =>
    _maybeQuote('dupe:$notetypeId,${text.replaceAll(r'\', r'\\')}');

String _stateName(StateKind kind) => switch (kind) {
      StateKind.newCard => 'new',
      StateKind.review => 'review',
      StateKind.learning => 'learn',
      StateKind.due => 'due',
      StateKind.buried => 'buried',
      StateKind.userBuried => 'buried-manually',
      StateKind.schedBuried => 'buried-sibling',
      StateKind.suspended => 'suspended',
    };

String _writeProperty(String operator, PropertyKind kind) => switch (kind) {
      DueProperty(:final value) => 'prop:due$operator$value',
      IntervalProperty(:final value) => 'prop:ivl$operator$value',
      RepsProperty(:final value) => 'prop:reps$operator$value',
      LapsesProperty(:final value) => 'prop:lapses$operator$value',
      EaseProperty(:final value) => 'prop:ease$operator${_formatF32(value)}',
      PositionProperty(:final value) => 'prop:pos$operator$value',
      RatedProperty(:final days, :final rating) => switch (rating) {
          AnswerButton(:final value) => 'prop:rated$operator$days:$value',
          AnyAnswerButton() => 'prop:rated$operator$days',
          ManualReschedule() => 'prop:resched$operator$days',
        },
      StabilityProperty(:final value) => 'prop:s$operator${_formatF32(value)}',
      DifficultyProperty(:final value) => 'prop:d$operator${_formatF32(value)}',
      RetrievabilityProperty(:final value) =>
        'prop:r$operator${_formatF32(value)}',
      CustomDataNumberProperty(:final key, :final value) =>
        'prop:cdn:$key$operator${_formatF32(value)}',
      CustomDataStringProperty(:final key, :final value) =>
        _maybeQuote('prop:cds:$key$operator$value'),
    };

String _formatF32(double value) {
  final f32 = (Float32List(1)..[0] = value)[0];
  if (f32.isNaN) return 'NaN';
  if (f32 == double.infinity) return 'inf';
  if (f32 == double.negativeInfinity) return '-inf';
  if (f32 == 0) return f32.isNegative ? '-0' : '0';

  // Rust's f32 Display uses the shortest decimal that round-trips to the same
  // f32. Dart's double.toString() describes the widened binary value instead,
  // so find the shortest significant spelling that narrows back to this f32.
  var spelling = f32.toString();
  for (var precision = 1; precision <= 9; precision++) {
    final candidate = f32.toStringAsPrecision(precision);
    final parsed = double.tryParse(candidate);
    if (parsed != null && (Float32List(1)..[0] = parsed)[0] == f32) {
      spelling = candidate;
      break;
    }
  }
  return _expandExponent(spelling);
}

String _expandExponent(String spelling) {
  final lower = spelling.toLowerCase();
  final exponentAt = lower.indexOf('e');
  if (exponentAt < 0) return _trimDecimalZeros(spelling);

  final exponent = int.parse(lower.substring(exponentAt + 1));
  final mantissa = lower.substring(0, exponentAt);
  final negative = mantissa.startsWith('-');
  final unsigned = negative ? mantissa.substring(1) : mantissa;
  final point = unsigned.indexOf('.');
  final decimalPosition = (point < 0 ? unsigned.length : point) + exponent;
  final digits = unsigned.replaceAll('.', '');
  final fixed = decimalPosition <= 0
      ? '0.${'0' * -decimalPosition}$digits'
      : decimalPosition >= digits.length
          ? '$digits${'0' * (decimalPosition - digits.length)}'
          : '${digits.substring(0, decimalPosition)}.${digits.substring(decimalPosition)}';
  return _trimDecimalZeros('${negative ? '-' : ''}$fixed');
}

String _trimDecimalZeros(String value) {
  if (!value.contains('.')) return value;
  return value
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _escapeAnkiWildcards(String text) =>
    text.replaceAllMapped(RegExp(r'[\\*_]'), (match) => '\\${match[0]}');
