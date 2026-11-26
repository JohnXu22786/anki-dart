// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as protoConfig;
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as protoScheduler;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
      ),
      location: ':memory:',
      nowMillis: () => 1712345678999,
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
CREATE TABLE revlog (
  id INTEGER PRIMARY KEY, cid INTEGER NOT NULL, usn INTEGER NOT NULL,
  ease INTEGER NOT NULL, ivl INTEGER NOT NULL, lastIvl INTEGER NOT NULL,
  factor INTEGER NOT NULL, time INTEGER NOT NULL, type INTEGER NOT NULL
);
CREATE TABLE notes (
  id INTEGER PRIMARY KEY, guid TEXT NOT NULL, mid INTEGER NOT NULL,
  mod INTEGER NOT NULL, usn INTEGER NOT NULL, tags TEXT NOT NULL,
  flds TEXT NOT NULL, sfld INTEGER NOT NULL, csum INTEGER NOT NULL,
  flags INTEGER NOT NULL DEFAULT 0, data TEXT NOT NULL DEFAULT ''
);
CREATE TABLE tags (
  tag TEXT NOT NULL PRIMARY KEY COLLATE NOCASE,
  usn INTEGER NOT NULL, collapsed INTEGER NOT NULL
);
INSERT INTO notes VALUES (100, 'note-guid', 1, 17, 3, '', 'front\x1fback', 'front', 1, 0, '');
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
    'derives Review due from the generated state and answer timing',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      const timing = CollectionAnswerTiming(
        now: 1712345678,
        daysElapsed: 6,
        nextDayAt: 1712347478,
        secsUntilDayRollover: 1800,
      );
      await storage.executeBatch(
        'UPDATE cards SET type = 2, queue = 2, did = 40, odid = 0 WHERE id = 1',
      );
      final generated = await storage.cardAnswerRequestForCard(
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        customData: '',
        answeredAtMillis: Int64(1712345679000),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
      final expectedDue = resolveReviewAnswerDueDay(
        nextState: ReviewCardState(
          scheduledDays: generated.newState.normal.review.scheduledDays,
        ),
        answerTiming: timing,
      );

      final answered = await storage.answerCard(
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345679000),
        millisecondsTaken: 300,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
        usn: 8,
        answerTiming: timing,
        desiredRetention: null,
      );

      expect(answered.due, expectedDue);
      expect((await storage.getCard(Int64(1)))!.due, expectedDue);
    },
  );

  test('resolves answer config from a stored normal card home deck', () async {
    final config = DeckConfig(
      id: Int64(10),
      name: 'Answer config',
      inner: DeckConfig.defaults().inner
        ..capAnswerTimeToSecs = 37
        ..leechAction =
            protoConfig.DeckConfig_Config_LeechAction.LEECH_ACTION_SUSPEND
        ..buryNew = true
        ..buryReviews = false
        ..buryInterdayLearning = true,
    );
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(config);

    final beforeCard = await storage.getCard(Int64.ONE);
    final beforeConfig = storage.deckConfigs.getDeckConfig(config.id);
    final beforeDeck = storage.decks.getDeck(Int64(7));
    final beforeRevlogCount = await storage.queryInt(
      'SELECT count(*) FROM revlog',
    );
    final result = await storage.answerDeckConfigForCard(Int64.ONE);

    expect(result.homeDeckConfigId, Int64(10));
    expect(result.capAnswerTimeToSecs, 37);
    expect(result.suspendLeechedCards, isTrue);
    expect(result.buryNewSiblings, isTrue);
    expect(result.buryReviewSiblings, isFalse);
    expect(result.buryInterdayLearningSiblings, isTrue);
    // These are exactly the caller-resolved config inputs to answerCard;
    // timing, due, fuzz, and scheduling-context inputs remain caller-owned.
    expect({
      'capAnswerTimeToSecs': result.capAnswerTimeToSecs,
      'suspendLeechedCards': result.suspendLeechedCards,
      'buryNewSiblings': result.buryNewSiblings,
      'buryReviewSiblings': result.buryReviewSiblings,
      'buryInterdayLearningSiblings': result.buryInterdayLearningSiblings,
    }, hasLength(5));
    expect(
      (await storage.getCard(Int64.ONE))!.toProto().writeToBuffer(),
      beforeCard!.toProto().writeToBuffer(),
    );
    expect(
      storage.deckConfigs.getDeckConfig(config.id)!.toProto().writeToBuffer(),
      beforeConfig!.toProto().writeToBuffer(),
    );
    expect(
      storage.decks.getDeck(Int64(7))!.toProto().writeToBuffer(),
      beforeDeck!.toProto().writeToBuffer(),
    );
    expect(
      await storage.queryInt('SELECT count(*) FROM revlog'),
      beforeRevlogCount,
    );
    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test(
    'filtered card resolves original home config and ignores assigned config',
    () async {
      final assignedConfig = DeckConfig(
        id: Int64(11),
        name: 'Assigned config',
        inner: DeckConfig.defaults().inner
          ..capAnswerTimeToSecs = 5
          ..buryNew = false,
      );
      final homeConfig = DeckConfig(
        id: Int64(12),
        name: 'Home config',
        inner: DeckConfig.defaults().inner
          ..capAnswerTimeToSecs = 91
          ..leechAction =
              protoConfig.DeckConfig_Config_LeechAction.LEECH_ACTION_SUSPEND
          ..buryNew = true
          ..buryReviews = true
          ..buryInterdayLearning = true,
      );
      storage.deckConfigs
        ..addOrUpdateDeckConfigWithExistingId(assignedConfig)
        ..addOrUpdateDeckConfigWithExistingId(homeConfig);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(7),
          name: 'Filtered with config',
          kind: NormalDeckKind(
            protoDeck.Deck_Normal(configId: assignedConfig.id),
          ),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(40),
          name: 'Home',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: homeConfig.id)),
        ),
      );
      await storage.executeBatch('UPDATE cards SET odid = 40 WHERE id = 1');

      final result = await storage.answerDeckConfigForCard(Int64.ONE);

      expect(result.homeDeckConfigId, homeConfig.id);
      expect(result.capAnswerTimeToSecs, 91);
      expect(result.suspendLeechedCards, isTrue);
      expect(result.buryNewSiblings, isTrue);
      expect(result.buryReviewSiblings, isTrue);
      expect(result.buryInterdayLearningSiblings, isTrue);
    },
  );

  test('missing home config row uses Core defaults and keeps its ID', () async {
    storage.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64(40),
        name: 'Home',
        kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(88))),
      ),
    );
    await storage.executeBatch('UPDATE cards SET odid = 40 WHERE id = 1');

    final result = await storage.answerDeckConfigForCard(Int64.ONE);

    final defaults = DeckConfig.defaults().inner;
    expect(result.homeDeckConfigId, Int64(88));
    expect(result.capAnswerTimeToSecs, defaults.capAnswerTimeToSecs);
    expect(result.suspendLeechedCards, isFalse);
    expect(result.buryNewSiblings, defaults.buryNew);
    expect(result.buryReviewSiblings, defaults.buryReviews);
    expect(result.buryInterdayLearningSiblings, defaults.buryInterdayLearning);
    expect(await storage.queryInt('SELECT count(*) FROM deck_config'), 1);
  });

  test(
    'rejects missing assigned/home decks and missing or invalid config IDs',
    () async {
      await expectLater(
        storage.answerDeckConfigForCard(Int64(999)),
        _stateError('card not found: 999'),
      );

      await storage.executeBatch('DELETE FROM decks WHERE id = 7');
      await expectLater(
        storage.answerDeckConfigForCard(Int64.ONE),
        _stateError('deck not found: 7'),
      );

      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await storage.executeBatch('UPDATE cards SET odid = 99 WHERE id = 1');
      await expectLater(
        storage.answerDeckConfigForCard(Int64.ONE),
        _stateError('home deck not found: 99'),
      );

      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(99),
          name: 'No config',
          kind: FilteredDeckKind(protoDeck.Deck_Filtered()),
        ),
      );
      await expectLater(
        storage.answerDeckConfigForCard(Int64.ONE),
        _stateError('home deck has no config ID: 99'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(99),
          name: 'Invalid config',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ZERO)),
        ),
      );
      await expectLater(
        storage.answerDeckConfigForCard(Int64.ONE),
        _stateError('home deck has no config ID: 99'),
      );
    },
  );

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

  test(
    'constructs rated answer requests from each stored-card dispatch mode',
    () async {
      const context = ReviewSchedulingContext(
        fuzzFactor: 0,
        relearningAgainDelaySecs: 600,
      );
      final cardId = Int64.parseInt('9007199254740997');
      final answeredAtMillis = Int64.parseInt('-9007199254740997');
      await storage.executeBatch(
        'UPDATE cards SET id = $cardId, type = 0, queue = 0, did = 7, odid = 0',
      );

      for (final mode in ['normal', 'rescheduling', 'preview']) {
        storage.decks.addOrUpdateDeckWithExistingId(
          mode == 'normal'
              ? _normalDeck()
              : _filteredDeck(reschedule: mode == 'rescheduling'),
        );
        await storage.executeBatch(
          'UPDATE cards SET did = 7, odid = ${mode == 'normal' ? 0 : 40}',
        );
        final dispatched = await storage.schedulingStatesProtoForCard(
          cardId: cardId,
          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: BigInt.from(13),
          now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
        );
        for (final rating in [
          protoScheduler.CardAnswer_Rating.AGAIN,
          protoScheduler.CardAnswer_Rating.HARD,
          protoScheduler.CardAnswer_Rating.GOOD,
          protoScheduler.CardAnswer_Rating.EASY,
        ]) {
          final customData = mode == 'normal' ? '' : '學習 🦊';
          final request = await storage.cardAnswerRequestForCard(
            cardId: cardId,
            rating: rating,
            customData: customData,
            answeredAtMillis: answeredAtMillis,
            millisecondsTaken: 0xffffffff,
            baseContext: context,
            loadBalancerEnabled: false,
            fuzzSeed: BigInt.from(13),
            now: DateTime.fromMillisecondsSinceEpoch(
              1700000000000,
              isUtc: true,
            ),
          );
          final expected = switch (rating) {
            protoScheduler.CardAnswer_Rating.AGAIN => dispatched.again,
            protoScheduler.CardAnswer_Rating.HARD => dispatched.hard,
            protoScheduler.CardAnswer_Rating.GOOD => dispatched.good,
            protoScheduler.CardAnswer_Rating.EASY => dispatched.easy,
            _ => throw StateError('unexpected test rating: $rating'),
          };
          expect(request.cardId, cardId, reason: mode);
          expect(
            request.currentState.toProto3Json(),
            dispatched.current.toProto3Json(),
            reason: mode,
          );
          final expectedNewState = expected.deepCopy()..customData = customData;
          expect(
            request.newState.toProto3Json(),
            expectedNewState.toProto3Json(),
            reason: '$mode $rating',
          );
          expect(
            request.newState.hasCustomData(),
            isTrue,
            reason: '$mode $rating',
          );
          expect(
            request.newState.customData,
            customData,
            reason: '$mode $rating',
          );
          expect(
            request.currentState.hasCustomData(),
            isFalse,
            reason: '$mode $rating',
          );
          expect(request.rating, rating, reason: mode);
          expect(request.answeredAtMillis, answeredAtMillis, reason: mode);
          expect(request.millisecondsTaken, 0xffffffff, reason: mode);
          expect(
            request.currentState.whichKind(),
            dispatched.current.whichKind(),
            reason: mode,
          );
        }
      }
    },
  );

  test(
    'answerCard updates assigned and parent deck study stats atomically',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(7),
          name: 'Root::Middle::Child',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
          common: protoDeck.Deck_Common(
            lastDayStudied: 5,
            newStudied: 4,
            reviewStudied: 6,
            millisecondsStudied: 700,
          ),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(42),
          name: 'Root::Middle',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
          common: protoDeck.Deck_Common(
            lastDayStudied: 5,
            newStudied: 3,
            reviewStudied: 2,
            millisecondsStudied: 400,
          ),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(41),
          name: 'Root',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
          common: protoDeck.Deck_Common(
            lastDayStudied: 5,
            newStudied: 8,
            reviewStudied: 9,
            millisecondsStudied: 1200,
          ),
        ),
      );
      final cardBefore = await storage.getCard(Int64(1));
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345678000),
        millisecondsTaken: 2500,
        capAnswerTimeToSecs: 1,
        suspendLeechedCards: false,
        answerTiming: const CollectionAnswerTiming(
          now: 1712345678,
          daysElapsed: 6,
          nextDayAt: 1712345978,
          secsUntilDayRollover: 300,
        ),
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,
        desiredRetention: null,
        fuzzedLearningSecs: 90,
      );

      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345678000)))!.interval,
        1,
      );

      for (final deckId in [Int64(7), Int64(42), Int64(41)]) {
        final deck = storage.decks.getDeck(deckId)!;
        expect(deck.common.lastDayStudied, 6);
        expect(deck.common.newStudied, 1, reason: 'deck $deckId');
        expect(deck.common.reviewStudied, 0);
        expect(deck.common.millisecondsStudied, 1000);
        expect(deck.mtimeSecs, Int64(1712345678));
        expect(deck.usn, 8);
      }
      expect(
        storage.collectionUndoChanges.map((change) => change.kind),
        contains(CollectionUndoChangeKind.deck),
      );

      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeck(Int64(7))!.common.newStudied, 4);
      expect(storage.decks.getDeck(Int64(42))!.common.newStudied, 3);
      expect(storage.decks.getDeck(Int64(41))!.common.newStudied, 8);
      expect(
        (await storage.getCard(Int64(1)))!.toProto(),
        cardBefore!.toProto(),
      );
      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345678000))),
        isNull,
      );

      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeck(Int64(7))!.common.newStudied, 1);
      expect(storage.decks.getDeck(Int64(42))!.common.newStudied, 1);
      expect(storage.decks.getDeck(Int64(41))!.common.newStudied, 1);
    },
  );

  test(
    'answerCard classifies original queue and rolls daily stats forward',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(7),
          name: 'Root::Child',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
          common: protoDeck.Deck_Common(
            lastDayStudied: 6,
            newStudied: 10,
            learningStudied: 7,
            reviewStudied: 20,
            millisecondsStudied: 3000,
          ),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(41),
          name: 'Root',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
          common: protoDeck.Deck_Common(
            lastDayStudied: 6,
            newStudied: 10,
            reviewStudied: 20,
            millisecondsStudied: 3000,
          ),
        ),
      );

      const queues = [0, 1, 2, 3, 4, -1, -2, -3];
      for (final (index, queue) in queues.indexed) {
        await storage.executeBatch(
          'UPDATE cards SET type = 0, queue = $queue, did = 7 WHERE id = 1',
        );
        await storage.answerCard(
          buryNewSiblings: false,
          buryInterdayLearningSiblings: false,
          buryReviewSiblings: false,
          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: Int64(1712345680000 + index),
          millisecondsTaken: 100,
          capAnswerTimeToSecs: 5,
          suspendLeechedCards: false,
          answerTiming: _answerTiming(
            daysElapsed: 6,
            secsUntilDayRollover: 1800,
          ),

          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,

          desiredRetention: null,
          fuzzedLearningSecs: 90,
        );
        final deck = storage.decks.getDeck(Int64(7))!;
        expect(
          deck.common.newStudied,
          10 + queues.take(index + 1).where((value) => value == 0).length,
          reason: 'queue $queue',
        );
        expect(
          deck.common.reviewStudied,
          20 +
              queues
                  .take(index + 1)
                  .where((value) => value == 2 || value == 3)
                  .length,
          reason: 'queue $queue',
        );
        expect(deck.common.millisecondsStudied, 3000 + (index + 1) * 100);
      }

      await storage.executeBatch(
        'UPDATE cards SET type = 0, queue = 0, did = 7 WHERE id = 1',
      );
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345680100),
        millisecondsTaken: 2500,
        capAnswerTimeToSecs: 1,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 7, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        fuzzedLearningSecs: 90,
      );
      final rolledOver = storage.decks.getDeck(Int64(7))!;
      expect(rolledOver.common.lastDayStudied, 7);
      expect(rolledOver.common.newStudied, 1);
      expect(rolledOver.common.learningStudied, 0);
      expect(rolledOver.common.reviewStudied, 0);
      expect(rolledOver.common.millisecondsStudied, 1000);

      database.execute('UPDATE decks SET common = ? WHERE id = 7', [
        protoDeck.Deck_Common(
          lastDayStudied: 7,
          millisecondsStudied: 0x7fffffff,
        ).writeToBuffer(),
      ]);
      await storage.executeBatch(
        'UPDATE cards SET type = 0, queue = 0, did = 7 WHERE id = 1',
      );
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345680101),
        millisecondsTaken: 1,
        capAnswerTimeToSecs: 1,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 7, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        fuzzedLearningSecs: 90,
      );
      expect(
        storage.decks.getDeck(Int64(7))!.common.millisecondsStudied,
        -0x80000000,
      );
    },
  );

  test(
    'answerCard updates the currently assigned filtered deck stats',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(7),
          name: 'Root::Filtered',
          kind: FilteredDeckKind(protoDeck.Deck_Filtered(previewGoodSecs: 180)),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64(41),
          name: 'Root',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
        ),
      );
      await storage.executeBatch(
        'UPDATE cards SET type = 0, queue = 2, did = 7, odid = 40 WHERE id = 1',
      );
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345680200),
        millisecondsTaken: 250,
        capAnswerTimeToSecs: 1,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        dueTimestampSecs: 1712346000,
      );
      expect(storage.decks.getDeck(Int64(7))!.common.reviewStudied, 1);
      expect(storage.decks.getDeck(Int64(7))!.common.millisecondsStudied, 250);
      expect(storage.decks.getDeck(Int64(41))!.common.reviewStudied, 1);
      expect(storage.decks.getDeck(Int64(40))!.common.reviewStudied, 0);
    },
  );

  test(
    'answerCard caps normal elapsed time before revlog persistence',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      final cases = [
        (millisecondsTaken: 900, capSecs: 1, expectedMillis: 900),
        (millisecondsTaken: 1000, capSecs: 1, expectedMillis: 1000),
        (millisecondsTaken: 2500, capSecs: 1, expectedMillis: 1000),
        (millisecondsTaken: 2500, capSecs: 0, expectedMillis: 0),
        (millisecondsTaken: 100, capSecs: 0xffffffff, expectedMillis: 100),
      ];

      for (final (index, testCase) in cases.indexed) {
        await storage.executeBatch(
          'UPDATE cards SET type = 0, queue = 0, did = 7, odid = 0 WHERE id = 1',
        );
        final answerId = Int64(1712345678000 + index);
        await storage.answerCard(
          buryNewSiblings: false,
          buryInterdayLearningSiblings: false,
          buryReviewSiblings: false,
          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: answerId,
          millisecondsTaken: testCase.millisecondsTaken,
          capAnswerTimeToSecs: testCase.capSecs,
          suspendLeechedCards: false,
          answerTiming: _answerTiming(
            daysElapsed: 6,
            secsUntilDayRollover: 1800,
          ),

          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,

          desiredRetention: null,
          fuzzedLearningSecs: 90,
        );
        expect(
          storage.revlog.getRevlogEntry(RevlogId(answerId))!.takenMillis,
          testCase.expectedMillis,
        );
      }
    },
  );

  test('answerCard caps Preview and rescheduling elapsed time', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    final previewAnswerId = Int64(1712345679000);
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
    await storage.executeBatch(
      'UPDATE cards SET type = 0, queue = 0, did = 7, odid = 40 WHERE id = 1',
    );
    await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: previewAnswerId,
      millisecondsTaken: 2500,
      capAnswerTimeToSecs: 1,
      suspendLeechedCards: false,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: null,
      dueTimestampSecs: 1712346000,
    );
    expect(
      storage.revlog.getRevlogEntry(RevlogId(previewAnswerId))!.takenMillis,
      1000,
    );

    final reschedulingAnswerId = Int64(1712345680000);
    storage.decks.addOrUpdateDeckWithExistingId(
      _filteredDeck(reschedule: true),
    );
    await storage.executeBatch(
      'UPDATE cards SET type = 1, queue = 1, did = 7, odid = 40 WHERE id = 1',
    );
    await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: reschedulingAnswerId,
      millisecondsTaken: 2500,
      capAnswerTimeToSecs: 1,
      suspendLeechedCards: false,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      baseContext: context,
      scheduledSecs: 90,
      elapsedSecs: 12,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: 0.91,
      fuzzedLearningSecs: 90,
    );
    expect(
      storage.revlog
          .getRevlogEntry(RevlogId(reschedulingAnswerId))!
          .takenMillis,
      1000,
    );
  });

  test(
    'answerCard rejects caps that cannot be represented in milliseconds',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      for (final capSecs in [-1, 0x100000000]) {
        await expectLater(
          storage.answerCard(
            buryNewSiblings: false,
            buryInterdayLearningSiblings: false,
            buryReviewSiblings: false,
            cardId: Int64(1),
            rating: protoScheduler.CardAnswer_Rating.GOOD,
            answeredAtMillis: Int64(1712345681000 + capSecs),
            millisecondsTaken: 100,
            capAnswerTimeToSecs: capSecs,
            suspendLeechedCards: false,
            answerTiming: _answerTiming(
              daysElapsed: 6,
              secsUntilDayRollover: 1800,
            ),

            baseContext: context,
            loadBalancerEnabled: false,
            fuzzSeed: null,
            usn: 8,

            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345680999))),
        isNull,
      );
    },
  );

  test('answers and records one normal stored card for every rating', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
    await storage.executeBatch(
      "UPDATE cards SET type = 0, queue = 0, did = 7, odid = 0, "
      "data = '{\"cd\":\"stored 🦊\"}' WHERE id = 1",
    );
    final ratings = [
      protoScheduler.CardAnswer_Rating.AGAIN,
      protoScheduler.CardAnswer_Rating.HARD,
      protoScheduler.CardAnswer_Rating.GOOD,
      protoScheduler.CardAnswer_Rating.EASY,
    ];

    for (final (index, rating) in ratings.indexed) {
      await storage.executeBatch(
        'UPDATE cards SET type = 0, queue = 0, did = 7, odid = 0 WHERE id = 1',
      );
      final answerTime = Int64(1712345678000 + index);
      final applied = await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 3600),

        cardId: Int64(1),
        rating: rating,
        answeredAtMillis: answerTime,
        millisecondsTaken: 850,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: BigInt.from(13),
        usn: 7,

        desiredRetention: 0.91,
        fuzzedLearningSecs: 90,
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );

      expect(applied.customData, 'stored 🦊');
      expect((await storage.getCard(Int64(1)))!.toProto(), applied.toProto());
      final revlog = storage.revlog.getRevlogEntry(RevlogId(answerTime));
      expect(revlog, isNotNull);
      expect(revlog!.buttonChosen, index + 1);
    }

    final committed = await storage.getCard(Int64(1));
    final lastRevlog = RevlogId(Int64(1712345678003));
    await storage.undoLastCollectionOperation();
    expect(
      (await storage.getCard(Int64(1)))!.toProto(),
      isNot(committed!.toProto()),
    );
    expect(storage.revlog.getRevlogEntry(lastRevlog), isNull);
    await storage.redoLastCollectionOperation();
    expect((await storage.getCard(Int64(1)))!.toProto(), committed.toProto());
    expect(storage.revlog.getRevlogEntry(lastRevlog), isNotNull);
  });

  test(
    'answerCard buries same-note siblings selected by caller flags and original queue',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await storage.executeBatch('''
INSERT INTO cards VALUES
 (2, 100, 7, 1, 11, 1, 0, 0, 22, 31, 2400, 9, 2, 1, 0, 0, 3, 'new'),
 (3, 100, 7, 2, 12, 2, 2, 2, 23, 32, 2500, 10, 3, 2, 0, 0, 4, 'review'),
 (4, 100, 7, 3, 13, 3, 3, 3, 24, 33, 2600, 11, 4, 3, 0, 0, 5, 'daylearn'),
 (5, 100, 7, 4, 14, 4, 1, 1, 25, 34, 2700, 12, 5, 4, 0, 0, 6, 'learn'),
 (6, 100, 7, 5, 15, 5, 1, 4, 26, 35, 2800, 13, 6, 5, 0, 0, 7, 'preview'),
 (7, 100, 7, 6, 16, 6, 0, -1, 27, 36, 2900, 14, 7, 6, 0, 0, 8, 'suspended'),
 (8, 100, 7, 7, 17, 7, 0, -2, 28, 37, 3000, 15, 8, 7, 0, 0, 9, 'buried'),
 (9, 100, 7, 8, 18, 8, 0, -3, 29, 38, 3100, 16, 9, 8, 0, 0, 10, 'user-buried'),
 (10, 101, 7, 9, 19, 9, 0, 0, 30, 39, 3200, 17, 10, 9, 0, 0, 11, 'other-note');
INSERT INTO notes VALUES (101, 'other-note-guid', 1, 17, 3, '', 'other\\x1fback', 'other', 2, 0, '');
''');
      final originalSiblings = <int, Card>{
        for (var id = 2; id <= 10; id++)
          id: (await storage.getCard(Int64(id)))!,
      };
      final queues = [
        CardQueue.newCard,
        CardQueue.learn,
        CardQueue.review,
        CardQueue.dayLearn,
        CardQueue.previewRepeat,
        CardQueue.suspended,
        CardQueue.schedBuried,
        CardQueue.userBuried,
      ];
      var answerMillis = 1712345680000;
      for (final answeredQueue in queues) {
        for (var mask = 0; mask < 8; mask++) {
          await storage.executeBatch(
            'UPDATE cards SET type = 0, queue = ${answeredQueue.value} WHERE id = 1',
          );
          final flags = [mask & 1 != 0, mask & 2 != 0, mask & 4 != 0];
          final buryNew = flags[0];
          final buryInterdayLearning = flags[1];
          final buryReviews = flags[2];
          await storage.answerCard(
            capAnswerTimeToSecs: 120,
            suspendLeechedCards: false,
            buryNewSiblings: buryNew,
            buryInterdayLearningSiblings: buryInterdayLearning,
            buryReviewSiblings: buryReviews,
            answerTiming: _answerTiming(
              daysElapsed: 6,
              secsUntilDayRollover: 1800,
            ),

            cardId: Int64(1),
            rating: protoScheduler.CardAnswer_Rating.GOOD,
            answeredAtMillis: Int64(answerMillis),
            millisecondsTaken: 300,
            baseContext: context,
            loadBalancerEnabled: false,
            fuzzSeed: null,
            usn: 19,

            desiredRetention: null,
            fuzzedLearningSecs: 90,
          );
          expect(
            (await storage.getCard(Int64(1)))!.queue,
            isNot(CardQueue.schedBuried),
            reason: 'the answered card is never selected as its own sibling',
          );

          final permitsInterday =
              answeredQueue == CardQueue.learn ||
              answeredQueue == CardQueue.previewRepeat ||
              answeredQueue == CardQueue.dayLearn;
          final permitsReviews =
              permitsInterday || answeredQueue == CardQueue.review;
          final expectedBuried = <int>{
            if (buryNew) 2,
            if (buryReviews && permitsReviews) 3,
            if (buryInterdayLearning && permitsInterday) 4,
          };
          for (final entry in originalSiblings.entries) {
            final id = entry.key;
            final original = entry.value;
            final actual = (await storage.getCard(original.id))!;
            expect(
              actual.queue,
              expectedBuried.contains(id)
                  ? CardQueue.schedBuried
                  : original.queue,
              reason: 'answered=$answeredQueue mask=$mask sibling=$id',
            );
            if (expectedBuried.contains(id)) {
              expect(actual.usn, 19);
              expect(actual.mtimeSecs, Int64(1712345678));
              final expected = Card.fromProto(
                original.toProto()
                  ..queue = CardQueue.schedBuried.value
                  ..usn = 19
                  ..mtimeSecs = Int64(1712345678),
              );
              expect(
                actual.toProto(),
                expected.toProto(),
                reason: 'bury must preserve every non-queue Card field',
              );
            } else {
              expect(actual.toProto(), original.toProto());
            }
          }
          await storage.undoLastCollectionOperation();
          for (final entry in originalSiblings.entries) {
            final id = entry.key;
            final original = entry.value;
            expect(
              (await storage.getCard(original.id))!.toProto(),
              original.toProto(),
              reason: 'undo answered=$answeredQueue mask=$mask sibling=$id',
            );
          }
          answerMillis++;
        }
      }
    },
  );

  test('answerCard stores answer time except for filtered Preview', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    const originalReviewTime = 1699999999;
    await storage.executeBatch(
      "UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, "
      "data = '{\"s\":3.25,\"d\":4.5,\"lrt\":$originalReviewTime}' "
      'WHERE id = 1',
    );
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());

    const normalAnswerTime = 1712345680123;
    final normal = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      capAnswerTimeToSecs: 120,
      suspendLeechedCards: false,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(normalAnswerTime),
      millisecondsTaken: 300,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: null,
    );
    expect(normal.lastReviewTimeSecs, Int64(normalAnswerTime ~/ 1000));
    expect(
      (await storage.getCard(Int64(1)))!.lastReviewTimeSecs,
      Int64(normalAnswerTime ~/ 1000),
    );
    final normalRevlog = RevlogId(Int64(normalAnswerTime));
    expect(storage.revlog.getRevlogEntry(normalRevlog), isNotNull);
    await storage.undoLastCollectionOperation();
    expect(
      (await storage.getCard(Int64(1)))!.lastReviewTimeSecs,
      Int64(originalReviewTime),
    );
    expect(storage.revlog.getRevlogEntry(normalRevlog), isNull);
    await storage.redoLastCollectionOperation();
    expect(
      (await storage.getCard(Int64(1)))!.lastReviewTimeSecs,
      Int64(normalAnswerTime ~/ 1000),
    );
    expect(storage.revlog.getRevlogEntry(normalRevlog), isNotNull);

    await storage.executeBatch(
      'UPDATE cards SET type = 1, queue = 1, did = 7, odid = 40 WHERE id = 1',
    );
    storage.decks.addOrUpdateDeckWithExistingId(
      _filteredDeck(reschedule: true),
    );
    const rescheduleAnswerTime = 1712345681123;
    final rescheduled = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      capAnswerTimeToSecs: 120,
      suspendLeechedCards: false,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(rescheduleAnswerTime),
      millisecondsTaken: 300,
      baseContext: context,
      scheduledSecs: 90,
      elapsedSecs: 12,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: 0.91,
      fuzzedLearningSecs: 90,
    );
    expect(rescheduled.lastReviewTimeSecs, Int64(rescheduleAnswerTime ~/ 1000));
    expect(
      (await storage.getCard(Int64(1)))!.lastReviewTimeSecs,
      Int64(rescheduleAnswerTime ~/ 1000),
    );

    await storage.executeBatch(
      'UPDATE cards SET type = 0, queue = 0, did = 7, odid = 40 WHERE id = 1',
    );
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
    const previewAnswerTime = 1712345682123;
    final preview = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      capAnswerTimeToSecs: 120,
      suspendLeechedCards: false,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: Int64(previewAnswerTime),
      millisecondsTaken: 300,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: null,
      dueTimestampSecs: 1712346000,
    );
    expect(preview.lastReviewTimeSecs, Int64(rescheduleAnswerTime ~/ 1000));
    expect(
      (await storage.getCard(Int64(1)))!.lastReviewTimeSecs,
      Int64(rescheduleAnswerTime ~/ 1000),
    );
    expect(
      storage.revlog.getRevlogEntry(RevlogId(Int64(previewAnswerTime))),
      isNotNull,
    );
  });

  test('answerCard suspends caller-selected leeched answers before commit', () async {
    const context = ReviewSchedulingContext(
      fuzzFactor: 0,
      leechThreshold: 1,
      relearningAgainDelaySecs: 600,
    );
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
    await storage.executeBatch(
      'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, lapses = 7 WHERE id = 1',
    );
    await storage.executeBatch('''
INSERT INTO cards VALUES
 (20, 100, 7, 1, 11, 1, 0, 0, 22, 31, 2400, 9, 2, 1, 0, 0, 3, 'bury-new'),
 (21, 100, 7, 2, 12, 2, 2, 2, 23, 32, 2500, 10, 3, 2, 0, 0, 4, 'bury-review'),
 (22, 100, 7, 3, 13, 3, 3, 3, 24, 33, 2600, 11, 4, 3, 0, 0, 5, 'keep-daylearn');
''');

    const suspendedAnswerId = 1712345683123;
    final suspended = await storage.answerCard(
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: Int64(suspendedAnswerId),
      millisecondsTaken: 300,
      capAnswerTimeToSecs: 120,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      desiredRetention: null,
      fuzzedLearningSecs: 90,
      suspendLeechedCards: true,
      buryNewSiblings: true,
      buryInterdayLearningSiblings: true,
      buryReviewSiblings: true,
    );
    expect(suspended.queue, CardQueue.suspended);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.suspended);
    expect((await storage.getCard(Int64(20)))!.queue, CardQueue.schedBuried);
    expect((await storage.getCard(Int64(21)))!.queue, CardQueue.schedBuried);
    expect((await storage.getCard(Int64(22)))!.queue, CardQueue.dayLearn);
    expect(
      storage.revlog.getRevlogEntry(RevlogId(Int64(suspendedAnswerId))),
      isNotNull,
    );
    expect((await storage.getNote(Int64(100)))!.tags, [
      'leech',
    ], reason: 'a leeched answer adds the Core leech tag');
    expect(database.select('SELECT tag, usn, collapsed FROM tags'), [
      {'tag': 'leech', 'usn': 8, 'collapsed': 1},
    ]);
    expect(
      database.select('SELECT mod, usn FROM notes WHERE id = 100').single,
      {'mod': 1712345678, 'usn': 8},
    );
    expect(
      storage.collectionUndoChanges.map((change) => change.kind),
      containsAll([
        CollectionUndoChangeKind.card,
        CollectionUndoChangeKind.revlog,
        CollectionUndoChangeKind.note,
        CollectionUndoChangeKind.noteTags,
        CollectionUndoChangeKind.tag,
        CollectionUndoChangeKind.deck,
      ]),
    );
    await storage.undoLastCollectionOperation();
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.review);
    expect((await storage.getCard(Int64(20)))!.queue, CardQueue.newCard);
    expect((await storage.getCard(Int64(21)))!.queue, CardQueue.review);
    expect((await storage.getCard(Int64(22)))!.queue, CardQueue.dayLearn);
    expect((await storage.getNote(Int64(100)))!.tags, isEmpty);
    expect(
      database.select('SELECT mod, usn FROM notes WHERE id = 100').single,
      {'mod': 17, 'usn': 3},
    );
    expect(database.select('SELECT * FROM tags'), isEmpty);
    expect(storage.decks.getDeck(Int64(7))!.common.reviewStudied, 0);
    expect(
      storage.revlog.getRevlogEntry(RevlogId(Int64(suspendedAnswerId))),
      isNull,
    );
    await storage.redoLastCollectionOperation();
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.suspended);
    expect((await storage.getCard(Int64(20)))!.queue, CardQueue.schedBuried);
    expect((await storage.getCard(Int64(21)))!.queue, CardQueue.schedBuried);
    expect((await storage.getCard(Int64(22)))!.queue, CardQueue.dayLearn);
    expect((await storage.getNote(Int64(100)))!.tags, ['leech']);
    expect(database.select('SELECT tag FROM tags'), [
      {'tag': 'leech'},
    ]);
    expect(storage.decks.getDeck(Int64(7))!.common.reviewStudied, 1);
    expect(
      storage.revlog.getRevlogEntry(RevlogId(Int64(suspendedAnswerId))),
      isNotNull,
    );

    await storage.executeBatch("UPDATE notes SET tags = '' WHERE id = 100");
    await storage.executeBatch('DELETE FROM tags');
    await storage.executeBatch(
      'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, lapses = 7 WHERE id = 1',
    );
    final unsuspended = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: Int64(1712345684123),
      millisecondsTaken: 300,
      capAnswerTimeToSecs: 120,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      desiredRetention: null,
      fuzzedLearningSecs: 90,
      suspendLeechedCards: false,
    );
    expect(unsuspended.queue, CardQueue.learn);
    expect((await storage.getNote(Int64(100)))!.tags, ['leech']);
    expect(database.select('SELECT tag, usn FROM tags'), [
      {'tag': 'leech', 'usn': 8},
    ]);

    await storage.executeBatch(
      'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, lapses = 0 WHERE id = 1',
    );
    final ordinary = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: Int64(1712345685123),
      millisecondsTaken: 300,
      capAnswerTimeToSecs: 120,
      baseContext: const ReviewSchedulingContext(
        fuzzFactor: 0,
        leechThreshold: 8,
        relearningAgainDelaySecs: 600,
      ),
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      desiredRetention: null,
      fuzzedLearningSecs: 90,
      suspendLeechedCards: true,
    );
    expect(ordinary.queue, CardQueue.learn);
    expect((await storage.getNote(Int64(100)))!.tags, ['leech']);

    await storage.executeBatch("UPDATE notes SET tags = '' WHERE id = 100");
    await storage.executeBatch('DELETE FROM tags');
    storage.decks.addOrUpdateDeckWithExistingId(
      _filteredDeck(reschedule: true),
    );
    await storage.executeBatch(
      'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 40, lapses = 7 WHERE id = 1',
    );
    final rescheduledLeech = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: Int64(1712345685623),
      millisecondsTaken: 300,
      capAnswerTimeToSecs: 120,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      desiredRetention: null,
      fuzzedLearningSecs: 90,
      suspendLeechedCards: true,
    );
    expect(rescheduledLeech.queue, CardQueue.suspended);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.suspended);
    expect((await storage.getNote(Int64(100)))!.tags, ['leech']);

    await storage.executeBatch(
      'UPDATE cards SET type = 0, queue = 0, did = 7, odid = 40, lapses = 0 WHERE id = 1',
    );
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
    final preview = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.AGAIN,
      answeredAtMillis: Int64(1712345686123),
      millisecondsTaken: 300,
      capAnswerTimeToSecs: 120,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      desiredRetention: null,
      dueTimestampSecs: 1712346000,
      suspendLeechedCards: true,
    );
    expect(preview.queue, CardQueue.previewRepeat);
    expect((await storage.getNote(Int64(100)))!.tags, ['leech']);
  });

  test(
    'answerCard does not register leech tags for ordinary or Preview answers',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0, leechThreshold: 1);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await storage.executeBatch(
        'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, lapses = 0 WHERE id = 1',
      );
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.AGAIN,
        answeredAtMillis: Int64(1712345687001),
        millisecondsTaken: 300,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        fuzzedLearningSecs: 90,
      );
      expect((await storage.getNote(Int64(100)))!.tags, isEmpty);
      expect(database.select('SELECT * FROM tags'), isEmpty);

      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
      await storage.executeBatch(
        'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 40, lapses = 7 WHERE id = 1',
      );
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.AGAIN,
        answeredAtMillis: Int64(1712345687002),
        millisecondsTaken: 300,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: true,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        dueTimestampSecs: 1712346000,
      );
      expect((await storage.getNote(Int64(100)))!.tags, isEmpty);
      expect(database.select('SELECT * FROM tags'), isEmpty);
    },
  );

  test(
    'answerCard preserves case-insensitive leech and unrelated tags',
    () async {
      const context = ReviewSchedulingContext(
        fuzzFactor: 0,
        leechThreshold: 1,
        relearningAgainDelaySecs: 600,
      );
      await storage.executeBatch("""
      UPDATE notes SET tags = 'zeta LeEcH alpha' WHERE id = 100;
      INSERT INTO tags VALUES ('leech', 4, 0);
      INSERT INTO tags VALUES ('alpha', 5, 1);
      INSERT INTO tags VALUES ('zeta', 6, 1);
    """);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await storage.executeBatch(
        'UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, lapses = 7 WHERE id = 1',
      );

      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.AGAIN,
        answeredAtMillis: Int64(1712345687003),
        millisecondsTaken: 300,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        fuzzedLearningSecs: 90,
      );

      expect((await storage.getNote(Int64(100)))!.tags, [
        'zeta',
        'LeEcH',
        'alpha',
      ]);
      expect(
        database.select('SELECT mod, usn FROM notes WHERE id = 100').single,
        {'mod': 17, 'usn': 3},
        reason: 'an already-present leech tag does not modify the Note',
      );
      expect(
        database.select('SELECT tag, usn, collapsed FROM tags ORDER BY tag'),
        [
          {'tag': 'alpha', 'usn': 5, 'collapsed': 1},
          {'tag': 'leech', 'usn': 4, 'collapsed': 0},
          {'tag': 'zeta', 'usn': 6, 'collapsed': 1},
        ],
      );

      await storage.executeBatch("""
        UPDATE notes SET tags = 'zeta alpha fooſ foos' WHERE id = 100;
        UPDATE tags SET tag = 'Leech' WHERE tag = 'leech';
        INSERT INTO tags VALUES ('foos', 7, 1);
        UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, lapses = 7
        WHERE id = 1;
      """);
      await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.AGAIN,
        answeredAtMillis: Int64(1712345687004),
        millisecondsTaken: 300,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 9,

        desiredRetention: null,
        fuzzedLearningSecs: 90,
      );
      expect((await storage.getNote(Int64(100)))!.tags, [
        'alpha',
        'fooſ',
        'Leech',
        'zeta',
      ]);
      expect(unicodeCaseFold('fooſ'), unicodeCaseFold('foos'));
      expect(
        database.select('SELECT tag, usn, collapsed FROM tags WHERE tag = ?', [
          'leech',
        ]),
        [
          {'tag': 'Leech', 'usn': 4, 'collapsed': 0},
        ],
      );
    },
  );

  test('recordCardAnswerResult rejects a leech tag for another Note', () async {
    final card = (await storage.getCard(Int64(1)))!;
    final undoGeneration = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: card,
        revlog: RevlogEntry(
          id: RevlogId(Int64(1712345687005)),
          cardId: card.id,
        ),
        leechTagNoteId: Int64(101),
        leechTagUsn: 8,
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await storage.getCard(card.id), isNotNull);
    expect(database.select('SELECT * FROM revlog'), isEmpty);
    expect((await storage.getNote(Int64(100)))!.tags, isEmpty);
    expect(database.select('SELECT * FROM tags'), isEmpty);
    expect(storage.collectionUndoGeneration, undoGeneration);

    await storage.executeBatch('UPDATE cards SET nid = 101 WHERE id = 1');
    await expectLater(
      storage.recordCardAnswerResult(
        card: card,
        revlog: RevlogEntry(
          id: RevlogId(Int64(1712345687006)),
          cardId: card.id,
        ),
        leechTagNoteId: card.noteId,
        leechTagUsn: 8,
      ),
      _stateError('leech tag note no longer matches answered card'),
    );
    expect(database.select('SELECT * FROM revlog'), isEmpty);
    expect((await storage.getNote(Int64(100)))!.tags, isEmpty);
    expect(database.select('SELECT * FROM tags'), isEmpty);
  });

  test(
    'rejects a card changed while its answer request is being built',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await storage.executeBatch(
        "INSERT INTO cards VALUES (20, 100, 7, 1, 11, 1, 0, 0, 22, 31, 2400, 9, 2, 1, 0, 0, 3, 'stale-answer-sibling')",
      );
      final pendingAnswer = storage.answerCard(
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        buryNewSiblings: true,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345679000),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
      );

      database.execute('UPDATE cards SET due = 18 WHERE id = 1');

      await expectLater(
        pendingAnswer,
        _stateError('card changed while preparing answer'),
      );
      expect((await storage.getCard(Int64(1)))!.due, 18);
      expect((await storage.getCard(Int64(20)))!.queue, CardQueue.newCard);
      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345679000))),
        isNull,
      );
    },
  );

  test('does not overwrite a card changed before answer commit', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    storage.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64(7),
        name: 'Normal',
        kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
        common: protoDeck.Deck_Common(
          lastDayStudied: 6,
          newStudied: 4,
          millisecondsStudied: 200,
        ),
      ),
    );
    final operationEntered = Completer<void>();
    final allowOperationToFinish = Completer<void>();
    final existingOperation = storage.runUndoableCollectionOperation(
      prepare: () async {
        operationEntered.complete();
        await allowOperationToFinish.future;
        return true;
      },
      apply: () async =>
          database.execute('UPDATE cards SET due = 18 WHERE id = 1'),
    );
    await operationEntered.future;

    final pendingAnswer = storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      capAnswerTimeToSecs: 120,
      suspendLeechedCards: false,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(1712345679001),
      millisecondsTaken: 300,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: null,
      fuzzedLearningSecs: 90,
    );
    await Future<void>.delayed(Duration.zero);
    allowOperationToFinish.complete();
    await existingOperation;

    await expectLater(
      pendingAnswer,
      _stateError('card changed while preparing answer'),
    );
    expect((await storage.getCard(Int64(1)))!.due, 18);
    expect(
      storage.revlog.getRevlogEntry(RevlogId(Int64(1712345679001))),
      isNull,
    );
    expect(storage.decks.getDeck(Int64(7))!.common.newStudied, 4);
    expect(storage.decks.getDeck(Int64(7))!.common.millisecondsStudied, 200);
  });

  test(
    'routes Preview and rescheduling answers and validates caller due data',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      await storage.executeBatch(
        "UPDATE cards SET type = 0, queue = 0, did = 7, odid = 40, "
        "data = '{\"cd\":\"preview data\"}' WHERE id = 1",
      );
      await storage.executeBatch('''
INSERT INTO cards VALUES
 (20, 100, 7, 1, 11, 1, 0, 0, 22, 31, 2400, 9, 2, 1, 0, 0, 3, 'filtered-new-sibling'),
 (21, 100, 7, 2, 12, 2, 2, 2, 23, 32, 2500, 10, 3, 2, 0, 0, 4, 'filtered-review-sibling'),
 (22, 100, 7, 3, 13, 3, 3, 3, 24, 33, 2600, 11, 4, 3, 0, 0, 5, 'filtered-daylearn-sibling');
''');
      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: false),
      );
      final preview = await storage.answerCard(
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        buryNewSiblings: true,
        buryInterdayLearningSiblings: true,
        buryReviewSiblings: true,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.AGAIN,
        answeredAtMillis: Int64(1712345680000),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        dueTimestampSecs: 1712346000,
      );
      expect(preview.queue, CardQueue.previewRepeat);
      expect(preview.due, 1712346000);
      expect(preview.customData, 'preview data');
      expect((await storage.getCard(Int64(20)))!.queue, CardQueue.schedBuried);
      expect((await storage.getCard(Int64(21)))!.queue, CardQueue.review);
      expect((await storage.getCard(Int64(22)))!.queue, CardQueue.dayLearn);
      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(20)))!.queue, CardQueue.newCard);
      expect((await storage.getCard(Int64(21)))!.queue, CardQueue.review);
      expect((await storage.getCard(Int64(22)))!.queue, CardQueue.dayLearn);

      await storage.executeBatch(
        'UPDATE cards SET type = 1, queue = 1, did = 7, odid = 40 WHERE id = 1',
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: true),
      );
      await expectLater(
        storage.answerCard(
          buryNewSiblings: false,
          buryInterdayLearningSiblings: false,
          buryReviewSiblings: false,
          capAnswerTimeToSecs: 120,
          suspendLeechedCards: false,
          answerTiming: _answerTiming(
            daysElapsed: 6,
            secsUntilDayRollover: 1800,
          ),

          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: Int64(1712345680001),
          millisecondsTaken: 300,
          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,

          desiredRetention: 0.91,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('required for Learn cards'),
          ),
        ),
      );
      final before = (await storage.getCard(Int64(1)))!.toProto();
      await expectLater(
        storage.answerCard(
          buryNewSiblings: false,
          buryInterdayLearningSiblings: false,
          buryReviewSiblings: false,
          capAnswerTimeToSecs: 120,
          suspendLeechedCards: false,
          answerTiming: _answerTiming(
            daysElapsed: 6,
            secsUntilDayRollover: 1800,
          ),

          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: Int64(1712345680002),
          millisecondsTaken: 300,
          baseContext: context,
          scheduledSecs: 90,
          elapsedSecs: 12,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,

          desiredRetention: 0.91,
        ),
        throwsArgumentError,
      );
      expect((await storage.getCard(Int64(1)))!.toProto(), before);

      final rescheduling = await storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        buryReviewSiblings: false,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345680003),
        millisecondsTaken: 300,
        baseContext: context,
        scheduledSecs: 90,
        elapsedSecs: 12,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: 0.91,
        fuzzedLearningSecs: 90,
      );
      expect(rescheduling.deckId, Int64(7));
      expect(rescheduling.queue, CardQueue.learn);
      expect(rescheduling.due, 90);
      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345680003))),
        isNotNull,
      );

      await storage.executeBatch('UPDATE cards SET type = 99 WHERE id = 1');
      await expectLater(
        storage.answerCard(
          buryNewSiblings: false,
          buryInterdayLearningSiblings: false,
          buryReviewSiblings: false,
          capAnswerTimeToSecs: 120,
          suspendLeechedCards: false,
          answerTiming: _answerTiming(
            daysElapsed: 6,
            secsUntilDayRollover: 1800,
          ),

          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: Int64(1712345680004),
          millisecondsTaken: 300,
          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,

          desiredRetention: 0.91,
        ),
        throwsA(isA<InvalidModelValue>()),
      );
    },
  );

  test('revlog collision rolls back the card and cache update', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
    await storage.executeBatch(
      "UPDATE cards SET type = 2, queue = 2, did = 7, odid = 0, data = '{}' WHERE id = 1",
    );
    await storage.executeBatch(
      "INSERT INTO cards VALUES (20, 100, 7, 1, 11, 1, 2, 2, 22, 31, 2400, 9, 2, 1, 0, 0, 3, 'answer-sibling')",
    );
    final cachedPreset = Int64(10);
    final cache = LoadBalancerCache.fromHistory(
      cardsByDay: List.generate(
        99,
        (index) => index == 0
            ? [(Int64(90), Int64(100), Int64(7))]
            : <LoadBalancerHistoryCard>[],
      ),
      deckConfigByDeck: {Int64(7): cachedPreset},
      configs: {cachedPreset: _config()},
    );
    final loadBalancerContext = CollectionLoadBalancerContext(
      daysElapsed: 0,
      nextDayAt: Int64(1712345678),
      cache: cache,
    );
    const answerTime = 1712345681000;
    await storage.executeBatch(
      'INSERT INTO revlog VALUES ($answerTime, 1, 0, 3, 30, 30, 2500, 0, 0)',
    );
    final before = (await storage.getCard(Int64(1)))!.toProto();
    final beforeUndo = storage.collectionUndoGeneration;

    await expectLater(
      storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        buryReviewSiblings: true,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(answerTime),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
      ),
      throwsStateError,
    );
    expect((await storage.getCard(Int64(1)))!.toProto(), before);
    expect((await storage.getCard(Int64(20)))!.queue, CardQueue.review);
    expect(storage.collectionUndoGeneration, beforeUndo);

    await expectLater(
      storage.answerCard(
        buryNewSiblings: false,
        buryInterdayLearningSiblings: false,
        capAnswerTimeToSecs: 120,
        suspendLeechedCards: false,
        buryReviewSiblings: true,
        answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(answerTime),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,

        desiredRetention: null,
        loadBalancerContext: loadBalancerContext,
        homeDeckConfigId: cachedPreset,
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      ),
      throwsStateError,
    );
    expect((await storage.getCard(Int64(1)))!.toProto(), before);
    expect((await storage.getCard(Int64(20)))!.queue, CardQueue.review);
    expect(storage.collectionUndoGeneration, beforeUndo);
    expect(cache.daysByPreset[cachedPreset]![0].cardCount, 1);
    expect(cache.daysByPreset[cachedPreset]![41].cardCount, 0);
    await storage.executeBatch('DELETE FROM revlog WHERE id = $answerTime');
    final applied = await storage.answerCard(
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      capAnswerTimeToSecs: 120,
      suspendLeechedCards: false,
      buryReviewSiblings: true,
      answerTiming: _answerTiming(daysElapsed: 6, secsUntilDayRollover: 1800),

      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(answerTime + 1),
      millisecondsTaken: 300,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,

      desiredRetention: null,
      loadBalancerContext: loadBalancerContext,
      homeDeckConfigId: cachedPreset,
      now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
    );
    expect((await storage.getCard(Int64(20)))!.queue, CardQueue.schedBuried);
    expect(cache.daysByPreset[cachedPreset]![applied.interval].cardCount, 1);
  });

  test('answerCard derives Learning and Relearning due from state and timing', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    const timing = CollectionAnswerTiming(
      now: 1712345678,
      daysElapsed: 6,
      nextDayAt: 1712345738,
      secsUntilDayRollover: 60,
    );

    var answerId = 1712345679000;
    Future<Card> answer({
      CollectionAnswerTiming? answerTiming,
      int? fuzzedLearningSecs,
    }) => storage.answerCard(
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(answerId++),
      millisecondsTaken: 300,
      capAnswerTimeToSecs: 120,
      suspendLeechedCards: false,
      buryNewSiblings: false,
      buryInterdayLearningSiblings: false,
      buryReviewSiblings: false,
      baseContext: context,
      scheduledSecs: 90,
      elapsedSecs: 0,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      answerTiming: answerTiming ?? timing,
      desiredRetention: null,
      fuzzedLearningSecs: fuzzedLearningSecs,
    );

    await storage.executeBatch(
      'UPDATE cards SET type = 1, queue = 1, left = 2, due = 0, did = 40, odid = 0 WHERE id = 1',
    );
    final learning = await answer();
    expect(learning.queue, CardQueue.dayLearn);
    expect(learning.due, 7);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.dayLearn);
    expect((await storage.getCard(Int64(1)))!.due, 7);

    await storage.executeBatch(
      'UPDATE cards SET type = 1, queue = 1, left = 2, due = 0, did = 7, odid = 40 WHERE id = 1',
    );
    final filteredLearning = await answer();
    expect(filteredLearning.queue, CardQueue.dayLearn);
    expect(filteredLearning.due, 7);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.dayLearn);
    expect((await storage.getCard(Int64(1)))!.due, 7);

    await storage.executeBatch(
      'UPDATE cards SET type = 3, queue = 3, left = 2, due = 0, did = 40, odid = 0 WHERE id = 1',
    );
    final relearning = await answer();
    expect(relearning.queue, CardQueue.dayLearn);
    expect(relearning.due, 7);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.dayLearn);
    expect((await storage.getCard(Int64(1)))!.due, 7);

    await storage.executeBatch(
      'UPDATE cards SET type = 3, queue = 3, left = 2, due = 0, did = 7, odid = 40 WHERE id = 1',
    );
    final filteredRelearning = await answer();
    expect(filteredRelearning.queue, CardQueue.dayLearn);
    expect(filteredRelearning.due, 7);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.dayLearn);
    expect((await storage.getCard(Int64(1)))!.due, 7);

    await storage.executeBatch(
      'UPDATE cards SET type = 1, queue = 1, left = 2, due = 0, did = 40, odid = 0 WHERE id = 1',
    );
    const intradayTiming = CollectionAnswerTiming(
      now: 1712345678,
      daysElapsed: 6,
      nextDayAt: 1712347478,
      secsUntilDayRollover: 1800,
    );
    const intradayDue = 1712345768;
    final intraday = await answer(
      answerTiming: intradayTiming,
      fuzzedLearningSecs: 90,
    );
    expect(intraday.queue, CardQueue.learn);
    expect(intraday.due, intradayDue);
    expect((await storage.getCard(Int64(1)))!.queue, CardQueue.learn);
    expect((await storage.getCard(Int64(1)))!.due, intradayDue);

    await storage.executeBatch(
      'UPDATE cards SET type = 1, queue = 1, left = 2, due = 0, did = 7, odid = 40 WHERE id = 1',
    );
    final filteredIntraday = await answer(
      answerTiming: intradayTiming,
      fuzzedLearningSecs: 90,
    );
    expect(filteredIntraday.queue, CardQueue.learn);
    expect(filteredIntraday.due, intradayDue);
    expect((await storage.getCard(Int64(1)))!.due, intradayDue);

    await storage.executeBatch(
      'UPDATE cards SET type = 3, queue = 3, left = 2, due = 0, did = 40, odid = 0 WHERE id = 1',
    );
    final intradayRelearning = await answer(
      answerTiming: intradayTiming,
      fuzzedLearningSecs: 90,
    );
    expect(intradayRelearning.queue, CardQueue.learn);
    expect(intradayRelearning.due, intradayDue);
    expect((await storage.getCard(Int64(1)))!.due, intradayDue);

    await storage.executeBatch(
      'UPDATE cards SET type = 3, queue = 3, left = 2, due = 0, did = 7, odid = 40 WHERE id = 1',
    );
    final filteredIntradayRelearning = await answer(
      answerTiming: intradayTiming,
      fuzzedLearningSecs: 90,
    );
    expect(filteredIntradayRelearning.queue, CardQueue.learn);
    expect(filteredIntradayRelearning.due, intradayDue);
    expect((await storage.getCard(Int64(1)))!.due, intradayDue);
  });

  test(
    'preserves dispatch errors, caller timing, and elapsed bounds',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      Future<protoScheduler.CardAnswer> answer({
        CardId? cardId,
        int? scheduledSecs,
        int? elapsedSecs,
        int millisecondsTaken = 0,
      }) => storage.cardAnswerRequestForCard(
        cardId: cardId ?? Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        customData: '',
        answeredAtMillis: Int64(12),
        millisecondsTaken: millisecondsTaken,
        baseContext: context,
        scheduledSecs: scheduledSecs,
        elapsedSecs: elapsedSecs,
        loadBalancerEnabled: false,
        fuzzSeed: null,
      );

      await expectLater(
        answer(cardId: Int64(404)),
        _stateError('card not found'),
      );
      await storage.executeBatch('UPDATE cards SET type = 99 WHERE id = 1');
      await expectLater(answer(), _stateError('invalid stored card value'));
      await storage.executeBatch(
        'UPDATE cards SET type = 1, queue = 1 WHERE id = 1',
      );
      await expectLater(answer(), _stateError('required for Learn cards'));
      final learned = await answer(scheduledSecs: 90, elapsedSecs: 12);
      expect(
        learned
            .currentState
            .filtered
            .rescheduling
            .originalState
            .learning
            .elapsedSecs,
        12,
      );
      await storage.executeBatch(
        'UPDATE cards SET type = 3, queue = 3 WHERE id = 1',
      );
      final relearned = await answer(scheduledSecs: 75, elapsedSecs: 8);
      expect(
        relearned
            .currentState
            .filtered
            .rescheduling
            .originalState
            .relearning
            .learning
            .scheduledSecs,
        75,
      );
      expect(
        relearned
            .currentState
            .filtered
            .rescheduling
            .originalState
            .relearning
            .learning
            .elapsedSecs,
        8,
      );
      await expectLater(
        answer(millisecondsTaken: -1, scheduledSecs: 90, elapsedSecs: 12),
        throwsArgumentError,
      );
      await expectLater(
        answer(
          millisecondsTaken: 0x100000000,
          scheduledSecs: 90,
          elapsedSecs: 12,
        ),
        throwsArgumentError,
      );
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

CollectionAnswerTiming _answerTiming({
  required int daysElapsed,
  required int secsUntilDayRollover,
}) => CollectionAnswerTiming(
  now: 0,
  daysElapsed: daysElapsed,
  nextDayAt: secsUntilDayRollover,
  secsUntilDayRollover: secsUntilDayRollover,
);
