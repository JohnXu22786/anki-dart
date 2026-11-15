//
//  Generated code. Do not modify.
//  source: anki/deck_config.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UpdateDeckConfigsMode extends $pb.ProtobufEnum {
  static const UpdateDeckConfigsMode UPDATE_DECK_CONFIGS_MODE_NORMAL = UpdateDeckConfigsMode._(0, _omitEnumNames ? '' : 'UPDATE_DECK_CONFIGS_MODE_NORMAL');
  static const UpdateDeckConfigsMode UPDATE_DECK_CONFIGS_MODE_APPLY_TO_CHILDREN = UpdateDeckConfigsMode._(1, _omitEnumNames ? '' : 'UPDATE_DECK_CONFIGS_MODE_APPLY_TO_CHILDREN');
  static const UpdateDeckConfigsMode UPDATE_DECK_CONFIGS_MODE_COMPUTE_ALL_PARAMS = UpdateDeckConfigsMode._(2, _omitEnumNames ? '' : 'UPDATE_DECK_CONFIGS_MODE_COMPUTE_ALL_PARAMS');

  static const $core.List<UpdateDeckConfigsMode> values = <UpdateDeckConfigsMode> [
    UPDATE_DECK_CONFIGS_MODE_NORMAL,
    UPDATE_DECK_CONFIGS_MODE_APPLY_TO_CHILDREN,
    UPDATE_DECK_CONFIGS_MODE_COMPUTE_ALL_PARAMS,
  ];

  static final $core.Map<$core.int, UpdateDeckConfigsMode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UpdateDeckConfigsMode? valueOf($core.int value) => _byValue[value];

  const UpdateDeckConfigsMode._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_NewCardInsertOrder extends $pb.ProtobufEnum {
  static const DeckConfig_Config_NewCardInsertOrder NEW_CARD_INSERT_ORDER_DUE = DeckConfig_Config_NewCardInsertOrder._(0, _omitEnumNames ? '' : 'NEW_CARD_INSERT_ORDER_DUE');
  static const DeckConfig_Config_NewCardInsertOrder NEW_CARD_INSERT_ORDER_RANDOM = DeckConfig_Config_NewCardInsertOrder._(1, _omitEnumNames ? '' : 'NEW_CARD_INSERT_ORDER_RANDOM');

  static const $core.List<DeckConfig_Config_NewCardInsertOrder> values = <DeckConfig_Config_NewCardInsertOrder> [
    NEW_CARD_INSERT_ORDER_DUE,
    NEW_CARD_INSERT_ORDER_RANDOM,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_NewCardInsertOrder> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_NewCardInsertOrder? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_NewCardInsertOrder._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_NewCardGatherPriority extends $pb.ProtobufEnum {
  static const DeckConfig_Config_NewCardGatherPriority NEW_CARD_GATHER_PRIORITY_DECK = DeckConfig_Config_NewCardGatherPriority._(0, _omitEnumNames ? '' : 'NEW_CARD_GATHER_PRIORITY_DECK');
  static const DeckConfig_Config_NewCardGatherPriority NEW_CARD_GATHER_PRIORITY_DECK_THEN_RANDOM_NOTES = DeckConfig_Config_NewCardGatherPriority._(5, _omitEnumNames ? '' : 'NEW_CARD_GATHER_PRIORITY_DECK_THEN_RANDOM_NOTES');
  static const DeckConfig_Config_NewCardGatherPriority NEW_CARD_GATHER_PRIORITY_LOWEST_POSITION = DeckConfig_Config_NewCardGatherPriority._(1, _omitEnumNames ? '' : 'NEW_CARD_GATHER_PRIORITY_LOWEST_POSITION');
  static const DeckConfig_Config_NewCardGatherPriority NEW_CARD_GATHER_PRIORITY_HIGHEST_POSITION = DeckConfig_Config_NewCardGatherPriority._(2, _omitEnumNames ? '' : 'NEW_CARD_GATHER_PRIORITY_HIGHEST_POSITION');
  static const DeckConfig_Config_NewCardGatherPriority NEW_CARD_GATHER_PRIORITY_RANDOM_NOTES = DeckConfig_Config_NewCardGatherPriority._(3, _omitEnumNames ? '' : 'NEW_CARD_GATHER_PRIORITY_RANDOM_NOTES');
  static const DeckConfig_Config_NewCardGatherPriority NEW_CARD_GATHER_PRIORITY_RANDOM_CARDS = DeckConfig_Config_NewCardGatherPriority._(4, _omitEnumNames ? '' : 'NEW_CARD_GATHER_PRIORITY_RANDOM_CARDS');

  static const $core.List<DeckConfig_Config_NewCardGatherPriority> values = <DeckConfig_Config_NewCardGatherPriority> [
    NEW_CARD_GATHER_PRIORITY_DECK,
    NEW_CARD_GATHER_PRIORITY_DECK_THEN_RANDOM_NOTES,
    NEW_CARD_GATHER_PRIORITY_LOWEST_POSITION,
    NEW_CARD_GATHER_PRIORITY_HIGHEST_POSITION,
    NEW_CARD_GATHER_PRIORITY_RANDOM_NOTES,
    NEW_CARD_GATHER_PRIORITY_RANDOM_CARDS,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_NewCardGatherPriority> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_NewCardGatherPriority? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_NewCardGatherPriority._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_NewCardSortOrder extends $pb.ProtobufEnum {
  static const DeckConfig_Config_NewCardSortOrder NEW_CARD_SORT_ORDER_TEMPLATE = DeckConfig_Config_NewCardSortOrder._(0, _omitEnumNames ? '' : 'NEW_CARD_SORT_ORDER_TEMPLATE');
  static const DeckConfig_Config_NewCardSortOrder NEW_CARD_SORT_ORDER_NO_SORT = DeckConfig_Config_NewCardSortOrder._(1, _omitEnumNames ? '' : 'NEW_CARD_SORT_ORDER_NO_SORT');
  static const DeckConfig_Config_NewCardSortOrder NEW_CARD_SORT_ORDER_TEMPLATE_THEN_RANDOM = DeckConfig_Config_NewCardSortOrder._(2, _omitEnumNames ? '' : 'NEW_CARD_SORT_ORDER_TEMPLATE_THEN_RANDOM');
  static const DeckConfig_Config_NewCardSortOrder NEW_CARD_SORT_ORDER_RANDOM_NOTE_THEN_TEMPLATE = DeckConfig_Config_NewCardSortOrder._(3, _omitEnumNames ? '' : 'NEW_CARD_SORT_ORDER_RANDOM_NOTE_THEN_TEMPLATE');
  static const DeckConfig_Config_NewCardSortOrder NEW_CARD_SORT_ORDER_RANDOM_CARD = DeckConfig_Config_NewCardSortOrder._(4, _omitEnumNames ? '' : 'NEW_CARD_SORT_ORDER_RANDOM_CARD');

  static const $core.List<DeckConfig_Config_NewCardSortOrder> values = <DeckConfig_Config_NewCardSortOrder> [
    NEW_CARD_SORT_ORDER_TEMPLATE,
    NEW_CARD_SORT_ORDER_NO_SORT,
    NEW_CARD_SORT_ORDER_TEMPLATE_THEN_RANDOM,
    NEW_CARD_SORT_ORDER_RANDOM_NOTE_THEN_TEMPLATE,
    NEW_CARD_SORT_ORDER_RANDOM_CARD,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_NewCardSortOrder> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_NewCardSortOrder? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_NewCardSortOrder._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_ReviewCardOrder extends $pb.ProtobufEnum {
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_DAY = DeckConfig_Config_ReviewCardOrder._(0, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_DAY');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_DAY_THEN_DECK = DeckConfig_Config_ReviewCardOrder._(1, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_DAY_THEN_DECK');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_DECK_THEN_DAY = DeckConfig_Config_ReviewCardOrder._(2, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_DECK_THEN_DAY');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_INTERVALS_ASCENDING = DeckConfig_Config_ReviewCardOrder._(3, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_INTERVALS_ASCENDING');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_INTERVALS_DESCENDING = DeckConfig_Config_ReviewCardOrder._(4, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_INTERVALS_DESCENDING');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_EASE_ASCENDING = DeckConfig_Config_ReviewCardOrder._(5, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_EASE_ASCENDING');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_EASE_DESCENDING = DeckConfig_Config_ReviewCardOrder._(6, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_EASE_DESCENDING');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_RETRIEVABILITY_ASCENDING = DeckConfig_Config_ReviewCardOrder._(7, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_RETRIEVABILITY_ASCENDING');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_RETRIEVABILITY_DESCENDING = DeckConfig_Config_ReviewCardOrder._(11, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_RETRIEVABILITY_DESCENDING');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_RELATIVE_OVERDUENESS = DeckConfig_Config_ReviewCardOrder._(12, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_RELATIVE_OVERDUENESS');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_RANDOM = DeckConfig_Config_ReviewCardOrder._(8, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_RANDOM');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_ADDED = DeckConfig_Config_ReviewCardOrder._(9, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_ADDED');
  static const DeckConfig_Config_ReviewCardOrder REVIEW_CARD_ORDER_REVERSE_ADDED = DeckConfig_Config_ReviewCardOrder._(10, _omitEnumNames ? '' : 'REVIEW_CARD_ORDER_REVERSE_ADDED');

  static const $core.List<DeckConfig_Config_ReviewCardOrder> values = <DeckConfig_Config_ReviewCardOrder> [
    REVIEW_CARD_ORDER_DAY,
    REVIEW_CARD_ORDER_DAY_THEN_DECK,
    REVIEW_CARD_ORDER_DECK_THEN_DAY,
    REVIEW_CARD_ORDER_INTERVALS_ASCENDING,
    REVIEW_CARD_ORDER_INTERVALS_DESCENDING,
    REVIEW_CARD_ORDER_EASE_ASCENDING,
    REVIEW_CARD_ORDER_EASE_DESCENDING,
    REVIEW_CARD_ORDER_RETRIEVABILITY_ASCENDING,
    REVIEW_CARD_ORDER_RETRIEVABILITY_DESCENDING,
    REVIEW_CARD_ORDER_RELATIVE_OVERDUENESS,
    REVIEW_CARD_ORDER_RANDOM,
    REVIEW_CARD_ORDER_ADDED,
    REVIEW_CARD_ORDER_REVERSE_ADDED,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_ReviewCardOrder> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_ReviewCardOrder? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_ReviewCardOrder._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_ReviewMix extends $pb.ProtobufEnum {
  static const DeckConfig_Config_ReviewMix REVIEW_MIX_MIX_WITH_REVIEWS = DeckConfig_Config_ReviewMix._(0, _omitEnumNames ? '' : 'REVIEW_MIX_MIX_WITH_REVIEWS');
  static const DeckConfig_Config_ReviewMix REVIEW_MIX_AFTER_REVIEWS = DeckConfig_Config_ReviewMix._(1, _omitEnumNames ? '' : 'REVIEW_MIX_AFTER_REVIEWS');
  static const DeckConfig_Config_ReviewMix REVIEW_MIX_BEFORE_REVIEWS = DeckConfig_Config_ReviewMix._(2, _omitEnumNames ? '' : 'REVIEW_MIX_BEFORE_REVIEWS');

  static const $core.List<DeckConfig_Config_ReviewMix> values = <DeckConfig_Config_ReviewMix> [
    REVIEW_MIX_MIX_WITH_REVIEWS,
    REVIEW_MIX_AFTER_REVIEWS,
    REVIEW_MIX_BEFORE_REVIEWS,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_ReviewMix> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_ReviewMix? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_ReviewMix._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_LeechAction extends $pb.ProtobufEnum {
  static const DeckConfig_Config_LeechAction LEECH_ACTION_SUSPEND = DeckConfig_Config_LeechAction._(0, _omitEnumNames ? '' : 'LEECH_ACTION_SUSPEND');
  static const DeckConfig_Config_LeechAction LEECH_ACTION_TAG_ONLY = DeckConfig_Config_LeechAction._(1, _omitEnumNames ? '' : 'LEECH_ACTION_TAG_ONLY');

  static const $core.List<DeckConfig_Config_LeechAction> values = <DeckConfig_Config_LeechAction> [
    LEECH_ACTION_SUSPEND,
    LEECH_ACTION_TAG_ONLY,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_LeechAction> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_LeechAction? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_LeechAction._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_AnswerAction extends $pb.ProtobufEnum {
  static const DeckConfig_Config_AnswerAction ANSWER_ACTION_BURY_CARD = DeckConfig_Config_AnswerAction._(0, _omitEnumNames ? '' : 'ANSWER_ACTION_BURY_CARD');
  static const DeckConfig_Config_AnswerAction ANSWER_ACTION_ANSWER_AGAIN = DeckConfig_Config_AnswerAction._(1, _omitEnumNames ? '' : 'ANSWER_ACTION_ANSWER_AGAIN');
  static const DeckConfig_Config_AnswerAction ANSWER_ACTION_ANSWER_GOOD = DeckConfig_Config_AnswerAction._(2, _omitEnumNames ? '' : 'ANSWER_ACTION_ANSWER_GOOD');
  static const DeckConfig_Config_AnswerAction ANSWER_ACTION_ANSWER_HARD = DeckConfig_Config_AnswerAction._(3, _omitEnumNames ? '' : 'ANSWER_ACTION_ANSWER_HARD');
  static const DeckConfig_Config_AnswerAction ANSWER_ACTION_SHOW_REMINDER = DeckConfig_Config_AnswerAction._(4, _omitEnumNames ? '' : 'ANSWER_ACTION_SHOW_REMINDER');

  static const $core.List<DeckConfig_Config_AnswerAction> values = <DeckConfig_Config_AnswerAction> [
    ANSWER_ACTION_BURY_CARD,
    ANSWER_ACTION_ANSWER_AGAIN,
    ANSWER_ACTION_ANSWER_GOOD,
    ANSWER_ACTION_ANSWER_HARD,
    ANSWER_ACTION_SHOW_REMINDER,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_AnswerAction> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_AnswerAction? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_AnswerAction._($core.int v, $core.String n) : super(v, n);
}

class DeckConfig_Config_QuestionAction extends $pb.ProtobufEnum {
  static const DeckConfig_Config_QuestionAction QUESTION_ACTION_SHOW_ANSWER = DeckConfig_Config_QuestionAction._(0, _omitEnumNames ? '' : 'QUESTION_ACTION_SHOW_ANSWER');
  static const DeckConfig_Config_QuestionAction QUESTION_ACTION_SHOW_REMINDER = DeckConfig_Config_QuestionAction._(1, _omitEnumNames ? '' : 'QUESTION_ACTION_SHOW_REMINDER');

  static const $core.List<DeckConfig_Config_QuestionAction> values = <DeckConfig_Config_QuestionAction> [
    QUESTION_ACTION_SHOW_ANSWER,
    QUESTION_ACTION_SHOW_REMINDER,
  ];

  static final $core.Map<$core.int, DeckConfig_Config_QuestionAction> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DeckConfig_Config_QuestionAction? valueOf($core.int value) => _byValue[value];

  const DeckConfig_Config_QuestionAction._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
