/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: SearchRequest.kt, Flag.kt, CardState.kt, and
 * Collection.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_search_request.dart';
import 'kotlin_whitespace.dart';

/// Boolean joiners used by AnkiDroid's structured search nodes.
enum BrowserSearchJoiner { and, or }

/// A headless search-node plan, before backend protobuf conversion or parsing.
sealed class BrowserSearchNodePlan {
  const BrowserSearchNodePlan();
}

/// A typed boolean group. The source collapses groups containing one node.
final class BrowserSearchGroupPlan extends BrowserSearchNodePlan {
  BrowserSearchGroupPlan._(this.joiner, List<BrowserSearchNodePlan> children)
      : children = List.unmodifiable(children);

  final BrowserSearchJoiner joiner;
  final List<BrowserSearchNodePlan> children;
}

/// A query parsed by the host backend, not a term parsed by this Dart model.
final class BrowserSearchTextTermPlan extends BrowserSearchNodePlan {
  const BrowserSearchTextTermPlan(this.text);

  final String text;
}

final class BrowserSearchDeckTermPlan extends BrowserSearchNodePlan {
  const BrowserSearchDeckTermPlan(this.name);

  final String name;
}

/// Semantic flag search values; these are not serialized AnkiDroid flag codes.
enum BrowserSearchFlagValue {
  none,
  red,
  orange,
  green,
  blue,
  pink,
  turquoise,
  purple
}

final class BrowserSearchFlagTermPlan extends BrowserSearchNodePlan {
  const BrowserSearchFlagTermPlan(this.value);

  final BrowserSearchFlagValue value;
}

final class BrowserSearchTagTermPlan extends BrowserSearchNodePlan {
  const BrowserSearchTagTermPlan(this.tag);

  final String tag;
}

final class BrowserSearchNoteTypeTermPlan extends BrowserSearchNodePlan {
  const BrowserSearchNoteTypeTermPlan(this.name);

  final String name;
}

/// Semantic card-state search values, separate from their stored integer codes.
enum BrowserSearchCardStateValue {
  newCard,
  learning,
  review,
  buried,
  suspended
}

final class BrowserSearchCardStateTermPlan extends BrowserSearchNodePlan {
  const BrowserSearchCardStateTermPlan(this.value);

  final BrowserSearchCardStateValue value;
}

/// Builds the structure produced before Anki's backend serializes a search.
///
/// This mirrors `SearchRequest.toSearchString()` through node construction.
/// It does not build the backend protobuf `SearchNode`, serialize a
/// `SearchString`, parse query syntax, or validate backend search errors.
/// Unsupported stored flag/card-state codes throw [FormatException], rather
/// than being mapped to an unrelated search value.
BrowserSearchNodePlan buildBrowserSearchNodePlan(BrowserSearchRequest request) {
  final filters = request.filters;
  final query = trimKotlinWhitespace(request.query);
  final hasFilters = filters.decks.isNotEmpty ||
      filters.flags.isNotEmpty ||
      filters.tags.isNotEmpty ||
      filters.noteTypes.isNotEmpty ||
      filters.cardStateCodes.isNotEmpty;

  final nodes = <BrowserSearchNodePlan>[];
  if (!hasFilters || query.isNotEmpty) {
    nodes.add(BrowserSearchTextTermPlan(query));
  }

  void addOrGroup<T>(List<T> values, BrowserSearchNodePlan Function(T) term) {
    if (values.isEmpty) return;
    final node =
        _groupSearchNodes(values.map(term).toList(), BrowserSearchJoiner.or);
    if (node != null) nodes.add(node);
  }

  addOrGroup(filters.decks, (deck) => BrowserSearchDeckTermPlan(deck.name));
  addOrGroup(
    filters.flags,
    (code) => BrowserSearchFlagTermPlan(_flagValue(code)),
  );
  addOrGroup(filters.tags, BrowserSearchTagTermPlan.new);
  addOrGroup(
    filters.noteTypes,
    (noteType) => BrowserSearchNoteTypeTermPlan(noteType.name),
  );
  addOrGroup(
    filters.cardStateCodes,
    (code) => BrowserSearchCardStateTermPlan(_cardStateValue(code)),
  );

  return _groupSearchNodes(nodes, BrowserSearchJoiner.and)!;
}

BrowserSearchNodePlan? _groupSearchNodes(
  List<BrowserSearchNodePlan> nodes,
  BrowserSearchJoiner joiner,
) {
  if (nodes.isEmpty) return null;
  if (nodes.length == 1) return nodes.single;
  return BrowserSearchGroupPlan._(joiner, nodes);
}

BrowserSearchFlagValue _flagValue(int code) => switch (code) {
      0 => BrowserSearchFlagValue.none,
      1 => BrowserSearchFlagValue.red,
      2 => BrowserSearchFlagValue.orange,
      3 => BrowserSearchFlagValue.green,
      4 => BrowserSearchFlagValue.blue,
      5 => BrowserSearchFlagValue.pink,
      6 => BrowserSearchFlagValue.turquoise,
      7 => BrowserSearchFlagValue.purple,
      _ => throw FormatException('Unsupported AnkiDroid flag code: $code'),
    };

BrowserSearchCardStateValue _cardStateValue(int code) => switch (code) {
      0 => BrowserSearchCardStateValue.newCard,
      1 => BrowserSearchCardStateValue.learning,
      2 => BrowserSearchCardStateValue.review,
      3 => BrowserSearchCardStateValue.buried,
      4 => BrowserSearchCardStateValue.suspended,
      _ =>
        throw FormatException('Unsupported AnkiDroid card-state code: $code'),
    };
