// SPDX-License-Identifier: AGPL-3.0-or-later

final _emptyFieldContents = RegExp(
  r'^(?:[\u0009-\u000d\u0020]|</?(?:br|div) ?/?>)*$',
  caseSensitive: false,
  unicode: true,
);

/// Returns whether field text contains only whitespace and empty BR/DIV tags.
bool fieldIsEmpty(String text) => _emptyFieldContents.hasMatch(text);
