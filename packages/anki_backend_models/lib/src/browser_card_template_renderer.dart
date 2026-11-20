// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'card.dart';
import 'card_template.dart';
import 'blake3.dart';
import 'field_is_empty.dart';
import 'html_entity_decoder.dart';
import 'note.dart';
import 'notetype.dart';

/// The rendered sides needed by the Card Browser before Core's HTML-to-text
/// conversion is applied by the host row projector.
final class BrowserCardSides {
  const BrowserCardSides._({
    this.questionHtml,
    this.answerHtml,
    this.unavailableReason,
  });

  const BrowserCardSides.available(String question, String answer)
      : this._(questionHtml: question, answerHtml: answer);

  const BrowserCardSides.unavailable(String reason)
      : this._(unavailableReason: reason);

  final String? questionHtml;
  final String? answerHtml;
  final String? unavailableReason;

  bool get isAvailable => unavailableReason == null;
}

/// Renders a selected card with Anki Core's browser template formats.
///
/// This is platform-neutral. It returns an explicit unavailable result for a
/// Core-reported template error, missing field, or unsupported template
/// feature. Syntax that Core tokenizes as literal text is preserved verbatim.
final class BrowserCardTemplateRenderer {
  const BrowserCardTemplateRenderer();

  BrowserCardSides render({
    required Note note,
    required Card card,
    required Notetype notetype,
    String deckName = '(Deck)',
    bool useBrowserFormats = true,
  }) {
    final template = _templateFor(notetype, card);
    if (template == null) {
      return const BrowserCardSides.unavailable('missing-template');
    }
    if (note.fields.length < notetype.fields.length) {
      return const BrowserCardSides.unavailable('missing-note-field');
    }

    final fields = <String, String>{};
    for (var i = 0; i < notetype.fields.length; i++) {
      fields[notetype.fields[i].name] = note.fields[i];
    }
    void addSpecial(String name, String value) =>
        fields.putIfAbsent(name, () => value);
    addSpecial('Tags', note.tags.join(' '));
    addSpecial('Type', notetype.name);
    addSpecial('Deck', deckName);
    addSpecial('Subdeck', deckName.split('::').last);
    addSpecial('Card', template.name);
    addSpecial('CardID', card.id.toString());
    addSpecial('CardFlag', 'flag${card.flags}');
    fields.putIfAbsent('c${card.templateIdx + 1}', () => '1');

    final nonempty = <String>{
      for (final entry in fields.entries)
        if (!fieldIsEmpty(entry.value)) entry.key,
    };
    try {
      final question = _renderSide(
        useBrowserFormats
            ? _browserFormat(
                template.config.qFormatBrowser, template.config.qFormat)
            : template.config.qFormat,
        fields,
        nonempty,
        card.templateIdx,
        null,
      );
      if (notetype.isCloze &&
          !_containsClozeOrdinal(fields.values, card.templateIdx + 1)) {
        return const BrowserCardSides.unavailable('missing-cloze');
      }
      final answer = _renderSide(
        useBrowserFormats
            ? _browserFormat(
                template.config.aFormatBrowser, template.config.aFormat)
            : template.config.aFormat,
        fields,
        nonempty,
        card.templateIdx,
        '',
      );
      return BrowserCardSides.available(
        _prettifyAv(question),
        _prettifyAv(answer),
      );
    } on _TemplateFailure catch (error) {
      return BrowserCardSides.unavailable(error.reason);
    }
  }

  CardTemplate? _templateFor(Notetype notetype, Card card) {
    if (notetype.isCloze) {
      return notetype.templates.isEmpty ? null : notetype.templates.first;
    }
    return card.templateIdx >= 0 && card.templateIdx < notetype.templates.length
        ? notetype.templates[card.templateIdx]
        : null;
  }
}

/// Whether a parsed question template can render nonempty content from
/// [nonemptyFields], matching Core's `ParsedTemplate::renders_with_fields`.
/// Literal text alone does not make a template render a card.
bool templateRendersWithFields(
  String template,
  Set<String> nonemptyFields,
) {
  const alternateDirective = '{{=<% %>=}}';
  var source = template;
  var alternate = false;
  if (template.trimLeft().startsWith(alternateDirective)) {
    source = template.trimLeft();
    while (source.startsWith(alternateDirective)) {
      source = source.substring(alternateDirective.length);
    }
    alternate = true;
  }
  try {
    final nodes = _parse(
      _tokenize(source, alternate ? '<%' : '{{', alternate ? '%>' : '}}'),
    );
    return _nodesRenderContent(nodes, nonemptyFields);
  } on _TemplateFailure {
    return false;
  }
}

bool _nodesRenderContent(List<_Node> nodes, Set<String> nonemptyFields) {
  for (final node in nodes) {
    switch (node.kind) {
      case _NodeKind.text:
        break;
      case _NodeKind.replacement:
        if (nonemptyFields.contains(node.value)) return true;
        break;
      case _NodeKind.conditional:
        final active = nonemptyFields.contains(node.value);
        final shouldRender = node.negated ? !active : active;
        if (shouldRender &&
            _nodesRenderContent(node.children, nonemptyFields)) {
          return true;
        }
        break;
    }
  }
  return false;
}

String _browserFormat(String browser, String standard) =>
    browser.isEmpty ? standard : browser;

bool _containsClozeOrdinal(Iterable<String> fields, int ordinal) {
  final opening = RegExp(r'\{\{c([0-9]+)::');
  for (final field in fields) {
    for (final match in opening.allMatches(field)) {
      if (int.tryParse(match[1]!) == ordinal &&
          field.indexOf('}}', match.end) >= 0) {
        return true;
      }
    }
  }
  return false;
}

String _renderSide(
  String template,
  Map<String, String> fields,
  Set<String> nonempty,
  int cardOrdinal,
  String? frontSide,
) {
  const alternateDirective = '{{=<% %>=}}';
  var source = template;
  var alternate = false;
  if (template.trimLeft().startsWith(alternateDirective)) {
    source = template.trimLeft();
    while (source.startsWith(alternateDirective)) {
      source = source.substring(alternateDirective.length);
    }
    alternate = true;
  }
  final start = alternate ? '<%' : '{{';
  final end = alternate ? '%>' : '}}';
  final tokens = _tokenize(source, start, end);
  final nodes = _parse(tokens);
  return _renderNodes(nodes, fields, nonempty, cardOrdinal, frontSide);
}

List<_Token> _tokenize(String source, String start, String end) {
  final tokens = <_Token>[];
  var cursor = 0;
  while (cursor < source.length) {
    final tagAt = source.indexOf(start, cursor);
    final commentAt = source.indexOf('<!--', cursor);
    final next = [tagAt, commentAt].where((index) => index >= 0).fold<int?>(
          null,
          (best, index) => best == null || index < best ? index : best,
        );
    if (next == null) {
      tokens.add(_Token.text(source.substring(cursor)));
      break;
    }
    if (next > cursor) tokens.add(_Token.text(source.substring(cursor, next)));
    if (next == commentAt) {
      final closing = source.indexOf('-->', next + 4);
      if (closing < 0) {
        // Core keeps an unclosed comment opener as text, then resumes scanning
        // for handlebars and any later well-formed comments.
        tokens.add(_Token.text(source.substring(next, next + 4)));
        cursor = next + 4;
        continue;
      }
      tokens.add(_Token.comment(source.substring(next, closing + 3)));
      cursor = closing + 3;
      continue;
    }
    final closing = source.indexOf(end, next + start.length);
    if (closing < 0) {
      tokens.add(_Token.text(source.substring(next)));
      break;
    }
    // Core's classify_handle() strips leading opening braces before trimming.
    final content = source
        .substring(next + start.length, closing)
        .replaceFirst(RegExp(r'^\{+'), '')
        .trim();
    if (content.startsWith('#')) {
      tokens.add(_Token.open(content.substring(1).trimLeft(), false));
    } else if (content.startsWith('^')) {
      tokens.add(_Token.open(content.substring(1).trimLeft(), true));
    } else if (content.startsWith('/')) {
      tokens.add(_Token.close(content.substring(1).trimLeft()));
    } else {
      tokens.add(_Token.replacement(content));
    }
    cursor = closing + end.length;
  }
  return tokens;
}

List<_Node> _parse(List<_Token> tokens) {
  var cursor = 0;
  List<_Node> parseChildren(String? openKey) {
    final result = <_Node>[];
    while (cursor < tokens.length) {
      final token = tokens[cursor++];
      switch (token.kind) {
        case _TokenKind.text:
          result.add(_Node.text(token.value));
        case _TokenKind.comment:
          result.add(_Node.text(token.value));
        case _TokenKind.replacement:
          final parts = token.value.split(':');
          result.add(
            _Node.replacement(
              parts.last,
              parts.take(parts.length - 1).toList(),
            ),
          );
        case _TokenKind.open:
          result.add(
            _Node.conditional(
              token.value,
              token.negated,
              parseChildren(token.value),
            ),
          );
        case _TokenKind.close:
          if (openKey == null || token.value != openKey) {
            throw const _TemplateFailure('conditional-close-mismatch');
          }
          return result;
      }
    }
    if (openKey != null) throw const _TemplateFailure('conditional-not-closed');
    return result;
  }

  return parseChildren(null);
}

String _renderNodes(
  List<_Node> nodes,
  Map<String, String> fields,
  Set<String> nonempty,
  int ordinal,
  String? frontSide,
) {
  final output = StringBuffer();
  for (final node in nodes) {
    switch (node.kind) {
      case _NodeKind.text:
        output.write(node.value);
      case _NodeKind.replacement:
        if (node.value == 'FrontSide') {
          output.write(frontSide ?? '');
          continue;
        }
        // Core's partial browser renderer accepts a filtered empty field name
        // as an empty Replacement; browser_table later projects its empty text.
        if (node.value.isEmpty && node.filters.isNotEmpty) continue;
        final value = fields[node.value];
        if (value == null) throw const _TemplateFailure('unknown-field');
        output.write(
          _applyFilters(value, node.filters, node.value, ordinal, frontSide),
        );
      case _NodeKind.conditional:
        final knownCloze = _isClozeConditional(node.value);
        if (!fields.containsKey(node.value) && !knownCloze) {
          throw const _TemplateFailure('unknown-conditional-field');
        }
        final active = nonempty.contains(node.value);
        final show = node.negated ? !active : active;
        final rendered = _renderNodes(
          node.children,
          fields,
          nonempty,
          ordinal,
          frontSide,
        );
        if (show) output.write(rendered);
    }
  }
  return output.toString();
}

bool _isClozeConditional(String key) {
  if (!key.startsWith('c')) return false;
  final ordinal = int.tryParse(key.substring(1));
  return ordinal != null && ordinal >= 0 && ordinal <= 0xffffffff;
}

String _applyFilters(
  String input,
  List<String> filters,
  String field,
  int ordinal,
  String? frontSide,
) {
  var value = input;
  var names = filters.reversed.toList();
  if (names.length == 2 && names[0] == 'cloze' && names[1] == 'type') {
    names = ['type-cloze'];
  } else if (names.length == 2 && names[0] == 'nc' && names[1] == 'type') {
    names = ['type-nc'];
  } else if (names.isNotEmpty && names.last == 'type') {
    names = ['type'];
  }
  for (final filter in names) {
    switch (filter) {
      case '':
        break;
      case 'text':
        value = decodeAnkiHtmlEntities(
          value.replaceAll(
            RegExp(
              r'<!--.*?-->|<style.*?>.*?</style>|<script.*?>.*?</script>|<.*?>',
              dotAll: true,
              caseSensitive: false,
            ),
            '',
          ),
        );
      case 'kanji':
        value = _furigana(value, 1);
      case 'kana':
        value = _furigana(value, 2);
      case 'furigana':
        value = _furigana(value, 0);
      case 'hint':
        value = _hintFilter(value, field);
      case 'cloze':
        value = _renderClozes(value, ordinal + 1, frontSide == null, true);
      case 'cloze-only':
        value = _renderClozes(value, ordinal + 1, frontSide == null, false);
      case 'type':
        value = '[[' + 'type:$field' + ']]';
      case 'type-cloze':
        value = '[[type:cloze:$field]]';
      case 'type-nc':
        value = '[[type:nc:$field]]';
      default:
        if (filter.startsWith('tts ')) {
          value = '[anki:tts lang=${filter.substring(4)}]$value[/anki:tts]';
        } else {
          // Browser partial rendering stops at the first custom filter and
          // passes the current text to the caller unchanged.
          return value;
        }
      // Core's browser partial renderer leaves unknown filters for its caller;
      // browser_table converts the current text node and ignores the filter.
    }
  }
  return value;
}

String _furigana(String value, int mode) =>
    value.replaceAll('&nbsp;', ' ').replaceAllMapped(
      RegExp(r' ?([^ >]+?)\[(.+?)\]'),
      (match) {
        if (match[2]!.startsWith('sound:')) return match[0]!;
        return switch (mode) {
          1 => match[1]!,
          2 => match[2]!,
          _ => '<ruby><rb>${match[1]}</rb><rt>${match[2]}</rt></ruby>',
        };
      },
    );

String _hintFilter(String value, String field) {
  if (value.trim().isEmpty) return value;
  final id = blake3Prefix64Hex('$value$field');
  return '''
<a class=hint href="#"
onclick="this.style.display='none';
document.getElementById('hint$id').style.display='block';
return false;" draggable=false>
$field</a>
<div id="hint$id" class=hint style="display: none">$value</div>
''';
}

String _renderClozes(String input, int ordinal, bool question, bool withHtml) {
  if (input.contains('<anki-mathjax') && input.contains('{{c$ordinal::')) {
    throw const _TemplateFailure('unsupported-mathjax-cloze');
  }
  if (input.contains('{{c$ordinal::image-occlusion:')) {
    throw const _TemplateFailure('unsupported-image-occlusion');
  }
  if (RegExp(r'\{\{c\d+(?:,\d+)+::').hasMatch(input) ||
      _containsNestedCloze(input)) {
    throw const _TemplateFailure('unsupported-complex-cloze');
  }
  final matches = RegExp(
    r'\{\{c(\d+)::(.*?)(?:::(.*?))?\}\}',
    dotAll: true,
  ).allMatches(input).toList();
  if (matches.isEmpty ||
      !matches.any((match) => int.tryParse(match[1]!) == ordinal)) return '';
  if (!withHtml) {
    return matches
        .where((match) => int.tryParse(match[1]!) == ordinal)
        .map((match) => question ? (match[3] ?? '...') : match[2]!)
        .join(', ');
  }
  final output = StringBuffer();
  var cursor = 0;
  for (final match in matches) {
    output.write(input.substring(cursor, match.start));
    final index = int.tryParse(match[1]!) ?? 0;
    final text = match[2]!;
    final hint = match[3] ?? '...';
    if (withHtml && question && index == ordinal) {
      output.write(
        '<span class="cloze" data-cloze="${_escapeAttribute(text)}" data-ordinal="$index">[$hint]</span>',
      );
    } else {
      final active = index == ordinal;
      output.write(
        '<span class="cloze${active ? '' : '-inactive'}" data-ordinal="$index">$text</span>',
      );
    }
    cursor = match.end;
  }
  output.write(input.substring(cursor));
  return output.toString();
}

bool _containsNestedCloze(String input) {
  final tokens = RegExp(r'\{\{c\d+(?:,\d+)*::|\}\}').allMatches(input);
  var depth = 0;
  for (final token in tokens) {
    if (token[0]!.startsWith('{{c')) {
      if (depth > 0) return true;
      depth++;
    } else if (depth > 0) {
      depth--;
    }
  }
  return false;
}

String _escapeAttribute(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _prettifyAv(String value) {
  return value.replaceAllMapped(
    RegExp(
      r'\[anki:tts(?=\s|\])((?:"[^"]*"|[^\]])*)\](.*?)\[/anki:tts\]|'
      r'\[anki:([^\]\s]+)((?:"[^"]*"|[^\]])*)\](.*?)\[/anki:\3\]|'
      r'\[sound:([^\]]+)\]',
      dotAll: true,
    ),
    (match) {
      if (match[1] != null) return '💬${match[2]}💬';
      if (match[3] != null) {
        final options = _formatDirectiveOptions(match[4]!);
        if (options == null) return match[0]!;
        final name = match[3]!;
        return '[anki:$name$options]${match[5]}[/anki:$name]';
      }
      return '🔉${match[6]}🔉';
    },
  );
}

String? _formatDirectiveOptions(String source) {
  final options = <(String, String)>[];
  var cursor = 0;
  bool isWhitespace(int codeUnit) =>
      codeUnit == 0x20 || (codeUnit >= 0x09 && codeUnit <= 0x0d);

  while (cursor < source.length) {
    while (cursor < source.length && isWhitespace(source.codeUnitAt(cursor))) {
      cursor++;
    }
    if (cursor == source.length) break;

    final keyStart = cursor;
    while (cursor < source.length &&
        !isWhitespace(source.codeUnitAt(cursor)) &&
        source[cursor] != '=') {
      cursor++;
    }
    if (cursor == keyStart ||
        cursor == source.length ||
        source[cursor] != '=') {
      return null;
    }
    final key = source.substring(keyStart, cursor);
    cursor++;

    late final String value;
    if (cursor < source.length && source[cursor] == '"') {
      final valueStart = ++cursor;
      final closingQuote = source.indexOf('"', cursor);
      if (closingQuote < 0) return null;
      value = source.substring(valueStart, closingQuote);
      cursor = closingQuote + 1;
    } else {
      final valueStart = cursor;
      while (cursor < source.length &&
          !isWhitespace(source.codeUnitAt(cursor)) &&
          source[cursor] != '"') {
        cursor++;
      }
      value = source.substring(valueStart, cursor);
    }
    options.add((key, value));
  }

  final formatted = options.map((option) {
    final (key, value) = option;
    return value.contains(RegExp(r'[\] \t\r\n]'))
        ? ' $key="$value"'
        : ' $key=$value';
  }).join();
  return formatted;
}

enum _TokenKind { text, comment, replacement, open, close }

final class _Token {
  const _Token(this.kind, this.value, this.negated);
  const _Token.text(String value) : this(_TokenKind.text, value, false);
  const _Token.comment(String value) : this(_TokenKind.comment, value, false);
  const _Token.replacement(String value)
      : this(_TokenKind.replacement, value, false);
  const _Token.open(String value, bool negated)
      : this(_TokenKind.open, value, negated);
  const _Token.close(String value) : this(_TokenKind.close, value, false);
  final _TokenKind kind;
  final String value;
  final bool negated;
}

enum _NodeKind { text, replacement, conditional }

final class _Node {
  const _Node(this.kind, this.value, this.filters, this.children, this.negated);
  const _Node.text(String value)
      : this(_NodeKind.text, value, const [], const [], false);
  const _Node.replacement(String value, List<String> filters)
      : this(_NodeKind.replacement, value, filters, const [], false);
  const _Node.conditional(String value, bool negated, List<_Node> children)
      : this(_NodeKind.conditional, value, const [], children, negated);
  final _NodeKind kind;
  final String value;
  final List<String> filters;
  final List<_Node> children;
  final bool negated;
}

final class _TemplateFailure implements Exception {
  const _TemplateFailure(this.reason);
  final String reason;
}
