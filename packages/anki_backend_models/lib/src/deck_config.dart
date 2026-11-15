// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

typedef DeckConfigId = Int64;

/// Deck scheduling preferences stored by Anki Core.
class DeckConfig {
  DeckConfig({
    this.id = Int64.ZERO,
    this.name = '',
    this.mtimeSecs = Int64.ZERO,
    int usn = 0,
    required proto.DeckConfig_Config inner,
  })  : usn = usn.toSigned(32),
        inner = inner.deepCopy();

  factory DeckConfig.defaults() => DeckConfig(
        inner: proto.DeckConfig_Config(
          learnSteps: [1, 10],
          relearnSteps: [10],
          easyDaysPercentages: List<double>.filled(7, 1),
          newPerDay: 20,
          reviewsPerDay: 200,
          newPerDayMinimum: 0,
          initialEase: 2.5,
          easyMultiplier: 1.3,
          hardMultiplier: 1.2,
          lapseMultiplier: 0,
          intervalMultiplier: 1,
          maximumReviewInterval: 36500,
          minimumLapseInterval: 1,
          graduatingIntervalGood: 1,
          graduatingIntervalEasy: 4,
          newCardInsertOrder: proto
              .DeckConfig_Config_NewCardInsertOrder.NEW_CARD_INSERT_ORDER_DUE,
          newCardGatherPriority: proto.DeckConfig_Config_NewCardGatherPriority
              .NEW_CARD_GATHER_PRIORITY_DECK,
          newCardSortOrder: proto
              .DeckConfig_Config_NewCardSortOrder.NEW_CARD_SORT_ORDER_TEMPLATE,
          reviewOrder:
              proto.DeckConfig_Config_ReviewCardOrder.REVIEW_CARD_ORDER_DAY,
          newMix: proto.DeckConfig_Config_ReviewMix.REVIEW_MIX_MIX_WITH_REVIEWS,
          interdayLearningMix:
              proto.DeckConfig_Config_ReviewMix.REVIEW_MIX_MIX_WITH_REVIEWS,
          leechAction:
              proto.DeckConfig_Config_LeechAction.LEECH_ACTION_TAG_ONLY,
          leechThreshold: 8,
          disableAutoplay: false,
          capAnswerTimeToSecs: 60,
          showTimer: false,
          stopTimerOnAnswer: false,
          secondsToShowQuestion: 0,
          secondsToShowAnswer: 0,
          questionAction: proto
              .DeckConfig_Config_QuestionAction.QUESTION_ACTION_SHOW_ANSWER,
          answerAction:
              proto.DeckConfig_Config_AnswerAction.ANSWER_ACTION_BURY_CARD,
          waitForAudio: true,
          skipQuestionWhenReplayingAnswer: false,
          buryNew: false,
          buryReviews: false,
          buryInterdayLearning: false,
          desiredRetention: 0.9,
          historicalRetention: 0.9,
          paramSearch: '',
          ignoreRevlogsBeforeDate: '',
        ),
      );

  factory DeckConfig.fromProto(proto.DeckConfig value) => DeckConfig(
        id: value.id,
        name: value.name,
        mtimeSecs: value.mtimeSecs,
        usn: value.usn,
        inner: value.hasConfig() ? value.config : proto.DeckConfig_Config(),
      );

  final DeckConfigId id;
  final String name;
  final Int64 mtimeSecs;
  final int usn;
  final proto.DeckConfig_Config inner;

  List<double> get fsrsParams => inner.fsrsParams6.isNotEmpty
      ? inner.fsrsParams6
      : inner.fsrsParams5.isNotEmpty
          ? inner.fsrsParams5
          : inner.fsrsParams4;

  proto.DeckConfig toProto() => proto.DeckConfig(
        id: id,
        name: name,
        mtimeSecs: mtimeSecs,
        usn: usn,
        config: inner.deepCopy(),
      );
}
