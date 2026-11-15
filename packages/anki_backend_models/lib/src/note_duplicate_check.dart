// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';

import 'field_checksum.dart';
import 'note.dart';
import 'note_text.dart';

/// A first-field value returned by a checksum-filtered note storage query.
class NoteChecksumMatch {
  const NoteChecksumMatch({required this.noteId, required this.firstField});

  final Int64 noteId;
  final String firstField;
}

/// Host adapter for Anki Core's `note_fields_by_checksum()` storage query.
typedef NoteFieldsByChecksum = List<NoteChecksumMatch> Function(
  Int64 notetypeId,
  int checksum,
);

/// Returns whether another note has the same normalized, HTML-stripped field.
///
/// [firstFieldWithoutHtml] must already have passed through the source's field
/// normalization and `strip_html_preserving_media_filenames()` steps. The host
/// supplies candidates from its storage query; this function computes the
/// checksum, ignores the current note, strips each candidate, and compares in
/// source order.
bool isDuplicateNoteField({
  required Note note,
  required String firstFieldWithoutHtml,
  required NoteFieldsByChecksum loadFieldsByChecksum,
}) {
  final checksum = fieldChecksum(firstFieldWithoutHtml);
  final matches = loadFieldsByChecksum(note.notetypeId, checksum);
  for (final match in matches) {
    if (match.noteId != note.id &&
        stripHtmlPreservingMediaFilenames(match.firstField) ==
            firstFieldWithoutHtml) {
      return true;
    }
  }
  return false;
}
