// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

/// Find cloze-filtered field names in the first question template.
///
/// This mirrors Core's template tokenizer and `all_referenced_cloze_field_names`
/// for the replacement and conditional syntax relevant to cloze fields.
Set<String> clozeFieldNamesInFirstQuestion(String template) {
  const standardStart = '{{';
  const standardEnd = '}}';
  const alternateDirective = '{{=<% %>=}}';
  final trimmed = template.trimLeft();
  final alternate = trimmed.startsWith(alternateDirective);
  var text = alternate
      ? trimmed.replaceFirst(alternateDirective, '').trimLeft()
      : template;
  final start = alternate ? '<%' : standardStart;
  final end = alternate ? '%>' : standardEnd;
  final conditionals = <String>[];
  final fields = <String>{};
  var index = 0;

  while (index < text.length) {
    final comment = text.indexOf('<!--', index);
    final handlebar = text.indexOf(start, index);
    if (comment >= 0 && (handlebar < 0 || comment < handlebar)) {
      final commentEnd = text.indexOf('-->', comment + 4);
      // Core's comment parser fails on an unterminated comment and then keeps
      // scanning for valid template tokens inside the remaining text.
      index = commentEnd < 0 ? comment + 4 : commentEnd + 3;
      continue;
    }
    if (handlebar < 0) break;
    final close = text.indexOf(end, handlebar + start.length);
    if (close < 0) break;
    final raw = text.substring(handlebar + start.length, close);
    index = close + end.length;
    var token = raw.trim();
    while (token.startsWith('{')) {
      token = token.substring(1).trimLeft();
    }
    if (token.startsWith('#') || token.startsWith('^')) {
      conditionals.add(token.substring(1).trimLeft());
    } else if (token.startsWith('/')) {
      final name = token.substring(1).trimLeft();
      if (conditionals.isEmpty || conditionals.removeLast() != name) return {};
    } else {
      final parts = token.split(':');
      final key = parts.removeLast();
      if (parts.contains('cloze')) fields.add(key);
    }
  }
  if (conditionals.isNotEmpty) return {};
  return fields;
}
