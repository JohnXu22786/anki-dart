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
 * Behavioral reference: `TypeAnswer.updateInfo()` in AnkiDroid 2.25.3.
 */

import 'type_answer_cloze.dart';
import 'type_answer_field_result.dart';

/// One ordered state assignment projected from `TypeAnswer.updateInfo()`.
sealed class TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoUpdateEffect();

  Object? get value;

  @override
  bool operator ==(Object other) =>
      other is TypeAnswerInfoUpdateEffect &&
      other.runtimeType == runtimeType &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class TypeAnswerInfoSetCombining extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetCombining(this.value);

  @override
  final bool value;
}

final class TypeAnswerInfoSetNoSuggest extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetNoSuggest(this.value);

  @override
  final bool value;
}

final class TypeAnswerInfoSetCorrectAnswer extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetCorrectAnswer(this.value);

  @override
  final String? value;
}

final class TypeAnswerInfoSetFont extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetFont(this.value);

  @override
  final String value;
}

final class TypeAnswerInfoSetFontSize extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetFontSize(this.value);

  @override
  final int value;
}

final class TypeAnswerInfoSetLanguageHint extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetLanguageHint(this.value);

  @override
  final Object? value;
}

/// A warning assignment; null clears the prior warning.
final class TypeAnswerInfoSetWarning extends TypeAnswerInfoUpdateEffect {
  const TypeAnswerInfoSetWarning(this.value);

  @override
  final String? value;
}

/// The source note lookup failed after the earlier effects in the plan.
///
/// Kotlin `Note.getItem` throws `IllegalArgumentException` for an unknown
/// field name. The host applies preceding [TypeAnswerInfoUpdatePlan.effects],
/// then reproduces that failure at the lookup boundary.
final class TypeAnswerInfoLookupFailure {
  const TypeAnswerInfoLookupFailure(this.fieldName);

  final String fieldName;

  String get message => "No field named '$fieldName' found";
}

/// An immutable, source-ordered update plan for one `TypeAnswer.updateInfo`.
///
/// The host applies [effects] in order. A non-null [failure] means the source
/// would throw while reading the selected note field after the preceding
/// effects have run. The plan does not access Android, collection or resource
/// APIs and does not mutate the host's TypeAnswer state.
final class TypeAnswerInfoUpdatePlan {
  TypeAnswerInfoUpdatePlan({
    required List<TypeAnswerInfoUpdateEffect> effects,
    this.failure,
  }) : effects = List.unmodifiable(effects);

  final List<TypeAnswerInfoUpdateEffect> effects;
  final TypeAnswerInfoLookupFailure? failure;
}

/// Projects the pure branches and ordered assignments of `updateInfo()`.
///
/// Inputs are already available to the host: rendered [question], zero-based
/// [cardOrdinal], source-ordered [fields], keyed non-null [noteValues], and
/// localized warning strings. The host performs lookup and applies the returned
/// effects. `input`, prior warning and prior metadata are preserved whenever
/// the source does not assign them.
TypeAnswerInfoUpdatePlan planTypeAnswerInfoUpdate({
  required String question,
  required int cardOrdinal,
  required List<TypeAnswerFieldMetadata> fields,
  required Map<String, String> noteValues,
  required String localizedUnknownFieldWarning,
  required String localizedEmptyClozeFrontWarning,
}) {
  final effects = <TypeAnswerInfoUpdateEffect>[
    const TypeAnswerInfoSetCombining(true),
    const TypeAnswerInfoSetNoSuggest(false),
    const TypeAnswerInfoSetCorrectAnswer(null),
  ];

  final declaration = typeAnswerDeclarationForQuestion(question, cardOrdinal);
  if (declaration == null) {
    return TypeAnswerInfoUpdatePlan(effects: effects);
  }

  final modifiers = declaration.modifiers;
  final clozeIndex = declaration.clozeIndex;
  effects
    ..add(TypeAnswerInfoSetCombining(modifiers.combining))
    ..add(TypeAnswerInfoSetNoSuggest(modifiers.noSuggest));

  TypeAnswerFieldMetadata? field;
  for (final candidate in fields) {
    if (candidate.name == modifiers.fieldName) {
      field = candidate;
      break;
    }
  }

  if (field == null) {
    return TypeAnswerInfoUpdatePlan(
      effects: [
        ...effects,
        TypeAnswerInfoSetWarning(
          clozeIndex != 0
              ? localizedEmptyClozeFrontWarning
              : localizedUnknownFieldWarning,
        ),
      ],
    );
  }

  if (!noteValues.containsKey(field.name)) {
    return TypeAnswerInfoUpdatePlan(
      effects: effects,
      failure: TypeAnswerInfoLookupFailure(field.name),
    );
  }

  final rawCorrectAnswer = noteValues[field.name]!;
  String? correctAnswer = rawCorrectAnswer;
  effects.add(TypeAnswerInfoSetCorrectAnswer(correctAnswer));
  if (clozeIndex != 0) {
    correctAnswer = typeAnswerContentForCloze(rawCorrectAnswer, clozeIndex);
    effects.add(TypeAnswerInfoSetCorrectAnswer(correctAnswer));
  }

  effects
    ..add(TypeAnswerInfoSetFont(field.font))
    ..add(TypeAnswerInfoSetFontSize(field.fontSize))
    ..add(TypeAnswerInfoSetLanguageHint(field.languageHint));

  if (correctAnswer == null) {
    effects.add(
      TypeAnswerInfoSetWarning(
        clozeIndex != 0
            ? localizedEmptyClozeFrontWarning
            : localizedUnknownFieldWarning,
      ),
    );
  } else if (correctAnswer.isEmpty) {
    effects.add(const TypeAnswerInfoSetCorrectAnswer(null));
  } else {
    effects.add(const TypeAnswerInfoSetWarning(null));
  }

  return TypeAnswerInfoUpdatePlan(effects: effects);
}
