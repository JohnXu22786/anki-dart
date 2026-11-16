// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

/// The portable SQL query surface required by [DeckStorage].
abstract interface class DeckStorageDatabase {
  /// Executes a query with integer-safe row values and column names.
  List<Map<String, Object?>> select(String sql, [List<Object?> parameters]);

  /// Executes a mutation and returns SQLite's changed-row count.
  int execute(String sql, [List<Object?> parameters]);
}

/// Reads and writes Anki Core `decks` rows without choosing a SQLite driver.
class DeckStorage {
  DeckStorage(this.db, {int Function()? nowMillis})
      : _nowMillis = nowMillis ?? _currentTimeMillis;

  final DeckStorageDatabase db;
  final int Function() _nowMillis;

  /// Returns a deck by ID, or null when no row exists.
  Deck? getDeck(Int64 id) {
    final rows = db.select('$_getDeckSql WHERE id = ?', [_sqlInt64(id)]);
    return rows.isEmpty ? null : _deckFromRow(rows.single);
  }

  /// Returns a deck by its native, `\x1f`-separated name.
  Deck? getDeckByName(String nativeName) {
    final rows = db.select('$_getDeckSql WHERE name = ?', [nativeName]);
    return rows.isEmpty ? null : _deckFromRow(rows.single);
  }

  /// Returns decks in SQLite's natural query order, matching Core's query.
  List<Deck> getAllDecks() =>
      db.select(_getDeckSql).map(_deckFromRow).toList(growable: false);

  /// Returns deck IDs and human-readable names ordered by SQLite name order.
  List<(Int64, String)> getAllDeckNames() => db
      .select('SELECT id, name FROM decks ORDER BY name')
      .map((row) => (
            _int64(row['id'], 'id'),
            _string(row['name'], 'name').replaceAll('\x1f', '::'),
          ))
      .toList(growable: false);

  /// Returns the ID for a native, `\x1f`-separated name, if present.
  Int64? getDeckId(String nativeName) {
    final rows = db.select('SELECT id FROM decks WHERE name = ?', [nativeName]);
    return rows.isEmpty ? null : _int64(rows.single['id'], 'id');
  }

  /// Inserts a deck and returns a copy containing its allocated ID.
  ///
  /// As in Core, the current time in milliseconds is used unless it already
  /// exists, in which case `max(id) + 1` is selected. The caller remains
  /// responsible for ensuring the deck name is unique.
  Deck addDeck(Deck deck) {
    if (deck.id != Int64.ZERO) {
      throw StateError('deck ID must be zero before it can be added');
    }
    final id = _int64(
      db.select(_allocateIdSql, [_nowMillis()]).single['id'],
      'allocated id',
    );
    final storedDeck = _withId(deck, id);
    addOrUpdateDeckWithExistingId(storedDeck);
    return storedDeck;
  }

  /// Updates a stored deck. A missing row is an error, matching Core.
  void updateDeck(Deck deck) {
    _requireNonzeroId(deck);
    final changed = db.execute(
      '''
UPDATE decks
SET name = ?, mtime_secs = ?, usn = ?, common = ?, kind = ?
WHERE id = ?''',
      _deckParameters(deck)..add(_sqlInt64(deck.id)),
    );
    if (changed == 0) {
      throw StateError('update_deck() called with non-existent deck');
    }
  }

  /// Inserts or replaces a row with the supplied ID, as used by sync/undo.
  void addOrUpdateDeckWithExistingId(Deck deck) {
    _requireNonzeroId(deck);
    db.execute(
      '''
INSERT OR REPLACE INTO decks (id, name, mtime_secs, usn, common, kind)
VALUES (?, ?, ?, ?, ?, ?)''',
      [_sqlInt64(deck.id), ..._deckParameters(deck)],
    );
  }

  /// Deletes a deck if present. Missing IDs are a successful no-op.
  void removeDeck(Int64 id) {
    db.execute('DELETE FROM decks WHERE id = ?', [_sqlInt64(id)]);
  }

  List<Object?> _deckParameters(Deck deck) {
    final kind = switch (deck.kind) {
      NormalDeckKind(:final value) => proto.Deck_KindContainer(
          normal: value,
        ),
      FilteredDeckKind(:final value) => proto.Deck_KindContainer(
          filtered: value,
        ),
    };
    final serializedCommon = deck.common.writeToBuffer();
    final serializedKind = kind.writeToBuffer();
    return [
      _nativeName(deck.name),
      _sqlInt64(deck.mtimeSecs),
      deck.usn,
      Uint8List.fromList(serializedCommon),
      Uint8List.fromList(serializedKind),
    ];
  }

  Deck _deckFromRow(Map<String, Object?> row) {
    final id = _int64(row['id'], 'id');
    final kindContainer = proto.Deck_KindContainer.fromBuffer(
      _blob(row['kind'], 'kind'),
    );
    final common = proto.Deck_Common.fromBuffer(_blob(row['common'], 'common'));
    final protoDeck = proto.Deck(
      id: id,
      name: _humanName(_string(row['name'], 'name')),
      mtimeSecs: _int64(row['mtime_secs'], 'mtime_secs'),
      usn: _int32(row['usn'], 'usn'),
      common: common,
      normal: switch (kindContainer.whichKind()) {
        proto.Deck_KindContainer_Kind.normal => kindContainer.normal,
        proto.Deck_KindContainer_Kind.filtered ||
        proto.Deck_KindContainer_Kind.notSet =>
          null,
      },
      filtered: switch (kindContainer.whichKind()) {
        proto.Deck_KindContainer_Kind.filtered => kindContainer.filtered,
        proto.Deck_KindContainer_Kind.normal ||
        proto.Deck_KindContainer_Kind.notSet =>
          null,
      },
    );
    if (kindContainer.whichKind() == proto.Deck_KindContainer_Kind.notSet) {
      throw StateError('invalid deck kind: $id');
    }
    return Deck.fromProto(protoDeck);
  }

  static String _nativeName(String humanName) =>
      normalizeDeckName(humanName).replaceAll('::', '\x1f');

  static String _humanName(String nativeName) =>
      nativeName.replaceAll('\x1f', '::');

  static Deck _withId(Deck deck, Int64 id) => Deck(
        id: id,
        name: deck.name,
        mtimeSecs: deck.mtimeSecs,
        usn: deck.usn,
        common: deck.common,
        kind: deck.kind,
      );

  static void _requireNonzeroId(Deck deck) {
    if (deck.id == Int64.ZERO) throw StateError('deck with id 0');
  }

  static Int64 _int64(Object? value, String field) {
    if (value is Int64) return value;
    if (value is BigInt) return Int64.parseInt(value.toString());
    if (value is int) return Int64(value);
    throw FormatException('invalid signed 64-bit deck $field');
  }

  static BigInt _sqlInt64(Int64 value) => BigInt.parse(value.toString());

  static int _int32(Object? value, String field) {
    final integer = switch (value) {
      int value => value,
      BigInt value
          when value >= BigInt.from(-0x80000000) &&
              value <= BigInt.from(0x7fffffff) =>
        value.toInt(),
      _ => throw FormatException('invalid signed 32-bit deck $field'),
    };
    if (integer < -0x80000000 || integer > 0x7fffffff) {
      throw FormatException('invalid signed 32-bit deck $field');
    }
    return integer;
  }

  static String _string(Object? value, String field) => value is String
      ? value
      : throw FormatException('invalid text deck $field');

  static List<int> _blob(Object? value, String field) => switch (value) {
        Uint8List bytes => bytes,
        List<int> bytes => bytes,
        _ => throw FormatException('invalid blob deck $field'),
      };

  static int _currentTimeMillis() => DateTime.now().millisecondsSinceEpoch;

  static const _getDeckSql = '''
SELECT id, name, mtime_secs, usn, common, kind
FROM decks''';

  static const _allocateIdSql = '''
SELECT CASE
  WHEN ?1 IN (SELECT id FROM decks) THEN (SELECT max(id) + 1 FROM decks)
  ELSE ?1
END AS id''';
}
