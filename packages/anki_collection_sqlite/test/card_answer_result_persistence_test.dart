// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
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
        id INTEGER PRIMARY KEY, nid INTEGER NOT NULL, did INTEGER NOT NULL,
        ord INTEGER NOT NULL, mod INTEGER NOT NULL, usn INTEGER NOT NULL,
        type INTEGER NOT NULL, queue INTEGER NOT NULL, due INTEGER NOT NULL,
        ivl INTEGER NOT NULL, factor INTEGER NOT NULL, reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL, left INTEGER NOT NULL, odue INTEGER NOT NULL,
        odid INTEGER NOT NULL, flags INTEGER NOT NULL, data TEXT NOT NULL
      );
      CREATE TABLE revlog (
        id INTEGER PRIMARY KEY, cid INTEGER NOT NULL, usn INTEGER NOT NULL,
        ease INTEGER NOT NULL, ivl INTEGER NOT NULL, lastIvl INTEGER NOT NULL,
        factor INTEGER NOT NULL, time INTEGER NOT NULL, type INTEGER NOT NULL
      );
      INSERT INTO cards VALUES (41, 12, 13, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
    ''');
  });

  tearDown(() async => storage.close());

  test(
    'persists one answer and undo/redo restores both supplied rows',
    () async {
      final before = await storage.getCard(Int64(41));
      final suppliedCard = _card(id: 41, due: 27);
      final entry = _revlog(id: 1712345678000, cardId: 41);

      await storage.recordCardAnswerResult(card: suppliedCard, revlog: entry);

      expect((await storage.getCard(Int64(41)))!.due, 27);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
      expect(storage.collectionUndoLabel, 'answerCard');
      expect(
        storage.collectionUndoChanges.map((change) => change.kind),
        containsAll([
          CollectionUndoChangeKind.card,
          CollectionUndoChangeKind.revlog,
        ]),
      );

      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, before!.due);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);

      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, 27);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
    },
  );

  test('applies and persists all four Normal answer states', () async {
    final cases =
        <
          ({
            scheduler.CardAnswer answer,
            CardQueue? queue,
            int? due,
            int? reviewDue,
            CardType expectedType,
            CardQueue expectedQueue,
            int expectedDue,
          })
        >[
          (
            answer: _newAnswer(answeredAt: 1712345678000),
            queue: null,
            due: null,
            reviewDue: null,
            expectedType: CardType.newCard,
            expectedQueue: CardQueue.newCard,
            expectedDue: 9,
          ),
          (
            answer: _learningAnswer(answeredAt: 1712345678001),
            queue: CardQueue.learn,
            due: 123456,
            reviewDue: null,
            expectedType: CardType.learn,
            expectedQueue: CardQueue.learn,
            expectedDue: 123456,
          ),
          (
            answer: _reviewAnswer(answeredAt: 1712345678002),
            queue: null,
            due: null,
            reviewDue: 47,
            expectedType: CardType.review,
            expectedQueue: CardQueue.review,
            expectedDue: 47,
          ),
          (
            answer: _relearningAnswer(answeredAt: 1712345678003),
            queue: CardQueue.dayLearn,
            due: 19,
            reviewDue: null,
            expectedType: CardType.relearn,
            expectedQueue: CardQueue.dayLearn,
            expectedDue: 19,
          ),
        ];

    for (final (index, result) in cases.indexed) {
      final card = _card(id: 41, due: 4);
      final applied = await storage.applyAndRecordCardAnswerResult(
        card: card,
        answer: result.answer,
        usn: 7,
        secsUntilDayRollover: 3600,
        desiredRetention: 0.91,
        learningQueue: result.queue,
        learningDue: result.due,
        reviewDueDay: result.reviewDue,
      );

      expect(applied.reps, 1);
      expect(applied.ctype, result.expectedType);
      expect(applied.queue, result.expectedQueue);
      expect(applied.due, result.expectedDue);
      expect((await storage.getCard(Int64(41)))!.toProto(), applied.toProto());
      final revlog = storage.revlog.getRevlogEntry(
        RevlogId(Int64(1712345678000 + index)),
      );
      expect(revlog, isNotNull);
      expect(revlog!.cardId, Int64(41));
      expect(revlog.id.value, Int64(1712345678000 + index));
      expect(revlog.usn, 7);
      expect(revlog.buttonChosen, 3);
      expect(revlog.takenMillis, 850);
      expect(revlog.reviewKind, RevlogReviewKind.learning);
    }
  });

  test(
    'applies rescheduling-filtered answers and persists both rows',
    () async {
      for (final leavesFilteredDeck in <bool>[false, true]) {
        for (final kind in <scheduler.SchedulingState_Normal_Kind>[
          scheduler.SchedulingState_Normal_Kind.new_1,
          scheduler.SchedulingState_Normal_Kind.learning,
          scheduler.SchedulingState_Normal_Kind.review,
          scheduler.SchedulingState_Normal_Kind.relearning,
        ]) {
          final answer = _reschedulingAnswer(
            kind: kind,
            answeredAt:
                1712345680000 + (leavesFilteredDeck ? 10 : 0) + kind.index,
            staysFiltered: !leavesFilteredDeck,
          );
          final expectedDue = switch (kind) {
            scheduler.SchedulingState_Normal_Kind.new_1 => 9,
            scheduler.SchedulingState_Normal_Kind.learning => 123456,
            scheduler.SchedulingState_Normal_Kind.review => 47,
            scheduler.SchedulingState_Normal_Kind.relearning => 19,
            scheduler.SchedulingState_Normal_Kind.notSet => 0,
          };
          final applied = await storage
              .applyAndRecordReschedulingFilteredCardAnswerResult(
                card: _filteredCard(),
                answer: answer,
                usn: 23,
                secsUntilDayRollover: 1800,
                desiredRetention: 0.91,
                learningQueue:
                    kind == scheduler.SchedulingState_Normal_Kind.relearning
                    ? CardQueue.dayLearn
                    : CardQueue.learn,
                learningDue:
                    kind == scheduler.SchedulingState_Normal_Kind.relearning
                    ? 19
                    : 123456,
                reviewDueDay: 47,
              );

          expect(applied.due, expectedDue);
          expect(applied.deckId, leavesFilteredDeck ? Int64(13) : Int64(99));
          expect(
            applied.originalDeckId,
            leavesFilteredDeck ? Int64.ZERO : Int64(13),
          );
          expect(applied.originalDue, leavesFilteredDeck ? 0 : expectedDue);
          expect(
            (await storage.getCard(Int64(41)))!.toProto(),
            applied.toProto(),
          );
          final revlog = storage.revlog.getRevlogEntry(
            RevlogId(answer.answeredAtMillis),
          );
          expect(revlog, isNotNull);
          expect(revlog!.cardId, Int64(41));
          expect(revlog.usn, 23);
          expect(revlog.takenMillis, 850);
        }
      }
    },
  );

  test(
    'rejects malformed filtered answers before writes and cache changes',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final generation = storage.collectionUndoGeneration;
      final valid = _reschedulingAnswer(
        kind: scheduler.SchedulingState_Normal_Kind.review,
        answeredAt: 1712345680100,
        staysFiltered: true,
      );
      final invalid = <scheduler.CardAnswer>[
        _reschedulingAnswer(
          kind: scheduler.SchedulingState_Normal_Kind.review,
          cardId: Int64(42),
          answeredAt: 1712345680101,
          staysFiltered: true,
        ),
        scheduler.CardAnswer(cardId: Int64(41)),
        _reschedulingAnswer(
          kind: scheduler.SchedulingState_Normal_Kind.review,
          answeredAt: 1712345680102,
          staysFiltered: true,
          malformedCurrent: true,
        ),
        _reschedulingAnswer(
          kind: scheduler.SchedulingState_Normal_Kind.review,
          answeredAt: 1712345680104,
          staysFiltered: true,
          missingCurrentNewPosition: true,
        ),
      ];
      for (final answer in invalid) {
        await expectLater(
          storage.applyAndRecordReschedulingFilteredCardAnswerResult(
            card: _filteredCard(),
            answer: answer,
            usn: 23,
            secsUntilDayRollover: 1800,
            desiredRetention: null,
            reviewDueDay: 47,
            loadBalancerContext: context,
            homeDeckConfigId: preset,
          ),
          throwsArgumentError,
        );
      }
      for (final kind in [
        scheduler.SchedulingState_Normal_Kind.learning,
        scheduler.SchedulingState_Normal_Kind.relearning,
      ]) {
        await expectLater(
          storage.applyAndRecordReschedulingFilteredCardAnswerResult(
            card: _filteredCard(),
            answer: _reschedulingAnswer(
              kind: kind,
              answeredAt: 1712345680103 + kind.index,
              staysFiltered: true,
            ),
            usn: 23,
            secsUntilDayRollover: 1800,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        storage.applyAndRecordReschedulingFilteredCardAnswerResult(
          card: _filteredCard(),
          answer: valid,
          usn: 23,
          secsUntilDayRollover: 1800,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );
      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(database.select('SELECT id FROM revlog'), isEmpty);
      expect(storage.collectionUndoGeneration, generation);
      expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    },
  );

  test(
    'collision rolls back filtered answer and cache; successful answer is undoable',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final collision = _reschedulingAnswer(
        kind: scheduler.SchedulingState_Normal_Kind.review,
        answeredAt: 1712345680200,
        staysFiltered: false,
      );
      storage.revlog.addRevlogEntry(_revlog(id: 1712345680200, cardId: 41));
      final generation = storage.collectionUndoGeneration;
      await expectLater(
        storage.applyAndRecordReschedulingFilteredCardAnswerResult(
          card: _filteredCard(),
          answer: collision,
          usn: 23,
          secsUntilDayRollover: 1800,
          desiredRetention: null,
          reviewDueDay: 47,
          loadBalancerContext: context,
          homeDeckConfigId: preset,
        ),
        throwsA(isA<StateError>()),
      );
      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(context.cache.daysByPreset[preset]![8].cardCount, 0);
      expect(storage.collectionUndoGeneration, generation);

      final answer = _reschedulingAnswer(
        kind: scheduler.SchedulingState_Normal_Kind.review,
        answeredAt: 1712345680201,
        staysFiltered: false,
      );
      final applied = await storage
          .applyAndRecordReschedulingFilteredCardAnswerResult(
            card: _filteredCard(),
            answer: answer,
            usn: 23,
            secsUntilDayRollover: 1800,
            desiredRetention: null,
            reviewDueDay: 47,
            loadBalancerContext: context,
            homeDeckConfigId: preset,
          );
      expect(context.cache.daysByPreset[preset]![8].cardCount, 1);
      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(
        storage.revlog.getRevlogEntry(RevlogId(answer.answeredAtMillis)),
        isNull,
      );
      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.toProto(), applied.toProto());
      expect(
        storage.revlog.getRevlogEntry(RevlogId(answer.answeredAtMillis)),
        isNotNull,
      );
    },
  );

  test(
    'rejects invalid, missing, and filtered answers before writing',
    () async {
      final generation = storage.collectionUndoGeneration;
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final invalid = <scheduler.CardAnswer>[
        scheduler.CardAnswer(cardId: Int64(41)),
        scheduler.CardAnswer(
          cardId: Int64(41),
          currentState: scheduler.SchedulingState(
            normal: scheduler.SchedulingState_Normal(
              new_1: scheduler.SchedulingState_New(position: 1),
            ),
          ),
          newState: scheduler.SchedulingState(
            normal: scheduler.SchedulingState_Normal(),
          ),
        ),
        scheduler.CardAnswer(
          cardId: Int64(41),
          currentState: _normalNewState(5),
          newState: scheduler.SchedulingState(
            normal: scheduler.SchedulingState_Normal(
              new_1: scheduler.SchedulingState_New(),
            ),
          ),
        ),
        scheduler.CardAnswer(
          cardId: Int64(41),
          currentState: scheduler.SchedulingState(
            normal: scheduler.SchedulingState_Normal(
              new_1: scheduler.SchedulingState_New(),
            ),
          ),
          newState: scheduler.SchedulingState(
            normal: scheduler.SchedulingState_Normal(
              review: scheduler.SchedulingState_Review(
                scheduledDays: 8,
                elapsedDays: 3,
                easeFactor: 2.5,
                lapses: 0,
              ),
            ),
          ),
        ),
        scheduler.CardAnswer(
          cardId: Int64(41),
          currentState: _normalNewState(5),
          newState: scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered(
              preview: scheduler.SchedulingState_Preview(scheduledSecs: 30),
            ),
          ),
        ),
        scheduler.CardAnswer(
          cardId: Int64(41),
          currentState: scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered(
              rescheduling: scheduler.SchedulingState_ReschedulingFilter(
                originalState: scheduler.SchedulingState_Normal(
                  new_1: scheduler.SchedulingState_New(position: 5),
                ),
              ),
            ),
          ),
          newState: _normalNewState(9),
        ),
        _newAnswer(cardId: Int64(42)),
      ];
      for (final answer in invalid) {
        await expectLater(
          storage.applyAndRecordCardAnswerResult(
            card: _card(id: 41, due: 4),
            answer: answer,
            usn: 7,
            secsUntilDayRollover: 3600,
            desiredRetention: null,
            loadBalancerContext: context,
            homeDeckConfigId: preset,
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        storage.applyAndRecordCardAnswerResult(
          card: _card(id: 41, due: 4),
          answer: _learningAnswer(),
          usn: 7,
          secsUntilDayRollover: 3600,
          desiredRetention: null,
          learningQueue: CardQueue.review,
          learningDue: 90,
        ),
        throwsArgumentError,
      );
      for (final answer in [
        _learningAnswer(),
        _reviewAnswer(),
        _relearningAnswer(),
      ]) {
        await expectLater(
          storage.applyAndRecordCardAnswerResult(
            card: _card(id: 41, due: 4),
            answer: answer,
            usn: 7,
            secsUntilDayRollover: 3600,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }

      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(database.select('SELECT id FROM revlog'), isEmpty);
      expect(storage.collectionUndoGeneration, generation);
      expect(context.cache.daysByPreset[preset]![9].cardCount, 0);
    },
  );

  test(
    'failed revlog insert leaves applied card and cache unchanged',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final collision = _revlog(id: 1712345678000, cardId: 41);
      storage.revlog.addRevlogEntry(collision);
      final generation = storage.collectionUndoGeneration;

      await expectLater(
        storage.applyAndRecordCardAnswerResult(
          card: _card(id: 41, due: 4),
          answer: _reviewAnswer(),
          usn: 7,
          secsUntilDayRollover: 3600,
          desiredRetention: null,
          reviewDueDay: 47,
          loadBalancerContext: context,
          homeDeckConfigId: preset,
        ),
        throwsA(isA<StateError>()),
      );

      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(database.select('SELECT id FROM revlog'), hasLength(1));
      expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
      expect(storage.collectionUndoGeneration, generation);
    },
  );

  test('commits cache mutation with answer and undo/redo rows', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);
    final answer = _reviewAnswer(answeredAt: 1712345678015);

    final applied = await storage.applyAndRecordCardAnswerResult(
      card: _card(id: 41, due: 4),
      answer: answer,
      usn: 7,
      secsUntilDayRollover: 3600,
      desiredRetention: null,
      reviewDueDay: 47,
      loadBalancerContext: context,
      homeDeckConfigId: preset,
    );
    expect(applied.queue, CardQueue.review);
    expect(context.cache.daysByPreset[preset]![8].cardCount, 1);
    expect(storage.collectionUndoLabel, 'answerCard');

    await storage.undoLastCollectionOperation();
    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(
      storage.revlog.getRevlogEntry(RevlogId(answer.answeredAtMillis)),
      isNull,
    );
    await storage.redoLastCollectionOperation();
    expect((await storage.getCard(Int64(41)))!.due, 47);
    expect(
      storage.revlog.getRevlogEntry(RevlogId(answer.answeredAtMillis)),
      isNotNull,
    );
  });

  test(
    'applies finished Preview answer and persists undoable result',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final answer = _filteredPreviewAnswer(
        answeredAt: 1712345678020,
        next: _previewState(scheduledSecs: 0, finished: true),
      );

      final applied = await storage
          .applyAndRecordFilteredPreviewCardAnswerResult(
            card: _filteredCard(),
            answer: answer,
            usn: 9,
            secsUntilDayRollover: 5400,
            loadBalancerContext: context,
            homeDeckConfigId: preset,
          );

      expect(applied.deckId, Int64(13));
      expect(applied.originalDeckId, Int64.ZERO);
      expect(applied.originalDue, 0);
      expect(applied.due, 47);
      expect(applied.queue, CardQueue.review);
      expect((await storage.getCard(Int64(41)))!.toProto(), applied.toProto());
      final entry = storage.revlog.getRevlogEntry(
        RevlogId(answer.answeredAtMillis),
      );
      expect(entry, isNotNull);
      expect(entry!.cardId, Int64(41));
      expect(entry.usn, 9);
      expect(entry.buttonChosen, 3);
      expect(entry.takenMillis, 850);
      expect(entry.interval, 0);
      expect(entry.reviewKind, RevlogReviewKind.filtered);
      expect(context.cache.daysByPreset[preset]![7].cardCount, 1);
      expect(storage.collectionUndoLabel, 'answerCard');

      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);

      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.toProto(), applied.toProto());
      expect(storage.revlog.getRevlogEntry(entry.id), isNotNull);
    },
  );

  test('applies unfinished PreviewRepeat using caller-resolved due', () async {
    final answer = _filteredPreviewAnswer(
      answeredAt: 1712345678021,
      next: _previewState(scheduledSecs: 30, finished: false),
    );

    final applied = await storage.applyAndRecordFilteredPreviewCardAnswerResult(
      card: _filteredCard(),
      answer: answer,
      usn: 11,
      secsUntilDayRollover: 7200,
      dueTimestampSecs: 1700000123,
    );

    expect(applied.deckId, Int64(99));
    expect(applied.originalDeckId, Int64(13));
    expect(applied.due, 1700000123);
    expect(applied.queue, CardQueue.previewRepeat);
    expect((await storage.getCard(Int64(41)))!.toProto(), applied.toProto());
    final entry = storage.revlog.getRevlogEntry(
      RevlogId(answer.answeredAtMillis),
    );
    expect(entry, isNotNull);
    expect(entry!.usn, 11);
    expect(entry.interval, -30);
    expect(entry.reviewKind, RevlogReviewKind.filtered);
  });

  test(
    'rejects invalid Preview answers and rolls back duplicate revlog',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final generationBeforeInvalid = storage.collectionUndoGeneration;
      final validCurrent = _previewState(scheduledSecs: 60, finished: false);
      final validNext = _previewState(scheduledSecs: 0, finished: true);
      final invalidAnswers = <scheduler.CardAnswer>[
        _filteredPreviewAnswer(cardId: Int64(42)),
        _filteredPreviewAnswer(current: _normalNewState(1)),
        _filteredPreviewAnswer(next: _normalNewState(2)),
        _filteredPreviewAnswer(
          current: scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered(
              preview: scheduler.SchedulingState_Preview(finished: false),
            ),
          ),
        ),
        _filteredPreviewAnswer(
          next: scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered(
              preview: scheduler.SchedulingState_Preview(scheduledSecs: 10),
            ),
          ),
        ),
      ];
      for (final answer in invalidAnswers) {
        await expectLater(
          storage.applyAndRecordFilteredPreviewCardAnswerResult(
            card: _filteredCard(),
            answer: answer,
            usn: 9,
            secsUntilDayRollover: 5400,
            dueTimestampSecs: 1700000123,
            loadBalancerContext: context,
            homeDeckConfigId: preset,
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        storage.applyAndRecordFilteredPreviewCardAnswerResult(
          card: _filteredCard(originalDeckId: Int64.ZERO),
          answer: _filteredPreviewAnswer(
            current: validCurrent,
            next: validNext,
          ),
          usn: 9,
          secsUntilDayRollover: 5400,
          loadBalancerContext: context,
          homeDeckConfigId: preset,
        ),
        throwsArgumentError,
      );
      await expectLater(
        storage.applyAndRecordFilteredPreviewCardAnswerResult(
          card: _filteredCard(),
          answer: _filteredPreviewAnswer(
            next: _previewState(scheduledSecs: 30, finished: false),
          ),
          usn: 9,
          secsUntilDayRollover: 5400,
        ),
        throwsArgumentError,
      );
      expect(storage.collectionUndoGeneration, generationBeforeInvalid);

      final collision = _revlog(id: 1712345678022, cardId: 41);
      storage.revlog.addRevlogEntry(collision);
      final generation = storage.collectionUndoGeneration;
      await expectLater(
        storage.applyAndRecordFilteredPreviewCardAnswerResult(
          card: _filteredCard(),
          answer: _filteredPreviewAnswer(answeredAt: 1712345678022),
          usn: 9,
          secsUntilDayRollover: 5400,
          loadBalancerContext: context,
          homeDeckConfigId: preset,
        ),
        throwsA(isA<StateError>()),
      );

      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(
        storage.revlog.getRevlogEntry(collision.id)!.toProto(),
        collision.toProto(),
      );
      expect(database.select('SELECT id FROM revlog'), hasLength(1));
      expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
      expect(storage.collectionUndoGeneration, generation);
    },
  );

  test(
    'adds a persisted review result to the supplied home-config cache',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final answeredCard = _card(
        id: 41,
        due: 27,
        queue: CardQueue.review,
        interval: 7,
      );

      await storage.recordCardAnswerResult(
        card: answeredCard,
        revlog: _revlog(id: 1712345678010, cardId: 41),
        loadBalancerContext: context,
        homeDeckConfigId: preset,
      );

      final day = context.cache.daysByPreset[preset]![7];
      expect(day.cardCount, 1);
      expect(day.hasSibling(Int64(12)), isTrue);
      expect(context.cache.daysByPreset[preset]![27].cardCount, 0);
      expect((await storage.getCard(Int64(41)))!.interval, 7);
      context.cache.removeCard(Int64(99));
      expect(day.cardCount, 1);
      context.cache.removeCard(Int64(41));
      expect(day.cardCount, 0);
    },
  );

  test('ignores non-review results and missing home-config IDs', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);

    await storage.recordCardAnswerResult(
      card: _card(id: 41, due: 27, queue: CardQueue.learn, interval: 7),
      revlog: _revlog(id: 1712345678011, cardId: 41),
      loadBalancerContext: context,
      homeDeckConfigId: preset,
    );
    await storage.recordCardAnswerResult(
      card: _card(id: 41, due: 27, queue: CardQueue.review, interval: 8),
      revlog: _revlog(id: 1712345678012, cardId: 41),
      loadBalancerContext: context,
      homeDeckConfigId: null,
    );

    expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    expect(context.cache.daysByPreset[preset]![8].cardCount, 0);
  });

  test('card update failure preserves the prior review cache', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);
    context.addAnsweredReviewCard(
      _card(id: 55, due: 0, queue: CardQueue.review, interval: 3),
      preset,
    );
    await storage.executeBatch('''
      CREATE TRIGGER reject_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
    ''');

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27, queue: CardQueue.review, interval: 7),
        revlog: _revlog(id: 1712345678013, cardId: 41),
        loadBalancerContext: context,
        homeDeckConfigId: preset,
      ),
      throwsA(isA<SqliteException>()),
    );

    expect(context.cache.daysByPreset[preset]![3].cardCount, 1);
    expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    expect(
      context.cache.daysByPreset[preset]![3].hasSibling(Int64(12)),
      isTrue,
    );
    expect(
      context.cache.daysByPreset[preset]![7].hasSibling(Int64(12)),
      isFalse,
    );
  });

  test('revlog collision preserves the prior review cache', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);
    final existing = _revlog(id: 1712345678014, cardId: 41);
    storage.revlog.addRevlogEntry(existing);
    context.addAnsweredReviewCard(
      _card(id: 55, due: 0, queue: CardQueue.review, interval: 3),
      preset,
    );

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27, queue: CardQueue.review, interval: 7),
        revlog: existing,
        loadBalancerContext: context,
        homeDeckConfigId: preset,
      ),
      throwsA(isA<StateError>()),
    );

    expect(context.cache.daysByPreset[preset]![3].cardCount, 1);
    expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    expect(
      context.cache.daysByPreset[preset]![3].hasSibling(Int64(12)),
      isTrue,
    );
    expect(
      context.cache.daysByPreset[preset]![7].hasSibling(Int64(12)),
      isFalse,
    );
  });

  test(
    'unchanged card values still persist a distinct answer revlog',
    () async {
      final before = await storage.getCard(Int64(41));
      final entry = _revlog(id: 1712345678001, cardId: 41);

      await storage.recordCardAnswerResult(card: before!, revlog: entry);

      expect((await storage.getCard(Int64(41)))!.due, before.due);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
      expect(storage.collectionUndoLabel, 'answerCard');
      await storage.undoLastCollectionOperation();
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);
      expect((await storage.getCard(Int64(41)))!.due, before.due);
    },
  );

  test('mismatched and missing card IDs fail without mutation', () async {
    final generation = storage.collectionUndoGeneration;
    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: _revlog(id: 1712345678002, cardId: 42),
      ),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 99, due: 27),
        revlog: _revlog(id: 1712345678003, cardId: 99),
      ),
      throwsA(isA<StateError>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(await storage.getCard(Int64(99)), isNull);
    expect(database.select('SELECT id FROM revlog'), isEmpty);
    expect(storage.collectionUndoGeneration, generation);
  });

  test('revlog collision rolls back the supplied card update', () async {
    final existing = _revlog(id: 1712345678004, cardId: 41);
    storage.revlog.addRevlogEntry(existing);
    final generation = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: existing,
      ),
      throwsA(isA<StateError>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(storage.revlog.getRevlogEntry(existing.id)!.cardId, Int64(41));
    expect(database.select('SELECT id FROM revlog'), hasLength(1));
    expect(storage.collectionUndoGeneration, generation);
  });

  test('card update failure rolls back before inserting the revlog', () async {
    await storage.executeBatch('''
      CREATE TRIGGER reject_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
    ''');
    final entry = _revlog(id: 1712345678005, cardId: 41);
    final generation = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: entry,
      ),
      throwsA(isA<SqliteException>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(storage.revlog.getRevlogEntry(entry.id), isNull);
    expect(storage.collectionUndoGeneration, generation);
  });

  test(
    'a suppressed card update rolls back instead of writing only revlog',
    () async {
      await storage.executeBatch('''
      CREATE TRIGGER ignore_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(IGNORE); END;
    ''');
      final entry = _revlog(id: 1712345678006, cardId: 41);
      final generation = storage.collectionUndoGeneration;

      await expectLater(
        storage.recordCardAnswerResult(
          card: _card(id: 41, due: 27),
          revlog: entry,
        ),
        throwsA(isA<StateError>()),
      );

      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);
      expect(storage.collectionUndoGeneration, generation);
    },
  );
}

scheduler.SchedulingState _normalNewState(int position) =>
    scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        new_1: scheduler.SchedulingState_New(position: position),
      ),
    );

scheduler.SchedulingState_Normal _reschedulingNormal(
  scheduler.SchedulingState_Normal_Kind kind,
) => switch (kind) {
  scheduler.SchedulingState_Normal_Kind.new_1 =>
    scheduler.SchedulingState_Normal(
      new_1: scheduler.SchedulingState_New(position: 9),
    ),
  scheduler.SchedulingState_Normal_Kind.learning =>
    scheduler.SchedulingState_Normal(
      learning: scheduler.SchedulingState_Learning(
        remainingSteps: 2,
        scheduledSecs: 60,
        elapsedSecs: 4,
      ),
    ),
  scheduler.SchedulingState_Normal_Kind.review =>
    scheduler.SchedulingState_Normal(
      review: scheduler.SchedulingState_Review(
        scheduledDays: 8,
        elapsedDays: 3,
        easeFactor: 2.5,
        lapses: 0,
      ),
    ),
  scheduler.SchedulingState_Normal_Kind.relearning =>
    scheduler.SchedulingState_Normal(
      relearning: scheduler.SchedulingState_Relearning(
        review: scheduler.SchedulingState_Review(
          scheduledDays: 8,
          elapsedDays: 3,
          easeFactor: 2.5,
          lapses: 1,
        ),
        learning: scheduler.SchedulingState_Learning(
          remainingSteps: 2,
          scheduledSecs: 60,
          elapsedSecs: 4,
        ),
      ),
    ),
  scheduler.SchedulingState_Normal_Kind.notSet =>
    scheduler.SchedulingState_Normal(),
};

scheduler.SchedulingState _reschedulingWrapper(
  scheduler.SchedulingState_Normal normal,
) => scheduler.SchedulingState(
  filtered: scheduler.SchedulingState_Filtered(
    rescheduling: scheduler.SchedulingState_ReschedulingFilter(
      originalState: normal,
    ),
  ),
);

scheduler.CardAnswer _reschedulingAnswer({
  Int64? cardId,
  required scheduler.SchedulingState_Normal_Kind kind,
  required int answeredAt,
  required bool staysFiltered,
  bool malformedCurrent = false,
  bool missingCurrentNewPosition = false,
}) {
  final next = _reschedulingNormal(kind);
  final current = malformedCurrent
      ? scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            rescheduling: scheduler.SchedulingState_ReschedulingFilter(),
          ),
        )
      : _reschedulingWrapper(
          missingCurrentNewPosition
              ? scheduler.SchedulingState_Normal(
                  new_1: scheduler.SchedulingState_New(),
                )
              : scheduler.SchedulingState_Normal(
                  new_1: scheduler.SchedulingState_New(position: 5),
                ),
        );
  return scheduler.CardAnswer(
    cardId: cardId ?? Int64(41),
    currentState: current,
    newState: staysFiltered
        ? _reschedulingWrapper(next)
        : scheduler.SchedulingState(normal: next),
    rating: scheduler.CardAnswer_Rating.GOOD,
    answeredAtMillis: Int64(answeredAt),
    millisecondsTaken: 850,
  );
}

scheduler.SchedulingState _previewState({
  required int scheduledSecs,
  required bool finished,
}) => scheduler.SchedulingState(
  filtered: scheduler.SchedulingState_Filtered(
    preview: scheduler.SchedulingState_Preview(
      scheduledSecs: scheduledSecs,
      finished: finished,
    ),
  ),
);

scheduler.CardAnswer _filteredPreviewAnswer({
  Int64? cardId,
  int answeredAt = 1712345678022,
  scheduler.SchedulingState? current,
  scheduler.SchedulingState? next,
}) => scheduler.CardAnswer(
  cardId: cardId ?? Int64(41),
  currentState: current ?? _previewState(scheduledSecs: 60, finished: false),
  newState: next ?? _previewState(scheduledSecs: 0, finished: true),
  rating: scheduler.CardAnswer_Rating.GOOD,
  answeredAtMillis: Int64(answeredAt),
  millisecondsTaken: 850,
);

scheduler.CardAnswer _newAnswer({
  Int64? cardId,
  int answeredAt = 1712345678000,
}) => scheduler.CardAnswer(
  cardId: cardId ?? Int64(41),
  currentState: _normalNewState(5),
  newState: scheduler.SchedulingState(
    normal: scheduler.SchedulingState_Normal(
      new_1: scheduler.SchedulingState_New(position: 9),
    ),
  )..customData = 'new',
  rating: scheduler.CardAnswer_Rating.GOOD,
  answeredAtMillis: Int64(answeredAt),
  millisecondsTaken: 850,
);

scheduler.CardAnswer _learningAnswer({int answeredAt = 1712345678000}) =>
    scheduler.CardAnswer(
      cardId: Int64(41),
      currentState: _normalNewState(5),
      newState: scheduler.SchedulingState(
        normal: scheduler.SchedulingState_Normal(
          learning: scheduler.SchedulingState_Learning(
            remainingSteps: 2,
            scheduledSecs: 60,
            elapsedSecs: 4,
          ),
        ),
      )..customData = 'learning',
      rating: scheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(answeredAt),
      millisecondsTaken: 850,
    );

scheduler.CardAnswer _reviewAnswer({int answeredAt = 1712345678000}) =>
    scheduler.CardAnswer(
      cardId: Int64(41),
      currentState: _normalNewState(5),
      newState: scheduler.SchedulingState(
        normal: scheduler.SchedulingState_Normal(
          review: scheduler.SchedulingState_Review(
            scheduledDays: 8,
            elapsedDays: 3,
            easeFactor: 2.5,
            lapses: 0,
          ),
        ),
      )..customData = 'review',
      rating: scheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(answeredAt),
      millisecondsTaken: 850,
    );

scheduler.CardAnswer _relearningAnswer({int answeredAt = 1712345678000}) =>
    scheduler.CardAnswer(
      cardId: Int64(41),
      currentState: _normalNewState(5),
      newState: scheduler.SchedulingState(
        normal: scheduler.SchedulingState_Normal(
          relearning: scheduler.SchedulingState_Relearning(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 8,
              elapsedDays: 3,
              easeFactor: 2.5,
              lapses: 1,
            ),
            learning: scheduler.SchedulingState_Learning(
              remainingSteps: 2,
              scheduledSecs: 60,
              elapsedSecs: 4,
            ),
          ),
        ),
      )..customData = 'relearning',
      rating: scheduler.CardAnswer_Rating.GOOD,
      answeredAtMillis: Int64(answeredAt),
      millisecondsTaken: 850,
    );

Card _card({
  required int id,
  required int due,
  CardQueue queue = CardQueue.newCard,
  int interval = 0,
}) => Card(
  id: Int64(id),
  noteId: Int64(12),
  deckId: Int64(13),
  mtimeSecs: Int64(1),
  due: due,
  queue: queue,
  interval: interval,
);

Card _filteredCard({Int64? originalDeckId}) => Card(
  id: Int64(41),
  noteId: Int64(12),
  deckId: Int64(99),
  mtimeSecs: Int64(1),
  ctype: CardType.review,
  queue: CardQueue.previewRepeat,
  due: 4,
  interval: 7,
  originalDue: 47,
  originalDeckId: originalDeckId ?? Int64(13),
);

RevlogEntry _revlog({required int id, required int cardId}) => RevlogEntry(
  id: RevlogId(Int64(id)),
  cardId: Int64(cardId),
  usn: -1,
  buttonChosen: 3,
  interval: 8,
  lastInterval: 4,
  easeFactor: 2500,
  takenMillis: 1200,
  reviewKind: RevlogReviewKind.review,
);

CollectionLoadBalancerContext _loadBalancerContext(DeckConfigId preset) {
  final history = List.generate(99, (_) => <LoadBalancerHistoryCard>[]);
  history[0].add((Int64(1), Int64(10), Int64(7)));
  return CollectionLoadBalancerContext(
    daysElapsed: 0,
    nextDayAt: Int64.ZERO,
    cache: LoadBalancerCache.fromHistory(
      cardsByDay: history,
      deckConfigByDeck: {Int64(7): preset},
      configs: {preset: DeckConfig.defaults()},
    ),
  );
}
