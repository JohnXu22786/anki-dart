// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  final db = _Database();
  final storage = NoteStorage(db);
  final note = Note(
    id: Int64.parseInt('9007199254740993'),
    guid: 'web-smoke',
    notetypeId: Int64(1),
    fields: ['front'],
  );
  note.prepareForUpdate(_notetype(), normalizeText: false);
  storage.addOrUpdateNote(note);
  if (db.parameters.first != note.id) {
    throw StateError('note ID lost 64-bit precision on the web target');
  }

  final added = Note(
    guid: 'generated-web-smoke',
    notetypeId: Int64(1),
    fields: ['front'],
  )..prepareForUpdate(_notetype(), normalizeText: false);
  storage.addNote(added);
  if (added.id != db.lastInsertRowId) {
    throw StateError('generated row ID was not retained');
  }
}

Notetype _notetype() =>
    Notetype(id: NotetypeId(Int64(1)), config: Notetype.defaultConfig());

class _Database implements NoteStorageDatabase {
  List<Object?> parameters = [];

  @override
  Int64 lastInsertRowId = Int64.parseInt('9007199254740995');

  @override
  NoteStorageStatement prepareCached(String sql) => _Statement(this);
}

class _Statement implements NoteStorageStatement {
  _Statement(this.db);

  final _Database db;

  @override
  int execute(List<Object?> parameters) {
    db.parameters = parameters;
    return 1;
  }
}
