// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notes.pbenum.dart' as notes;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

void main() {
  final card = Card(id: Int64(1));
  final note = Note(id: Int64(2));
  if (card.id.toInt() + note.id.toInt() != 3) {
    throw StateError('model package JS smoke compilation failed');
  }
  if (fieldChecksum('test') != 2840236005) {
    throw StateError('unsigned SHA-1 checksum differs on JavaScript');
  }
  final notetype = Notetype(
    id: NotetypeId(Int64(7)),
    fields: [
      NoteField(name: 'Front', config: proto.Notetype_Field_Config()),
    ],
    config: Notetype.defaultConfig(),
  );
  final state = noteFieldsCheck(
    note: Note(id: Int64(2), notetypeId: Int64(7), fields: ['front']),
    getNotetype: (_) => notetype,
    normalizeText: false,
    loadFieldsByChecksum: (_, __) => [],
  );
  if (containsCloze('{{c1::text}}') != true ||
      state != notes.NoteFieldsCheckResponse_State.NORMAL) {
    throw StateError('note field validation differs on JavaScript');
  }
}
