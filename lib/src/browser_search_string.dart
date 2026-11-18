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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: SearchRequest.kt, SearchFilters.kt, and Collection.kt
 * in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_search_parser/anki_search_parser.dart';

import 'browser_search_node_plan.dart';
import 'browser_search_request.dart';

/// Projects a structured Card Browser request to canonical Anki search text.
///
/// This builds only the source-equivalent query string. It does not validate
/// search semantics against a collection or execute a search. Invalid query
/// syntax is reported by the shared parser; unsupported persisted codes are
/// reported while building the typed plan.
String browserSearchString(BrowserSearchRequest request) {
  final plan = buildBrowserSearchNodePlan(request);
  return writeNodes([_planNode(plan)]);
}

Node _planNode(BrowserSearchNodePlan plan) => switch (plan) {
  BrowserSearchGroupPlan(:final joiner, :final children) => GroupNode([
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0)
        BooleanNode(
          joiner == BrowserSearchJoiner.and ? NodeKind.and : NodeKind.or,
        ),
      _planNode(children[index]),
    ],
  ]),
  BrowserSearchTextTermPlan(:final text) => _parsedTextNode(text),
  BrowserSearchDeckTermPlan(:final name) => Search(
    SearchNodeBuilder.fromDeckName(name),
  ),
  BrowserSearchFlagTermPlan(:final value) => Search(Flag(value.index)),
  BrowserSearchTagTermPlan(:final tag) => Search(
    SearchNodeBuilder.fromTagName(tag),
  ),
  BrowserSearchNoteTypeTermPlan(:final name) => Search(
    SearchNodeBuilder.fromNotetypeName(name),
  ),
  BrowserSearchCardStateTermPlan(:final value) => Search(
    SearchNodeBuilder.fromStateKind(switch (value) {
      BrowserSearchCardStateValue.newCard => StateKind.newCard,
      BrowserSearchCardStateValue.learning => StateKind.learning,
      BrowserSearchCardStateValue.review => StateKind.review,
      BrowserSearchCardStateValue.buried => StateKind.buried,
      BrowserSearchCardStateValue.suspended => StateKind.suspended,
    }),
  ),
};

Node _parsedTextNode(String text) {
  final nodes = parse(text);
  if (nodes.length == 1 && nodes.single is BooleanNode) {
    final code = (nodes.single as BooleanNode).kind == NodeKind.and
        ? SearchErrorCode.misplacedAnd
        : SearchErrorCode.misplacedOr;
    throw SearchParseException(code, provided: text, remaining: text);
  }
  return nodes.length == 1 ? nodes.single : GroupNode(nodes);
}
