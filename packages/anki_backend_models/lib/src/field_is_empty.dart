// SPDX-License-Identifier: AGPL-3.0-or-later

final _emptyFieldContents = RegExp(
  r'^(?:[\u0009-\u000d\u0020\u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]|</?(?:br|div) ?/?>)*$',
  caseSensitive: false,
  unicode: true,
);

/// Returns whether field text contains only whitespace and empty BR/DIV tags.
bool fieldIsEmpty(String text) => _emptyFieldContents.hasMatch(text);
