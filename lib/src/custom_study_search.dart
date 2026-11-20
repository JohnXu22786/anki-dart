/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_search_parser/anki_search_parser.dart'
    show SearchNodeBuilder, deckSearch, searchValueToNode, writeNode;

import 'custom_study_card_state.dart';

/// Validates the count and source-defined combined tag selection limit.
void validateCustomStudyInput({
  required int cardLimit,
  List<String> includedTags = const [],
  List<String> excludedTags = const [],
}) {
  if (cardLimit < 1) throw ArgumentError.value(cardLimit, 'cardLimit');
  if (cardLimit > 0x7fffffff) {
    throw RangeError.value(cardLimit, 'cardLimit');
  }
  if (includedTags.length + excludedTags.length > 100) {
    throw ArgumentError('No more than 100 tags may be selected.');
  }
}

/// Builds the Core search used by Custom Study's card-state or tag action.
/// Included tags form an OR group; excluded tags and the state are ANDed.
String buildCustomStudySearch({
  required String deckName,
  required CustomStudyCardState state,
  List<String> includedTags = const [],
  List<String> excludedTags = const [],
}) {
  final terms = <String>[deckSearch(deckName)];
  final stateTerm = switch (state) {
    CustomStudyCardState.NewCardsOnly => 'is:new',
    CustomStudyCardState.DueCardsOnly => 'is:due',
    CustomStudyCardState.ReviewCardsRandom => 'is:review',
    CustomStudyCardState.AllCardsRandom => null,
  };
  if (stateTerm != null) terms.add(stateTerm);
  if (includedTags.isNotEmpty) {
    final tags = includedTags.map(_tagSearch);
    terms.add('(${tags.join(' OR ')})');
  }
  terms.addAll(excludedTags.map((tag) => '-${_tagSearch(tag)}'));
  return terms.join(' ');
}

String _tagSearch(String value) =>
    writeNode(searchValueToNode(SearchNodeBuilder.fromTagName(value)));
