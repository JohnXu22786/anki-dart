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

/// Host-supplied metadata for one source note-type field.
///
/// [languageHint] is intentionally opaque so the pure model does not depend on
/// Android or Flutter locale types.
final class TypeAnswerFieldMetadata {
  const TypeAnswerFieldMetadata({
    required this.name,
    required this.font,
    required this.fontSize,
    required this.languageHint,
  });

  final String name;
  final String font;
  final int fontSize;
  final Object? languageHint;
}

/// Describes how the host should update the existing TypeAnswer warning.
enum TypeAnswerWarningUpdateKind {
  /// Keep the warning already held by the host.
  preservePrevious,

  /// Clear the warning.
  clear,

  /// Set the warning to [TypeAnswerWarningUpdate.value].
  set,
}

/// A warning-state operation projected from `TypeAnswer.updateInfo()`.
final class TypeAnswerWarningUpdate {
  const TypeAnswerWarningUpdate._(this.kind, this.value);

  const TypeAnswerWarningUpdate.preservePrevious()
      : this._(TypeAnswerWarningUpdateKind.preservePrevious, null);

  const TypeAnswerWarningUpdate.clear()
      : this._(TypeAnswerWarningUpdateKind.clear, null);

  const TypeAnswerWarningUpdate.set(String warning)
      : this._(TypeAnswerWarningUpdateKind.set, warning);

  final TypeAnswerWarningUpdateKind kind;
  final String? value;
}

/// The host-visible result of resolving one TypeAnswer field declaration.
///
/// A null [matchedField] means no metadata update: source `updateInfo()` leaves
/// its previous font, size and language hint unchanged when no field matches.
final class TypeAnswerFieldResolution {
  const TypeAnswerFieldResolution({
    required this.correctAnswer,
    required this.matchedField,
    required this.warningUpdate,
  });

  final String? correctAnswer;
  final TypeAnswerFieldMetadata? matchedField;
  final TypeAnswerWarningUpdate warningUpdate;
}

/// Projects the field/result decisions made by `TypeAnswer.updateInfo()`.
///
/// Inputs are already resolved by the host: [fields] is in source field order,
/// [noteValues] contains note values keyed by field name, [clozeIndex] is
/// already derived, and warning strings are already localized. The first field
/// whose name exactly equals [fieldName] wins. An absent selected note value
/// throws [ArgumentError], matching the source note-field lookup failure.
///
/// With no matching field, the answer is null and the appropriate warning is
/// set; [matchedField] is null so the host retains prior metadata. A matched
/// empty answer becomes null but preserves the prior warning. A nonempty answer
/// clears the warning. For a nonzero cloze index, the existing source-mapped
/// cloze extractor runs before these null/empty/nonempty decisions.
TypeAnswerFieldResolution resolveTypeAnswerFieldResult({
  required String fieldName,
  required List<TypeAnswerFieldMetadata> fields,
  required Map<String, String> noteValues,
  required int clozeIndex,
  required String localizedUnknownFieldWarning,
  required String localizedEmptyClozeFrontWarning,
}) {
  TypeAnswerFieldMetadata? matchedField;
  for (final field in fields) {
    if (field.name == fieldName) {
      matchedField = field;
      break;
    }
  }

  if (matchedField == null) {
    return TypeAnswerFieldResolution(
      correctAnswer: null,
      matchedField: null,
      warningUpdate: TypeAnswerWarningUpdate.set(
        clozeIndex != 0
            ? localizedEmptyClozeFrontWarning
            : localizedUnknownFieldWarning,
      ),
    );
  }

  if (!noteValues.containsKey(matchedField.name)) {
    throw ArgumentError("No field named '${matchedField.name}' found");
  }

  String? correctAnswer = noteValues[matchedField.name]!;
  if (clozeIndex != 0) {
    correctAnswer = typeAnswerContentForCloze(correctAnswer, clozeIndex);
  }

  if (correctAnswer == null) {
    return TypeAnswerFieldResolution(
      correctAnswer: null,
      matchedField: matchedField,
      warningUpdate: TypeAnswerWarningUpdate.set(
        clozeIndex != 0
            ? localizedEmptyClozeFrontWarning
            : localizedUnknownFieldWarning,
      ),
    );
  }

  if (correctAnswer.isEmpty) {
    return TypeAnswerFieldResolution(
      correctAnswer: null,
      matchedField: matchedField,
      warningUpdate: const TypeAnswerWarningUpdate.preservePrevious(),
    );
  }

  return TypeAnswerFieldResolution(
    correctAnswer: correctAnswer,
    matchedField: matchedField,
    warningUpdate: const TypeAnswerWarningUpdate.clear(),
  );
}
