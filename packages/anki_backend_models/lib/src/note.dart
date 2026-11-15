// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/notes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

import 'ids.dart';
import 'base91.dart';
import 'notetype.dart';

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
