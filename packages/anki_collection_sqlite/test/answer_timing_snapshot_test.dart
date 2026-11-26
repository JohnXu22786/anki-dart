// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as protoScheduler;
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
CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL);
CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
CREATE TABLE cards (
  id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER,
  usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl INTEGER,
  factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER,
  odid INTEGER, flags INTEGER, data TEXT
);
INSERT INTO col VALUES (1700000000, '{}');
''');
  });

  tearDown(() async => storage.close());

  group('answerTimingForNow', () {
    const creationSecs = 1700000000;

    test('returns one collection timing snapshot before rollover', () {
      final nowSecs = creationSecs + 3 * Duration.secondsPerDay - 1;
      final now = DateTime.fromMillisecondsSinceEpoch(
        nowSecs * 1000,
        isUtc: true,
      );
      final timing = storage.answerTimingForNow(now: now);

      expect(timing.now, nowSecs);
      expect(timing.daysElapsed, 2);
      expect(timing.nextDayAt, creationSecs + 3 * Duration.secondsPerDay);
      expect(timing.secsUntilDayRollover, 1);
      expect(timing.secsUntilDayRollover, inInclusiveRange(0, 0xffffffff));
    });

    test(
      'preserves rollover boundary and answer input values read-only',
      () async {
        final nowSecs = creationSecs + 3 * Duration.secondsPerDay;
        final now = DateTime.fromMillisecondsSinceEpoch(
          nowSecs * 1000,
          isUtc: true,
        );
        final before = database.select('SELECT crt, conf FROM col').single;

        final timing = storage.answerTimingForNow(now: now);

        expect(timing.now, nowSecs);
        expect(timing.daysElapsed, 3);
        expect(timing.nextDayAt, nowSecs + Duration.secondsPerDay);
        expect(timing.secsUntilDayRollover, Duration.secondsPerDay);
        expect(timing.daysElapsed, inInclusiveRange(0, 0xffffffff));
        final after = database.select('SELECT crt, conf FROM col').single;
        expect(after['crt'], before['crt']);
        expect(after['conf'], before['conf']);

        // These are the exact answerCard timing arguments; other scheduling
        // inputs remain explicit and are not inferred by this snapshot helper.
        await expectLater(
          storage.answerCard(
            cardId: Int64(-1),
            rating: protoScheduler.CardAnswer_Rating.GOOD,
            answeredAtMillis: Int64(nowSecs * 1000),
            millisecondsTaken: 0,
            capAnswerTimeToSecs: 60,
            suspendLeechedCards: false,
            buryNewSiblings: false,
            buryInterdayLearningSiblings: false,
            buryReviewSiblings: false,
            baseContext: const ReviewSchedulingContext(),
            loadBalancerEnabled: false,
            fuzzSeed: null,
            usn: 0,
            secsUntilDayRollover: timing.secsUntilDayRollover,
            daysElapsed: timing.daysElapsed,
            desiredRetention: null,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
