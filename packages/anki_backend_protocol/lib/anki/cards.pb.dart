//
//  Generated code. Do not modify.
//  source: anki/cards.proto
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

import 'collection.pb.dart' as $2;

class CardId extends $pb.GeneratedMessage {
  factory CardId({
    $fixnum.Int64? cid,
  }) {
    final $result = create();
    if (cid != null) {
      $result.cid = cid;
    }
    return $result;
  }
  CardId._() : super();
  factory CardId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CardId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CardId', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'cid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CardId clone() => CardId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CardId copyWith(void Function(CardId) updates) => super.copyWith((message) => updates(message as CardId)) as CardId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardId create() => CardId._();
  CardId createEmptyInstance() => create();
  static $pb.PbList<CardId> createRepeated() => $pb.PbList<CardId>();
  @$core.pragma('dart2js:noInline')
  static CardId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardId>(create);
  static CardId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get cid => $_getI64(0);
  @$pb.TagNumber(1)
  set cid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCid() => $_has(0);
  @$pb.TagNumber(1)
  void clearCid() => clearField(1);
}

class CardIds extends $pb.GeneratedMessage {
  factory CardIds({
    $core.Iterable<$fixnum.Int64>? cids,
  }) {
    final $result = create();
    if (cids != null) {
      $result.cids.addAll(cids);
    }
    return $result;
  }
  CardIds._() : super();
  factory CardIds.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CardIds.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CardIds', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'cids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CardIds clone() => CardIds()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CardIds copyWith(void Function(CardIds) updates) => super.copyWith((message) => updates(message as CardIds)) as CardIds;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardIds create() => CardIds._();
  CardIds createEmptyInstance() => create();
  static $pb.PbList<CardIds> createRepeated() => $pb.PbList<CardIds>();
  @$core.pragma('dart2js:noInline')
  static CardIds getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CardIds>(create);
  static CardIds? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get cids => $_getList(0);
}

class Card extends $pb.GeneratedMessage {
  factory Card({
    $fixnum.Int64? id,
    $fixnum.Int64? noteId,
    $fixnum.Int64? deckId,
    $core.int? templateIdx,
    $fixnum.Int64? mtimeSecs,
    $core.int? usn,
    $core.int? ctype,
    $core.int? queue,
    $core.int? due,
    $core.int? interval,
    $core.int? easeFactor,
    $core.int? reps,
    $core.int? lapses,
    $core.int? remainingSteps,
    $core.int? originalDue,
    $fixnum.Int64? originalDeckId,
    $core.int? flags,
    $core.int? originalPosition,
    $core.String? customData,
    FsrsMemoryState? memoryState,
    $core.double? desiredRetention,
    $core.double? decay,
    $fixnum.Int64? lastReviewTimeSecs,
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
    if (templateIdx != null) {
      $result.templateIdx = templateIdx;
    }
    if (mtimeSecs != null) {
      $result.mtimeSecs = mtimeSecs;
    }
    if (usn != null) {
      $result.usn = usn;
    }
    if (ctype != null) {
      $result.ctype = ctype;
    }
    if (queue != null) {
      $result.queue = queue;
    }
    if (due != null) {
      $result.due = due;
    }
    if (interval != null) {
      $result.interval = interval;
    }
    if (easeFactor != null) {
      $result.easeFactor = easeFactor;
    }
    if (reps != null) {
      $result.reps = reps;
    }
    if (lapses != null) {
      $result.lapses = lapses;
    }
    if (remainingSteps != null) {
      $result.remainingSteps = remainingSteps;
    }
    if (originalDue != null) {
      $result.originalDue = originalDue;
    }
    if (originalDeckId != null) {
      $result.originalDeckId = originalDeckId;
    }
    if (flags != null) {
      $result.flags = flags;
    }
    if (originalPosition != null) {
      $result.originalPosition = originalPosition;
    }
    if (customData != null) {
      $result.customData = customData;
    }
    if (memoryState != null) {
      $result.memoryState = memoryState;
    }
    if (desiredRetention != null) {
      $result.desiredRetention = desiredRetention;
    }
    if (decay != null) {
      $result.decay = decay;
    }
    if (lastReviewTimeSecs != null) {
      $result.lastReviewTimeSecs = lastReviewTimeSecs;
    }
    return $result;
  }
  Card._() : super();
  factory Card.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Card.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Card', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'noteId')
    ..aInt64(3, _omitFieldNames ? '' : 'deckId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'templateIdx', $pb.PbFieldType.OU3)
    ..aInt64(5, _omitFieldNames ? '' : 'mtimeSecs')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'usn', $pb.PbFieldType.OS3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'ctype', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'queue', $pb.PbFieldType.OS3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'due', $pb.PbFieldType.OS3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'interval', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'easeFactor', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'reps', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'lapses', $pb.PbFieldType.OU3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'remainingSteps', $pb.PbFieldType.OU3)
    ..a<$core.int>(15, _omitFieldNames ? '' : 'originalDue', $pb.PbFieldType.OS3)
    ..aInt64(16, _omitFieldNames ? '' : 'originalDeckId')
    ..a<$core.int>(17, _omitFieldNames ? '' : 'flags', $pb.PbFieldType.OU3)
    ..a<$core.int>(18, _omitFieldNames ? '' : 'originalPosition', $pb.PbFieldType.OU3)
    ..aOS(19, _omitFieldNames ? '' : 'customData')
    ..aOM<FsrsMemoryState>(20, _omitFieldNames ? '' : 'memoryState', subBuilder: FsrsMemoryState.create)
    ..a<$core.double>(21, _omitFieldNames ? '' : 'desiredRetention', $pb.PbFieldType.OF)
    ..a<$core.double>(22, _omitFieldNames ? '' : 'decay', $pb.PbFieldType.OF)
    ..aInt64(23, _omitFieldNames ? '' : 'lastReviewTimeSecs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Card clone() => Card()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Card copyWith(void Function(Card) updates) => super.copyWith((message) => updates(message as Card)) as Card;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Card create() => Card._();
  Card createEmptyInstance() => create();
  static $pb.PbList<Card> createRepeated() => $pb.PbList<Card>();
  @$core.pragma('dart2js:noInline')
  static Card getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Card>(create);
  static Card? _defaultInstance;

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

  @$pb.TagNumber(4)
  $core.int get templateIdx => $_getIZ(3);
  @$pb.TagNumber(4)
  set templateIdx($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTemplateIdx() => $_has(3);
  @$pb.TagNumber(4)
  void clearTemplateIdx() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get mtimeSecs => $_getI64(4);
  @$pb.TagNumber(5)
  set mtimeSecs($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMtimeSecs() => $_has(4);
  @$pb.TagNumber(5)
  void clearMtimeSecs() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get usn => $_getIZ(5);
  @$pb.TagNumber(6)
  set usn($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasUsn() => $_has(5);
  @$pb.TagNumber(6)
  void clearUsn() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get ctype => $_getIZ(6);
  @$pb.TagNumber(7)
  set ctype($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasCtype() => $_has(6);
  @$pb.TagNumber(7)
  void clearCtype() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get queue => $_getIZ(7);
  @$pb.TagNumber(8)
  set queue($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasQueue() => $_has(7);
  @$pb.TagNumber(8)
  void clearQueue() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get due => $_getIZ(8);
  @$pb.TagNumber(9)
  set due($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDue() => $_has(8);
  @$pb.TagNumber(9)
  void clearDue() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get interval => $_getIZ(9);
  @$pb.TagNumber(10)
  set interval($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasInterval() => $_has(9);
  @$pb.TagNumber(10)
  void clearInterval() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get easeFactor => $_getIZ(10);
  @$pb.TagNumber(11)
  set easeFactor($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasEaseFactor() => $_has(10);
  @$pb.TagNumber(11)
  void clearEaseFactor() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get reps => $_getIZ(11);
  @$pb.TagNumber(12)
  set reps($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasReps() => $_has(11);
  @$pb.TagNumber(12)
  void clearReps() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get lapses => $_getIZ(12);
  @$pb.TagNumber(13)
  set lapses($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasLapses() => $_has(12);
  @$pb.TagNumber(13)
  void clearLapses() => clearField(13);

  @$pb.TagNumber(14)
  $core.int get remainingSteps => $_getIZ(13);
  @$pb.TagNumber(14)
  set remainingSteps($core.int v) { $_setUnsignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasRemainingSteps() => $_has(13);
  @$pb.TagNumber(14)
  void clearRemainingSteps() => clearField(14);

  @$pb.TagNumber(15)
  $core.int get originalDue => $_getIZ(14);
  @$pb.TagNumber(15)
  set originalDue($core.int v) { $_setSignedInt32(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasOriginalDue() => $_has(14);
  @$pb.TagNumber(15)
  void clearOriginalDue() => clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get originalDeckId => $_getI64(15);
  @$pb.TagNumber(16)
  set originalDeckId($fixnum.Int64 v) { $_setInt64(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasOriginalDeckId() => $_has(15);
  @$pb.TagNumber(16)
  void clearOriginalDeckId() => clearField(16);

  @$pb.TagNumber(17)
  $core.int get flags => $_getIZ(16);
  @$pb.TagNumber(17)
  set flags($core.int v) { $_setUnsignedInt32(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasFlags() => $_has(16);
  @$pb.TagNumber(17)
  void clearFlags() => clearField(17);

  @$pb.TagNumber(18)
  $core.int get originalPosition => $_getIZ(17);
  @$pb.TagNumber(18)
  set originalPosition($core.int v) { $_setUnsignedInt32(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasOriginalPosition() => $_has(17);
  @$pb.TagNumber(18)
  void clearOriginalPosition() => clearField(18);

  @$pb.TagNumber(19)
  $core.String get customData => $_getSZ(18);
  @$pb.TagNumber(19)
  set customData($core.String v) { $_setString(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasCustomData() => $_has(18);
  @$pb.TagNumber(19)
  void clearCustomData() => clearField(19);

  @$pb.TagNumber(20)
  FsrsMemoryState get memoryState => $_getN(19);
  @$pb.TagNumber(20)
  set memoryState(FsrsMemoryState v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasMemoryState() => $_has(19);
  @$pb.TagNumber(20)
  void clearMemoryState() => clearField(20);
  @$pb.TagNumber(20)
  FsrsMemoryState ensureMemoryState() => $_ensure(19);

  @$pb.TagNumber(21)
  $core.double get desiredRetention => $_getN(20);
  @$pb.TagNumber(21)
  set desiredRetention($core.double v) { $_setFloat(20, v); }
  @$pb.TagNumber(21)
  $core.bool hasDesiredRetention() => $_has(20);
  @$pb.TagNumber(21)
  void clearDesiredRetention() => clearField(21);

  @$pb.TagNumber(22)
  $core.double get decay => $_getN(21);
  @$pb.TagNumber(22)
  set decay($core.double v) { $_setFloat(21, v); }
  @$pb.TagNumber(22)
  $core.bool hasDecay() => $_has(21);
  @$pb.TagNumber(22)
  void clearDecay() => clearField(22);

  @$pb.TagNumber(23)
  $fixnum.Int64 get lastReviewTimeSecs => $_getI64(22);
  @$pb.TagNumber(23)
  set lastReviewTimeSecs($fixnum.Int64 v) { $_setInt64(22, v); }
  @$pb.TagNumber(23)
  $core.bool hasLastReviewTimeSecs() => $_has(22);
  @$pb.TagNumber(23)
  void clearLastReviewTimeSecs() => clearField(23);
}

class FsrsMemoryState extends $pb.GeneratedMessage {
  factory FsrsMemoryState({
    $core.double? stability,
    $core.double? difficulty,
  }) {
    final $result = create();
    if (stability != null) {
      $result.stability = stability;
    }
    if (difficulty != null) {
      $result.difficulty = difficulty;
    }
    return $result;
  }
  FsrsMemoryState._() : super();
  factory FsrsMemoryState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FsrsMemoryState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FsrsMemoryState', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'stability', $pb.PbFieldType.OF)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'difficulty', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FsrsMemoryState clone() => FsrsMemoryState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FsrsMemoryState copyWith(void Function(FsrsMemoryState) updates) => super.copyWith((message) => updates(message as FsrsMemoryState)) as FsrsMemoryState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FsrsMemoryState create() => FsrsMemoryState._();
  FsrsMemoryState createEmptyInstance() => create();
  static $pb.PbList<FsrsMemoryState> createRepeated() => $pb.PbList<FsrsMemoryState>();
  @$core.pragma('dart2js:noInline')
  static FsrsMemoryState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FsrsMemoryState>(create);
  static FsrsMemoryState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get stability => $_getN(0);
  @$pb.TagNumber(1)
  set stability($core.double v) { $_setFloat(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStability() => $_has(0);
  @$pb.TagNumber(1)
  void clearStability() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get difficulty => $_getN(1);
  @$pb.TagNumber(2)
  set difficulty($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDifficulty() => $_has(1);
  @$pb.TagNumber(2)
  void clearDifficulty() => clearField(2);
}

class UpdateCardsRequest extends $pb.GeneratedMessage {
  factory UpdateCardsRequest({
    $core.Iterable<Card>? cards,
    $core.bool? skipUndoEntry,
  }) {
    final $result = create();
    if (cards != null) {
      $result.cards.addAll(cards);
    }
    if (skipUndoEntry != null) {
      $result.skipUndoEntry = skipUndoEntry;
    }
    return $result;
  }
  UpdateCardsRequest._() : super();
  factory UpdateCardsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateCardsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateCardsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..pc<Card>(1, _omitFieldNames ? '' : 'cards', $pb.PbFieldType.PM, subBuilder: Card.create)
    ..aOB(2, _omitFieldNames ? '' : 'skipUndoEntry')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateCardsRequest clone() => UpdateCardsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateCardsRequest copyWith(void Function(UpdateCardsRequest) updates) => super.copyWith((message) => updates(message as UpdateCardsRequest)) as UpdateCardsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateCardsRequest create() => UpdateCardsRequest._();
  UpdateCardsRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateCardsRequest> createRepeated() => $pb.PbList<UpdateCardsRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateCardsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateCardsRequest>(create);
  static UpdateCardsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Card> get cards => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get skipUndoEntry => $_getBF(1);
  @$pb.TagNumber(2)
  set skipUndoEntry($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSkipUndoEntry() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipUndoEntry() => clearField(2);
}

class RemoveCardsRequest extends $pb.GeneratedMessage {
  factory RemoveCardsRequest({
    $core.Iterable<$fixnum.Int64>? cardIds,
  }) {
    final $result = create();
    if (cardIds != null) {
      $result.cardIds.addAll(cardIds);
    }
    return $result;
  }
  RemoveCardsRequest._() : super();
  factory RemoveCardsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RemoveCardsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RemoveCardsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'cardIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RemoveCardsRequest clone() => RemoveCardsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RemoveCardsRequest copyWith(void Function(RemoveCardsRequest) updates) => super.copyWith((message) => updates(message as RemoveCardsRequest)) as RemoveCardsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveCardsRequest create() => RemoveCardsRequest._();
  RemoveCardsRequest createEmptyInstance() => create();
  static $pb.PbList<RemoveCardsRequest> createRepeated() => $pb.PbList<RemoveCardsRequest>();
  @$core.pragma('dart2js:noInline')
  static RemoveCardsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoveCardsRequest>(create);
  static RemoveCardsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get cardIds => $_getList(0);
}

class SetDeckRequest extends $pb.GeneratedMessage {
  factory SetDeckRequest({
    $core.Iterable<$fixnum.Int64>? cardIds,
    $fixnum.Int64? deckId,
  }) {
    final $result = create();
    if (cardIds != null) {
      $result.cardIds.addAll(cardIds);
    }
    if (deckId != null) {
      $result.deckId = deckId;
    }
    return $result;
  }
  SetDeckRequest._() : super();
  factory SetDeckRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetDeckRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetDeckRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'cardIds', $pb.PbFieldType.K6)
    ..aInt64(2, _omitFieldNames ? '' : 'deckId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetDeckRequest clone() => SetDeckRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetDeckRequest copyWith(void Function(SetDeckRequest) updates) => super.copyWith((message) => updates(message as SetDeckRequest)) as SetDeckRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDeckRequest create() => SetDeckRequest._();
  SetDeckRequest createEmptyInstance() => create();
  static $pb.PbList<SetDeckRequest> createRepeated() => $pb.PbList<SetDeckRequest>();
  @$core.pragma('dart2js:noInline')
  static SetDeckRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetDeckRequest>(create);
  static SetDeckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get cardIds => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deckId => $_getI64(1);
  @$pb.TagNumber(2)
  set deckId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeckId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeckId() => clearField(2);
}

class SetFlagRequest extends $pb.GeneratedMessage {
  factory SetFlagRequest({
    $core.Iterable<$fixnum.Int64>? cardIds,
    $core.int? flag,
  }) {
    final $result = create();
    if (cardIds != null) {
      $result.cardIds.addAll(cardIds);
    }
    if (flag != null) {
      $result.flag = flag;
    }
    return $result;
  }
  SetFlagRequest._() : super();
  factory SetFlagRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetFlagRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetFlagRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.cards'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'cardIds', $pb.PbFieldType.K6)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'flag', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetFlagRequest clone() => SetFlagRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetFlagRequest copyWith(void Function(SetFlagRequest) updates) => super.copyWith((message) => updates(message as SetFlagRequest)) as SetFlagRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetFlagRequest create() => SetFlagRequest._();
  SetFlagRequest createEmptyInstance() => create();
  static $pb.PbList<SetFlagRequest> createRepeated() => $pb.PbList<SetFlagRequest>();
  @$core.pragma('dart2js:noInline')
  static SetFlagRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetFlagRequest>(create);
  static SetFlagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get cardIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get flag => $_getIZ(1);
  @$pb.TagNumber(2)
  set flag($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFlag() => $_has(1);
  @$pb.TagNumber(2)
  void clearFlag() => clearField(2);
}

class CardsServiceApi {
  $pb.RpcClient _client;
  CardsServiceApi(this._client);

  $async.Future<Card> getCard($pb.ClientContext? ctx, CardId request) =>
    _client.invoke<Card>(ctx, 'CardsService', 'GetCard', request, Card())
  ;
  $async.Future<$2.OpChanges> updateCards($pb.ClientContext? ctx, UpdateCardsRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'CardsService', 'UpdateCards', request, $2.OpChanges())
  ;
  $async.Future<$2.OpChangesWithCount> removeCards($pb.ClientContext? ctx, RemoveCardsRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'CardsService', 'RemoveCards', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> setDeck($pb.ClientContext? ctx, SetDeckRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'CardsService', 'SetDeck', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> setFlag($pb.ClientContext? ctx, SetFlagRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'CardsService', 'SetFlag', request, $2.OpChangesWithCount())
  ;
}

class BackendCardsServiceApi {
  $pb.RpcClient _client;
  BackendCardsServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
