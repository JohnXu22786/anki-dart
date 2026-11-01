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

import 'insert_field_dialog_selection.dart' show FieldName;
import 'java_float_format.dart'
    show javaFloatToString, kotlinFloatHashCode, float32Bits, float32Value;
import 'kotlin_string_hash_code.dart' show kotlinStringHashCode;

/// Properties accumulated while applying a template field-filter chain.
///
/// The value and transitions match the corresponding Kotlin data class. Filter
/// execution remains the host's responsibility.
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

/// Source options for AnkiDroid's `tts` field filter.
///
/// Nullable values are preserved as supplied, and [voices] remains the original
/// list reference so its structural equality and hash reflect later mutations.
final class TextToSpeechOptions {
  const TextToSpeechOptions({this.language, this.voices, double? speed})
    : _speed = speed;

  final String? language;
  final List<String>? voices;
  final double? _speed;

  /// The source Float value, narrowed to the JVM binary32 representation.
  double? get speed => _speed == null ? null : float32Value(_speed);

  bool get isValid => language != null && language!.isNotEmpty;

  String render() {
    final output = <String>[];
    if (language != null) output.add('lang=$language');
    if (voices != null) output.add('voices=${voices!.join(',')}');
    final value = speed;
    if (value != null) output.add('speed=${javaFloatToString(value)}');
    if (output.isEmpty) return '';
    return ' ${output.join(' ')}';
  }

  @override
  bool operator ==(Object other) =>
      other is TextToSpeechOptions &&
      other.language == language &&
      _stringListsEqual(other.voices, voices) &&
      _floatValuesEqual(other.speed, speed);

  @override
  int get hashCode => _kotlinDataClassHashCode([
    language == null ? 0 : kotlinStringHashCode(language!),
    voices == null ? 0 : _kotlinStringListHashCode(voices!),
    speed == null ? 0 : kotlinFloatHashCode(speed!),
  ]);

  @override
  String toString() {
    final value = speed;
    final renderedSpeed = value == null ? 'null' : javaFloatToString(value);
    return 'TextToSpeechOptions(language=$language, voices=$voices, '
        'speed=$renderedSpeed)';
  }
}

/// AnkiDroid's terminal text-to-speech field filter.
final class TextToSpeechFilter extends FieldFilter {
  const TextToSpeechFilter({this.options = const TextToSpeechOptions()});

  final TextToSpeechOptions options;

  @override
  String get name => 'tts';

  @override
  bool get isValid => options.isValid;

  @override
  FilterContext updateContext(FilterContext input) =>
      input.copyWith(isTerminal: true);

  @override
  String render() => '$name${options.render()}';

  @override
  bool operator ==(Object other) =>
      other is TextToSpeechFilter && other.options == options;

  @override
  int get hashCode => options.hashCode;

  @override
  String toString() => 'TextToSpeechFilter(options=$options)';
}

/// Access to the source's builtin filter values.
abstract final class FieldFilters {
  static const text = TextFilter();
  static const cloze = ClozeFilter();
  static const clozeOnly = ClozeOnlyFilter();
  static const hint = HintFilter();
  static const type = TypeTheAnswerFilter();
  static const typeNonCombining = TypeTheAnswerNonCombiningFilter();
  static const noSuggest = NoSuggestFilter();
  static const textToSpeech = TextToSpeechFilter();
  static const furigana = FuriganaFilter();
  static const kana = KanaFilter();
  static const kanji = KanjiFilter();

  /// Builtin filters in the exact source registration order.
  static final List<FieldFilter> ALL = List.unmodifiable([
    text,
    cloze,
    clozeOnly,
    hint,
    type,
    typeNonCombining,
    noSuggest,
    textToSpeech,
    furigana,
    kana,
    kanji,
  ]);
}

/// An immutable chain of field filters validated against accumulated context.
///
/// Filter rendering follows the source's right-to-left application order.
final class FieldFilterChain {
  FieldFilterChain._({
    required this.fieldName,
    required List<FieldFilter> filters,
    required this.context,
    required this.isValid,
  }) : filters = List<FieldFilter>.unmodifiable(filters);

  final FieldName fieldName;
  final List<FieldFilter> filters;
  final FilterContext context;
  final bool isValid;

  /// Returns a new chain when [filter] can be appended, or `null` otherwise.
  FieldFilterChain? tryAdd(FieldFilter filter, {bool allowInvalid = false}) {
    if (!allowInvalid && (!filter.isValid || !isValid)) return null;
    if (!filter.canApplyTo(context)) return null;
    if (filters
        .map((existing) => existing.name)
        .toList()
        .contains(filter.name)) {
      return null;
    }

    return FieldFilterChain._(
      fieldName: fieldName,
      filters: [...filters, filter],
      context: filter.updateContext(context),
      isValid: isValid && filter.isValid,
    );
  }

  String render() => toString();

  @override
  String toString() {
    if (filters.isEmpty) return '{{$fieldName}}';
    final renderedFilters = filters.reversed.map((filter) => filter.render());
    return '{{${renderedFilters.join(':')}:$fieldName}}';
  }

  /// Creates an empty chain with the default context for [fieldName].
  static FieldFilterChain build(
    FieldName fieldName, {
    required bool isClozeNoteType,
  }) => FieldFilterChain._(
    fieldName: fieldName,
    filters: const [],
    context: FilterContext(isClozeNoteType: isClozeNoteType),
    isValid: true,
  );
}

int _kotlinDataClassHashCode(List<int> fields) {
  var hash = fields.first;
  for (final field in fields.skip(1)) {
    hash = _kotlinInt32(31 * hash + field);
  }
  return hash;
}

int _kotlinBooleanHashCode(bool value) => value ? 1231 : 1237;

bool _stringListsEqual(List<String>? left, List<String>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

int _kotlinStringListHashCode(List<String> values) {
  var hash = 1;
  for (final value in values) {
    hash = _kotlinInt32(31 * hash + kotlinStringHashCode(value));
  }
  return hash;
}

bool _floatValuesEqual(double? left, double? right) {
  if (left == null || right == null) return left == right;
  final leftBits = left.isNaN ? 0x7fc00000 : float32Bits(left);
  final rightBits = right.isNaN ? 0x7fc00000 : float32Bits(right);
  return leftBits == rightBits;
}

int _kotlinInt32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
