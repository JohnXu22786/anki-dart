// SPDX-License-Identifier: AGPL-3.0-or-later
enum SearchErrorCode {
  misplacedAnd,
  misplacedOr,
  emptyGroup,
  unopenedGroup,
  unclosedGroup,
  emptyQuote,
  unclosedQuote,
  missingKey,
  unknownEscape,
  invalidState,
  invalidFlag,
  invalidPropProperty,
  invalidPropOperator,
  invalidNumber,
  invalidWholeNumber,
  invalidPositiveWholeNumber,
  invalidNegativeWholeNumber,
  invalidAnswerButton,
  other,
}

/// Error category and source remainder returned by Anki's search parser.
final class SearchParseException implements Exception {
  const SearchParseException(this.code,
      {this.provided, this.context, this.info, this.remaining = ''});
  final SearchErrorCode code;
  final String? provided;
  final String? context;
  final String? info;
  final String remaining;

  @override
  String toString() =>
      'SearchParseException(${code.name}, provided: $provided, context: $context, remaining: $remaining)';
}
