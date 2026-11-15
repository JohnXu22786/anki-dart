// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/stats.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cards.pb.dart' as $3;
import 'generic.pb.dart' as $0;
import 'stats.pbenum.dart';

export 'stats.pbenum.dart';

class ReviewLogs extends $pb.GeneratedMessage {
  factory ReviewLogs({
    $core.Iterable<CardStatsResponse_StatsRevlogEntry>? entries,
  }) {
    final $result = create();
    if (entries != null) {
      $result.entries.addAll(entries);
    }
    return $result;
  }
  ReviewLogs._() : super();
  factory ReviewLogs.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReviewLogs.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReviewLogs', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..pc<CardStatsResponse_StatsRevlogEntry>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM, subBuilder: CardStatsResponse_StatsRevlogEntry.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReviewLogs clone() => ReviewLogs()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReviewLogs copyWith(void Function(ReviewLogs) updates) => super.copyWith((message) => updates(message as ReviewLogs)) as ReviewLogs;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReviewLogs create() => ReviewLogs._();
  ReviewLogs createEmptyInstance() => create();
  static $pb.PbList<ReviewLogs> createRepeated() => $pb.PbList<ReviewLogs>();
  @$core.pragma('dart2js:noInline')
  static ReviewLogs getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReviewLogs>(create);
  static ReviewLogs? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<CardStatsResponse_StatsRevlogEntry> get entries => $_getList(0);
}

class CardStatsResponse_StatsRevlogEntry extends $pb.GeneratedMessage {
  factory CardStatsResponse_StatsRevlogEntry({
    $fixnum.Int64? time,
    RevlogEntry_ReviewKind? reviewKind,
    $core.int? buttonChosen,
    $core.int? interval,
    $core.int? ease,
    $core.double? takenSecs,
    $3.FsrsMemoryState? memoryState,
    $core.int? lastInterval,
  }) {
    final $result = create();
    if (time != null) {
      $result.time = time;
    }
    if (reviewKind != null) {
      $result.reviewKind = reviewKind;
    }
    if (buttonChosen != null) {
      $result.buttonChosen = buttonChosen;
    }
    if (interval != null) {
      $result.interval = interval;
    }
    if (ease != null) {
      $result.ease = ease;
    }
    if (takenSecs != null) {
      $result.takenSecs = takenSecs;
    }
    if (memoryState != null) {
      $result.memoryState = memoryState;
    }
    if (lastInterval != null) {
      $result.lastInterval = lastInterval;
    }
    return $result;
  }
  CardStatsResponse_StatsRevlogEntry._() : super();
  factory CardStatsResponse_StatsRevlogEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CardStatsResponse_StatsRevlogEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CardStatsResponse.StatsRevlogEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'time')
    ..e<RevlogEntry_ReviewKind>(2, _omitFieldNames ? '' : 'reviewKind', $pb.PbFieldType.OE, defaultOrMaker: RevlogEntry_ReviewKind.LEARNING, valueOf: RevlogEntry_ReviewKind.valueOf, enumValues: RevlogEntry_ReviewKind.values)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'buttonChosen', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'interval', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'ease', $pb.PbFieldType.OU3)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'takenSecs', $pb.PbFieldType.OF)
    ..aOM<$3.FsrsMemoryState>(7, _omitFieldNames ? '' : 'memoryState', subBuilder: $3.FsrsMemoryState.create)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'lastInterval', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CardStatsResponse_StatsRevlogEntry clone() => CardStatsResponse_StatsRevlogEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CardStatsResponse_StatsRevlogEntry copyWith(void Function(CardStatsResponse_StatsRevlogEntry) updates) => super.copyWith((message) => updates(message as CardStatsResponse_StatsRevlogEntry)) as CardStatsResponse_StatsRevlogEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardStatsResponse_StatsRevlogEntry create() => CardStatsResponse_StatsRevlogEntry._();
  CardStatsResponse_StatsRevlogEntry createEmptyInstance() => create();
  static $pb.PbList<CardStatsResponse_StatsRevlogEntry> createRepeated() => $pb.PbList<CardStatsResponse_StatsRevlogEntry>();
  @$core.pragma('dart2js:noInline')
  static CardStatsResponse_StatsRevlogEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardStatsResponse_StatsRevlogEntry>(create);
  static CardStatsResponse_StatsRevlogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get time => $_getI64(0);
  @$pb.TagNumber(1)
  set time($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearTime() => clearField(1);

  @$pb.TagNumber(2)
  RevlogEntry_ReviewKind get reviewKind => $_getN(1);
  @$pb.TagNumber(2)
  set reviewKind(RevlogEntry_ReviewKind v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasReviewKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearReviewKind() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get buttonChosen => $_getIZ(2);
  @$pb.TagNumber(3)
  set buttonChosen($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasButtonChosen() => $_has(2);
  @$pb.TagNumber(3)
  void clearButtonChosen() => clearField(3);

  /// seconds
  @$pb.TagNumber(4)
  $core.int get interval => $_getIZ(3);
  @$pb.TagNumber(4)
  set interval($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasInterval() => $_has(3);
  @$pb.TagNumber(4)
  void clearInterval() => clearField(4);

  /// per mill
  @$pb.TagNumber(5)
  $core.int get ease => $_getIZ(4);
  @$pb.TagNumber(5)
  set ease($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEase() => $_has(4);
  @$pb.TagNumber(5)
  void clearEase() => clearField(5);

  @$pb.TagNumber(6)
  $core.double get takenSecs => $_getN(5);
  @$pb.TagNumber(6)
  set takenSecs($core.double v) { $_setFloat(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasTakenSecs() => $_has(5);
  @$pb.TagNumber(6)
  void clearTakenSecs() => clearField(6);

  @$pb.TagNumber(7)
  $3.FsrsMemoryState get memoryState => $_getN(6);
  @$pb.TagNumber(7)
  set memoryState($3.FsrsMemoryState v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasMemoryState() => $_has(6);
  @$pb.TagNumber(7)
  void clearMemoryState() => clearField(7);
  @$pb.TagNumber(7)
  $3.FsrsMemoryState ensureMemoryState() => $_ensure(6);

  /// seconds
  @$pb.TagNumber(8)
  $core.int get lastInterval => $_getIZ(7);
  @$pb.TagNumber(8)
  set lastInterval($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasLastInterval() => $_has(7);
  @$pb.TagNumber(8)
  void clearLastInterval() => clearField(8);
}

class CardStatsResponse extends $pb.GeneratedMessage {
  factory CardStatsResponse({
    $core.Iterable<CardStatsResponse_StatsRevlogEntry>? revlog,
    $fixnum.Int64? cardId,
    $fixnum.Int64? noteId,
    $core.String? deck,
    $fixnum.Int64? added,
    $fixnum.Int64? firstReview,
    $fixnum.Int64? latestReview,
    $fixnum.Int64? dueDate,
    $core.int? duePosition,
    $core.int? interval,
    $core.int? ease,
    $core.int? reviews,
    $core.int? lapses,
    $core.double? averageSecs,
    $core.double? totalSecs,
    $core.String? cardType,
    $core.String? notetype,
    $3.FsrsMemoryState? memoryState,
    $core.double? fsrsRetrievability,
    $core.String? customData,
    $core.String? preset,
    $core.String? originalDeck,
    $core.double? desiredRetention,
    $core.Iterable<$core.double>? fsrsParams,
  }) {
    final $result = create();
    if (revlog != null) {
      $result.revlog.addAll(revlog);
    }
    if (cardId != null) {
      $result.cardId = cardId;
    }
    if (noteId != null) {
      $result.noteId = noteId;
    }
    if (deck != null) {
      $result.deck = deck;
    }
    if (added != null) {
      $result.added = added;
    }
    if (firstReview != null) {
      $result.firstReview = firstReview;
    }
    if (latestReview != null) {
      $result.latestReview = latestReview;
    }
    if (dueDate != null) {
      $result.dueDate = dueDate;
    }
    if (duePosition != null) {
      $result.duePosition = duePosition;
    }
    if (interval != null) {
      $result.interval = interval;
    }
    if (ease != null) {
      $result.ease = ease;
    }
    if (reviews != null) {
      $result.reviews = reviews;
    }
    if (lapses != null) {
      $result.lapses = lapses;
    }
    if (averageSecs != null) {
      $result.averageSecs = averageSecs;
    }
    if (totalSecs != null) {
      $result.totalSecs = totalSecs;
    }
    if (cardType != null) {
      $result.cardType = cardType;
    }
    if (notetype != null) {
      $result.notetype = notetype;
    }
    if (memoryState != null) {
      $result.memoryState = memoryState;
    }
    if (fsrsRetrievability != null) {
      $result.fsrsRetrievability = fsrsRetrievability;
    }
    if (customData != null) {
      $result.customData = customData;
    }
    if (preset != null) {
      $result.preset = preset;
    }
    if (originalDeck != null) {
      $result.originalDeck = originalDeck;
    }
    if (desiredRetention != null) {
      $result.desiredRetention = desiredRetention;
    }
    if (fsrsParams != null) {
      $result.fsrsParams.addAll(fsrsParams);
    }
    return $result;
  }
  CardStatsResponse._() : super();
  factory CardStatsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CardStatsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CardStatsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..pc<CardStatsResponse_StatsRevlogEntry>(1, _omitFieldNames ? '' : 'revlog', $pb.PbFieldType.PM, subBuilder: CardStatsResponse_StatsRevlogEntry.create)
    ..aInt64(2, _omitFieldNames ? '' : 'cardId')
    ..aInt64(3, _omitFieldNames ? '' : 'noteId')
    ..aOS(4, _omitFieldNames ? '' : 'deck')
    ..aInt64(5, _omitFieldNames ? '' : 'added')
    ..aInt64(6, _omitFieldNames ? '' : 'firstReview')
    ..aInt64(7, _omitFieldNames ? '' : 'latestReview')
    ..aInt64(8, _omitFieldNames ? '' : 'dueDate')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'duePosition', $pb.PbFieldType.O3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'interval', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'ease', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'reviews', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'lapses', $pb.PbFieldType.OU3)
    ..a<$core.double>(14, _omitFieldNames ? '' : 'averageSecs', $pb.PbFieldType.OF)
    ..a<$core.double>(15, _omitFieldNames ? '' : 'totalSecs', $pb.PbFieldType.OF)
    ..aOS(16, _omitFieldNames ? '' : 'cardType')
    ..aOS(17, _omitFieldNames ? '' : 'notetype')
    ..aOM<$3.FsrsMemoryState>(18, _omitFieldNames ? '' : 'memoryState', subBuilder: $3.FsrsMemoryState.create)
    ..a<$core.double>(19, _omitFieldNames ? '' : 'fsrsRetrievability', $pb.PbFieldType.OF)
    ..aOS(20, _omitFieldNames ? '' : 'customData')
    ..aOS(21, _omitFieldNames ? '' : 'preset')
    ..aOS(22, _omitFieldNames ? '' : 'originalDeck')
    ..a<$core.double>(23, _omitFieldNames ? '' : 'desiredRetention', $pb.PbFieldType.OF)
    ..p<$core.double>(24, _omitFieldNames ? '' : 'fsrsParams', $pb.PbFieldType.KF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CardStatsResponse clone() => CardStatsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CardStatsResponse copyWith(void Function(CardStatsResponse) updates) => super.copyWith((message) => updates(message as CardStatsResponse)) as CardStatsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardStatsResponse create() => CardStatsResponse._();
  CardStatsResponse createEmptyInstance() => create();
  static $pb.PbList<CardStatsResponse> createRepeated() => $pb.PbList<CardStatsResponse>();
  @$core.pragma('dart2js:noInline')
  static CardStatsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardStatsResponse>(create);
  static CardStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<CardStatsResponse_StatsRevlogEntry> get revlog => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get cardId => $_getI64(1);
  @$pb.TagNumber(2)
  set cardId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get noteId => $_getI64(2);
  @$pb.TagNumber(3)
  set noteId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNoteId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNoteId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get deck => $_getSZ(3);
  @$pb.TagNumber(4)
  set deck($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeck() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeck() => clearField(4);

  /// Unix timestamps
  @$pb.TagNumber(5)
  $fixnum.Int64 get added => $_getI64(4);
  @$pb.TagNumber(5)
  set added($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAdded() => $_has(4);
  @$pb.TagNumber(5)
  void clearAdded() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get firstReview => $_getI64(5);
  @$pb.TagNumber(6)
  set firstReview($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasFirstReview() => $_has(5);
  @$pb.TagNumber(6)
  void clearFirstReview() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get latestReview => $_getI64(6);
  @$pb.TagNumber(7)
  set latestReview($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasLatestReview() => $_has(6);
  @$pb.TagNumber(7)
  void clearLatestReview() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get dueDate => $_getI64(7);
  @$pb.TagNumber(8)
  set dueDate($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasDueDate() => $_has(7);
  @$pb.TagNumber(8)
  void clearDueDate() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get duePosition => $_getIZ(8);
  @$pb.TagNumber(9)
  set duePosition($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDuePosition() => $_has(8);
  @$pb.TagNumber(9)
  void clearDuePosition() => clearField(9);

  /// days
  @$pb.TagNumber(10)
  $core.int get interval => $_getIZ(9);
  @$pb.TagNumber(10)
  set interval($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasInterval() => $_has(9);
  @$pb.TagNumber(10)
  void clearInterval() => clearField(10);

  /// per mill
  @$pb.TagNumber(11)
  $core.int get ease => $_getIZ(10);
  @$pb.TagNumber(11)
  set ease($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasEase() => $_has(10);
  @$pb.TagNumber(11)
  void clearEase() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get reviews => $_getIZ(11);
  @$pb.TagNumber(12)
  set reviews($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasReviews() => $_has(11);
  @$pb.TagNumber(12)
  void clearReviews() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get lapses => $_getIZ(12);
  @$pb.TagNumber(13)
  set lapses($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasLapses() => $_has(12);
  @$pb.TagNumber(13)
  void clearLapses() => clearField(13);

  @$pb.TagNumber(14)
  $core.double get averageSecs => $_getN(13);
  @$pb.TagNumber(14)
  set averageSecs($core.double v) { $_setFloat(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasAverageSecs() => $_has(13);
  @$pb.TagNumber(14)
  void clearAverageSecs() => clearField(14);

  @$pb.TagNumber(15)
  $core.double get totalSecs => $_getN(14);
  @$pb.TagNumber(15)
  set totalSecs($core.double v) { $_setFloat(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasTotalSecs() => $_has(14);
  @$pb.TagNumber(15)
  void clearTotalSecs() => clearField(15);

  @$pb.TagNumber(16)
  $core.String get cardType => $_getSZ(15);
  @$pb.TagNumber(16)
  set cardType($core.String v) { $_setString(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasCardType() => $_has(15);
  @$pb.TagNumber(16)
  void clearCardType() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get notetype => $_getSZ(16);
  @$pb.TagNumber(17)
  set notetype($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasNotetype() => $_has(16);
  @$pb.TagNumber(17)
  void clearNotetype() => clearField(17);

  @$pb.TagNumber(18)
  $3.FsrsMemoryState get memoryState => $_getN(17);
  @$pb.TagNumber(18)
  set memoryState($3.FsrsMemoryState v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasMemoryState() => $_has(17);
  @$pb.TagNumber(18)
  void clearMemoryState() => clearField(18);
  @$pb.TagNumber(18)
  $3.FsrsMemoryState ensureMemoryState() => $_ensure(17);

  /// not set if due date/state not available
  @$pb.TagNumber(19)
  $core.double get fsrsRetrievability => $_getN(18);
  @$pb.TagNumber(19)
  set fsrsRetrievability($core.double v) { $_setFloat(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasFsrsRetrievability() => $_has(18);
  @$pb.TagNumber(19)
  void clearFsrsRetrievability() => clearField(19);

  @$pb.TagNumber(20)
  $core.String get customData => $_getSZ(19);
  @$pb.TagNumber(20)
  set customData($core.String v) { $_setString(19, v); }
  @$pb.TagNumber(20)
  $core.bool hasCustomData() => $_has(19);
  @$pb.TagNumber(20)
  void clearCustomData() => clearField(20);

  @$pb.TagNumber(21)
  $core.String get preset => $_getSZ(20);
  @$pb.TagNumber(21)
  set preset($core.String v) { $_setString(20, v); }
  @$pb.TagNumber(21)
  $core.bool hasPreset() => $_has(20);
  @$pb.TagNumber(21)
  void clearPreset() => clearField(21);

  @$pb.TagNumber(22)
  $core.String get originalDeck => $_getSZ(21);
  @$pb.TagNumber(22)
  set originalDeck($core.String v) { $_setString(21, v); }
  @$pb.TagNumber(22)
  $core.bool hasOriginalDeck() => $_has(21);
  @$pb.TagNumber(22)
  void clearOriginalDeck() => clearField(22);

  @$pb.TagNumber(23)
  $core.double get desiredRetention => $_getN(22);
  @$pb.TagNumber(23)
  set desiredRetention($core.double v) { $_setFloat(22, v); }
  @$pb.TagNumber(23)
  $core.bool hasDesiredRetention() => $_has(22);
  @$pb.TagNumber(23)
  void clearDesiredRetention() => clearField(23);

  @$pb.TagNumber(24)
  $core.List<$core.double> get fsrsParams => $_getList(23);
}

class GraphsRequest extends $pb.GeneratedMessage {
  factory GraphsRequest({
    $core.String? search,
    $core.int? days,
  }) {
    final $result = create();
    if (search != null) {
      $result.search = search;
    }
    if (days != null) {
      $result.days = days;
    }
    return $result;
  }
  GraphsRequest._() : super();
  factory GraphsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'search')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'days', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsRequest clone() => GraphsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsRequest copyWith(void Function(GraphsRequest) updates) => super.copyWith((message) => updates(message as GraphsRequest)) as GraphsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsRequest create() => GraphsRequest._();
  GraphsRequest createEmptyInstance() => create();
  static $pb.PbList<GraphsRequest> createRepeated() => $pb.PbList<GraphsRequest>();
  @$core.pragma('dart2js:noInline')
  static GraphsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsRequest>(create);
  static GraphsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get search => $_getSZ(0);
  @$pb.TagNumber(1)
  set search($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSearch() => $_has(0);
  @$pb.TagNumber(1)
  void clearSearch() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get days => $_getIZ(1);
  @$pb.TagNumber(2)
  set days($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDays() => $_has(1);
  @$pb.TagNumber(2)
  void clearDays() => clearField(2);
}

class GraphsResponse_Added extends $pb.GeneratedMessage {
  factory GraphsResponse_Added({
    $core.Map<$core.int, $core.int>? added,
  }) {
    final $result = create();
    if (added != null) {
      $result.added.addAll(added);
    }
    return $result;
  }
  GraphsResponse_Added._() : super();
  factory GraphsResponse_Added.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Added.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Added', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..m<$core.int, $core.int>(1, _omitFieldNames ? '' : 'added', entryClassName: 'GraphsResponse.Added.AddedEntry', keyFieldType: $pb.PbFieldType.O3, valueFieldType: $pb.PbFieldType.OU3, packageName: const $pb.PackageName('anki.stats'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Added clone() => GraphsResponse_Added()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Added copyWith(void Function(GraphsResponse_Added) updates) => super.copyWith((message) => updates(message as GraphsResponse_Added)) as GraphsResponse_Added;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Added create() => GraphsResponse_Added._();
  GraphsResponse_Added createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Added> createRepeated() => $pb.PbList<GraphsResponse_Added>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Added getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Added>(create);
  static GraphsResponse_Added? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, $core.int> get added => $_getMap(0);
}

class GraphsResponse_Intervals extends $pb.GeneratedMessage {
  factory GraphsResponse_Intervals({
    $core.Map<$core.int, $core.int>? intervals,
  }) {
    final $result = create();
    if (intervals != null) {
      $result.intervals.addAll(intervals);
    }
    return $result;
  }
  GraphsResponse_Intervals._() : super();
  factory GraphsResponse_Intervals.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Intervals.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Intervals', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..m<$core.int, $core.int>(1, _omitFieldNames ? '' : 'intervals', entryClassName: 'GraphsResponse.Intervals.IntervalsEntry', keyFieldType: $pb.PbFieldType.OU3, valueFieldType: $pb.PbFieldType.OU3, packageName: const $pb.PackageName('anki.stats'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Intervals clone() => GraphsResponse_Intervals()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Intervals copyWith(void Function(GraphsResponse_Intervals) updates) => super.copyWith((message) => updates(message as GraphsResponse_Intervals)) as GraphsResponse_Intervals;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Intervals create() => GraphsResponse_Intervals._();
  GraphsResponse_Intervals createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Intervals> createRepeated() => $pb.PbList<GraphsResponse_Intervals>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Intervals getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Intervals>(create);
  static GraphsResponse_Intervals? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, $core.int> get intervals => $_getMap(0);
}

class GraphsResponse_Eases extends $pb.GeneratedMessage {
  factory GraphsResponse_Eases({
    $core.Map<$core.int, $core.int>? eases,
    $core.double? average,
  }) {
    final $result = create();
    if (eases != null) {
      $result.eases.addAll(eases);
    }
    if (average != null) {
      $result.average = average;
    }
    return $result;
  }
  GraphsResponse_Eases._() : super();
  factory GraphsResponse_Eases.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Eases.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Eases', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..m<$core.int, $core.int>(1, _omitFieldNames ? '' : 'eases', entryClassName: 'GraphsResponse.Eases.EasesEntry', keyFieldType: $pb.PbFieldType.OU3, valueFieldType: $pb.PbFieldType.OU3, packageName: const $pb.PackageName('anki.stats'))
    ..a<$core.double>(2, _omitFieldNames ? '' : 'average', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Eases clone() => GraphsResponse_Eases()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Eases copyWith(void Function(GraphsResponse_Eases) updates) => super.copyWith((message) => updates(message as GraphsResponse_Eases)) as GraphsResponse_Eases;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Eases create() => GraphsResponse_Eases._();
  GraphsResponse_Eases createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Eases> createRepeated() => $pb.PbList<GraphsResponse_Eases>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Eases getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Eases>(create);
  static GraphsResponse_Eases? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, $core.int> get eases => $_getMap(0);

  @$pb.TagNumber(2)
  $core.double get average => $_getN(1);
  @$pb.TagNumber(2)
  set average($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAverage() => $_has(1);
  @$pb.TagNumber(2)
  void clearAverage() => clearField(2);
}

class GraphsResponse_Retrievability extends $pb.GeneratedMessage {
  factory GraphsResponse_Retrievability({
    $core.Map<$core.int, $core.int>? retrievability,
    $core.double? average,
    $core.double? sumByCard,
    $core.double? sumByNote,
  }) {
    final $result = create();
    if (retrievability != null) {
      $result.retrievability.addAll(retrievability);
    }
    if (average != null) {
      $result.average = average;
    }
    if (sumByCard != null) {
      $result.sumByCard = sumByCard;
    }
    if (sumByNote != null) {
      $result.sumByNote = sumByNote;
    }
    return $result;
  }
  GraphsResponse_Retrievability._() : super();
  factory GraphsResponse_Retrievability.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Retrievability.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Retrievability', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..m<$core.int, $core.int>(1, _omitFieldNames ? '' : 'retrievability', entryClassName: 'GraphsResponse.Retrievability.RetrievabilityEntry', keyFieldType: $pb.PbFieldType.OU3, valueFieldType: $pb.PbFieldType.OU3, packageName: const $pb.PackageName('anki.stats'))
    ..a<$core.double>(2, _omitFieldNames ? '' : 'average', $pb.PbFieldType.OF)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'sumByCard', $pb.PbFieldType.OF)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'sumByNote', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Retrievability clone() => GraphsResponse_Retrievability()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Retrievability copyWith(void Function(GraphsResponse_Retrievability) updates) => super.copyWith((message) => updates(message as GraphsResponse_Retrievability)) as GraphsResponse_Retrievability;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Retrievability create() => GraphsResponse_Retrievability._();
  GraphsResponse_Retrievability createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Retrievability> createRepeated() => $pb.PbList<GraphsResponse_Retrievability>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Retrievability getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Retrievability>(create);
  static GraphsResponse_Retrievability? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, $core.int> get retrievability => $_getMap(0);

  @$pb.TagNumber(2)
  $core.double get average => $_getN(1);
  @$pb.TagNumber(2)
  set average($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAverage() => $_has(1);
  @$pb.TagNumber(2)
  void clearAverage() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get sumByCard => $_getN(2);
  @$pb.TagNumber(3)
  set sumByCard($core.double v) { $_setFloat(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSumByCard() => $_has(2);
  @$pb.TagNumber(3)
  void clearSumByCard() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get sumByNote => $_getN(3);
  @$pb.TagNumber(4)
  set sumByNote($core.double v) { $_setFloat(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSumByNote() => $_has(3);
  @$pb.TagNumber(4)
  void clearSumByNote() => clearField(4);
}

class GraphsResponse_FutureDue extends $pb.GeneratedMessage {
  factory GraphsResponse_FutureDue({
    $core.Map<$core.int, $core.int>? futureDue,
    $core.bool? haveBacklog,
    $core.int? dailyLoad,
  }) {
    final $result = create();
    if (futureDue != null) {
      $result.futureDue.addAll(futureDue);
    }
    if (haveBacklog != null) {
      $result.haveBacklog = haveBacklog;
    }
    if (dailyLoad != null) {
      $result.dailyLoad = dailyLoad;
    }
    return $result;
  }
  GraphsResponse_FutureDue._() : super();
  factory GraphsResponse_FutureDue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_FutureDue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.FutureDue', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..m<$core.int, $core.int>(1, _omitFieldNames ? '' : 'futureDue', entryClassName: 'GraphsResponse.FutureDue.FutureDueEntry', keyFieldType: $pb.PbFieldType.O3, valueFieldType: $pb.PbFieldType.OU3, packageName: const $pb.PackageName('anki.stats'))
    ..aOB(2, _omitFieldNames ? '' : 'haveBacklog')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'dailyLoad', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_FutureDue clone() => GraphsResponse_FutureDue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_FutureDue copyWith(void Function(GraphsResponse_FutureDue) updates) => super.copyWith((message) => updates(message as GraphsResponse_FutureDue)) as GraphsResponse_FutureDue;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_FutureDue create() => GraphsResponse_FutureDue._();
  GraphsResponse_FutureDue createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_FutureDue> createRepeated() => $pb.PbList<GraphsResponse_FutureDue>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_FutureDue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_FutureDue>(create);
  static GraphsResponse_FutureDue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, $core.int> get futureDue => $_getMap(0);

  @$pb.TagNumber(2)
  $core.bool get haveBacklog => $_getBF(1);
  @$pb.TagNumber(2)
  set haveBacklog($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHaveBacklog() => $_has(1);
  @$pb.TagNumber(2)
  void clearHaveBacklog() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get dailyLoad => $_getIZ(2);
  @$pb.TagNumber(3)
  set dailyLoad($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDailyLoad() => $_has(2);
  @$pb.TagNumber(3)
  void clearDailyLoad() => clearField(3);
}

class GraphsResponse_Today extends $pb.GeneratedMessage {
  factory GraphsResponse_Today({
    $core.int? answerCount,
    $core.int? answerMillis,
    $core.int? correctCount,
    $core.int? matureCorrect,
    $core.int? matureCount,
    $core.int? learnCount,
    $core.int? reviewCount,
    $core.int? relearnCount,
    $core.int? earlyReviewCount,
  }) {
    final $result = create();
    if (answerCount != null) {
      $result.answerCount = answerCount;
    }
    if (answerMillis != null) {
      $result.answerMillis = answerMillis;
    }
    if (correctCount != null) {
      $result.correctCount = correctCount;
    }
    if (matureCorrect != null) {
      $result.matureCorrect = matureCorrect;
    }
    if (matureCount != null) {
      $result.matureCount = matureCount;
    }
    if (learnCount != null) {
      $result.learnCount = learnCount;
    }
    if (reviewCount != null) {
      $result.reviewCount = reviewCount;
    }
    if (relearnCount != null) {
      $result.relearnCount = relearnCount;
    }
    if (earlyReviewCount != null) {
      $result.earlyReviewCount = earlyReviewCount;
    }
    return $result;
  }
  GraphsResponse_Today._() : super();
  factory GraphsResponse_Today.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Today.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Today', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'answerCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'answerMillis', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'correctCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'matureCorrect', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'matureCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'learnCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'reviewCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'relearnCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'earlyReviewCount', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Today clone() => GraphsResponse_Today()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Today copyWith(void Function(GraphsResponse_Today) updates) => super.copyWith((message) => updates(message as GraphsResponse_Today)) as GraphsResponse_Today;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Today create() => GraphsResponse_Today._();
  GraphsResponse_Today createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Today> createRepeated() => $pb.PbList<GraphsResponse_Today>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Today getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Today>(create);
  static GraphsResponse_Today? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get answerCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set answerCount($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAnswerCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnswerCount() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get answerMillis => $_getIZ(1);
  @$pb.TagNumber(2)
  set answerMillis($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAnswerMillis() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnswerMillis() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get correctCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set correctCount($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCorrectCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCorrectCount() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get matureCorrect => $_getIZ(3);
  @$pb.TagNumber(4)
  set matureCorrect($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMatureCorrect() => $_has(3);
  @$pb.TagNumber(4)
  void clearMatureCorrect() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get matureCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set matureCount($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMatureCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearMatureCount() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get learnCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set learnCount($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLearnCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearLearnCount() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get reviewCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set reviewCount($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasReviewCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearReviewCount() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get relearnCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set relearnCount($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasRelearnCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearRelearnCount() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get earlyReviewCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set earlyReviewCount($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasEarlyReviewCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearEarlyReviewCount() => clearField(9);
}

class GraphsResponse_Hours_Hour extends $pb.GeneratedMessage {
  factory GraphsResponse_Hours_Hour({
    $core.int? total,
    $core.int? correct,
  }) {
    final $result = create();
    if (total != null) {
      $result.total = total;
    }
    if (correct != null) {
      $result.correct = correct;
    }
    return $result;
  }
  GraphsResponse_Hours_Hour._() : super();
  factory GraphsResponse_Hours_Hour.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Hours_Hour.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Hours.Hour', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'correct', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Hours_Hour clone() => GraphsResponse_Hours_Hour()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Hours_Hour copyWith(void Function(GraphsResponse_Hours_Hour) updates) => super.copyWith((message) => updates(message as GraphsResponse_Hours_Hour)) as GraphsResponse_Hours_Hour;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Hours_Hour create() => GraphsResponse_Hours_Hour._();
  GraphsResponse_Hours_Hour createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Hours_Hour> createRepeated() => $pb.PbList<GraphsResponse_Hours_Hour>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Hours_Hour getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Hours_Hour>(create);
  static GraphsResponse_Hours_Hour? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get total => $_getIZ(0);
  @$pb.TagNumber(1)
  set total($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get correct => $_getIZ(1);
  @$pb.TagNumber(2)
  set correct($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCorrect() => $_has(1);
  @$pb.TagNumber(2)
  void clearCorrect() => clearField(2);
}

/// each bucket is a 24 element vec
class GraphsResponse_Hours extends $pb.GeneratedMessage {
  factory GraphsResponse_Hours({
    $core.Iterable<GraphsResponse_Hours_Hour>? oneMonth,
    $core.Iterable<GraphsResponse_Hours_Hour>? threeMonths,
    $core.Iterable<GraphsResponse_Hours_Hour>? oneYear,
    $core.Iterable<GraphsResponse_Hours_Hour>? allTime,
  }) {
    final $result = create();
    if (oneMonth != null) {
      $result.oneMonth.addAll(oneMonth);
    }
    if (threeMonths != null) {
      $result.threeMonths.addAll(threeMonths);
    }
    if (oneYear != null) {
      $result.oneYear.addAll(oneYear);
    }
    if (allTime != null) {
      $result.allTime.addAll(allTime);
    }
    return $result;
  }
  GraphsResponse_Hours._() : super();
  factory GraphsResponse_Hours.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Hours.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Hours', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..pc<GraphsResponse_Hours_Hour>(1, _omitFieldNames ? '' : 'oneMonth', $pb.PbFieldType.PM, subBuilder: GraphsResponse_Hours_Hour.create)
    ..pc<GraphsResponse_Hours_Hour>(2, _omitFieldNames ? '' : 'threeMonths', $pb.PbFieldType.PM, subBuilder: GraphsResponse_Hours_Hour.create)
    ..pc<GraphsResponse_Hours_Hour>(3, _omitFieldNames ? '' : 'oneYear', $pb.PbFieldType.PM, subBuilder: GraphsResponse_Hours_Hour.create)
    ..pc<GraphsResponse_Hours_Hour>(4, _omitFieldNames ? '' : 'allTime', $pb.PbFieldType.PM, subBuilder: GraphsResponse_Hours_Hour.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Hours clone() => GraphsResponse_Hours()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Hours copyWith(void Function(GraphsResponse_Hours) updates) => super.copyWith((message) => updates(message as GraphsResponse_Hours)) as GraphsResponse_Hours;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Hours create() => GraphsResponse_Hours._();
  GraphsResponse_Hours createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Hours> createRepeated() => $pb.PbList<GraphsResponse_Hours>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Hours getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Hours>(create);
  static GraphsResponse_Hours? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GraphsResponse_Hours_Hour> get oneMonth => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<GraphsResponse_Hours_Hour> get threeMonths => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<GraphsResponse_Hours_Hour> get oneYear => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<GraphsResponse_Hours_Hour> get allTime => $_getList(3);
}

class GraphsResponse_ReviewCountsAndTimes_Reviews extends $pb.GeneratedMessage {
  factory GraphsResponse_ReviewCountsAndTimes_Reviews({
    $core.int? learn,
    $core.int? relearn,
    $core.int? young,
    $core.int? mature,
    $core.int? filtered,
  }) {
    final $result = create();
    if (learn != null) {
      $result.learn = learn;
    }
    if (relearn != null) {
      $result.relearn = relearn;
    }
    if (young != null) {
      $result.young = young;
    }
    if (mature != null) {
      $result.mature = mature;
    }
    if (filtered != null) {
      $result.filtered = filtered;
    }
    return $result;
  }
  GraphsResponse_ReviewCountsAndTimes_Reviews._() : super();
  factory GraphsResponse_ReviewCountsAndTimes_Reviews.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_ReviewCountsAndTimes_Reviews.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.ReviewCountsAndTimes.Reviews', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'learn', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'relearn', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'young', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'mature', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'filtered', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_ReviewCountsAndTimes_Reviews clone() => GraphsResponse_ReviewCountsAndTimes_Reviews()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_ReviewCountsAndTimes_Reviews copyWith(void Function(GraphsResponse_ReviewCountsAndTimes_Reviews) updates) => super.copyWith((message) => updates(message as GraphsResponse_ReviewCountsAndTimes_Reviews)) as GraphsResponse_ReviewCountsAndTimes_Reviews;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_ReviewCountsAndTimes_Reviews create() => GraphsResponse_ReviewCountsAndTimes_Reviews._();
  GraphsResponse_ReviewCountsAndTimes_Reviews createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_ReviewCountsAndTimes_Reviews> createRepeated() => $pb.PbList<GraphsResponse_ReviewCountsAndTimes_Reviews>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_ReviewCountsAndTimes_Reviews getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_ReviewCountsAndTimes_Reviews>(create);
  static GraphsResponse_ReviewCountsAndTimes_Reviews? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get learn => $_getIZ(0);
  @$pb.TagNumber(1)
  set learn($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLearn() => $_has(0);
  @$pb.TagNumber(1)
  void clearLearn() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get relearn => $_getIZ(1);
  @$pb.TagNumber(2)
  set relearn($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRelearn() => $_has(1);
  @$pb.TagNumber(2)
  void clearRelearn() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get young => $_getIZ(2);
  @$pb.TagNumber(3)
  set young($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasYoung() => $_has(2);
  @$pb.TagNumber(3)
  void clearYoung() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get mature => $_getIZ(3);
  @$pb.TagNumber(4)
  set mature($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMature() => $_has(3);
  @$pb.TagNumber(4)
  void clearMature() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get filtered => $_getIZ(4);
  @$pb.TagNumber(5)
  set filtered($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasFiltered() => $_has(4);
  @$pb.TagNumber(5)
  void clearFiltered() => clearField(5);
}

class GraphsResponse_ReviewCountsAndTimes extends $pb.GeneratedMessage {
  factory GraphsResponse_ReviewCountsAndTimes({
    $core.Map<$core.int, GraphsResponse_ReviewCountsAndTimes_Reviews>? count,
    $core.Map<$core.int, GraphsResponse_ReviewCountsAndTimes_Reviews>? time,
  }) {
    final $result = create();
    if (count != null) {
      $result.count.addAll(count);
    }
    if (time != null) {
      $result.time.addAll(time);
    }
    return $result;
  }
  GraphsResponse_ReviewCountsAndTimes._() : super();
  factory GraphsResponse_ReviewCountsAndTimes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_ReviewCountsAndTimes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.ReviewCountsAndTimes', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..m<$core.int, GraphsResponse_ReviewCountsAndTimes_Reviews>(1, _omitFieldNames ? '' : 'count', entryClassName: 'GraphsResponse.ReviewCountsAndTimes.CountEntry', keyFieldType: $pb.PbFieldType.O3, valueFieldType: $pb.PbFieldType.OM, valueCreator: GraphsResponse_ReviewCountsAndTimes_Reviews.create, valueDefaultOrMaker: GraphsResponse_ReviewCountsAndTimes_Reviews.getDefault, packageName: const $pb.PackageName('anki.stats'))
    ..m<$core.int, GraphsResponse_ReviewCountsAndTimes_Reviews>(2, _omitFieldNames ? '' : 'time', entryClassName: 'GraphsResponse.ReviewCountsAndTimes.TimeEntry', keyFieldType: $pb.PbFieldType.O3, valueFieldType: $pb.PbFieldType.OM, valueCreator: GraphsResponse_ReviewCountsAndTimes_Reviews.create, valueDefaultOrMaker: GraphsResponse_ReviewCountsAndTimes_Reviews.getDefault, packageName: const $pb.PackageName('anki.stats'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_ReviewCountsAndTimes clone() => GraphsResponse_ReviewCountsAndTimes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_ReviewCountsAndTimes copyWith(void Function(GraphsResponse_ReviewCountsAndTimes) updates) => super.copyWith((message) => updates(message as GraphsResponse_ReviewCountsAndTimes)) as GraphsResponse_ReviewCountsAndTimes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_ReviewCountsAndTimes create() => GraphsResponse_ReviewCountsAndTimes._();
  GraphsResponse_ReviewCountsAndTimes createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_ReviewCountsAndTimes> createRepeated() => $pb.PbList<GraphsResponse_ReviewCountsAndTimes>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_ReviewCountsAndTimes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_ReviewCountsAndTimes>(create);
  static GraphsResponse_ReviewCountsAndTimes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, GraphsResponse_ReviewCountsAndTimes_Reviews> get count => $_getMap(0);

  @$pb.TagNumber(2)
  $core.Map<$core.int, GraphsResponse_ReviewCountsAndTimes_Reviews> get time => $_getMap(1);
}

class GraphsResponse_Buttons_ButtonCounts extends $pb.GeneratedMessage {
  factory GraphsResponse_Buttons_ButtonCounts({
    $core.Iterable<$core.int>? learning,
    $core.Iterable<$core.int>? young,
    $core.Iterable<$core.int>? mature,
  }) {
    final $result = create();
    if (learning != null) {
      $result.learning.addAll(learning);
    }
    if (young != null) {
      $result.young.addAll(young);
    }
    if (mature != null) {
      $result.mature.addAll(mature);
    }
    return $result;
  }
  GraphsResponse_Buttons_ButtonCounts._() : super();
  factory GraphsResponse_Buttons_ButtonCounts.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Buttons_ButtonCounts.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Buttons.ButtonCounts', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'learning', $pb.PbFieldType.KU3)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'young', $pb.PbFieldType.KU3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'mature', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Buttons_ButtonCounts clone() => GraphsResponse_Buttons_ButtonCounts()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Buttons_ButtonCounts copyWith(void Function(GraphsResponse_Buttons_ButtonCounts) updates) => super.copyWith((message) => updates(message as GraphsResponse_Buttons_ButtonCounts)) as GraphsResponse_Buttons_ButtonCounts;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Buttons_ButtonCounts create() => GraphsResponse_Buttons_ButtonCounts._();
  GraphsResponse_Buttons_ButtonCounts createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Buttons_ButtonCounts> createRepeated() => $pb.PbList<GraphsResponse_Buttons_ButtonCounts>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Buttons_ButtonCounts getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Buttons_ButtonCounts>(create);
  static GraphsResponse_Buttons_ButtonCounts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get learning => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get young => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get mature => $_getList(2);
}

/// 4 element vecs for buttons 1-4
class GraphsResponse_Buttons extends $pb.GeneratedMessage {
  factory GraphsResponse_Buttons({
    GraphsResponse_Buttons_ButtonCounts? oneMonth,
    GraphsResponse_Buttons_ButtonCounts? threeMonths,
    GraphsResponse_Buttons_ButtonCounts? oneYear,
    GraphsResponse_Buttons_ButtonCounts? allTime,
  }) {
    final $result = create();
    if (oneMonth != null) {
      $result.oneMonth = oneMonth;
    }
    if (threeMonths != null) {
      $result.threeMonths = threeMonths;
    }
    if (oneYear != null) {
      $result.oneYear = oneYear;
    }
    if (allTime != null) {
      $result.allTime = allTime;
    }
    return $result;
  }
  GraphsResponse_Buttons._() : super();
  factory GraphsResponse_Buttons.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_Buttons.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.Buttons', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aOM<GraphsResponse_Buttons_ButtonCounts>(1, _omitFieldNames ? '' : 'oneMonth', subBuilder: GraphsResponse_Buttons_ButtonCounts.create)
    ..aOM<GraphsResponse_Buttons_ButtonCounts>(2, _omitFieldNames ? '' : 'threeMonths', subBuilder: GraphsResponse_Buttons_ButtonCounts.create)
    ..aOM<GraphsResponse_Buttons_ButtonCounts>(3, _omitFieldNames ? '' : 'oneYear', subBuilder: GraphsResponse_Buttons_ButtonCounts.create)
    ..aOM<GraphsResponse_Buttons_ButtonCounts>(4, _omitFieldNames ? '' : 'allTime', subBuilder: GraphsResponse_Buttons_ButtonCounts.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_Buttons clone() => GraphsResponse_Buttons()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_Buttons copyWith(void Function(GraphsResponse_Buttons) updates) => super.copyWith((message) => updates(message as GraphsResponse_Buttons)) as GraphsResponse_Buttons;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Buttons create() => GraphsResponse_Buttons._();
  GraphsResponse_Buttons createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_Buttons> createRepeated() => $pb.PbList<GraphsResponse_Buttons>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_Buttons getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_Buttons>(create);
  static GraphsResponse_Buttons? _defaultInstance;

  @$pb.TagNumber(1)
  GraphsResponse_Buttons_ButtonCounts get oneMonth => $_getN(0);
  @$pb.TagNumber(1)
  set oneMonth(GraphsResponse_Buttons_ButtonCounts v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasOneMonth() => $_has(0);
  @$pb.TagNumber(1)
  void clearOneMonth() => clearField(1);
  @$pb.TagNumber(1)
  GraphsResponse_Buttons_ButtonCounts ensureOneMonth() => $_ensure(0);

  @$pb.TagNumber(2)
  GraphsResponse_Buttons_ButtonCounts get threeMonths => $_getN(1);
  @$pb.TagNumber(2)
  set threeMonths(GraphsResponse_Buttons_ButtonCounts v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasThreeMonths() => $_has(1);
  @$pb.TagNumber(2)
  void clearThreeMonths() => clearField(2);
  @$pb.TagNumber(2)
  GraphsResponse_Buttons_ButtonCounts ensureThreeMonths() => $_ensure(1);

  @$pb.TagNumber(3)
  GraphsResponse_Buttons_ButtonCounts get oneYear => $_getN(2);
  @$pb.TagNumber(3)
  set oneYear(GraphsResponse_Buttons_ButtonCounts v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasOneYear() => $_has(2);
  @$pb.TagNumber(3)
  void clearOneYear() => clearField(3);
  @$pb.TagNumber(3)
  GraphsResponse_Buttons_ButtonCounts ensureOneYear() => $_ensure(2);

  @$pb.TagNumber(4)
  GraphsResponse_Buttons_ButtonCounts get allTime => $_getN(3);
  @$pb.TagNumber(4)
  set allTime(GraphsResponse_Buttons_ButtonCounts v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasAllTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllTime() => clearField(4);
  @$pb.TagNumber(4)
  GraphsResponse_Buttons_ButtonCounts ensureAllTime() => $_ensure(3);
}

class GraphsResponse_CardCounts_Counts extends $pb.GeneratedMessage {
  factory GraphsResponse_CardCounts_Counts({
    $core.int? newCards,
    $core.int? learn,
    $core.int? relearn,
    $core.int? young,
    $core.int? mature,
    $core.int? suspended,
    $core.int? buried,
  }) {
    final $result = create();
    if (newCards != null) {
      $result.newCards = newCards;
    }
    if (learn != null) {
      $result.learn = learn;
    }
    if (relearn != null) {
      $result.relearn = relearn;
    }
    if (young != null) {
      $result.young = young;
    }
    if (mature != null) {
      $result.mature = mature;
    }
    if (suspended != null) {
      $result.suspended = suspended;
    }
    if (buried != null) {
      $result.buried = buried;
    }
    return $result;
  }
  GraphsResponse_CardCounts_Counts._() : super();
  factory GraphsResponse_CardCounts_Counts.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_CardCounts_Counts.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.CardCounts.Counts', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'newCards', $pb.PbFieldType.OU3, protoName: 'newCards')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'learn', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'relearn', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'young', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'mature', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'suspended', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'buried', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_CardCounts_Counts clone() => GraphsResponse_CardCounts_Counts()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_CardCounts_Counts copyWith(void Function(GraphsResponse_CardCounts_Counts) updates) => super.copyWith((message) => updates(message as GraphsResponse_CardCounts_Counts)) as GraphsResponse_CardCounts_Counts;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_CardCounts_Counts create() => GraphsResponse_CardCounts_Counts._();
  GraphsResponse_CardCounts_Counts createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_CardCounts_Counts> createRepeated() => $pb.PbList<GraphsResponse_CardCounts_Counts>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_CardCounts_Counts getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_CardCounts_Counts>(create);
  static GraphsResponse_CardCounts_Counts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get newCards => $_getIZ(0);
  @$pb.TagNumber(1)
  set newCards($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNewCards() => $_has(0);
  @$pb.TagNumber(1)
  void clearNewCards() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get learn => $_getIZ(1);
  @$pb.TagNumber(2)
  set learn($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLearn() => $_has(1);
  @$pb.TagNumber(2)
  void clearLearn() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get relearn => $_getIZ(2);
  @$pb.TagNumber(3)
  set relearn($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRelearn() => $_has(2);
  @$pb.TagNumber(3)
  void clearRelearn() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get young => $_getIZ(3);
  @$pb.TagNumber(4)
  set young($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasYoung() => $_has(3);
  @$pb.TagNumber(4)
  void clearYoung() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get mature => $_getIZ(4);
  @$pb.TagNumber(5)
  set mature($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMature() => $_has(4);
  @$pb.TagNumber(5)
  void clearMature() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get suspended => $_getIZ(5);
  @$pb.TagNumber(6)
  set suspended($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSuspended() => $_has(5);
  @$pb.TagNumber(6)
  void clearSuspended() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get buried => $_getIZ(6);
  @$pb.TagNumber(7)
  set buried($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasBuried() => $_has(6);
  @$pb.TagNumber(7)
  void clearBuried() => clearField(7);
}

class GraphsResponse_CardCounts extends $pb.GeneratedMessage {
  factory GraphsResponse_CardCounts({
    GraphsResponse_CardCounts_Counts? includingInactive,
    GraphsResponse_CardCounts_Counts? excludingInactive,
  }) {
    final $result = create();
    if (includingInactive != null) {
      $result.includingInactive = includingInactive;
    }
    if (excludingInactive != null) {
      $result.excludingInactive = excludingInactive;
    }
    return $result;
  }
  GraphsResponse_CardCounts._() : super();
  factory GraphsResponse_CardCounts.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_CardCounts.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.CardCounts', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aOM<GraphsResponse_CardCounts_Counts>(1, _omitFieldNames ? '' : 'includingInactive', subBuilder: GraphsResponse_CardCounts_Counts.create)
    ..aOM<GraphsResponse_CardCounts_Counts>(2, _omitFieldNames ? '' : 'excludingInactive', subBuilder: GraphsResponse_CardCounts_Counts.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_CardCounts clone() => GraphsResponse_CardCounts()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_CardCounts copyWith(void Function(GraphsResponse_CardCounts) updates) => super.copyWith((message) => updates(message as GraphsResponse_CardCounts)) as GraphsResponse_CardCounts;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_CardCounts create() => GraphsResponse_CardCounts._();
  GraphsResponse_CardCounts createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_CardCounts> createRepeated() => $pb.PbList<GraphsResponse_CardCounts>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_CardCounts getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_CardCounts>(create);
  static GraphsResponse_CardCounts? _defaultInstance;

  /// Buried/suspended cards are included in counts; suspended/buried counts
  /// are 0.
  @$pb.TagNumber(1)
  GraphsResponse_CardCounts_Counts get includingInactive => $_getN(0);
  @$pb.TagNumber(1)
  set includingInactive(GraphsResponse_CardCounts_Counts v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasIncludingInactive() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludingInactive() => clearField(1);
  @$pb.TagNumber(1)
  GraphsResponse_CardCounts_Counts ensureIncludingInactive() => $_ensure(0);

  /// Buried/suspended cards are counted separately.
  @$pb.TagNumber(2)
  GraphsResponse_CardCounts_Counts get excludingInactive => $_getN(1);
  @$pb.TagNumber(2)
  set excludingInactive(GraphsResponse_CardCounts_Counts v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExcludingInactive() => $_has(1);
  @$pb.TagNumber(2)
  void clearExcludingInactive() => clearField(2);
  @$pb.TagNumber(2)
  GraphsResponse_CardCounts_Counts ensureExcludingInactive() => $_ensure(1);
}

class GraphsResponse_TrueRetentionStats_TrueRetention extends $pb.GeneratedMessage {
  factory GraphsResponse_TrueRetentionStats_TrueRetention({
    $core.int? youngPassed,
    $core.int? youngFailed,
    $core.int? maturePassed,
    $core.int? matureFailed,
  }) {
    final $result = create();
    if (youngPassed != null) {
      $result.youngPassed = youngPassed;
    }
    if (youngFailed != null) {
      $result.youngFailed = youngFailed;
    }
    if (maturePassed != null) {
      $result.maturePassed = maturePassed;
    }
    if (matureFailed != null) {
      $result.matureFailed = matureFailed;
    }
    return $result;
  }
  GraphsResponse_TrueRetentionStats_TrueRetention._() : super();
  factory GraphsResponse_TrueRetentionStats_TrueRetention.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_TrueRetentionStats_TrueRetention.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.TrueRetentionStats.TrueRetention', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'youngPassed', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'youngFailed', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'maturePassed', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'matureFailed', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_TrueRetentionStats_TrueRetention clone() => GraphsResponse_TrueRetentionStats_TrueRetention()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_TrueRetentionStats_TrueRetention copyWith(void Function(GraphsResponse_TrueRetentionStats_TrueRetention) updates) => super.copyWith((message) => updates(message as GraphsResponse_TrueRetentionStats_TrueRetention)) as GraphsResponse_TrueRetentionStats_TrueRetention;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_TrueRetentionStats_TrueRetention create() => GraphsResponse_TrueRetentionStats_TrueRetention._();
  GraphsResponse_TrueRetentionStats_TrueRetention createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_TrueRetentionStats_TrueRetention> createRepeated() => $pb.PbList<GraphsResponse_TrueRetentionStats_TrueRetention>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_TrueRetentionStats_TrueRetention getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_TrueRetentionStats_TrueRetention>(create);
  static GraphsResponse_TrueRetentionStats_TrueRetention? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get youngPassed => $_getIZ(0);
  @$pb.TagNumber(1)
  set youngPassed($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasYoungPassed() => $_has(0);
  @$pb.TagNumber(1)
  void clearYoungPassed() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get youngFailed => $_getIZ(1);
  @$pb.TagNumber(2)
  set youngFailed($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasYoungFailed() => $_has(1);
  @$pb.TagNumber(2)
  void clearYoungFailed() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get maturePassed => $_getIZ(2);
  @$pb.TagNumber(3)
  set maturePassed($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMaturePassed() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaturePassed() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get matureFailed => $_getIZ(3);
  @$pb.TagNumber(4)
  set matureFailed($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMatureFailed() => $_has(3);
  @$pb.TagNumber(4)
  void clearMatureFailed() => clearField(4);
}

class GraphsResponse_TrueRetentionStats extends $pb.GeneratedMessage {
  factory GraphsResponse_TrueRetentionStats({
    GraphsResponse_TrueRetentionStats_TrueRetention? today,
    GraphsResponse_TrueRetentionStats_TrueRetention? yesterday,
    GraphsResponse_TrueRetentionStats_TrueRetention? week,
    GraphsResponse_TrueRetentionStats_TrueRetention? month,
    GraphsResponse_TrueRetentionStats_TrueRetention? year,
    GraphsResponse_TrueRetentionStats_TrueRetention? allTime,
  }) {
    final $result = create();
    if (today != null) {
      $result.today = today;
    }
    if (yesterday != null) {
      $result.yesterday = yesterday;
    }
    if (week != null) {
      $result.week = week;
    }
    if (month != null) {
      $result.month = month;
    }
    if (year != null) {
      $result.year = year;
    }
    if (allTime != null) {
      $result.allTime = allTime;
    }
    return $result;
  }
  GraphsResponse_TrueRetentionStats._() : super();
  factory GraphsResponse_TrueRetentionStats.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse_TrueRetentionStats.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse.TrueRetentionStats', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aOM<GraphsResponse_TrueRetentionStats_TrueRetention>(1, _omitFieldNames ? '' : 'today', subBuilder: GraphsResponse_TrueRetentionStats_TrueRetention.create)
    ..aOM<GraphsResponse_TrueRetentionStats_TrueRetention>(2, _omitFieldNames ? '' : 'yesterday', subBuilder: GraphsResponse_TrueRetentionStats_TrueRetention.create)
    ..aOM<GraphsResponse_TrueRetentionStats_TrueRetention>(3, _omitFieldNames ? '' : 'week', subBuilder: GraphsResponse_TrueRetentionStats_TrueRetention.create)
    ..aOM<GraphsResponse_TrueRetentionStats_TrueRetention>(4, _omitFieldNames ? '' : 'month', subBuilder: GraphsResponse_TrueRetentionStats_TrueRetention.create)
    ..aOM<GraphsResponse_TrueRetentionStats_TrueRetention>(5, _omitFieldNames ? '' : 'year', subBuilder: GraphsResponse_TrueRetentionStats_TrueRetention.create)
    ..aOM<GraphsResponse_TrueRetentionStats_TrueRetention>(6, _omitFieldNames ? '' : 'allTime', subBuilder: GraphsResponse_TrueRetentionStats_TrueRetention.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse_TrueRetentionStats clone() => GraphsResponse_TrueRetentionStats()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse_TrueRetentionStats copyWith(void Function(GraphsResponse_TrueRetentionStats) updates) => super.copyWith((message) => updates(message as GraphsResponse_TrueRetentionStats)) as GraphsResponse_TrueRetentionStats;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse_TrueRetentionStats create() => GraphsResponse_TrueRetentionStats._();
  GraphsResponse_TrueRetentionStats createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse_TrueRetentionStats> createRepeated() => $pb.PbList<GraphsResponse_TrueRetentionStats>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse_TrueRetentionStats getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse_TrueRetentionStats>(create);
  static GraphsResponse_TrueRetentionStats? _defaultInstance;

  @$pb.TagNumber(1)
  GraphsResponse_TrueRetentionStats_TrueRetention get today => $_getN(0);
  @$pb.TagNumber(1)
  set today(GraphsResponse_TrueRetentionStats_TrueRetention v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasToday() => $_has(0);
  @$pb.TagNumber(1)
  void clearToday() => clearField(1);
  @$pb.TagNumber(1)
  GraphsResponse_TrueRetentionStats_TrueRetention ensureToday() => $_ensure(0);

  @$pb.TagNumber(2)
  GraphsResponse_TrueRetentionStats_TrueRetention get yesterday => $_getN(1);
  @$pb.TagNumber(2)
  set yesterday(GraphsResponse_TrueRetentionStats_TrueRetention v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasYesterday() => $_has(1);
  @$pb.TagNumber(2)
  void clearYesterday() => clearField(2);
  @$pb.TagNumber(2)
  GraphsResponse_TrueRetentionStats_TrueRetention ensureYesterday() => $_ensure(1);

  @$pb.TagNumber(3)
  GraphsResponse_TrueRetentionStats_TrueRetention get week => $_getN(2);
  @$pb.TagNumber(3)
  set week(GraphsResponse_TrueRetentionStats_TrueRetention v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasWeek() => $_has(2);
  @$pb.TagNumber(3)
  void clearWeek() => clearField(3);
  @$pb.TagNumber(3)
  GraphsResponse_TrueRetentionStats_TrueRetention ensureWeek() => $_ensure(2);

  @$pb.TagNumber(4)
  GraphsResponse_TrueRetentionStats_TrueRetention get month => $_getN(3);
  @$pb.TagNumber(4)
  set month(GraphsResponse_TrueRetentionStats_TrueRetention v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasMonth() => $_has(3);
  @$pb.TagNumber(4)
  void clearMonth() => clearField(4);
  @$pb.TagNumber(4)
  GraphsResponse_TrueRetentionStats_TrueRetention ensureMonth() => $_ensure(3);

  @$pb.TagNumber(5)
  GraphsResponse_TrueRetentionStats_TrueRetention get year => $_getN(4);
  @$pb.TagNumber(5)
  set year(GraphsResponse_TrueRetentionStats_TrueRetention v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasYear() => $_has(4);
  @$pb.TagNumber(5)
  void clearYear() => clearField(5);
  @$pb.TagNumber(5)
  GraphsResponse_TrueRetentionStats_TrueRetention ensureYear() => $_ensure(4);

  @$pb.TagNumber(6)
  GraphsResponse_TrueRetentionStats_TrueRetention get allTime => $_getN(5);
  @$pb.TagNumber(6)
  set allTime(GraphsResponse_TrueRetentionStats_TrueRetention v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasAllTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearAllTime() => clearField(6);
  @$pb.TagNumber(6)
  GraphsResponse_TrueRetentionStats_TrueRetention ensureAllTime() => $_ensure(5);
}

class GraphsResponse extends $pb.GeneratedMessage {
  factory GraphsResponse({
    GraphsResponse_Buttons? buttons,
    GraphsResponse_CardCounts? cardCounts,
    GraphsResponse_Hours? hours,
    GraphsResponse_Today? today,
    GraphsResponse_Eases? eases,
    GraphsResponse_Intervals? intervals,
    GraphsResponse_FutureDue? futureDue,
    GraphsResponse_Added? added,
    GraphsResponse_ReviewCountsAndTimes? reviews,
    $core.int? rolloverHour,
    GraphsResponse_Eases? difficulty,
    GraphsResponse_Retrievability? retrievability,
    $core.bool? fsrs,
    GraphsResponse_Intervals? stability,
    GraphsResponse_TrueRetentionStats? trueRetention,
  }) {
    final $result = create();
    if (buttons != null) {
      $result.buttons = buttons;
    }
    if (cardCounts != null) {
      $result.cardCounts = cardCounts;
    }
    if (hours != null) {
      $result.hours = hours;
    }
    if (today != null) {
      $result.today = today;
    }
    if (eases != null) {
      $result.eases = eases;
    }
    if (intervals != null) {
      $result.intervals = intervals;
    }
    if (futureDue != null) {
      $result.futureDue = futureDue;
    }
    if (added != null) {
      $result.added = added;
    }
    if (reviews != null) {
      $result.reviews = reviews;
    }
    if (rolloverHour != null) {
      $result.rolloverHour = rolloverHour;
    }
    if (difficulty != null) {
      $result.difficulty = difficulty;
    }
    if (retrievability != null) {
      $result.retrievability = retrievability;
    }
    if (fsrs != null) {
      $result.fsrs = fsrs;
    }
    if (stability != null) {
      $result.stability = stability;
    }
    if (trueRetention != null) {
      $result.trueRetention = trueRetention;
    }
    return $result;
  }
  GraphsResponse._() : super();
  factory GraphsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aOM<GraphsResponse_Buttons>(1, _omitFieldNames ? '' : 'buttons', subBuilder: GraphsResponse_Buttons.create)
    ..aOM<GraphsResponse_CardCounts>(2, _omitFieldNames ? '' : 'cardCounts', subBuilder: GraphsResponse_CardCounts.create)
    ..aOM<GraphsResponse_Hours>(3, _omitFieldNames ? '' : 'hours', subBuilder: GraphsResponse_Hours.create)
    ..aOM<GraphsResponse_Today>(4, _omitFieldNames ? '' : 'today', subBuilder: GraphsResponse_Today.create)
    ..aOM<GraphsResponse_Eases>(5, _omitFieldNames ? '' : 'eases', subBuilder: GraphsResponse_Eases.create)
    ..aOM<GraphsResponse_Intervals>(6, _omitFieldNames ? '' : 'intervals', subBuilder: GraphsResponse_Intervals.create)
    ..aOM<GraphsResponse_FutureDue>(7, _omitFieldNames ? '' : 'futureDue', subBuilder: GraphsResponse_FutureDue.create)
    ..aOM<GraphsResponse_Added>(8, _omitFieldNames ? '' : 'added', subBuilder: GraphsResponse_Added.create)
    ..aOM<GraphsResponse_ReviewCountsAndTimes>(9, _omitFieldNames ? '' : 'reviews', subBuilder: GraphsResponse_ReviewCountsAndTimes.create)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'rolloverHour', $pb.PbFieldType.OU3)
    ..aOM<GraphsResponse_Eases>(11, _omitFieldNames ? '' : 'difficulty', subBuilder: GraphsResponse_Eases.create)
    ..aOM<GraphsResponse_Retrievability>(12, _omitFieldNames ? '' : 'retrievability', subBuilder: GraphsResponse_Retrievability.create)
    ..aOB(13, _omitFieldNames ? '' : 'fsrs')
    ..aOM<GraphsResponse_Intervals>(14, _omitFieldNames ? '' : 'stability', subBuilder: GraphsResponse_Intervals.create)
    ..aOM<GraphsResponse_TrueRetentionStats>(15, _omitFieldNames ? '' : 'trueRetention', subBuilder: GraphsResponse_TrueRetentionStats.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphsResponse clone() => GraphsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphsResponse copyWith(void Function(GraphsResponse) updates) => super.copyWith((message) => updates(message as GraphsResponse)) as GraphsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphsResponse create() => GraphsResponse._();
  GraphsResponse createEmptyInstance() => create();
  static $pb.PbList<GraphsResponse> createRepeated() => $pb.PbList<GraphsResponse>();
  @$core.pragma('dart2js:noInline')
  static GraphsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphsResponse>(create);
  static GraphsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GraphsResponse_Buttons get buttons => $_getN(0);
  @$pb.TagNumber(1)
  set buttons(GraphsResponse_Buttons v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasButtons() => $_has(0);
  @$pb.TagNumber(1)
  void clearButtons() => clearField(1);
  @$pb.TagNumber(1)
  GraphsResponse_Buttons ensureButtons() => $_ensure(0);

  @$pb.TagNumber(2)
  GraphsResponse_CardCounts get cardCounts => $_getN(1);
  @$pb.TagNumber(2)
  set cardCounts(GraphsResponse_CardCounts v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardCounts() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardCounts() => clearField(2);
  @$pb.TagNumber(2)
  GraphsResponse_CardCounts ensureCardCounts() => $_ensure(1);

  @$pb.TagNumber(3)
  GraphsResponse_Hours get hours => $_getN(2);
  @$pb.TagNumber(3)
  set hours(GraphsResponse_Hours v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasHours() => $_has(2);
  @$pb.TagNumber(3)
  void clearHours() => clearField(3);
  @$pb.TagNumber(3)
  GraphsResponse_Hours ensureHours() => $_ensure(2);

  @$pb.TagNumber(4)
  GraphsResponse_Today get today => $_getN(3);
  @$pb.TagNumber(4)
  set today(GraphsResponse_Today v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasToday() => $_has(3);
  @$pb.TagNumber(4)
  void clearToday() => clearField(4);
  @$pb.TagNumber(4)
  GraphsResponse_Today ensureToday() => $_ensure(3);

  @$pb.TagNumber(5)
  GraphsResponse_Eases get eases => $_getN(4);
  @$pb.TagNumber(5)
  set eases(GraphsResponse_Eases v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasEases() => $_has(4);
  @$pb.TagNumber(5)
  void clearEases() => clearField(5);
  @$pb.TagNumber(5)
  GraphsResponse_Eases ensureEases() => $_ensure(4);

  @$pb.TagNumber(6)
  GraphsResponse_Intervals get intervals => $_getN(5);
  @$pb.TagNumber(6)
  set intervals(GraphsResponse_Intervals v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasIntervals() => $_has(5);
  @$pb.TagNumber(6)
  void clearIntervals() => clearField(6);
  @$pb.TagNumber(6)
  GraphsResponse_Intervals ensureIntervals() => $_ensure(5);

  @$pb.TagNumber(7)
  GraphsResponse_FutureDue get futureDue => $_getN(6);
  @$pb.TagNumber(7)
  set futureDue(GraphsResponse_FutureDue v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasFutureDue() => $_has(6);
  @$pb.TagNumber(7)
  void clearFutureDue() => clearField(7);
  @$pb.TagNumber(7)
  GraphsResponse_FutureDue ensureFutureDue() => $_ensure(6);

  @$pb.TagNumber(8)
  GraphsResponse_Added get added => $_getN(7);
  @$pb.TagNumber(8)
  set added(GraphsResponse_Added v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasAdded() => $_has(7);
  @$pb.TagNumber(8)
  void clearAdded() => clearField(8);
  @$pb.TagNumber(8)
  GraphsResponse_Added ensureAdded() => $_ensure(7);

  @$pb.TagNumber(9)
  GraphsResponse_ReviewCountsAndTimes get reviews => $_getN(8);
  @$pb.TagNumber(9)
  set reviews(GraphsResponse_ReviewCountsAndTimes v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasReviews() => $_has(8);
  @$pb.TagNumber(9)
  void clearReviews() => clearField(9);
  @$pb.TagNumber(9)
  GraphsResponse_ReviewCountsAndTimes ensureReviews() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.int get rolloverHour => $_getIZ(9);
  @$pb.TagNumber(10)
  set rolloverHour($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasRolloverHour() => $_has(9);
  @$pb.TagNumber(10)
  void clearRolloverHour() => clearField(10);

  @$pb.TagNumber(11)
  GraphsResponse_Eases get difficulty => $_getN(10);
  @$pb.TagNumber(11)
  set difficulty(GraphsResponse_Eases v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasDifficulty() => $_has(10);
  @$pb.TagNumber(11)
  void clearDifficulty() => clearField(11);
  @$pb.TagNumber(11)
  GraphsResponse_Eases ensureDifficulty() => $_ensure(10);

  @$pb.TagNumber(12)
  GraphsResponse_Retrievability get retrievability => $_getN(11);
  @$pb.TagNumber(12)
  set retrievability(GraphsResponse_Retrievability v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasRetrievability() => $_has(11);
  @$pb.TagNumber(12)
  void clearRetrievability() => clearField(12);
  @$pb.TagNumber(12)
  GraphsResponse_Retrievability ensureRetrievability() => $_ensure(11);

  @$pb.TagNumber(13)
  $core.bool get fsrs => $_getBF(12);
  @$pb.TagNumber(13)
  set fsrs($core.bool v) { $_setBool(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasFsrs() => $_has(12);
  @$pb.TagNumber(13)
  void clearFsrs() => clearField(13);

  @$pb.TagNumber(14)
  GraphsResponse_Intervals get stability => $_getN(13);
  @$pb.TagNumber(14)
  set stability(GraphsResponse_Intervals v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasStability() => $_has(13);
  @$pb.TagNumber(14)
  void clearStability() => clearField(14);
  @$pb.TagNumber(14)
  GraphsResponse_Intervals ensureStability() => $_ensure(13);

  @$pb.TagNumber(15)
  GraphsResponse_TrueRetentionStats get trueRetention => $_getN(14);
  @$pb.TagNumber(15)
  set trueRetention(GraphsResponse_TrueRetentionStats v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasTrueRetention() => $_has(14);
  @$pb.TagNumber(15)
  void clearTrueRetention() => clearField(15);
  @$pb.TagNumber(15)
  GraphsResponse_TrueRetentionStats ensureTrueRetention() => $_ensure(14);
}

class GraphPreferences extends $pb.GeneratedMessage {
  factory GraphPreferences({
    GraphPreferences_Weekday? calendarFirstDayOfWeek,
    $core.bool? cardCountsSeparateInactive,
    $core.bool? browserLinksSupported,
    $core.bool? futureDueShowBacklog,
  }) {
    final $result = create();
    if (calendarFirstDayOfWeek != null) {
      $result.calendarFirstDayOfWeek = calendarFirstDayOfWeek;
    }
    if (cardCountsSeparateInactive != null) {
      $result.cardCountsSeparateInactive = cardCountsSeparateInactive;
    }
    if (browserLinksSupported != null) {
      $result.browserLinksSupported = browserLinksSupported;
    }
    if (futureDueShowBacklog != null) {
      $result.futureDueShowBacklog = futureDueShowBacklog;
    }
    return $result;
  }
  GraphPreferences._() : super();
  factory GraphPreferences.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphPreferences.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphPreferences', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..e<GraphPreferences_Weekday>(1, _omitFieldNames ? '' : 'calendarFirstDayOfWeek', $pb.PbFieldType.OE, defaultOrMaker: GraphPreferences_Weekday.SUNDAY, valueOf: GraphPreferences_Weekday.valueOf, enumValues: GraphPreferences_Weekday.values)
    ..aOB(2, _omitFieldNames ? '' : 'cardCountsSeparateInactive')
    ..aOB(3, _omitFieldNames ? '' : 'browserLinksSupported')
    ..aOB(4, _omitFieldNames ? '' : 'futureDueShowBacklog')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphPreferences clone() => GraphPreferences()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphPreferences copyWith(void Function(GraphPreferences) updates) => super.copyWith((message) => updates(message as GraphPreferences)) as GraphPreferences;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphPreferences create() => GraphPreferences._();
  GraphPreferences createEmptyInstance() => create();
  static $pb.PbList<GraphPreferences> createRepeated() => $pb.PbList<GraphPreferences>();
  @$core.pragma('dart2js:noInline')
  static GraphPreferences getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphPreferences>(create);
  static GraphPreferences? _defaultInstance;

  @$pb.TagNumber(1)
  GraphPreferences_Weekday get calendarFirstDayOfWeek => $_getN(0);
  @$pb.TagNumber(1)
  set calendarFirstDayOfWeek(GraphPreferences_Weekday v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCalendarFirstDayOfWeek() => $_has(0);
  @$pb.TagNumber(1)
  void clearCalendarFirstDayOfWeek() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get cardCountsSeparateInactive => $_getBF(1);
  @$pb.TagNumber(2)
  set cardCountsSeparateInactive($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardCountsSeparateInactive() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardCountsSeparateInactive() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get browserLinksSupported => $_getBF(2);
  @$pb.TagNumber(3)
  set browserLinksSupported($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBrowserLinksSupported() => $_has(2);
  @$pb.TagNumber(3)
  void clearBrowserLinksSupported() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get futureDueShowBacklog => $_getBF(3);
  @$pb.TagNumber(4)
  set futureDueShowBacklog($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFutureDueShowBacklog() => $_has(3);
  @$pb.TagNumber(4)
  void clearFutureDueShowBacklog() => clearField(4);
}

class RevlogEntry extends $pb.GeneratedMessage {
  factory RevlogEntry({
    $fixnum.Int64? id,
    $fixnum.Int64? cid,
    $core.int? usn,
    $core.int? buttonChosen,
    $core.int? interval,
    $core.int? lastInterval,
    $core.int? easeFactor,
    $core.int? takenMillis,
    RevlogEntry_ReviewKind? reviewKind,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (cid != null) {
      $result.cid = cid;
    }
    if (usn != null) {
      $result.usn = usn;
    }
    if (buttonChosen != null) {
      $result.buttonChosen = buttonChosen;
    }
    if (interval != null) {
      $result.interval = interval;
    }
    if (lastInterval != null) {
      $result.lastInterval = lastInterval;
    }
    if (easeFactor != null) {
      $result.easeFactor = easeFactor;
    }
    if (takenMillis != null) {
      $result.takenMillis = takenMillis;
    }
    if (reviewKind != null) {
      $result.reviewKind = reviewKind;
    }
    return $result;
  }
  RevlogEntry._() : super();
  factory RevlogEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RevlogEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RevlogEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'cid')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'usn', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'buttonChosen', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'interval', $pb.PbFieldType.O3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'lastInterval', $pb.PbFieldType.O3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'easeFactor', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'takenMillis', $pb.PbFieldType.OU3)
    ..e<RevlogEntry_ReviewKind>(9, _omitFieldNames ? '' : 'reviewKind', $pb.PbFieldType.OE, defaultOrMaker: RevlogEntry_ReviewKind.LEARNING, valueOf: RevlogEntry_ReviewKind.valueOf, enumValues: RevlogEntry_ReviewKind.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RevlogEntry clone() => RevlogEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RevlogEntry copyWith(void Function(RevlogEntry) updates) => super.copyWith((message) => updates(message as RevlogEntry)) as RevlogEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevlogEntry create() => RevlogEntry._();
  RevlogEntry createEmptyInstance() => create();
  static $pb.PbList<RevlogEntry> createRepeated() => $pb.PbList<RevlogEntry>();
  @$core.pragma('dart2js:noInline')
  static RevlogEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevlogEntry>(create);
  static RevlogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get cid => $_getI64(1);
  @$pb.TagNumber(2)
  set cid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCid() => $_has(1);
  @$pb.TagNumber(2)
  void clearCid() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get usn => $_getIZ(2);
  @$pb.TagNumber(3)
  set usn($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUsn() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsn() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get buttonChosen => $_getIZ(3);
  @$pb.TagNumber(4)
  set buttonChosen($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasButtonChosen() => $_has(3);
  @$pb.TagNumber(4)
  void clearButtonChosen() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get interval => $_getIZ(4);
  @$pb.TagNumber(5)
  set interval($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasInterval() => $_has(4);
  @$pb.TagNumber(5)
  void clearInterval() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get lastInterval => $_getIZ(5);
  @$pb.TagNumber(6)
  set lastInterval($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLastInterval() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastInterval() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get easeFactor => $_getIZ(6);
  @$pb.TagNumber(7)
  set easeFactor($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasEaseFactor() => $_has(6);
  @$pb.TagNumber(7)
  void clearEaseFactor() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get takenMillis => $_getIZ(7);
  @$pb.TagNumber(8)
  set takenMillis($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTakenMillis() => $_has(7);
  @$pb.TagNumber(8)
  void clearTakenMillis() => clearField(8);

  @$pb.TagNumber(9)
  RevlogEntry_ReviewKind get reviewKind => $_getN(8);
  @$pb.TagNumber(9)
  set reviewKind(RevlogEntry_ReviewKind v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasReviewKind() => $_has(8);
  @$pb.TagNumber(9)
  void clearReviewKind() => clearField(9);
}

class CardEntry extends $pb.GeneratedMessage {
  factory CardEntry({
    $fixnum.Int64? id,
    $fixnum.Int64? noteId,
    $fixnum.Int64? deckId,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (noteId != null) {
      $result.noteId = noteId;
    }
    if (deckId != null) {
      $result.deckId = deckId;
    }
    return $result;
  }
  CardEntry._() : super();
  factory CardEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CardEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CardEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'noteId')
    ..aInt64(3, _omitFieldNames ? '' : 'deckId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CardEntry clone() => CardEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CardEntry copyWith(void Function(CardEntry) updates) => super.copyWith((message) => updates(message as CardEntry)) as CardEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardEntry create() => CardEntry._();
  CardEntry createEmptyInstance() => create();
  static $pb.PbList<CardEntry> createRepeated() => $pb.PbList<CardEntry>();
  @$core.pragma('dart2js:noInline')
  static CardEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardEntry>(create);
  static CardEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get noteId => $_getI64(1);
  @$pb.TagNumber(2)
  set noteId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNoteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNoteId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get deckId => $_getI64(2);
  @$pb.TagNumber(3)
  set deckId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDeckId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeckId() => clearField(3);
}

class DeckEntry extends $pb.GeneratedMessage {
  factory DeckEntry({
    $fixnum.Int64? id,
    $fixnum.Int64? parentId,
    $fixnum.Int64? presetId,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (parentId != null) {
      $result.parentId = parentId;
    }
    if (presetId != null) {
      $result.presetId = presetId;
    }
    return $result;
  }
  DeckEntry._() : super();
  factory DeckEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'parentId')
    ..aInt64(3, _omitFieldNames ? '' : 'presetId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckEntry clone() => DeckEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckEntry copyWith(void Function(DeckEntry) updates) => super.copyWith((message) => updates(message as DeckEntry)) as DeckEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckEntry create() => DeckEntry._();
  DeckEntry createEmptyInstance() => create();
  static $pb.PbList<DeckEntry> createRepeated() => $pb.PbList<DeckEntry>();
  @$core.pragma('dart2js:noInline')
  static DeckEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckEntry>(create);
  static DeckEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get parentId => $_getI64(1);
  @$pb.TagNumber(2)
  set parentId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasParentId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get presetId => $_getI64(2);
  @$pb.TagNumber(3)
  set presetId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPresetId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPresetId() => clearField(3);
}

class Dataset extends $pb.GeneratedMessage {
  factory Dataset({
    $core.Iterable<RevlogEntry>? revlogs,
    $core.Iterable<CardEntry>? cards,
    $core.Iterable<DeckEntry>? decks,
    $fixnum.Int64? nextDayAt,
  }) {
    final $result = create();
    if (revlogs != null) {
      $result.revlogs.addAll(revlogs);
    }
    if (cards != null) {
      $result.cards.addAll(cards);
    }
    if (decks != null) {
      $result.decks.addAll(decks);
    }
    if (nextDayAt != null) {
      $result.nextDayAt = nextDayAt;
    }
    return $result;
  }
  Dataset._() : super();
  factory Dataset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Dataset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Dataset', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.stats'), createEmptyInstance: create)
    ..pc<RevlogEntry>(1, _omitFieldNames ? '' : 'revlogs', $pb.PbFieldType.PM, subBuilder: RevlogEntry.create)
    ..pc<CardEntry>(2, _omitFieldNames ? '' : 'cards', $pb.PbFieldType.PM, subBuilder: CardEntry.create)
    ..pc<DeckEntry>(3, _omitFieldNames ? '' : 'decks', $pb.PbFieldType.PM, subBuilder: DeckEntry.create)
    ..aInt64(4, _omitFieldNames ? '' : 'nextDayAt')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Dataset clone() => Dataset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Dataset copyWith(void Function(Dataset) updates) => super.copyWith((message) => updates(message as Dataset)) as Dataset;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Dataset create() => Dataset._();
  Dataset createEmptyInstance() => create();
  static $pb.PbList<Dataset> createRepeated() => $pb.PbList<Dataset>();
  @$core.pragma('dart2js:noInline')
  static Dataset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Dataset>(create);
  static Dataset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<RevlogEntry> get revlogs => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<CardEntry> get cards => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<DeckEntry> get decks => $_getList(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get nextDayAt => $_getI64(3);
  @$pb.TagNumber(4)
  set nextDayAt($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNextDayAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextDayAt() => clearField(4);
}

class StatsServiceApi {
  $pb.RpcClient _client;
  StatsServiceApi(this._client);

  $async.Future<CardStatsResponse> cardStats($pb.ClientContext? ctx, $3.CardId request) =>
    _client.invoke<CardStatsResponse>(ctx, 'StatsService', 'CardStats', request, CardStatsResponse())
  ;
  $async.Future<ReviewLogs> getReviewLogs($pb.ClientContext? ctx, $3.CardId request) =>
    _client.invoke<ReviewLogs>(ctx, 'StatsService', 'GetReviewLogs', request, ReviewLogs())
  ;
  $async.Future<GraphsResponse> graphs($pb.ClientContext? ctx, GraphsRequest request) =>
    _client.invoke<GraphsResponse>(ctx, 'StatsService', 'Graphs', request, GraphsResponse())
  ;
  $async.Future<GraphPreferences> getGraphPreferences($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<GraphPreferences>(ctx, 'StatsService', 'GetGraphPreferences', request, GraphPreferences())
  ;
  $async.Future<$0.Empty> setGraphPreferences($pb.ClientContext? ctx, GraphPreferences request) =>
    _client.invoke<$0.Empty>(ctx, 'StatsService', 'SetGraphPreferences', request, $0.Empty())
  ;
}

class BackendStatsServiceApi {
  $pb.RpcClient _client;
  BackendStatsServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
