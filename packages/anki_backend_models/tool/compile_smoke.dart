// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notes.pbenum.dart' as notes;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/deck_config.pbenum.dart' as deck;
import 'package:anki_backend_protocol/anki/cards.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;
import 'package:fixnum/fixnum.dart';

void main() {
  if (fuzzLearningIntervalSecs(1200, BigInt.from(58205158)) != 1473) {
    throw StateError('seeded Learning fuzz differs on JavaScript');
  }
  final previewStates = FilteredPreviewState.current(scheduledSecs: 0)
      .nextStates(againDelaySecs: 30, hardDelaySecs: 0, goodDelaySecs: 90);
  if (previewStates.current.finished ||
      previewStates.again.scheduledSecs != 30 ||
      previewStates.hard.finished != true ||
      previewStates.good.finished ||
      previewStates.easy.finished != true) {
    throw StateError('filtered preview transitions differ on JavaScript');
  }

  final filteredPreviewCard = Card(
    id: Int64(10),
    deckId: Int64(20),
    ctype: CardType.learn,
    queue: CardQueue.previewRepeat,
    due: 1700000000,
    originalDeckId: Int64(30),
  );
  final filteredPreviewAnswer = scheduler.CardAnswer(
    cardId: filteredPreviewCard.id,
    currentState: scheduler.SchedulingState(
      filtered: scheduler.SchedulingState_Filtered(
        preview: scheduler.SchedulingState_Preview(
          scheduledSecs: 30,
          finished: false,
        ),
      ),
    ),
    newState: scheduler.SchedulingState(
      filtered: scheduler.SchedulingState_Filtered(
        preview: scheduler.SchedulingState_Preview(
          scheduledSecs: 0,
          finished: true,
        ),
      ),
    )..customData = '',
    rating: scheduler.CardAnswer_Rating.EASY,
  );
  final restoredPreviewCard = applyFilteredPreviewCardAnswerState(
    card: filteredPreviewCard,
    answer: filteredPreviewAnswer,
  );
  if (restoredPreviewCard.deckId != Int64(30) ||
      restoredPreviewCard.originalDeckId != Int64.ZERO ||
      restoredPreviewCard.queue != CardQueue.learn ||
      restoredPreviewCard.customData != '') {
    throw StateError('filtered Preview Card application differs on JavaScript');
  }

  final loadBalancerDay = LoadBalancerDay()
    ..add(CardId.parseInt('9223372036854775807'),
        NoteId.parseInt('9007199254740993'));
  if (!loadBalancerDay.hasSibling(NoteId.parseInt('9007199254740993'))) {
    throw StateError('load-balancer day state differs on JavaScript');
  }
  loadBalancerDay.remove(CardId.parseInt('9223372036854775807'));
  if (loadBalancerDay.hasSibling(NoteId.parseInt('9007199254740993'))) {
    throw StateError('load-balancer day removal differs on JavaScript');
  }
  if (intervalToWeekday(1, TimestampSecs(0)) !=
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal().weekday -
          1) {
    throw StateError('interval weekday projection differs on JavaScript');
  }

  final easyDays = parseEasyDaysPercentages(
    const [1.0, 0.0, 0.5, 1.0, 1.0, 1.0, 1.0],
  );
  final easyModifiers = calculateEasyDaysModifiers(
    easyDays,
    const [0, 1, 2],
    const [0, 2, 3],
  );
  if (easyModifiers.length != 3 ||
      easyModifiers[0] != 1.0 ||
      easyModifiers[1] != 0.00009999999747378752) {
    throw StateError('easy-day load modifiers differ on JavaScript');
  }
  final intervalWeight = calculateIntervalLoadWeight(
    const IntervalLoadCandidate(targetInterval: 10, reviewCount: 5),
  );
  if ((intervalWeight - 0.000031420597224496305).abs() > 1e-12) {
    throw StateError('interval load weight differs on JavaScript');
  }
  final weightedInterval = selectWeightedInterval(
    const [
      IntervalLoadCandidate(targetInterval: 10, reviewCount: 0),
      IntervalLoadCandidate(targetInterval: 20, reviewCount: 0),
    ],
    BigInt.parse('8000000000000000', radix: 16),
  );
  if (weightedInterval != 20) {
    throw StateError('seeded weighted selection differs on JavaScript');
  }
  final history = List<List<LoadBalancerHistoryCard>>.generate(99, (_) => []);
  for (var day = 4; day <= 6; day++) {
    for (var card = 0; card < 10; card++) {
      history[day].add((
        CardId(day * 100 + card),
        NoteId(day * 100 + card),
        DeckId(7),
      ));
    }
  }
  final loadBalancerCache = LoadBalancerCache.fromHistory(
    cardsByDay: history,
    deckConfigByDeck: {DeckId(7): DeckConfigId(1)},
    configs: {DeckConfigId(1): DeckConfig.defaults()},
  );
  int? chooseLoadBalancedInterval() => findLoadBalancedInterval(
        daysByPreset: loadBalancerCache.daysByPreset,
        easyDaysByPreset: loadBalancerCache.easyDaysByPreset,
        nextDayAt: TimestampSecs(0),
        deckConfigId: Int64(1),
        noteId: null,
        interval: 5,
        minimum: 1,
        maximum: 20,
        fuzzSeed: BigInt.zero,
      );
  if (chooseLoadBalancedInterval() != 5 || chooseLoadBalancedInterval() != 5) {
    throw StateError('seeded load-balancer interval differs on JavaScript');
  }
  final card = Card(id: Int64(1));
  final note = Note(id: Int64(2));
  if (card.id.toInt() + note.id.toInt() != 3) {
    throw StateError('model package JS smoke compilation failed');
  }
  final answer = scheduler.CardAnswer(
    cardId: Int64.parseInt('9007199254740997'),
    currentState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        learning: scheduler.SchedulingState_Learning(scheduledSecs: 3599),
      ),
    ),
    newState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        review: scheduler.SchedulingState_Review(
          scheduledDays: 2,
          easeFactor: 2.5,
        ),
      ),
    ),
    rating: scheduler.CardAnswer_Rating.GOOD,
    answeredAtMillis: Int64.parseInt('9007199254740999'),
    millisecondsTaken: 45000,
  );
  final newAnswer = scheduler.CardAnswer(
    cardId: Int64(1),
    newState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        new_1: scheduler.SchedulingState_New(position: 17),
      ),
    )..customData = '',
    rating: scheduler.CardAnswer_Rating.EASY,
  );
  final appliedNewCard = applyNewCardAnswerState(
    card: Card(id: Int64(1), reps: 4, originalPosition: 3),
    answer: newAnswer,
    desiredRetention: 0.9,
  );
  if (appliedNewCard.ctype != CardType.newCard ||
      appliedNewCard.queue != CardQueue.newCard ||
      appliedNewCard.due != 17 ||
      appliedNewCard.reps != 5 ||
      appliedNewCard.originalPosition != null ||
      appliedNewCard.customData != '' ||
      appliedNewCard.desiredRetention == null ||
      (appliedNewCard.desiredRetention! - 0.9).abs() > 0.000001) {
    throw StateError('Normal/New CardAnswer application differs on JavaScript');
  }

  final learningAnswer = scheduler.CardAnswer(
    cardId: Int64(1),
    currentState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        new_1: scheduler.SchedulingState_New(position: 8),
      ),
    ),
    newState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        learning: scheduler.SchedulingState_Learning(
          remainingSteps: 2,
          memoryState: proto.FsrsMemoryState(stability: 3.5, difficulty: 4.5),
        ),
      ),
    )..customData = 'learning',
    rating: scheduler.CardAnswer_Rating.GOOD,
  );
  final appliedLearningCard = applyLearningCardAnswerState(
    card: Card(id: Int64(1), reps: 2),
    answer: learningAnswer,
    queue: CardQueue.learn,
    due: 1700000000,
    desiredRetention: null,
  );
  if (appliedLearningCard.ctype != CardType.learn ||
      appliedLearningCard.queue != CardQueue.learn ||
      appliedLearningCard.due != 1700000000 ||
      appliedLearningCard.remainingSteps != 2 ||
      appliedLearningCard.originalPosition != 8 ||
      appliedLearningCard.memoryState?.stability != 3.5 ||
      appliedLearningCard.customData != 'learning' ||
      appliedLearningCard.reps != 3) {
    throw StateError(
        'Normal/Learning CardAnswer application differs on JavaScript');
  }

  final reviewAnswer = scheduler.CardAnswer(
    cardId: Int64(1),
    currentState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        new_1: scheduler.SchedulingState_New(position: 8),
      ),
    ),
    newState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        review: scheduler.SchedulingState_Review(
          scheduledDays: 23,
          easeFactor: 2.3456,
          lapses: 7,
          memoryState: proto.FsrsMemoryState(stability: 9.5, difficulty: 3.25),
        ),
      ),
    )..customData = 'review',
    rating: scheduler.CardAnswer_Rating.EASY,
  );
  final appliedReviewCard = applyReviewCardAnswerState(
    card: Card(id: Int64(1), reps: 2, remainingStepsRaw: 3),
    answer: reviewAnswer,
    dueDay: 1700000010,
    desiredRetention: null,
  );
  if (appliedReviewCard.ctype != CardType.review ||
      appliedReviewCard.queue != CardQueue.review ||
      appliedReviewCard.due != 1700000010 ||
      appliedReviewCard.interval != 23 ||
      appliedReviewCard.easeFactorRaw != 2346 ||
      appliedReviewCard.lapses != 7 ||
      appliedReviewCard.remainingSteps != 0 ||
      appliedReviewCard.originalPosition != 8 ||
      appliedReviewCard.memoryState?.stability != 9.5 ||
      appliedReviewCard.customData != 'review' ||
      appliedReviewCard.desiredRetention != null ||
      appliedReviewCard.reps != 3) {
    throw StateError(
        'Normal/Review CardAnswer application differs on JavaScript');
  }

  final relearningAnswer = scheduler.CardAnswer(
    cardId: Int64(1),
    currentState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        relearning: scheduler.SchedulingState_Relearning(
          review: scheduler.SchedulingState_Review(scheduledDays: 1),
          learning: scheduler.SchedulingState_Learning(remainingSteps: 2),
        ),
      ),
    ),
    newState: scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        relearning: scheduler.SchedulingState_Relearning(
          review: scheduler.SchedulingState_Review(
            scheduledDays: 23,
            easeFactor: 2.3456,
            lapses: 7,
          ),
          learning: scheduler.SchedulingState_Learning(
            remainingSteps: 4,
            memoryState:
                proto.FsrsMemoryState(stability: 9.5, difficulty: 3.25),
          ),
        ),
      ),
    )..customData = 'relearning',
    rating: scheduler.CardAnswer_Rating.AGAIN,
  );
  final appliedRelearningCard = applyRelearningCardAnswerState(
    card: Card(id: Int64(1), reps: 2, originalPosition: 3),
    answer: relearningAnswer,
    queue: CardQueue.dayLearn,
    due: 17,
    desiredRetention: null,
  );
  if (appliedRelearningCard.ctype != CardType.relearn ||
      appliedRelearningCard.queue != CardQueue.dayLearn ||
      appliedRelearningCard.due != 17 ||
      appliedRelearningCard.interval != 23 ||
      appliedRelearningCard.easeFactorRaw != 2346 ||
      appliedRelearningCard.lapses != 7 ||
      appliedRelearningCard.remainingSteps != 4 ||
      appliedRelearningCard.originalPosition != 3 ||
      appliedRelearningCard.memoryState?.stability != 9.5 ||
      appliedRelearningCard.customData != 'relearning' ||
      appliedRelearningCard.reps != 3) {
    throw StateError(
        'Normal/Relearning CardAnswer application differs on JavaScript');
  }

  final revlog = revlogEntryFromCardAnswer(
    answer: answer,
    usn: 8,
    secsUntilDayRollover: 3600,
  );
  if (revlog.cardId != answer.cardId ||
      revlog.id.value != answer.answeredAtMillis ||
      revlog.interval != 2 ||
      revlog.lastInterval != -3599 ||
      revlog.buttonChosen != 3 ||
      revlog.reviewKind != RevlogReviewKind.learning) {
    throw StateError('CardAnswer revlog derivation differs on JavaScript');
  }
  final reviewCard = Card(
    ctype: CardType.review,
    interval: 10,
    easeFactorRaw: 2345,
    lapses: 2,
  );
  final currentReviewState = ReviewCardState.fromCard(
    reviewCard,
    effectiveDue: 105,
    daysElapsed: 100,
  );
  if (currentReviewState.elapsedDays != 5 ||
      currentReviewState.easeFactor != reviewCard.easeFactor ||
      currentReviewState.lapses != 2 ||
      currentReviewState.leeched) {
    throw StateError('review card state projection differs on JavaScript');
  }
  final reviewStates = ReviewCardState(
    scheduledDays: 10,
    elapsedDays: 14,
  ).nextStates(const ReviewSchedulingContext());
  if (reviewStates.hard.review.scheduledDays != 12 ||
      reviewStates.good.review.scheduledDays != 30 ||
      reviewStates.easy.review.scheduledDays != 46) {
    throw StateError('review-state calculation differs on JavaScript');
  }
  if (fieldChecksum('test') != 2840236005) {
    throw StateError('unsigned SHA-1 checksum differs on JavaScript');
  }
  final fields = fixNoteFieldCount(['front', 'back', 'extra'], 2);
  if (fields.length != 2 || fields[1] != 'back; extra') {
    throw StateError('field-count migration differs on JavaScript');
  }
  if (!fieldIsEmpty('<BR />') || fieldIsEmpty('\u00a0')) {
    throw StateError('field emptiness differs on JavaScript');
  }
  final nonempty = Note(fields: ['answer']).nonEmptyFields([
    NoteField(name: 'Back', config: proto.Notetype_Field_Config()),
  ]);
  if (!nonempty.contains('Back')) {
    throw StateError('nonempty Note fields differ on JavaScript');
  }
  final hasDuplicate = isDuplicateNoteField(
    note: Note(id: Int64(2), notetypeId: Int64(3), fields: ['answer']),
    firstFieldWithoutHtml: 'answer',
    loadFieldsByChecksum: (notetypeId, checksum) {
      if (notetypeId != Int64(3) || checksum != fieldChecksum('answer')) {
        throw StateError('duplicate Note query arguments differ on JavaScript');
      }
      return [
        NoteChecksumMatch(
          noteId: Int64(4),
          firstField: '<b>answer</b>',
        ),
      ];
    },
  );
  if (!hasDuplicate) {
    throw StateError('duplicate Note check differs on JavaScript');
  }
  final notetype = Notetype(
    id: NotetypeId(Int64(7)),
    fields: [
      NoteField(name: 'Front', config: proto.Notetype_Field_Config()),
    ],
    config: Notetype.defaultConfig(),
  );
  final state = noteFieldsCheck(
    note: Note(id: Int64(2), notetypeId: Int64(7), fields: ['front']),
    getNotetype: (_) => notetype,
    normalizeText: false,
    loadFieldsByChecksum: (_, __) => [],
  );
  if (containsCloze('{{c1::text}}') != true ||
      state != notes.NoteFieldsCheckResponse_State.NORMAL) {
    throw StateError('note field validation differs on JavaScript');
  }
  final rendererType = Notetype(
    id: NotetypeId(Int64(8)),
    fields: [
      NoteField(name: 'field', config: proto.Notetype_Field_Config()),
    ],
    templates: [
      CardTemplate(
        name: 'Card 1',
        config: proto.Notetype_Template_Config(
          qFormatBrowser: '{{hint:field}}',
          aFormatBrowser: '{{FrontSide}}',
        ),
      ),
    ],
    config: Notetype.defaultConfig(),
  );
  final rendered = const BrowserCardTemplateRenderer().render(
    note: Note(id: Int64(9), notetypeId: Int64(8), fields: ['foo']),
    card: Card(id: Int64(10)),
    notetype: rendererType,
  );
  if (!rendered.isAvailable ||
      !rendered.questionHtml!.contains('hint83fe48607f0f3a66')) {
    throw StateError('browser template rendering differs on JavaScript');
  }
  final training = computeFsrsTrainingItems(
    revlogsByCard: [
      [
        RevlogEntry(
          id: RevlogId(Int64(100000000)),
          cardId: Int64(1),
          buttonChosen: 1,
          reviewKind: RevlogReviewKind.learning,
        ),
        RevlogEntry(
          id: RevlogId(Int64(200000000)),
          cardId: Int64(1),
          buttonChosen: 4,
          reviewKind: RevlogReviewKind.review,
        ),
      ],
    ],
    nextDayAt: Int64(300000),
    ignoreRevlogsBefore: Int64.ZERO,
  );
  if (training.reviewCount != 2 ||
      training.items.length != 1 ||
      training.items.single.reviews.last.rating != 4) {
    throw StateError('FSRS training-item projection differs on JavaScript');
  }
  final queue = LearningQueue(
    nowSecs: 100,
    learningCutoffSecs: 100,
    learnAheadSecs: 30,
    nextDayAtSecs: 200,
    entries: [
      LearningQueueEntry(
        due: Int64(100),
        id: Int64(11),
        mtime: Int64.ZERO,
        reps: 1,
      ),
    ],
  );
  final mixed = interspersedQueues([1, 2], [11]);
  final sortedQueueCandidates = sortNewQueueCandidates(
    [
      MainQueueSortCandidate(
        id: Int64.parseInt('9007199254740997'),
        noteId: Int64(1),
        templateIndex: 0,
        mtime: Int64.ZERO,
      ),
      MainQueueSortCandidate(
        id: Int64.parseInt('-9007199254740997'),
        noteId: Int64(2),
        templateIndex: 0,
        mtime: Int64.ZERO,
      ),
      MainQueueSortCandidate(
        id: Int64(1),
        noteId: Int64(3),
        templateIndex: 0,
        mtime: Int64.ZERO,
      ),
    ],
    deck.DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_RANDOM_CARD,
    daysElapsed: 2,
  );
  final mainQueue = composeMainQueue(
    reviews: const [],
    dayLearning: [
      ReviewQueueEntry(
        id: Int64(21),
        mtime: Int64.ZERO,
        kind: ReviewQueueEntryKind.learning,
      ),
    ],
    newCards: [
      MainQueueSortCandidate(
        id: Int64(22),
        noteId: Int64(4),
        templateIndex: 0,
        mtime: Int64.ZERO,
      ),
    ],
    sortOrder:
        deck.DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_NO_SORT,
    daysElapsed: 2,
    dayLearningMix: deck.DeckConfig_Config_ReviewMix.REVIEW_MIX_AFTER_REVIEWS,
    newReviewMix: deck.DeckConfig_Config_ReviewMix.REVIEW_MIX_AFTER_REVIEWS,
  );
  if (queue.intradayNow.single.id != Int64(11) ||
      mixed.join(',') != '1,11,2' ||
      ReviewQueueEntry.fromCard(Card(queue: CardQueue.dayLearn)).kind !=
          ReviewQueueEntryKind.review ||
      sortedQueueCandidates.map((entry) => entry.id.toString()).join(',') !=
          '9007199254740997,-9007199254740997,1' ||
      mainQueue.map((entry) => entry.kind).join(',') !=
          'MainQueueEntryKind.interdayLearning,MainQueueEntryKind.newCard') {
    throw StateError('review-queue primitives differ on JavaScript');
  }
  final admitted = admitQueueCandidates(
    QueueAdmissionInput(
      time: const QueueAdmissionTime(
        nowSecs: 100,
        daysElapsed: 2,
        nextDayAtSecs: 200,
      ),
      rootDeckId: 1,
      newCardsIgnoreReviewLimit: false,
      intradayCandidatesForBuryState: [
        QueueCandidate<int, int, int>(
          cardId: 12,
          noteId: 5,
          currentDeckId: 2,
          originalDeckId: 2,
          buryMode: const QueueBuryMode(buryReviews: true),
        ),
      ],
      reviewCandidates: [
        QueueCandidate<int, int, int>(
          cardId: 13,
          noteId: 5,
          currentDeckId: 2,
          originalDeckId: 2,
          buryMode: const QueueBuryMode(),
        ),
      ],
      parentDeckIds: const {2: 1},
    ),
  );
  if (admitted.reviews.isNotEmpty) {
    throw StateError('queue admission differs on JavaScript');
  }
}
