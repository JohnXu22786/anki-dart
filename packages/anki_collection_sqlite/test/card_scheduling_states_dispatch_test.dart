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
CREATE TABLE deck_config (
  id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, config BLOB NOT NULL
);
CREATE TABLE decks (
  id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, common BLOB NOT NULL,
  kind BLOB NOT NULL
);
CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL);
INSERT INTO col VALUES (1700000000, '{}');
''');
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(_config());
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
    storage.decks.addOrUpdateDeckWithExistingId(_homeDeck());
    storage.decks.addOrUpdateDeckWithExistingId(
      _filteredDeck(reschedule: true),
    );
    await _insertCard(storage, type: 0);
  });

  tearDown(() async => storage.close());

  test(
    'dispatches each card type by assigned deck mode into all five states',
    () async {
      const context = ReviewSchedulingContext(
        fuzzFactor: 0,
        relearningAgainDelaySecs: 600,
      );
      for (final mode in ['normal', 'rescheduling']) {
        for (final type in [0, 1, 2, 3]) {
          final isFiltered = mode == 'rescheduling';
          storage.decks.addOrUpdateDeckWithExistingId(
            isFiltered ? _filteredDeck(reschedule: true) : _normalDeck(),
          );
          await storage.executeBatch(
            'UPDATE cards SET type = $type, queue = $type, did = 7, '
            'odid = ${isFiltered ? 40 : 0} WHERE id = 1',
          );

          final result = await storage.schedulingStatesProtoForCard(
            cardId: Int64(1),
            baseContext: context,
            scheduledSecs: type == 1 || type == 3 ? 90 : null,
            elapsedSecs: type == 1 || type == 3 ? 12 : null,
            loadBalancerEnabled: false,
            fuzzSeed: BigInt.from(13),
            now: DateTime.fromMillisecondsSinceEpoch(
              1700000000000,
              isUtc: true,
            ),
          );
          final states = [
            result.current,
            result.again,
            result.hard,
            result.good,
            result.easy,
          ];
          expect(states, hasLength(5), reason: '$mode type $type');
          for (final state in states) {
            expect(
              state.whichKind(),
              isFiltered
                  ? protoScheduler.SchedulingState_Kind.filtered
                  : protoScheduler.SchedulingState_Kind.normal,
              reason: '$mode type $type',
            );
            final normal = isFiltered
                ? state.filtered.rescheduling.originalState
                : state.normal;
            expect(
              normal.whichKind(),
              isNot(protoScheduler.SchedulingState_Normal_Kind.notSet),
            );
          }
          final currentNormal = isFiltered
              ? result.current.filtered.rescheduling.originalState
              : result.current.normal;
          expect(
            currentNormal.whichKind(),
            [
              protoScheduler.SchedulingState_Normal_Kind.new_1,
              protoScheduler.SchedulingState_Normal_Kind.learning,
              protoScheduler.SchedulingState_Normal_Kind.review,
              protoScheduler.SchedulingState_Normal_Kind.relearning,
            ][type],
            reason: '$mode type $type',
          );
          if (type == 1 || type == 3) {
            final learning = type == 1
                ? currentNormal.learning
                : currentNormal.relearning.learning;
            expect(learning.scheduledSecs, 90);
            expect(learning.elapsedSecs, 12);
          }
        }
      }

      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
      await storage.executeBatch(
        'UPDATE cards SET type = 0, queue = 0, did = 7 WHERE id = 1',
      );
      final preview = await storage.schedulingStatesProtoForCard(
        cardId: Int64(1),
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: BigInt.from(13),
      );
      for (final state in [
        preview.current,
        preview.again,
        preview.hard,
        preview.good,
        preview.easy,
      ]) {
        expect(state.whichKind(), protoScheduler.SchedulingState_Kind.filtered);
        expect(
          state.filtered.whichKind(),
          protoScheduler.SchedulingState_Filtered_Kind.preview,
        );
      }
      expect(preview.current.filtered.preview.finished, isFalse);
      expect(preview.again.filtered.preview.scheduledSecs, 45);
      expect(preview.hard.filtered.preview.scheduledSecs, 90);
      expect(preview.good.filtered.preview.scheduledSecs, 180);
      expect(preview.easy.filtered.preview.finished, isTrue);
    },
  );

  test(
    'preserves Review timing and caller scheduling context through dispatch',
    () async {
      const context = ReviewSchedulingContext(
        intervalMultiplier: 1.2,
        hardMultiplier: 1.4,
        fuzzFactor: 0,
        relearningAgainDelaySecs: 600,
      );
      for (final reschedule in [false, true]) {
        storage.decks.addOrUpdateDeckWithExistingId(
          _filteredDeck(reschedule: true),
        );
        await storage.executeBatch(
          'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 40 WHERE id = 1',
        );
        if (reschedule) {
          final states = await storage.schedulingStatesProtoForCard(
            cardId: Int64(1),
            baseContext: context,
            loadBalancerEnabled: false,
            fuzzSeed: BigInt.from(13),
            now: DateTime.fromMillisecondsSinceEpoch(
              1700000000000,
              isUtc: true,
            ),
          );
          expect(
            states
                .current
                .filtered
                .rescheduling
                .originalState
                .review
                .elapsedDays,
            13,
          );
          expect(
            states.again.filtered.rescheduling.originalState.whichKind(),
            protoScheduler.SchedulingState_Normal_Kind.relearning,
          );
        } else {
          storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
          final states = await storage.schedulingStatesProtoForCard(
            cardId: Int64(1),
            baseContext: context,
            loadBalancerEnabled: false,
            fuzzSeed: BigInt.from(13),
            now: DateTime.fromMillisecondsSinceEpoch(
              1700000000000,
              isUtc: true,
            ),
          );
          expect(states.current.normal.review.elapsedDays, 30);
          expect(
            states.again.normal.whichKind(),
            protoScheduler.SchedulingState_Normal_Kind.relearning,
          );
        }
      }
    },
  );

  test(
    'rejects missing or invalid cards, missing decks and required timing',
    () async {
      Future<protoScheduler.SchedulingStates> project({
        CardId? cardId,
        int? scheduledSecs,
        int? elapsedSecs,
      }) => storage.schedulingStatesProtoForCard(
        cardId: cardId ?? Int64(1),
        baseContext: const ReviewSchedulingContext(),
        scheduledSecs: scheduledSecs,
        elapsedSecs: elapsedSecs,
        loadBalancerEnabled: false,
        fuzzSeed: null,
      );

      await expectLater(
        project(cardId: Int64(404)),
        _stateError('card not found'),
      );
      await storage.executeBatch('UPDATE cards SET type = 99 WHERE id = 1');
      await expectLater(project(), _stateError('invalid stored card value'));
      await storage.executeBatch('UPDATE cards SET type = 1 WHERE id = 1');
      await expectLater(project(), _stateError('required for Learn cards'));
      await storage.executeBatch(
        'UPDATE cards SET type = 0, did = 404 WHERE id = 1',
      );
      await expectLater(project(), _stateError('deck not found'));
      await storage.executeBatch(
        'UPDATE cards SET did = 7, odid = 0 WHERE id = 1',
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: true),
      );
      await expectLater(project(), _stateError('original deck ID'));
    },
  );
}

DeckConfig _config() {
  final inner = DeckConfig.defaults().inner
    ..learnSteps.addAll([1, 10])
    ..relearnSteps.addAll([1, 10])
    ..graduatingIntervalGood = 3;
  return DeckConfig(id: Int64(10), name: 'Default', inner: inner);
}

Deck _normalDeck() => Deck(
  id: Int64(7),
  name: 'Normal',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

Deck _homeDeck() => Deck(
  id: Int64(40),
  name: 'Home',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

Deck _filteredDeck({bool reschedule = false}) => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(
    protoDeck.Deck_Filtered(
      reschedule: reschedule,
      previewAgainSecs: 45,
      previewHardSecs: 90,
      previewGoodSecs: 180,
    ),
  ),
);

Future<void> _insertCard(
  CollectionSqliteStorage storage, {
  required int type,
}) => storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 0, $type, $type, 17, 30, 2375, 8, 5, 2, 0, 40, 0,
          '{"s":3.25,"d":4.5}');
''');

Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
