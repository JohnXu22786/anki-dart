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
CREATE TABLE revlog (
  id INTEGER PRIMARY KEY, cid INTEGER, usn INTEGER, ease INTEGER, ivl INTEGER,
  lastIvl INTEGER, factor INTEGER, time INTEGER, type INTEGER
);
INSERT INTO col VALUES (1700000000, '{}');
''');
    final initialConfig = _config()..inner.relearnSteps.add(1);
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(initialConfig);
    storage.decks.addOrUpdateDeckWithExistingId(_homeDeck());
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
    await _insertReviewCard(storage);
  });

  tearDown(() async => storage.close());

  group('reschedulingFilteredReviewCardSchedulingStatesForCardForNow', () {
    const creationSecs = 1700000000;
    final now = DateTime.fromMillisecondsSinceEpoch(
      (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
      isUtc: true,
    );
    const base = ReviewSchedulingContext(
      intervalMultiplier: 1.2,
      hardMultiplier: 1.4,
      fuzzFactor: 0.25,
      relearningAgainDelaySecs: 600,
    );

    test(
      'wraps current and every answer outcome with Core due and mappings',
      () async {
        final result = await storage
            .reschedulingFilteredReviewCardSchedulingStatesForCardForNow(
              cardId: Int64(1),
              baseContext: base,
              loadBalancerEnabled: false,
              fuzzSeed: null,
              now: now,
            );

        for (final state in [
          result.current,
          result.again,
          result.hard,
          result.good,
          result.easy,
        ]) {
          expect(
            state.whichKind(),
            protoScheduler.SchedulingState_Kind.filtered,
          );
          expect(
            state.filtered.whichKind(),
            protoScheduler.SchedulingState_Filtered_Kind.rescheduling,
          );
        }
        final current = result.current.filtered.rescheduling.originalState;
        expect(
          current.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.review,
        );
        // originalDue=40 is used without clamping to the collection day (12).
        expect(current.review.scheduledDays, 30);
        expect(current.review.elapsedDays, 2);
        expect(current.review.easeFactor, 2.375);
        expect(current.review.lapses, 5);
        expect(current.review.memoryState.stability, 3.25);

        expect(
          result.again.filtered.rescheduling.originalState.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.relearning,
        );
        for (final state in [result.hard, result.good, result.easy]) {
          expect(
            state.filtered.rescheduling.originalState.whichKind(),
            protoScheduler.SchedulingState_Normal_Kind.review,
          );
        }
        final expected = ReviewCardState.fromCard(
          (await storage.getCard(Int64(1)))!,
          effectiveDue: 40,
          daysElapsed: storage.timingTodayForNow(now: now).daysElapsed,
        ).nextStates(base.withDeckConfig(_config()));
        expect(
          result
              .again
              .filtered
              .rescheduling
              .originalState
              .relearning
              .review
              .scheduledDays,
          expected.again.review.scheduledDays,
        );
        for (final (actual, transition) in [
          (result.hard, expected.hard),
          (result.good, expected.good),
          (result.easy, expected.easy),
        ]) {
          final review = actual.filtered.rescheduling.originalState.review;
          expect(review.scheduledDays, transition.review.scheduledDays);
          expect(review.elapsedDays, transition.review.elapsedDays);
          expect(review.easeFactor, transition.review.easeFactor);
        }
        expect(base.fuzzFactor, 0.25);
      },
    );

    test(
      'falls back to due and derives FSRS memory and next states from home config',
      () async {
        await storage.executeBatch(
          "UPDATE cards SET odue = 0, data = '' WHERE id = 1",
        );
        final params = List<double>.filled(21, 0.25);
        final config = _config()
          ..inner.fsrsParams6.addAll(params)
          ..inner.historicalRetention = 0.87;
        storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(config);
        await storage.writeCollectionConfig('fsrs', true);
        await storage.revlog.addRevlogEntry(
          _revlog(1700000000000, RevlogReviewKind.learning, 1),
        );
        await storage.revlog.addRevlogEntry(
          _revlog(1700090000000, RevlogReviewKind.review, 8),
        );

        final supplied = const ReviewSchedulingContext(
          fuzzFactor: 0.3,
          intervalMultiplier: 1.1,
          fsrsParams: [0.1, 0.2, 0.3],
          fsrsDesiredRetention: 0.95,
          relearningAgainDelaySecs: 600,
        );
        final timing = storage.timingTodayForNow(now: now);
        final result = await storage
            .reschedulingFilteredReviewCardSchedulingStatesForCardForNow(
              cardId: Int64(1),
              baseContext: supplied,
              loadBalancerEnabled: false,
              fuzzSeed: null,
              now: now,
            );
        final revlogs = storage.revlog.getRevlogEntriesForCard(Int64(1))
          ..sort((a, b) => a.id.value.compareTo(b.id.value));
        final expectedMemory = computeFsrsMemoryState(
          revlogs: revlogs,
          nextDayAt: TimestampSecs(timing.nextDayAt),
          params: params,
          historicalRetention: config.inner.historicalRetention,
          ignoreRevlogsBefore: Int64.ZERO,
        );
        expect(
          result
              .current
              .filtered
              .rescheduling
              .originalState
              .review
              .scheduledDays,
          30,
        );
        expect(
          result.current.filtered.rescheduling.originalState.review.elapsedDays,
          35,
        );
        expect(
          result.current.filtered.rescheduling.originalState.review.memoryState,
          isNotNull,
        );
        expect(
          result
              .current
              .filtered
              .rescheduling
              .originalState
              .review
              .memoryState
              .stability,
          closeTo(expectedMemory!.stability, 1e-5),
        );
        final lastReviewTime = storage.revlog.timeOfLastReview(Int64(1));
        final elapsedSeconds = lastReviewTime == null
            ? 0
            : timing.nextDayAt - lastReviewTime.toInt();
        final expectedNext = computeFsrsNextStates(
          currentMemoryState: expectedMemory,
          daysElapsed: elapsedSeconds <= 0 ? 0 : elapsedSeconds ~/ 86400,
          desiredRetention: config.inner.desiredRetention,
          params: params,
        );
        for (final (actual, next) in [
          (
            result.again.filtered.rescheduling.originalState.relearning.review,
            expectedNext.again,
          ),
          (
            result.hard.filtered.rescheduling.originalState.review,
            expectedNext.hard,
          ),
          (
            result.good.filtered.rescheduling.originalState.review,
            expectedNext.good,
          ),
          (
            result.easy.filtered.rescheduling.originalState.review,
            expectedNext.easy,
          ),
        ]) {
          expect(actual.memoryState, isNotNull);
          expect(
            actual.memoryState.stability,
            closeTo(next.memoryState.stability, 1e-5),
          );
          expect(
            actual.memoryState.difficulty,
            closeTo(next.memoryState.difficulty, 1e-5),
          );
        }
        expect(supplied.intervalMultiplier, 1.1);
        expect(supplied.fsrsParams, [0.1, 0.2, 0.3]);
      },
    );

    test('uses home defaults when the config row is missing', () async {
      storage.deckConfigs.removeDeckConfig(Int64(10));
      final result = await storage
          .reschedulingFilteredReviewCardSchedulingStatesForCardForNow(
            cardId: Int64(1),
            baseContext: base,
            loadBalancerEnabled: false,
            fuzzSeed: null,
            now: now,
          );
      final expected = ReviewCardState.fromCard(
        (await storage.getCard(Int64(1)))!,
        effectiveDue: 40,
        daysElapsed: storage.timingTodayForNow(now: now).daysElapsed,
      ).nextStates(base.withDeckConfig(_config()));
      expect(
        result.good.filtered.rescheduling.originalState.review.scheduledDays,
        expected.good.review.scheduledDays,
      );
    });

    test(
      'load balancing resolves intervals from home config and disabled skips it',
      () async {
        await storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (2, 200, 8, 0, 0, 0, 2, 2, 12, 30, 2500, 2, 0, 0, 0, 0, 0, '');
''');
        final normalConfig = _config()..inner.easyDaysPercentages[0] = 100;
        storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(normalConfig);
        final enabled = await storage
            .reschedulingFilteredReviewCardSchedulingStatesForCardForNow(
              cardId: Int64(1),
              baseContext: base,
              loadBalancerEnabled: true,
              fuzzSeed: BigInt.from(42),
              now: now,
            );
        final timing = storage.timingTodayForNow(now: now);
        final card = (await storage.getCard(Int64(1)))!;
        final current = ReviewCardState.fromCard(
          card,
          effectiveDue: 40,
          daysElapsed: timing.daysElapsed,
        );
        final loadBalancer = await storage.loadBalancerContextForNow(now: now);
        final expected = current.nextStates(
          base
              .withDeckConfig(normalConfig)
              .withLoadBalancedIntervalResolver(
                loadBalancer.reviewIntervalResolver(
                  deckConfigId: Int64(10),
                  noteId: normalConfig.inner.buryReviews ? card.noteId : null,
                  fuzzSeed: BigInt.from(42),
                ),
              ),
        );
        final withoutLoadBalancer = current.nextStates(
          base
              .withDeckConfig(normalConfig)
              .withFsrsShortTermSettings(
                allowShortTerm: false,
                shortTermWithStepsEnabled: false,
              ),
        );
        final disabled = await storage
            .reschedulingFilteredReviewCardSchedulingStatesForCardForNow(
              cardId: Int64(1),
              baseContext: base,
              loadBalancerEnabled: false,
              fuzzSeed: BigInt.from(42),
              now: now,
            );
        expect(
          enabled
              .current
              .filtered
              .rescheduling
              .originalState
              .review
              .scheduledDays,
          30,
        );
        expect(
          enabled.good.filtered.rescheduling.originalState.review.scheduledDays,
          expected.good.review.scheduledDays,
        );
        expect(
          disabled
              .good
              .filtered
              .rescheduling
              .originalState
              .review
              .scheduledDays,
          withoutLoadBalancer.good.review.scheduledDays,
        );
        expect(base.fuzzFactor, 0.25);
      },
    );

    test(
      'rejects missing and invalid cards, assigned decks, and home deck/config',
      () async {
        Future<void> project([CardId? id]) async =>
            storage.reschedulingFilteredReviewCardSchedulingStatesForCardForNow(
              cardId: id ?? Int64(1),
              baseContext: base,
              loadBalancerEnabled: false,
              fuzzSeed: null,
              now: now,
            );
        await expectLater(project(Int64(404)), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET type = 99 WHERE id = 1');
        await expectLater(project(), _stateError('invalid stored card value'));
        await storage.executeBatch('UPDATE cards SET type = 0 WHERE id = 1');
        await expectLater(project(), _stateError('not a review card'));
        await storage.executeBatch(
          'UPDATE cards SET type = 2, did = 404 WHERE id = 1',
        );
        await expectLater(project(), _stateError('deck not found'));
        await storage.executeBatch(
          'UPDATE cards SET did = 7, odid = 0 WHERE id = 1',
        );
        await expectLater(project(), _stateError('no original deck ID'));
        await storage.executeBatch('UPDATE cards SET odid = 99 WHERE id = 1');
        await expectLater(project(), _stateError('home deck not found'));
        storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck(id: 8));
        await storage.executeBatch('UPDATE cards SET odid = 8 WHERE id = 1');
        await expectLater(project(), _stateError('not a normal deck'));
        storage.decks.addOrUpdateDeckWithExistingId(
          _normalDeck(includeConfigId: false),
        );
        await storage.executeBatch('UPDATE cards SET odid = 8 WHERE id = 1');
        await expectLater(project(), _stateError('no config ID'));
        await storage.executeBatch('UPDATE cards SET odid = 9 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          _normalDeck(id: 9, configId: Int64.ZERO),
        );
        await expectLater(project(), _stateError('no config ID'));
        storage.decks.addOrUpdateDeckWithExistingId(
          _normalDeck(id: 9, configId: Int64(10)),
        );
        await storage.executeBatch(
          'UPDATE cards SET did = 8, odid = 9 WHERE id = 1',
        );
        await expectLater(project(), _stateError('filtered deck required'));
        storage.decks.addOrUpdateDeckWithExistingId(
          _filteredDeck(id: 7, reschedule: false),
        );
        await storage.executeBatch('UPDATE cards SET did = 7 WHERE id = 1');
        await expectLater(project(), _stateError('does not reschedule'));
      },
    );
  });
}

Future<void> _insertReviewCard(CollectionSqliteStorage storage) =>
    storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 0, 2, 2, 7, 30, 2375, 8, 5, 0, 40, 8, 0,
          '{"s":3.25,"d":4.5}');
''');

DeckConfig _config() =>
    DeckConfig(id: Int64(10), name: 'Home', inner: DeckConfig.defaults().inner);
Deck _homeDeck() => Deck(
  id: Int64(8),
  name: 'Home',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);
Deck _normalDeck({int id = 8, Int64? configId, bool includeConfigId = true}) =>
    Deck(
      id: Int64(id),
      name: 'Normal $id',
      kind: NormalDeckKind(
        includeConfigId
            ? protoDeck.Deck_Normal(configId: configId ?? Int64(10))
            : protoDeck.Deck_Normal(),
      ),
    );
Deck _filteredDeck({int id = 7, bool reschedule = true}) => Deck(
  id: Int64(id),
  name: 'Filtered $id',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered(reschedule: reschedule)),
);
RevlogEntry _revlog(int timestampMillis, RevlogReviewKind kind, int interval) =>
    RevlogEntry(
      id: RevlogId(Int64(timestampMillis)),
      cardId: Int64(1),
      buttonChosen: 3,
      interval: interval,
      easeFactor: 2500,
      reviewKind: kind,
    );
Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
