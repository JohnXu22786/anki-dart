// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notes.pbenum.dart' as notes;
import 'package:fixnum/fixnum.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'note.dart';
import 'note_duplicate_check.dart';
import 'note_text.dart';
import 'notetype.dart';

/// A storage adapter that loads the note type for a note. Lookup failures
/// should be thrown by the host and are propagated unchanged.
typedef NotetypeById = Notetype Function(Int64 notetypeId);

/// Whether a cloze deletion with a nonzero u16 ordinal is closed in [text].
/// This follows Anki Core's cloze tokenizer, including nested clozes and its
/// ten-level parse limit.
bool containsCloze(String text) {
  final stack = <_ClozeFrame>[];
  var found = false;
  var index = 0;
  while (index < text.length) {
    if (text.startsWith('{{c', index)) {
      var end = index + 3;
      while (end < text.length &&
          (_isAsciiDigit(text.codeUnitAt(end)) || text[end] == ',')) {
        end++;
      }
      final ordinals = text
          .substring(index + 3, end)
          .split(',')
          .map(int.tryParse)
          .whereType<int>()
          .where((ordinal) => ordinal >= 0 && ordinal <= 0xffff)
          .toSet();
      if (ordinals.isNotEmpty && text.startsWith('::', end)) {
        if (stack.length < 10) {
          stack.add(_ClozeFrame(ordinals.any((ordinal) => ordinal != 0)));
        }
        index = end + 2;
        continue;
      }
    }
    if (text.startsWith('}}', index)) {
      if (stack.isNotEmpty) {
        final closed = stack.removeLast();
        if (stack.isEmpty) {
          found |= closed.containsNonzeroOrdinal;
        }
      }
      index += 2;
    } else {
      index++;
    }
  }
  return found;
}

bool _isAsciiDigit(int rune) => rune >= 0x30 && rune <= 0x39;

class _ClozeFrame {
  _ClozeFrame(this.containsNonzeroOrdinal);
  bool containsNonzeroOrdinal;
}

/// Apply the pinned Core note field validation ordering. The callbacks keep
/// storage access on the host while all validation policy remains here.
notes.NoteFieldsCheckResponse_State noteFieldsCheck({
  required Note note,
  required NotetypeById getNotetype,
  required bool normalizeText,
  required NoteFieldsByChecksum loadFieldsByChecksum,
}) {
  final notetype = getNotetype(note.notetypeId);
  final clozeState = _fieldClozeCheck(note, notetype);
  if (clozeState == notes.NoteFieldsCheckResponse_State.FIELD_NOT_CLOZE) {
    return clozeState;
  }

  if (note.fields.isEmpty) return notes.NoteFieldsCheckResponse_State.EMPTY;
  final firstField = note.fields.first;

  final normalized = normalizeText ? unorm.nfc(firstField) : firstField;
  final stripped = stripHtmlPreservingMediaFilenames(normalized);
  if (stripped.trim().isEmpty) return notes.NoteFieldsCheckResponse_State.EMPTY;
  if (clozeState != notes.NoteFieldsCheckResponse_State.NORMAL) {
    return clozeState;
  }
  return isDuplicateNoteField(
    note: note,
    firstFieldWithoutHtml: stripped,
    loadFieldsByChecksum: loadFieldsByChecksum,
  )
      ? notes.NoteFieldsCheckResponse_State.DUPLICATE
      : notes.NoteFieldsCheckResponse_State.NORMAL;
}

notes.NoteFieldsCheckResponse_State _fieldClozeCheck(
  Note note,
  Notetype notetype,
) {
  final clozeFields = notetype.clozeFields;
  var hasCloze = false;
  for (var index = 0; index < note.fields.length; index++) {
    if (containsCloze(note.fields[index])) {
      if (!notetype.isCloze) {
        return notes.NoteFieldsCheckResponse_State.NOTETYPE_NOT_CLOZE;
      }
      if (!clozeFields.contains(index)) {
        return notes.NoteFieldsCheckResponse_State.FIELD_NOT_CLOZE;
      }
      hasCloze = true;
    }
  }
  if (notetype.isCloze && !hasCloze) {
    return notes.NoteFieldsCheckResponse_State.MISSING_CLOZE;
  }
  return notes.NoteFieldsCheckResponse_State.NORMAL;
}
