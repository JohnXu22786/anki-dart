// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

QueueCandidate<String, String, String> _candidate(
  String id, {
  String? note,
  String deck = 'deck',
  String? originalDeck,
  QueueBuryMode buryMode = const QueueBuryMode(),
}) =>
    QueueCandidate(
      cardId: id,
      noteId: note ?? id,
      currentDeckId: deck,
      originalDeckId: originalDeck ?? deck,
      buryMode: buryMode,
    );

void main() {
  group('admitQueueCandidates', () {
    test(
      'gathers day learning then reviews then new and applies prior bury mode',
      () {
        final result = admitQueueCandidates(
          QueueAdmissionInput(
            time: const QueueAdmissionTime(
              nowSecs: 100,
              daysElapsed: 2,
              nextDayAtSecs: 200,
            ),
            rootDeckId: 'root',
            dayLearningCandidates: [
              _candidate(
                'learn-1',
                note: 'note',
                buryMode: const QueueBuryMode(
                  buryInterdayLearning: true,
                  buryReviews: true,
                ),
              ),
              _candidate('learn-2', note: 'note'),
            ],
            reviewCandidates: [
              _candidate('review-buried', note: 'note'),
              _candidate('review-admitted', note: 'other'),
            ],
            newCandidates: [
              _candidate(
                'new-1',
                note: 'note',
                buryMode: const QueueBuryMode(buryNew: true),
              ),
              _candidate('new-buried', note: 'note'),
            ],
            deckLimits: const {
              'deck': QueueDeckLimit(review: 2, newCards: 1),
            },
            parentDeckIds: const {'deck': 'root'},
          ),
        );

        expect(result.dayLearning.map((candidate) => candidate.cardId), [
          'learn-1',
        ]);
        // The buried review did not consume the remaining review allowance.
        expect(result.reviews.map((candidate) => candidate.cardId), [
          'review-admitted',
        ]);
        expect(result.newCards.map((candidate) => candidate.cardId), ['new-1']);
      },
    );

    test(
      'parent limits skip a candidate and root limits stop sorted traversal',
      () {
        final result = admitQueueCandidates(
          QueueAdmissionInput(
            time: const QueueAdmissionTime(
              nowSecs: 100,
              daysElapsed: 2,
              nextDayAtSecs: 200,
            ),
            rootDeckId: 'root',
            reviewCandidates: [
              _candidate('child-limited', deck: 'child'),
              _candidate('parent-limited', deck: 'sibling'),
              _candidate('review-1', deck: 'other'),
              _candidate('review-2', deck: 'other'),
              _candidate('review-after-root', deck: 'other'),
            ],
            newCandidates: [
              _candidate('new-1', deck: 'other'),
              _candidate('new-after-root', deck: 'other'),
            ],
            rootReviewLimit: 2,
            rootNewLimit: 1,
            deckLimits: const {
              'root': QueueDeckLimit(review: 2, newCards: 1),
              'parent': QueueDeckLimit(review: 0),
              'child': QueueDeckLimit(review: 2),
              'sibling': QueueDeckLimit(review: 2),
              'other': QueueDeckLimit(review: 5, newCards: 5),
            },
            parentDeckIds: const {
              'child': 'parent',
              'sibling': 'parent',
              'parent': 'root',
              'other': 'root',
            },
          ),
        );

        expect(result.reviews.map((candidate) => candidate.cardId), [
          'review-1',
          'review-2',
        ]);
        expect(result.newCards.map((candidate) => candidate.cardId), ['new-1']);
      },
    );

    test(
      'by-deck path stops at deck limit and then visits the next active deck',
      () {
        final result = admitQueueCandidates(
          QueueAdmissionInput(
            time: const QueueAdmissionTime(
              nowSecs: 100,
              daysElapsed: 2,
              nextDayAtSecs: 200,
            ),
            rootDeckId: 'root',
            newGatherPath: NewCardGatherPath.byDeck,
            newDeckOrder: const ['first', 'second', 'third'],
            newCandidatesByDeck: {
              'first': [
                _candidate('first-1', deck: 'first'),
                _candidate('first-after-limit', deck: 'first'),
              ],
              'second': [_candidate('second-skipped', deck: 'second')],
              'third': [_candidate('third-1', deck: 'third')],
            },
            rootNewLimit: 2,
            deckLimits: const {
              'first': QueueDeckLimit(newCards: 1),
              'second': QueueDeckLimit(newCards: 0),
              'third': QueueDeckLimit(newCards: 1),
            },
            parentDeckIds: const {
              'first': 'root',
              'second': 'root',
              'third': 'root',
            },
          ),
        );

        expect(result.newCards.map((candidate) => candidate.cardId), [
          'first-1',
          'third-1',
        ]);
      },
    );

    test(
      'prior intraday sibling mode seeds state but is not returned again',
      () {
        final result = admitQueueCandidates(
          QueueAdmissionInput(
            time: const QueueAdmissionTime(
              nowSecs: 100,
              daysElapsed: 2,
              nextDayAtSecs: 200,
            ),
            rootDeckId: 'root',
            intradayCandidatesForBuryState: [
              _candidate(
                'intraday-already-queued',
                note: 'note',
                buryMode: const QueueBuryMode(
                  buryInterdayLearning: true,
                  buryReviews: true,
                  buryNew: true,
                ),
              ),
            ],
            dayLearningCandidates: [
              _candidate('day-learning-sibling', note: 'note'),
            ],
            reviewCandidates: [_candidate('review-sibling', note: 'note')],
            newCandidates: [_candidate('new-sibling', note: 'note')],
            parentDeckIds: const {'deck': 'root'},
          ),
        );

        expect(result.dayLearning, isEmpty);
        expect(result.reviews, isEmpty);
        expect(result.newCards, isEmpty);
      },
    );
  });
}
