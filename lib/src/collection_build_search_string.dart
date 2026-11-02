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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Delegates one opaque search node to the host collection string builder.
///
/// The host receives the same node in a read-only singleton list. Search node
/// construction and search string generation remain host-side.
String collectionBuildSearchString<TSearchNode>(
  TSearchNode node,
  String Function(List<TSearchNode> nodes) buildSearchString,
) => buildSearchString(List<TSearchNode>.unmodifiable([node]));

/// Builds a host search string from an ordered mixture of strings and nodes.
///
/// [isSearchNode] validates opaque host nodes. [searchNodeFromString] creates
/// generated host nodes for text terms. When there is more than one node,
/// [toBackendJoiner] converts [joiner] and [groupSearchNodes] creates the host
/// group. The host backend receives the resulting node through
/// [buildSearchString]. This adapter does not implement search-node or backend
/// behavior itself.
String
collectionBuildSearchStringFromTerms<TSearchNode, TJoiner, TBackendJoiner>({
  required List<Object?> stringsOrSearchNodes,
  required TJoiner joiner,
  required bool Function(Object? value) isSearchNode,
  required TSearchNode Function(String term) searchNodeFromString,
  required TBackendJoiner Function(TJoiner joiner) toBackendJoiner,
  required TSearchNode Function(List<TSearchNode> nodes, TBackendJoiner joiner)
  groupSearchNodes,
  required String Function(TSearchNode node) buildSearchString,
}) {
  for (final value in stringsOrSearchNodes) {
    if (value is! String && !isSearchNode(value)) {
      throw ArgumentError(
        'buildSearchString expects a list containing Strings or SearchNodes: '
        '$stringsOrSearchNodes',
      );
    }
  }

  if (stringsOrSearchNodes.isEmpty) {
    throw ArgumentError('At least one entry must be provided!');
  }

  final nodes = List<TSearchNode>.unmodifiable(
    stringsOrSearchNodes.map((value) {
      if (value is String) {
        return searchNodeFromString(value);
      }
      return value as TSearchNode;
    }),
  );
  final term = nodes.length == 1
      ? nodes.single
      : groupSearchNodes(nodes, toBackendJoiner(joiner));
  return buildSearchString(term);
}
