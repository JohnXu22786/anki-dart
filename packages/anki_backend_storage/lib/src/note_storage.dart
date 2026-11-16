// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';

/// A cached SQL statement supplied by the platform's SQLite driver.
abstract interface class NoteStorageStatement {
  /// Executes this statement and returns SQLite's affected row count.
  int execute(List<Object?> parameters);
}

/// The small SQLite surface required by note row mutations.
abstract interface class NoteStorageDatabase {
  /// Returns a reusable prepared statement for [sql].
  NoteStorageStatement prepareCached(String sql);

  /// The 64-bit row ID from the most recent successful insert on this handle.
  Int64 get lastInsertRowId;
}

/// Writes notes using Anki Core's `notes` table layout and SQL semantics.
///
/// The database adapter owns SQLite connection setup, statement caching,
/// transactions, and flushing. This class stays platform neutral so the same
/// mutation logic can use native SQLite and a Web-compatible SQLite adapter.
class NoteStorage {
  NoteStorage(this.db, {int Function()? nowMillis})
      : _nowMillis = nowMillis ?? _currentTimeMillis;

  final NoteStorageDatabase db;
  final int Function() _nowMillis;

  /// Updates an existing row. The note must already have its derived fields
  /// prepared by [Note.prepareForUpdate].
  void updateNote(Note note) {
    if (note.id == Int64.ZERO) {
      throw StateError('note ID must be nonzero before it can be updated');
    }
    final parameters = _noteParameters(note)..removeAt(0);
    parameters.add(note.id);
    db.prepareCached(_updateSql).execute(parameters);
  }

  /// Inserts a new note and assigns SQLite's generated 64-bit row ID to it.
  void addNote(Note note) {
    if (note.id != Int64.ZERO) {
      throw StateError('note ID must be zero before it can be added');
    }
    db.prepareCached(_addSql).execute([
      _nowMillis(),
      ..._noteParameters(note, includeId: false),
    ]);
    note.id = db.lastInsertRowId;
  }

  /// Inserts [note] only when its ID is not already present.
  ///
  /// A duplicate ID is ignored by SQLite and returns false. Other SQLite
  /// errors are allowed to propagate from the driver.
  bool addNoteIfUnique(Note note) =>
      db.prepareCached(_addIfUniqueSql).execute(_noteParameters(note)) == 1;

  /// Inserts or replaces the row with [note]'s ID, matching SQLite
  /// `INSERT OR REPLACE` behavior.
  void addOrUpdateNote(Note note) {
    db.prepareCached(_addOrUpdateSql).execute(_noteParameters(note));
  }

  /// Deletes a note if it exists. A missing ID is a successful no-op.
  void removeNote(Int64 noteId) {
    db.prepareCached('delete from notes where id = ?').execute([noteId]);
  }

  List<Object?> _noteParameters(Note note, {bool includeId = true}) {
    if (note.sortField == null || note.checksum == null) {
      throw StateError('note must be prepared before it can be stored');
    }
    return [
      if (includeId) note.id,
      note.guid,
      note.notetypeId,
      note.mtimeSecs,
      note.usn,
      _joinTags(note.tags),
      note.fields.join('\x1f'),
      note.sortField,
      note.checksum,
    ];
  }

  static String _joinTags(List<String> tags) =>
      tags.isEmpty ? '' : ' ${tags.join(' ')} ';

  static int _currentTimeMillis() => DateTime.now().millisecondsSinceEpoch;

  static const _updateSql = '''
UPDATE notes
SET guid = ?,
  mid = ?,
  mod = ?,
  usn = ?,
  tags = ?,
  flds = ?,
  sfld = ?,
  csum = ?
WHERE id = ?''';

  static const _addSql = '''
INSERT INTO notes (
    id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data
  )
VALUES (
    CASE WHEN ?1 IN (SELECT id FROM notes)
      THEN (SELECT max(id) + 1 FROM notes) ELSE ?1 END,
    ?, ?, ?, ?, ?, ?, ?, ?, 0, ""
  )''';

  static const _addIfUniqueSql = '''
INSERT OR IGNORE INTO notes (
    id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data
  )
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, "")''';

  static const _addOrUpdateSql = '''
INSERT OR REPLACE INTO notes (
    id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data
  )
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, "")''';
}
