// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/scheduler.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class QueuedCards_Queue extends $pb.ProtobufEnum {
  static const QueuedCards_Queue NEW = QueuedCards_Queue._(0, _omitEnumNames ? '' : 'NEW');
  static const QueuedCards_Queue LEARNING = QueuedCards_Queue._(1, _omitEnumNames ? '' : 'LEARNING');
  static const QueuedCards_Queue REVIEW = QueuedCards_Queue._(2, _omitEnumNames ? '' : 'REVIEW');

  static const $core.List<QueuedCards_Queue> values = <QueuedCards_Queue> [
    NEW,
    LEARNING,
    REVIEW,
  ];

  static final $core.Map<$core.int, QueuedCards_Queue> _byValue = $pb.ProtobufEnum.initByValue(values);
  static QueuedCards_Queue? valueOf($core.int value) => _byValue[value];

  const QueuedCards_Queue._($core.int v, $core.String n) : super(v, n);
}

class UnburyDeckRequest_Mode extends $pb.ProtobufEnum {
  static const UnburyDeckRequest_Mode ALL = UnburyDeckRequest_Mode._(0, _omitEnumNames ? '' : 'ALL');
  static const UnburyDeckRequest_Mode SCHED_ONLY = UnburyDeckRequest_Mode._(1, _omitEnumNames ? '' : 'SCHED_ONLY');
  static const UnburyDeckRequest_Mode USER_ONLY = UnburyDeckRequest_Mode._(2, _omitEnumNames ? '' : 'USER_ONLY');

  static const $core.List<UnburyDeckRequest_Mode> values = <UnburyDeckRequest_Mode> [
    ALL,
    SCHED_ONLY,
    USER_ONLY,
  ];

  static final $core.Map<$core.int, UnburyDeckRequest_Mode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static UnburyDeckRequest_Mode? valueOf($core.int value) => _byValue[value];

  const UnburyDeckRequest_Mode._($core.int v, $core.String n) : super(v, n);
}

class BuryOrSuspendCardsRequest_Mode extends $pb.ProtobufEnum {
  static const BuryOrSuspendCardsRequest_Mode SUSPEND = BuryOrSuspendCardsRequest_Mode._(0, _omitEnumNames ? '' : 'SUSPEND');
  static const BuryOrSuspendCardsRequest_Mode BURY_SCHED = BuryOrSuspendCardsRequest_Mode._(1, _omitEnumNames ? '' : 'BURY_SCHED');
  static const BuryOrSuspendCardsRequest_Mode BURY_USER = BuryOrSuspendCardsRequest_Mode._(2, _omitEnumNames ? '' : 'BURY_USER');

  static const $core.List<BuryOrSuspendCardsRequest_Mode> values = <BuryOrSuspendCardsRequest_Mode> [
    SUSPEND,
    BURY_SCHED,
    BURY_USER,
  ];

  static final $core.Map<$core.int, BuryOrSuspendCardsRequest_Mode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static BuryOrSuspendCardsRequest_Mode? valueOf($core.int value) => _byValue[value];

  const BuryOrSuspendCardsRequest_Mode._($core.int v, $core.String n) : super(v, n);
}

class ScheduleCardsAsNewRequest_Context extends $pb.ProtobufEnum {
  static const ScheduleCardsAsNewRequest_Context BROWSER = ScheduleCardsAsNewRequest_Context._(0, _omitEnumNames ? '' : 'BROWSER');
  static const ScheduleCardsAsNewRequest_Context REVIEWER = ScheduleCardsAsNewRequest_Context._(1, _omitEnumNames ? '' : 'REVIEWER');

  static const $core.List<ScheduleCardsAsNewRequest_Context> values = <ScheduleCardsAsNewRequest_Context> [
    BROWSER,
    REVIEWER,
  ];

  static final $core.Map<$core.int, ScheduleCardsAsNewRequest_Context> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ScheduleCardsAsNewRequest_Context? valueOf($core.int value) => _byValue[value];

  const ScheduleCardsAsNewRequest_Context._($core.int v, $core.String n) : super(v, n);
}

class CardAnswer_Rating extends $pb.ProtobufEnum {
  static const CardAnswer_Rating AGAIN = CardAnswer_Rating._(0, _omitEnumNames ? '' : 'AGAIN');
  static const CardAnswer_Rating HARD = CardAnswer_Rating._(1, _omitEnumNames ? '' : 'HARD');
  static const CardAnswer_Rating GOOD = CardAnswer_Rating._(2, _omitEnumNames ? '' : 'GOOD');
  static const CardAnswer_Rating EASY = CardAnswer_Rating._(3, _omitEnumNames ? '' : 'EASY');

  static const $core.List<CardAnswer_Rating> values = <CardAnswer_Rating> [
    AGAIN,
    HARD,
    GOOD,
    EASY,
  ];

  static final $core.Map<$core.int, CardAnswer_Rating> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CardAnswer_Rating? valueOf($core.int value) => _byValue[value];

  const CardAnswer_Rating._($core.int v, $core.String n) : super(v, n);
}

class CustomStudyRequest_Cram_CramKind extends $pb.ProtobufEnum {
  static const CustomStudyRequest_Cram_CramKind CRAM_KIND_DUE = CustomStudyRequest_Cram_CramKind._(0, _omitEnumNames ? '' : 'CRAM_KIND_DUE');
  static const CustomStudyRequest_Cram_CramKind CRAM_KIND_NEW = CustomStudyRequest_Cram_CramKind._(1, _omitEnumNames ? '' : 'CRAM_KIND_NEW');
  static const CustomStudyRequest_Cram_CramKind CRAM_KIND_REVIEW = CustomStudyRequest_Cram_CramKind._(2, _omitEnumNames ? '' : 'CRAM_KIND_REVIEW');
  static const CustomStudyRequest_Cram_CramKind CRAM_KIND_ALL = CustomStudyRequest_Cram_CramKind._(3, _omitEnumNames ? '' : 'CRAM_KIND_ALL');

  static const $core.List<CustomStudyRequest_Cram_CramKind> values = <CustomStudyRequest_Cram_CramKind> [
    CRAM_KIND_DUE,
    CRAM_KIND_NEW,
    CRAM_KIND_REVIEW,
    CRAM_KIND_ALL,
  ];

  static final $core.Map<$core.int, CustomStudyRequest_Cram_CramKind> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CustomStudyRequest_Cram_CramKind? valueOf($core.int value) => _byValue[value];

  const CustomStudyRequest_Cram_CramKind._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
