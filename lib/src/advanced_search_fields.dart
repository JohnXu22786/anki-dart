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
 * Source-derived from AdvancedSearchFieldsTab.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'result_type.dart';

/// One option in AnkiDroid's advanced field-search tab.
///
/// [fieldText] is the source field-node text before the backend workaround.
/// For options with raw wildcard text, [buildSearchString] adds the source
/// placeholders before calling the host serializer and replaces them globally
/// in its result afterward.
final class AdvancedSearchFieldOption {
  const AdvancedSearchFieldOption({
    required this.title,
    required this.example,
    required this.fieldText,
    this.appendBefore,
    this.appendAfter,
  });

  final String title;
  final String example;
  final String fieldText;
  final String? appendBefore;
  final String? appendAfter;

  /// Builds a host-owned field node and serializes it once through the host.
  ///
  /// The callbacks construct and serialize the host's generated search node;
  /// this method only supplies the source field name and projected text.
  String buildSearchString<TFieldNode>({
    required String fieldName,
    required TFieldNode Function(String fieldName, String text) buildFieldNode,
    required String Function(TFieldNode fieldNode) buildHostSearchString,
  }) {
    final before = appendBefore;
    final after = appendAfter;
    final usesPlaceholders = before != null || after != null;
    final text = usesPlaceholders ? '!!BEFORE!!$fieldText!!AFTER!!' : fieldText;
    final fieldNode = buildFieldNode(fieldName, text);
    final searchString = buildHostSearchString(fieldNode);

    if (!usesPlaceholders) return searchString;
    return searchString
        .replaceAll('!!BEFORE!!', before ?? '')
        .replaceAll('!!AFTER!!', after ?? '');
  }
}

/// Source-ordered advanced field-search options keyed by their result type.
///
/// AnkiDroid's backend currently mishandles the wildcard text for three
/// options. Their field-node text is therefore wrapped in exact placeholders,
/// which are replaced with the raw source strings after host serialization.
final Map<ResultType, AdvancedSearchFieldOption> advancedSearchFieldsOptions =
    Map.unmodifiable(<ResultType, AdvancedSearchFieldOption>{
      const ResultType('field'): AdvancedSearchFieldOption(
        title: 'Search a named field',
        example: 'field:*text*',
        fieldText: 'text',
        appendBefore: '*',
        appendAfter: '*',
      ),
      const ResultType('field_exact_match'): AdvancedSearchFieldOption(
        title: 'Search a named field (exact text match)',
        example: 'field:text',
        fieldText: 'text',
      ),
      const ResultType('field_empty'): AdvancedSearchFieldOption(
        title: 'Notes with an empty field',
        example: 'field:',
        fieldText: '',
      ),
      const ResultType('field_non_empty'): AdvancedSearchFieldOption(
        title: 'Notes with a non-empty field',
        example: 'field:_*',
        fieldText: '',
        appendBefore: '_*',
        appendAfter: '',
      ),
      const ResultType('field_either_empty'): AdvancedSearchFieldOption(
        title: 'Notes with a field (empty or non-empty)',
        example: 'field:*',
        fieldText: '',
        appendBefore: '*',
        appendAfter: '',
      ),
    });
