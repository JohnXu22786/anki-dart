// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as protoScheduler;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
CREATE TABLE cards (
  id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER,
  usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl INTEGER,
  factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER,
  odid INTEGER, flags INTEGER, data TEXT
);
CREATE TABLE decks (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  common BLOB NOT NULL,
  kind BLOB NOT NULL
);
''');
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
    await _insertCard(storage);
  });

  tearDown(() async => storage.close());

  group('filteredPreviewSchedulingStatesForCard', () {
    test(
      'assembles current and four answer states from stored deck delays',
      () async {
        final result = await storage.filteredPreviewSchedulingStatesForCard(
          cardId: Int64(1),
        );

        expect(result.current.scheduledSecs, 45);
        expect(result.current.finished, isFalse);
        expect(result.again.scheduledSecs, 45);
        expect(result.again.finished, isFalse);
        expect(result.hard.scheduledSecs, 90);
        expect(result.hard.finished, isFalse);
        expect(result.good.scheduledSecs, 180);
        expect(result.good.finished, isFalse);
        expect(result.easy.scheduledSecs, 0);
        expect(result.easy.finished, isTrue);
      },
    );

    test(
      'keeps zero-delay current unfinished and zero-delay answers finished',
      () async {
        storage.decks.addOrUpdateDeckWithExistingId(
          _filteredDeck(again: 0, hard: 0, good: 0),
        );

        final result = await storage.filteredPreviewSchedulingStatesForCard(
          cardId: Int64(1),
        );

        expect(result.current.scheduledSecs, 0);
        expect(result.current.finished, isFalse);
        expect(result.again.finished, isTrue);
        expect(result.hard.finished, isTrue);
        expect(result.good.finished, isTrue);
        expect(result.easy.finished, isTrue);
      },
    );

    test(
      'rejects missing cards and decks, normal decks, and rescheduling',
      () async {
        Future<FilteredPreviewSchedulingStates> project([CardId? id]) => storage
            .filteredPreviewSchedulingStatesForCard(cardId: id ?? Int64(404));

        await expectLater(project(), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('deck not found'));

        await storage.executeBatch('UPDATE cards SET did = 7 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(7),
            name: 'Normal',
            kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
          ),
        );
        await expectLater(
          project(Int64(1)),
          _stateError('filtered deck required'),
        );

        storage.decks.addOrUpdateDeckWithExistingId(
          _filteredDeck(reschedule: true),
        );
        await expectLater(project(Int64(1)), _stateError('rescheduling'));
      },
    );
  });

  group('filteredPreviewSchedulingStatesProtoForCard', () {
    test('wraps all states in filtered Preview protocol oneofs', () async {
      final result = await storage.filteredPreviewSchedulingStatesProtoForCard(
        cardId: Int64(1),
      );

      final states = [
        result.current,
        result.again,
        result.hard,
        result.good,
        result.easy,
      ];
      final expected = [
        (45, false),
        (45, false),
        (90, false),
        (180, false),
        (0, true),
      ];
      for (var i = 0; i < states.length; i++) {
        final state = states[i];
        expect(state.whichKind(), protoScheduler.SchedulingState_Kind.filtered);
        expect(
          state.filtered.whichKind(),
          protoScheduler.SchedulingState_Filtered_Kind.preview,
        );
        expect(state.hasNormal(), isFalse);
        expect(state.filtered.hasRescheduling(), isFalse);
        expect(state.filtered.preview.scheduledSecs, expected[i].$1);
        expect(state.filtered.preview.finished, expected[i].$2);
      }
    });

    test('preserves zero-delay current and finished answer states', () async {
      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(again: 0, hard: 0, good: 0),
      );

      final result = await storage.filteredPreviewSchedulingStatesProtoForCard(
        cardId: Int64(1),
      );

      expect(result.current.filtered.preview.scheduledSecs, 0);
      expect(result.current.filtered.preview.finished, isFalse);
      for (final state in [
        result.again,
        result.hard,
        result.good,
        result.easy,
      ]) {
        expect(state.filtered.preview.scheduledSecs, 0);
        expect(state.filtered.preview.finished, isTrue);
      }
    });

    test('preserves card and assigned-deck validation', () async {
      Future<protoScheduler.SchedulingStates> project([CardId? id]) =>
          storage.filteredPreviewSchedulingStatesProtoForCard(
            cardId: id ?? Int64(404),
          );

      await expectLater(project(), _stateError('card not found'));
      await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
      await expectLater(project(Int64(1)), _stateError('deck not found'));

      await storage.executeBatch('UPDATE cards SET did = 7 WHERE id = 1');
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(7),
          name: 'Normal',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      await expectLater(
        project(Int64(1)),
        _stateError('filtered deck required'),
      );

      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: true),
      );
      await expectLater(project(Int64(1)), _stateError('rescheduling'));
    });
  });
}

Deck _filteredDeck({
  bool reschedule = false,
  int again = 45,
  int hard = 90,
  int good = 180,
}) => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(
    protoDeck.Deck_Filtered(
      reschedule: reschedule,
      previewAgainSecs: again,
      previewHardSecs: hard,
      previewGoodSecs: good,
    ),
  ),
);

Future<void> _insertCard(CollectionSqliteStorage storage) =>
    storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 2, 7, 0, 1, 0, 2, 4, 45, 0, 2500, 0, 0, 0, 0, 0, 0, '');
''');

Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
