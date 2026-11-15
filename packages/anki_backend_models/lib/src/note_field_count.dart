// SPDX-License-Identifier: AGPL-3.0-or-later

/// Pads or merges a note's fields to the given Anki note type field count.
///
/// Extra trailing values are appended to the final retained field with the
/// same `; ` separator used by Anki Core. At least one existing field is kept
/// when reducing a non-empty field list.
List<String> fixNoteFieldCount(List<String> fields, int noteTypeFieldCount) {
  if (noteTypeFieldCount < 0) {
    throw ArgumentError.value(noteTypeFieldCount, 'noteTypeFieldCount');
  }
  final fixed = List<String>.of(fields);
  while (fixed.length < noteTypeFieldCount) {
    fixed.add('');
  }
  while (fixed.length > noteTypeFieldCount && fixed.length > 1) {
    final last = fixed.removeLast();
    fixed[fixed.length - 1] = '${fixed.last}; $last';
  }
  return fixed;
}
