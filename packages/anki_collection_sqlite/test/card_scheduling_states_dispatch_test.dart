// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:anki_backend_models/anki_backend_models.dart';
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
        cardId: Int64(1),
        rating: rating,
        answeredAtMillis: answerTime,
        millisecondsTaken: 850,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: BigInt.from(13),
        usn: 7,
        secsUntilDayRollover: 3600,
        desiredRetention: 0.91,
        learningQueue: CardQueue.learn,
        learningDue: 1712346000,
        reviewDueDay: 47,
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
    'rejects a card changed while its answer request is being built',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      final pendingAnswer = storage.answerCard(
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(1712345679000),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,
        secsUntilDayRollover: 1800,
        desiredRetention: null,
      );

      database.execute('UPDATE cards SET due = 18 WHERE id = 1');

      await expectLater(
        pendingAnswer,
        _stateError('card changed while preparing answer'),
      );
      expect((await storage.getCard(Int64(1)))!.due, 18);
      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345679000))),
        isNull,
      );
    },
  );

  test('does not overwrite a card changed before answer commit', () async {
    const context = ReviewSchedulingContext(fuzzFactor: 0);
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
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
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(1712345679001),
      millisecondsTaken: 300,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      secsUntilDayRollover: 1800,
      desiredRetention: null,
      learningQueue: CardQueue.learn,
      learningDue: 1712346000,
      reviewDueDay: 47,
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
  });

  test(
    'routes Preview and rescheduling answers and validates caller due data',
    () async {
      const context = ReviewSchedulingContext(fuzzFactor: 0);
      await storage.executeBatch(
        "UPDATE cards SET type = 0, queue = 0, did = 7, odid = 40, "
        "data = '{\"cd\":\"preview data\"}' WHERE id = 1",
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: false),
      );
      final preview = await storage.answerCard(
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.AGAIN,
        answeredAtMillis: Int64(1712345680000),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,
        secsUntilDayRollover: 1800,
        desiredRetention: null,
        dueTimestampSecs: 1712346000,
      );
      expect(preview.queue, CardQueue.previewRepeat);
      expect(preview.due, 1712346000);
      expect(preview.customData, 'preview data');

      await storage.executeBatch(
        'UPDATE cards SET type = 1, queue = 1, did = 7, odid = 40 WHERE id = 1',
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: true),
      );
      await expectLater(
        storage.answerCard(
          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: Int64(1712345680001),
          millisecondsTaken: 300,
          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,
          secsUntilDayRollover: 1800,
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
          secsUntilDayRollover: 1800,
          desiredRetention: 0.91,
        ),
        throwsArgumentError,
      );
      expect((await storage.getCard(Int64(1)))!.toProto(), before);

      final rescheduling = await storage.answerCard(
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
        secsUntilDayRollover: 1800,
        desiredRetention: 0.91,
        learningQueue: CardQueue.learn,
        learningDue: 1712346000,
      );
      expect(rescheduling.deckId, Int64(7));
      expect(rescheduling.queue, CardQueue.learn);
      expect(rescheduling.due, 1712346000);
      expect(
        storage.revlog.getRevlogEntry(RevlogId(Int64(1712345680003))),
        isNotNull,
      );

      await storage.executeBatch('UPDATE cards SET type = 99 WHERE id = 1');
      await expectLater(
        storage.answerCard(
          cardId: Int64(1),
          rating: protoScheduler.CardAnswer_Rating.GOOD,
          answeredAtMillis: Int64(1712345680004),
          millisecondsTaken: 300,
          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: null,
          usn: 8,
          secsUntilDayRollover: 1800,
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
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(answerTime - 1),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,
        secsUntilDayRollover: 1800,
        desiredRetention: null,
      ),
      throwsArgumentError,
    );
    expect((await storage.getCard(Int64(1)))!.toProto(), before);
    expect(storage.collectionUndoGeneration, beforeUndo);

    await expectLater(
      storage.answerCard(
        cardId: Int64(1),
        rating: protoScheduler.CardAnswer_Rating.GOOD,
        answeredAtMillis: Int64(answerTime),
        millisecondsTaken: 300,
        baseContext: context,
        loadBalancerEnabled: false,
        fuzzSeed: null,
        usn: 8,
        secsUntilDayRollover: 1800,
        desiredRetention: null,
        reviewDueDay: 41,
        loadBalancerContext: loadBalancerContext,
        homeDeckConfigId: cachedPreset,
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      ),
      throwsStateError,
    );
    expect((await storage.getCard(Int64(1)))!.toProto(), before);
    expect(storage.collectionUndoGeneration, beforeUndo);
    expect(cache.daysByPreset[cachedPreset]![0].cardCount, 1);
    expect(cache.daysByPreset[cachedPreset]![41].cardCount, 0);
    await storage.executeBatch('DELETE FROM revlog WHERE id = $answerTime');
    final applied = await storage.answerCard(
      cardId: Int64(1),
      rating: protoScheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(answerTime + 1),
      millisecondsTaken: 300,
      baseContext: context,
      loadBalancerEnabled: false,
      fuzzSeed: null,
      usn: 8,
      secsUntilDayRollover: 1800,
      desiredRetention: null,
      reviewDueDay: 41,
      loadBalancerContext: loadBalancerContext,
      homeDeckConfigId: cachedPreset,
      now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
    );
    expect(cache.daysByPreset[cachedPreset]![applied.interval].cardCount, 1);
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
