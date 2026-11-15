// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// Adapted from NoteType.kt:getAllClozeTextFields in AnkiDroid 2.25.3;
// see ANKIDROID_UPSTREAM.md.

/// The source Kotlin regex, with its dot's JVM line terminators made explicit.
/// Dart's dot matches NEL, unlike Java's default regex dot.
final RegExp _clozeRegex = RegExp(
  r'\{\{(?:[^\r\n\u0085\u2028\u2029]*?:)?cloze:([^}]*)\}\}',
);

/// Returns the cloze text captures from a note type's single question format.
///
/// The Rust `NotetypeJson` remains host-side; callers pass its cloze flag and
/// template `qfmt` values. The non-cloze guard runs before the formats are
/// read, matching the source extension's order. Dart's `Iterable.single`
/// reports both zero and multiple values as [StateError]; Kotlin's
/// `single()` uses different exception classes for those cardinalities.
List<String> getAllClozeTextFields({
  required bool isCloze,
  required Iterable<String> templateQuestionFormats,
}) {
  if (!isCloze) {
    throw StateError('getAllClozeTextFields called on non-cloze template');
  }

  final questionFormat = templateQuestionFormats.single;
  return _clozeRegex
      .allMatches(questionFormat)
      .map((match) => match.group(1)!)
      .toList();
}
