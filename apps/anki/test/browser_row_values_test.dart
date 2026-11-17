/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_app/browser_row_values.dart';
import 'package:anki_app/l10n/app_localizations_en.dart';
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_dart/anki_dart.dart';
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const timing = SchedTimingToday(
    now: 1_700_000_000,
    daysElapsed: 100,
    nextDayAt: 1_700_086_400,
  );

  test('Notes aggregates review values and selects the earliest real due', () {
    final first = _card(
      id: 1,
      due: 105,
      interval: 10,
      ease: 2500,
      lapses: 2,
      reps: 7,
    );
    final second = _card(
      id: 2,
      due: 103,
      interval: 20,
      ease: 2000,
      lapses: 3,
      reps: 11,
    );
    final values = browserRowValues(
      cards: [first, second],
      note: models.Note(
        id: Int64(1_650_000_000_000),
        mtimeSecs: Int64(1_699_000_000),
      ),
      mode: BrowserColumnMode.notes,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );

    expect(values['cardDue'], _localDate(1_700_000_000 + 3 * 86400));
    expect(values['cardEase'], '225%');
    expect(values['cardIvl'], '15 days');
    expect(values['cardLapses'], '5');
    expect(values['cardReps'], '18');
    expect(values['noteCrt'], _localDateTime(1_650_000_000));
    expect(values['noteMod'], _localDateTime(1_699_000_000));
  });

  test('Cards preserves new, learning, and negative-queue due behavior', () {
    final newCard = _card(
      id: 1,
      type: models.CardType.newCard,
      queue: models.CardQueue.newCard,
      due: 42,
      interval: 0,
    );
    final learningCard = _card(
      id: 2,
      type: models.CardType.learn,
      queue: models.CardQueue.learn,
      due: 1_700_003_600,
      interval: 0,
    );
    final buriedCard = _card(
      id: 3,
      queue: models.CardQueue.userBuried,
      due: 98,
      interval: 2,
    );
    final filteredCard = _card(
      id: 4,
      due: 101,
      interval: 1,
      originalDeckId: Int64(42),
    );

    String due(models.Card card) => browserRowValues(
      cards: [card],
      note: models.Note(id: Int64(1)),
      mode: BrowserColumnMode.cards,
      timing: timing,
      l10n: AppLocalizationsEn(),
    )['cardDue']!;

    expect(due(newCard), 'New 42');
    expect(due(learningCard), _localDate(1_700_003_600));
    expect(due(buriedCard), '(${_localDate(1_700_000_000 - 2 * 86400)})');
    expect(due(filteredCard), 'Filtered');
    expect(
      browserRowValues(
        cards: [newCard],
        note: models.Note(id: Int64(1)),
        mode: BrowserColumnMode.cards,
        timing: timing,
        l10n: AppLocalizationsEn(),
      )['cardIvl'],
      'New',
    );
  });

  test('missing FSRS data stays empty and persisted position is preserved', () {
    final card = _card(id: 1, due: 7, interval: 1, position: 4_294_967_295);
    final values = browserRowValues(
      cards: [card],
      note: models.Note(id: Int64(1)),
      mode: BrowserColumnMode.cards,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );
    expect(values['stability'], '');
    expect(values['difficulty'], '');
    expect(values['retrievability'], '');
    expect(values['originalPosition'], '4294967295');

    final fsrsCard = _card(
      id: 2,
      due: 110,
      interval: 10,
      memoryState: models.FsrsMemoryState(stability: 10, difficulty: 4.6),
      lastReviewTimeSecs: Int64(timing.now - 30 * 86400),
    );
    final defaultDecay = browserRowValues(
      cards: [fsrsCard],
      note: models.Note(id: Int64(2)),
      mode: BrowserColumnMode.cards,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );
    final overrideDecay = browserRowValues(
      cards: [
        _card(
          id: 2,
          due: 110,
          interval: 10,
          memoryState: models.FsrsMemoryState(stability: 10, difficulty: 4.6),
          lastReviewTimeSecs: Int64(timing.now - 30 * 86400),
          decay: 0.2,
        ),
      ],
      note: models.Note(id: Int64(2)),
      mode: BrowserColumnMode.cards,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );
    expect(defaultDecay['stability'], '10 days');
    expect(defaultDecay['difficulty'], '40%');
    expect(defaultDecay['retrievability'], '77%');
    expect(overrideDecay['retrievability'], '80%');
  });

  test(
    'FSRS elapsed time uses persisted state and inferred review boundary',
    () {
      final state = models.FsrsMemoryState(stability: 10, difficulty: 4.6);
      String retrieval({
        int due = 110,
        int interval = 10,
        models.CardType type = models.CardType.review,
        models.CardQueue queue = models.CardQueue.review,
        Int64? lastReviewTimeSecs,
      }) => browserRowValues(
        cards: [
          _card(
            id: 3,
            type: type,
            queue: queue,
            due: due,
            interval: interval,
            memoryState: state,
            lastReviewTimeSecs: lastReviewTimeSecs,
          ),
        ],
        note: models.Note(id: Int64(3)),
        mode: BrowserColumnMode.cards,
        timing: timing,
        l10n: AppLocalizationsEn(),
      )['retrievability']!;

      // When the last review time is absent, Core derives elapsed time from
      // due, interval, and scheduler day timing. Exactly due minus interval is
      // the review boundary and therefore has 100% retrievability.
      expect(retrieval(), '100%');
      // Core casts signed elapsed seconds to u32, preserving wraparound if
      // persisted review time is unexpectedly in the future.
      expect(retrieval(lastReviewTimeSecs: Int64(timing.now + 86_400)), '3%');
      // A future timestamp due in a non-day queue uses the same Core u32
      // cast, without subtracting the card interval.
      expect(
        retrieval(
          due: timing.now + 86_400,
          type: models.CardType.learn,
          queue: models.CardQueue.learn,
        ),
        '3%',
      );
      // Core's due_time() handles the Learn queue before is_due_in_days():
      // even a small due value is a timestamp, then interval is subtracted
      // from that timestamp before saturating elapsed_secs().
      expect(
        retrieval(
          due: 110,
          interval: 10,
          type: models.CardType.learn,
          queue: models.CardQueue.learn,
        ),
        '5%',
      );
    },
  );

  test('FSRS stability follows Core timespan unit boundaries and rounding', () {
    String stability(double seconds) => browserRowValues(
      cards: [
        _card(
          id: 4,
          due: 110,
          interval: 10,
          memoryState: models.FsrsMemoryState(
            stability: seconds / 86400,
            difficulty: 4.6,
          ),
        ),
      ],
      note: models.Note(id: Int64(4)),
      mode: BrowserColumnMode.cards,
      timing: timing,
      l10n: AppLocalizationsEn(),
    )['stability']!;

    expect(stability(59.5), '60 seconds');
    expect(stability(60), '1 minute');
    expect(stability(90), '1.5 minutes');
    expect(stability(3600), '1 hour');
    expect(stability(86400), '1 day');
  });

  test('ease aggregation wraps as Core u16 before division', () {
    final manyCards = List.generate(
      27,
      (index) => _card(id: index + 10, due: 110, interval: 1, ease: 2500),
    );
    final easeValues = browserRowValues(
      cards: manyCards,
      note: models.Note(id: Int64(10)),
      mode: BrowserColumnMode.notes,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );
    expect(easeValues['cardEase'], '7%');
  });

  test('Notes lapse and review totals wrap as Core u32 sums', () {
    final values = browserRowValues(
      cards: [
        _card(
          id: 50,
          due: 110,
          interval: 1,
          lapses: 0xffffffff,
          reps: 0xffffffff,
        ),
        _card(
          id: 51,
          due: 110,
          interval: 1,
          lapses: 0xffffffff,
          reps: 0xffffffff,
        ),
      ],
      note: models.Note(id: Int64(50)),
      mode: BrowserColumnMode.notes,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );

    expect(values['cardLapses'], '4294967294');
    expect(values['cardReps'], '4294967294');
  });

  test('interval seconds multiplication wraps as Core u32 before division', () {
    final intervalValues = browserRowValues(
      cards: [_card(id: 40, due: 110, interval: 50_000)],
      note: models.Note(id: Int64(40)),
      mode: BrowserColumnMode.cards,
      timing: timing,
      l10n: AppLocalizationsEn(),
    );

    // Core's u32 seconds multiplication wraps 50000 * 86400 to 25032704.
    expect(intervalValues['cardIvl'], '9.5 months');
  });
}

String _localDate(int seconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toLocal();
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _localDateTime(int seconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toLocal();
  return '${_localDate(seconds)} @ ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

models.Card _card({
  required int id,
  models.CardType type = models.CardType.review,
  models.CardQueue queue = models.CardQueue.review,
  required int due,
  required int interval,
  int ease = 2500,
  int lapses = 0,
  int reps = 0,
  int? position,
  Int64? originalDeckId,
  models.FsrsMemoryState? memoryState,
  Int64? lastReviewTimeSecs,
  double? decay,
}) => models.Card(
  id: Int64(id),
  noteId: Int64(9),
  deckId: Int64.ONE,
  ctype: type,
  queue: queue,
  due: due,
  interval: interval,
  easeFactorRaw: ease,
  lapses: lapses,
  reps: reps,
  originalPosition: position,
  originalDeckId: originalDeckId ?? Int64.ZERO,
  memoryState: memoryState,
  lastReviewTimeSecs: lastReviewTimeSecs,
  decay: decay,
);
