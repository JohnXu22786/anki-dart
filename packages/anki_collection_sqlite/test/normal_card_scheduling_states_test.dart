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
    await _insertCard(storage, type: 0);
  });

  tearDown(() async => storage.close());

  test('assembles normal protocol states for each stored card type', () async {
    const context = ReviewSchedulingContext(
      fuzzFactor: 0,
      relearningAgainDelaySecs: 600,
    );
    for (final (type, expectedCurrentKind) in [
      (0, protoScheduler.SchedulingState_Normal_Kind.new_1),
      (1, protoScheduler.SchedulingState_Normal_Kind.learning),
      (2, protoScheduler.SchedulingState_Normal_Kind.review),
      (3, protoScheduler.SchedulingState_Normal_Kind.relearning),
    ]) {
      await storage.executeBatch(
        'UPDATE cards SET type = $type, queue = $type WHERE id = 1',
      );
      final result = await storage.normalCardSchedulingStatesProtoForCard(
        cardId: Int64(1),
        baseContext: context,
        scheduledSecs: type == 1 || type == 3 ? 90 : null,
        elapsedSecs: type == 1 || type == 3 ? 12 : null,
        loadBalancerEnabled: false,
        fuzzSeed: BigInt.from(13),
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
      final states = [
        result.current,
        result.again,
        result.hard,
        result.good,
        result.easy,
      ];
      expect(states, hasLength(5));
      for (final state in states) {
        expect(state.whichKind(), protoScheduler.SchedulingState_Kind.normal);
        expect(
          state.normal.whichKind(),
          isNot(protoScheduler.SchedulingState_Normal_Kind.notSet),
        );
      }
      expect(result.current.normal.whichKind(), expectedCurrentKind);
      if (type == 0) {
        final direct = await storage.newCardSchedulingStatesForCard(
          cardId: Int64(1),
          baseContext: context,
        );
        _expectLearningStates(result, direct);
        expect(result.current.normal.new_1.position, 17);
        expect(result.again.normal.learning.scheduledSecs, 60);
      } else if (type == 1) {
        final direct = await storage.learningCardSchedulingStatesForCard(
          cardId: Int64(1),
          scheduledSecs: 90,
          elapsedSecs: 12,
          baseContext: context,
        );
        _expectLearningStates(result, direct);
        expect(result.current.normal.learning.scheduledSecs, 90);
        expect(result.current.normal.learning.elapsedSecs, 12);
      } else if (type == 2) {
        expect(result.current.normal.review.scheduledDays, 30);
        expect(result.current.normal.review.elapsedDays, 30);
        expect(result.current.normal.review.easeFactor, 2.375);
        expect(result.current.normal.review.lapses, 5);
        final direct = await storage.reviewCardSchedulingStatesForCardForNow(
          cardId: Int64(1),
          baseContext: context,
          loadBalancerEnabled: false,
          fuzzSeed: BigInt.from(13),
          now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
        );
        final protocolStates = [
          result.current,
          result.again,
          result.hard,
          result.good,
          result.easy,
        ];
        final actual = protocolStates.map(_reviewProto).toList();
        final expected = [
          direct.current,
          direct.again,
          direct.hard,
          direct.good,
          direct.easy,
        ];
        for (var i = 0; i < actual.length; i++) {
          expect(
            protocolStates[i].normal.whichKind(),
            expected[i].kind == ReviewScheduleKind.review
                ? protoScheduler.SchedulingState_Normal_Kind.review
                : protoScheduler.SchedulingState_Normal_Kind.relearning,
          );
          expect(actual[i].scheduledDays, expected[i].review.scheduledDays);
          expect(actual[i].elapsedDays, expected[i].review.elapsedDays);
          expect(actual[i].easeFactor, expected[i].review.easeFactor);
          expect(actual[i].lapses, expected[i].review.lapses);
          expect(actual[i].leeched, expected[i].review.leeched);
          if (expected[i].kind == ReviewScheduleKind.relearning) {
            final learning = protocolStates[i].normal.relearning.learning;
            expect(
              learning.remainingSteps,
              expected[i].learning!.remainingSteps,
            );
            expect(learning.scheduledSecs, expected[i].learning!.scheduledSecs);
            expect(learning.elapsedSecs, expected[i].learning!.elapsedSecs);
          }
        }
      } else {
        final direct = await storage.relearningCardSchedulingStatesForCard(
          cardId: Int64(1),
          scheduledSecs: 90,
          elapsedSecs: 12,
          baseContext: context,
        );
        _expectLearningStates(result, direct);
        expect(result.current.normal.relearning.learning.scheduledSecs, 90);
        expect(result.current.normal.relearning.learning.elapsedSecs, 12);
        expect(result.current.normal.relearning.review.scheduledDays, 30);
      }
    }
  });

  test(
    'rejects missing and mismatched per-card inputs and invalid stored types',
    () async {
      Future<void> project({int? scheduledSecs, int? elapsedSecs}) =>
          storage.normalCardSchedulingStatesProtoForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(),
            scheduledSecs: scheduledSecs,
            elapsedSecs: elapsedSecs,
            loadBalancerEnabled: false,
            fuzzSeed: null,
          );

      await storage.executeBatch('UPDATE cards SET type = 1 WHERE id = 1');
      await expectLater(project(), _stateError('required for Learn cards'));
      await storage.executeBatch('UPDATE cards SET type = 3 WHERE id = 1');
      await expectLater(
        project(scheduledSecs: 4),
        _stateError('required for Relearn cards'),
      );
      await expectLater(project(scheduledSecs: 4, elapsedSecs: 1), completes);
      await storage.executeBatch('UPDATE cards SET type = 0 WHERE id = 1');
      await expectLater(
        project(scheduledSecs: 4, elapsedSecs: 1),
        _stateError('only apply to Learn and Relearn'),
      );
      await storage.executeBatch('UPDATE cards SET type = 99 WHERE id = 1');
      await expectLater(project(), _stateError('invalid stored card value'));
      await storage.executeBatch('UPDATE cards SET type = 0 WHERE id = 1');
      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
      await expectLater(project(), _stateError('filtered deck'));
      await expectLater(
        storage.normalCardSchedulingStatesProtoForCard(
          cardId: Int64(404),
          baseContext: const ReviewSchedulingContext(),
          loadBalancerEnabled: false,
          fuzzSeed: null,
        ),
        _stateError('card not found'),
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

Deck _filteredDeck() => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered()),
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

protoScheduler.SchedulingState_Review _reviewProto(
  protoScheduler.SchedulingState state,
) => switch (state.normal.whichKind()) {
  protoScheduler.SchedulingState_Normal_Kind.review => state.normal.review,
  protoScheduler.SchedulingState_Normal_Kind.relearning =>
    state.normal.relearning.review,
  _ => throw StateError('expected Review or Relearn protocol state'),
};

void _expectLearningStates(
  protoScheduler.SchedulingStates actual,
  LearningCardSchedulingStates expected,
) {
  final actualStates = [
    actual.current.normal,
    actual.again.normal,
    actual.hard.normal,
    actual.good.normal,
    actual.easy.normal,
  ];
  final expectedStates = [
    expected.current,
    expected.again,
    expected.hard,
    expected.good,
    expected.easy,
  ];
  for (var i = 0; i < actualStates.length; i++) {
    final protocol = actualStates[i];
    final transition = expectedStates[i];
    switch (transition.kind) {
      case LearningTransitionKind.newCard:
        expect(
          protocol.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.new_1,
        );
        expect(protocol.new_1.position, transition.newCard!.position);
      case LearningTransitionKind.learning:
        expect(
          protocol.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.learning,
        );
        _expectLearningProto(protocol.learning, transition.learning!);
      case LearningTransitionKind.review:
        expect(
          protocol.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.review,
        );
        _expectReviewProto(protocol.review, transition.review!);
      case LearningTransitionKind.relearning:
        expect(
          protocol.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.relearning,
        );
        _expectLearningProto(
          protocol.relearning.learning,
          transition.learning!,
        );
        _expectReviewProto(protocol.relearning.review, transition.review!);
    }
  }
}

void _expectLearningProto(
  protoScheduler.SchedulingState_Learning actual,
  LearningCardState expected,
) {
  expect(actual.remainingSteps, expected.remainingSteps);
  expect(actual.scheduledSecs, expected.scheduledSecs);
  expect(actual.elapsedSecs, expected.elapsedSecs);
  expect(actual.memoryState.stability, expected.memoryState?.stability ?? 0);
  expect(actual.memoryState.difficulty, expected.memoryState?.difficulty ?? 0);
}

void _expectReviewProto(
  protoScheduler.SchedulingState_Review actual,
  ReviewCardState expected,
) {
  expect(actual.scheduledDays, expected.scheduledDays);
  expect(actual.elapsedDays, expected.elapsedDays);
  expect(actual.easeFactor, expected.easeFactor);
  expect(actual.lapses, expected.lapses);
  expect(actual.leeched, expected.leeched);
  expect(actual.memoryState.stability, expected.memoryState?.stability ?? 0);
  expect(actual.memoryState.difficulty, expected.memoryState?.difficulty ?? 0);
}
