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
 * Behavioral reference: FieldFilters.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Properties accumulated while applying a template field-filter chain.
///
/// The value and transitions match the corresponding Kotlin data class. Filter
/// execution and chain construction remain responsibilities of the host.
final class FilterContext {
  const FilterContext({
    required this.isClozeNoteType,
    this.producesHtml = false,
    this.stripsAnkiPronunciationSyntax = false,
    this.isTerminal = false,
    this.producesTypeMarker = false,
  });

  final bool isClozeNoteType;
  final bool producesHtml;
  final bool stripsAnkiPronunciationSyntax;
  final bool isTerminal;
  final bool producesTypeMarker;

  FilterContext copyWith({
    bool? isClozeNoteType,
    bool? producesHtml,
    bool? stripsAnkiPronunciationSyntax,
    bool? isTerminal,
    bool? producesTypeMarker,
  }) => FilterContext(
    isClozeNoteType: isClozeNoteType ?? this.isClozeNoteType,
    producesHtml: producesHtml ?? this.producesHtml,
    stripsAnkiPronunciationSyntax:
        stripsAnkiPronunciationSyntax ?? this.stripsAnkiPronunciationSyntax,
    isTerminal: isTerminal ?? this.isTerminal,
    producesTypeMarker: producesTypeMarker ?? this.producesTypeMarker,
  );

  @override
  bool operator ==(Object other) =>
      other is FilterContext &&
      other.isClozeNoteType == isClozeNoteType &&
      other.producesHtml == producesHtml &&
      other.stripsAnkiPronunciationSyntax == stripsAnkiPronunciationSyntax &&
      other.isTerminal == isTerminal &&
      other.producesTypeMarker == producesTypeMarker;

  @override
  int get hashCode => _kotlinDataClassHashCode([
    _kotlinBooleanHashCode(isClozeNoteType),
    _kotlinBooleanHashCode(producesHtml),
    _kotlinBooleanHashCode(stripsAnkiPronunciationSyntax),
    _kotlinBooleanHashCode(isTerminal),
    _kotlinBooleanHashCode(producesTypeMarker),
  ]);

  @override
  String toString() =>
      'FilterContext(isClozeNoteType=$isClozeNoteType, '
      'producesHtml=$producesHtml, '
      'stripsAnkiPronunciationSyntax=$stripsAnkiPronunciationSyntax, '
      'isTerminal=$isTerminal, producesTypeMarker=$producesTypeMarker)';
}

/// Contract for a template field filter and its validation context effects.
///
/// This model does not execute rendering. Its defaults match AnkiDroid's
/// [FieldFilter] contract.
abstract class FieldFilter {
  const FieldFilter();

  String get name;

  bool canApplyTo(FilterContext context) => !context.isTerminal;

  FilterContext updateContext(FilterContext input) => input;

  String render() => name;

  bool get isValid => true;
}

final class TextFilter extends FieldFilter {
  const TextFilter();

  @override
  String get name => 'text';

  @override
  bool canApplyTo(FilterContext context) =>
      super.canApplyTo(context) && !context.producesHtml;
}

final class ClozeFilter extends FieldFilter {
  const ClozeFilter();

  @override
  String get name => 'cloze';

  @override
  bool canApplyTo(FilterContext context) =>
      super.canApplyTo(context) && context.isClozeNoteType;
}

final class ClozeOnlyFilter extends FieldFilter {
  const ClozeOnlyFilter();

  @override
  String get name => 'cloze-only';

  @override
  bool canApplyTo(FilterContext context) =>
      super.canApplyTo(context) && context.isClozeNoteType;
}

final class HintFilter extends FieldFilter {
  const HintFilter();

  @override
  String get name => 'hint';

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(producesHtml: true);
}

final class TypeTheAnswerFilter extends FieldFilter {
  const TypeTheAnswerFilter();

  @override
  String get name => 'type';

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(isTerminal: true, producesTypeMarker: true);
}

final class TypeTheAnswerNonCombiningFilter extends FieldFilter {
  const TypeTheAnswerNonCombiningFilter();

  @override
  String get name => 'type:nc';

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(isTerminal: true, producesTypeMarker: true);
}

final class NoSuggestFilter extends FieldFilter {
  const NoSuggestFilter();

  @override
  String get name => 'nosuggest';

  @override
  bool canApplyTo(FilterContext context) => context.producesTypeMarker;

  /// Applies the source runtime marker transformation.
  ///
  /// [fieldName] is part of the source callable contract and is retained even
  /// though the source implementation does not inspect it.
  String apply(String fieldText, String fieldName, String filterName) {
    if (filterName != name) return fieldText;
    if (!fieldText.contains('[[type:')) return fieldText;
    if (fieldText.contains('[[type:nosuggest:')) return fieldText;
    return fieldText.replaceAll('[[type:', '[[type:nosuggest:');
  }
}

final class FuriganaFilter extends FieldFilter {
  const FuriganaFilter();

  @override
  String get name => 'furigana';

  @override
  bool canApplyTo(FilterContext context) =>
      super.canApplyTo(context) && !context.stripsAnkiPronunciationSyntax;

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(stripsAnkiPronunciationSyntax: true, producesHtml: true);
}

final class KanaFilter extends FieldFilter {
  const KanaFilter();

  @override
  String get name => 'kana';

  @override
  bool canApplyTo(FilterContext context) =>
      super.canApplyTo(context) && !context.stripsAnkiPronunciationSyntax;

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(stripsAnkiPronunciationSyntax: true);
}

final class KanjiFilter extends FieldFilter {
  const KanjiFilter();

  @override
  String get name => 'kanji';

  @override
  bool canApplyTo(FilterContext context) =>
      super.canApplyTo(context) && !context.stripsAnkiPronunciationSyntax;

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(stripsAnkiPronunciationSyntax: true);
}

/// Access to the source's non-TTS builtin filter values.
///
/// `ALL`, TTS options, and template-chain registration are host-side in this
/// port unit.
abstract final class FieldFilters {
  static const text = TextFilter();
  static const cloze = ClozeFilter();
  static const clozeOnly = ClozeOnlyFilter();
  static const hint = HintFilter();
  static const type = TypeTheAnswerFilter();
  static const typeNonCombining = TypeTheAnswerNonCombiningFilter();
  static const noSuggest = NoSuggestFilter();
  static const furigana = FuriganaFilter();
  static const kana = KanaFilter();
  static const kanji = KanjiFilter();
}

int _kotlinDataClassHashCode(List<int> fields) {
  var hash = fields.first;
  for (final field in fields.skip(1)) {
    hash = _kotlinInt32(31 * hash + field);
  }
  return hash;
}

int _kotlinBooleanHashCode(bool value) => value ? 1231 : 1237;

int _kotlinInt32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
