// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/notes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

import 'field_checksum.dart';
import 'field_is_empty.dart';
import 'ids.dart';
import 'base91.dart';
import 'note_field.dart';
import 'notetype.dart';
import 'note_field_normalization.dart';
import 'note_text.dart';

/// An Anki note's stored identity, fields and tags.
class Note {
  Note({
    this.id = Int64.ZERO,
    this.guid = '',
    this.notetypeId = Int64.ZERO,
    this.mtimeSecs = Int64.ZERO,
    int usn = 0,
    List<String> tags = const [],
    List<String> fields = const [],
    String? sortField,
    int? checksum,
  })  : usn = usn.toSigned(32),
        tags = List<String>.of(tags),
        _fields = List<String>.of(fields),
        _sortField = sortField,
        _checksum = checksum?.toUnsigned(32);

  final NoteId id;
  final String guid;
  final Int64 notetypeId;
  final Int64 mtimeSecs;
  final int usn;
  final List<String> tags;
  final List<String> _fields;
  String? _sortField;
  int? _checksum;

  /// Create a new note with the same empty state and random base91 GUID as
  /// Anki Core's `Note::new()`.
  factory Note.newNote(
    Notetype notetype, {
    required BigInt Function() randomU64,
  }) {
    return Note(
      guid: base91U64(randomU64()),
      notetypeId: notetype.id.value,
      fields: List<String>.filled(notetype.fields.length, ''),
    );
  }

  List<String> get fields => List<String>.unmodifiable(_fields);
  String? get sortField => _sortField;
  int? get checksum => _checksum;

  /// Returns the names of note fields containing content.
  ///
  /// Whitespace and empty `br`/`div` tags are ignored, matching the behavior
  /// used when Anki decides whether a template produces a card.
  Set<String> nonEmptyFields(List<NoteField> notetypeFields) {
    final result = <String>{};
    for (var index = 0; index < _fields.length; index++) {
      if (index < notetypeFields.length && !fieldIsEmpty(_fields[index])) {
        result.add(notetypeFields[index].name);
      }
    }
    return result;
  }

  /// Replace one field and clear derived values, as Anki Core does.
  void setField(int index, String text) {
    if (index < 0 || index >= _fields.length) {
      throw RangeError('field idx out of range');
    }
    _fields[index] = text;
    _markDirty();
  }

  /// Obtain the mutable fields list after clearing derived values.
  List<String> fieldsMut() {
    _markDirty();
    return _fields;
  }

  void _markDirty() {
    _sortField = null;
    _checksum = null;
  }

  /// Prepare fields and cached values before saving, matching Anki Core's
  /// `Note::prepare_for_update()` contract.
  ///
  /// Fields are cleaned in place. The checksum is derived from the first field
  /// and the sort field from the configured field ordinal.
  void prepareForUpdate(Notetype notetype, {required bool normalizeText}) {
    if (notetype.id.value != notetypeId) {
      throw StateError('note and notetype IDs do not match');
    }
    final expectedFieldCount =
        notetype.fields.isEmpty ? 1 : notetype.fields.length;
    if (expectedFieldCount != _fields.length) {
      throw StateError(
        'note has ${_fields.length} fields, expected $expectedFieldCount',
      );
    }

    for (var index = 0; index < _fields.length; index++) {
      _fields[index] = normalizeNoteField(
        _fields[index],
        normalizeText: normalizeText,
      );
    }

    final field1NoHtml = stripHtmlPreservingMediaFilenames(_fields.first);
    final sortFieldIndex = notetype.config.sortFieldIdx;
    _sortField = sortFieldIndex == 0
        ? field1NoHtml
        : stripHtmlPreservingMediaFilenames(
            sortFieldIndex < _fields.length ? _fields[sortFieldIndex] : '',
          );
    _checksum = fieldChecksum(field1NoHtml);
  }

  factory Note.fromProto(proto.Note value) => Note(
        id: value.id,
        guid: value.guid,
        notetypeId: value.notetypeId,
        mtimeSecs: Int64(value.mtimeSecs),
        usn: value.usn,
        tags: value.tags,
        fields: value.fields,
      );

  proto.Note toProto() => proto.Note(
        id: id,
        guid: guid,
        notetypeId: notetypeId,
        mtimeSecs: mtimeSecs.toUnsigned(32).toInt(),
        usn: usn,
        tags: tags,
        fields: _fields,
      );
}
