// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewCardState.fromCard', () {
    test('matches Core for future, current-day, and past due dates', () {
      final card = _reviewCard(interval: 10);

      for (final (due, expectedElapsed) in [
        (105, 5), // Effective due is five days ahead of collection day 100.
        (100, 10),
        (96, 14),
      ]) {
        final state = ReviewCardState.fromCard(
          card,
          effectiveDue: due,
          daysElapsed: 100,
        );

        expect(state.scheduledDays, 10);
        expect(state.elapsedDays, expectedElapsed);
      }
    });

    test('clamps elapsed days to zero when effective due exceeds interval', () {
      final state = ReviewCardState.fromCard(
        _reviewCard(interval: 4),
        effectiveDue: 110,
        daysElapsed: 100,
      );

      expect(state.elapsedDays, 0);
    });

    test('preserves review values and marks the state not leeched', () {
      final memory = FsrsMemoryState(stability: 12.3456, difficulty: 6.7891);
      final card = _reviewCard(
        interval: 10,
        easeFactorRaw: 2345,
        lapses: 7,
        memoryState: memory,
      );

      final state = ReviewCardState.fromCard(
        card,
        effectiveDue: 100,
        daysElapsed: 100,
      );

      expect(state.easeFactor, card.easeFactor);
      expect(state.lapses, 7);
      expect(state.memoryState, same(memory));
      expect(state.leeched, isFalse);
    });

    test('rejects cards whose stored type is not review', () {
      expect(
        () => ReviewCardState.fromCard(
          Card(ctype: CardType.learn),
          effectiveDue: 100,
          daysElapsed: 100,
        ),
        throwsA(isA<InvalidModelValue>()),
      );
    });
  });
}

Card _reviewCard({
  required int interval,
  int easeFactorRaw = 2500,
  int lapses = 0,
  FsrsMemoryState? memoryState,
}) =>
    Card(
      ctype: CardType.review,
      interval: interval,
      easeFactorRaw: easeFactorRaw,
      lapses: lapses,
      memoryState: memoryState,
    );
