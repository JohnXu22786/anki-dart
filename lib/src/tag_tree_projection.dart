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
 * Source-derived from TagName.kt and ManageTagsViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_whitespace.dart';

/// A validated display tag name. Blank names are rejected by [build].
final class TagName {
  const TagName._(this.value);

  final String value;

  /// Ancestor paths in order, split only at AnkiDroid's literal `::` delimiter.
  List<String> get ancestors {
    final parts = value.split('::');
    if (parts.length <= 1) {
      return const [];
    }
    final result = <String>[];
    final prefix = StringBuffer();
    for (var index = 0; index < parts.length - 1; index++) {
      if (index > 0) {
        prefix.write('::');
      }
      prefix.write(parts[index]);
      result.add(prefix.toString());
    }
    return List.unmodifiable(result);
  }

  /// Builds a tag name, replacing spaces with underscores as the UI does.
  static TagName? build(String tagName) {
    if (trimKotlinWhitespace(tagName).isEmpty) {
      return null;
    }
    return TagName._(tagName.replaceAll(' ', '_'));
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is TagName && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Recursive tag-tree data supplied by the host's collection adapter.
final class TagTreeNode {
  TagTreeNode({
    required this.name,
    required this.level,
    this.collapsed = false,
    Iterable<TagTreeNode> children = const [],
  }) : children = List.unmodifiable(children);

  final String name;
  final int level;
  final bool collapsed;
  final List<TagTreeNode> children;
}

/// A flattened tag row, with Kotlin data-class equality over its five fields.
final class TagListItemState {
  TagListItemState({
    required this.fullTag,
    required this.displayName,
    required this.level,
    required this.hasChildren,
    required this.collapsed,
  }) : _fullTagLower = fullTag.value.toLowerCase();

  final TagName fullTag;
  final String displayName;
  final int level;
  final bool hasChildren;
  final bool collapsed;
  final String _fullTagLower;

  /// Case-insensitive substring match against the cached full path.
  bool containsLowercase(String query) => _fullTagLower.contains(query);

  TagListItemState copyWith({bool? collapsed}) => TagListItemState(
    fullTag: fullTag,
    displayName: displayName,
    level: level,
    hasChildren: hasChildren,
    collapsed: collapsed ?? this.collapsed,
  );

  @override
  bool operator ==(Object other) =>
      other is TagListItemState &&
      other.fullTag == fullTag &&
      other.displayName == displayName &&
      other.level == level &&
      other.hasChildren == hasChildren &&
      other.collapsed == collapsed;

  @override
  int get hashCode =>
      Object.hash(fullTag, displayName, level, hasChildren, collapsed);
}

/// Flattens a recursive tree in preorder while preserving source fields.
List<TagListItemState> flattenTagTree(TagTreeNode root) {
  final result = <TagListItemState>[];

  void traverse(TagTreeNode node, String parentFullTag) {
    for (final child in node.children) {
      final fullTag = parentFullTag.isEmpty
          ? child.name
          : '$parentFullTag::${child.name}';
      final tagName = TagName.build(fullTag);
      if (tagName == null) {
        throw StateError('Invalid tag provided');
      }
      result.add(
        TagListItemState(
          fullTag: tagName,
          displayName: child.name,
          level: child.level - 1,
          hasChildren: child.children.isNotEmpty,
          collapsed: child.collapsed,
        ),
      );
      if (child.children.isNotEmpty) {
        traverse(child, fullTag);
      }
    }
  }

  traverse(root, '');
  return List.unmodifiable(result);
}

/// Hides descendants below collapsed parents in a preorder list.
List<TagListItemState> applyCollapsedTagVisibility(
  List<TagListItemState> allNodes,
) {
  final visible = <TagListItemState>[];
  int? skipBelowLevel;
  for (final item in allNodes) {
    if (skipBelowLevel != null && item.level > skipBelowLevel) {
      continue;
    }
    skipBelowLevel = item.collapsed && item.hasChildren ? item.level : null;
    visible.add(item);
  }
  return List.unmodifiable(visible);
}

/// Includes case-insensitive full-path matches and their ancestors in source order.
List<TagListItemState> applyTagSearchFilter(
  List<TagListItemState> allNodes,
  String searchQuery,
) {
  final queryLowercase = searchQuery.toLowerCase();
  final visibleTags = <String>{};
  final parentsWithVisibleChildren = <String>{};
  for (final item in allNodes) {
    if (item.containsLowercase(queryLowercase)) {
      visibleTags.add(item.fullTag.value);
      for (final ancestor in item.fullTag.ancestors) {
        visibleTags.add(ancestor);
        parentsWithVisibleChildren.add(ancestor);
      }
    }
  }
  return List.unmodifiable(
    allNodes
        .where((item) => visibleTags.contains(item.fullTag.value))
        .map(
          (item) =>
              item.collapsed &&
                  parentsWithVisibleChildren.contains(item.fullTag.value)
              ? item.copyWith(collapsed: false)
              : item,
        ),
  );
}
