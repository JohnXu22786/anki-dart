//
//  Generated code. Do not modify.
//  source: anki/decks.proto
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
import 'decks.pbenum.dart';
import 'generic.pb.dart' as $0;

export 'decks.pbenum.dart';

class DeckId extends $pb.GeneratedMessage {
  factory DeckId({
    $fixnum.Int64? did,
  }) {
    final $result = create();
    if (did != null) {
      $result.did = did;
    }
    return $result;
  }
  DeckId._() : super();
  factory DeckId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckId', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'did')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckId clone() => DeckId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckId copyWith(void Function(DeckId) updates) => super.copyWith((message) => updates(message as DeckId)) as DeckId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckId create() => DeckId._();
  DeckId createEmptyInstance() => create();
  static $pb.PbList<DeckId> createRepeated() => $pb.PbList<DeckId>();
  @$core.pragma('dart2js:noInline')
  static DeckId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckId>(create);
  static DeckId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get did => $_getI64(0);
  @$pb.TagNumber(1)
  set did($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDid() => clearField(1);
}

class DeckIds extends $pb.GeneratedMessage {
  factory DeckIds({
    $core.Iterable<$fixnum.Int64>? dids,
  }) {
    final $result = create();
    if (dids != null) {
      $result.dids.addAll(dids);
    }
    return $result;
  }
  DeckIds._() : super();
  factory DeckIds.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckIds.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckIds', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'dids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckIds clone() => DeckIds()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckIds copyWith(void Function(DeckIds) updates) => super.copyWith((message) => updates(message as DeckIds)) as DeckIds;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckIds create() => DeckIds._();
  DeckIds createEmptyInstance() => create();
  static $pb.PbList<DeckIds> createRepeated() => $pb.PbList<DeckIds>();
  @$core.pragma('dart2js:noInline')
  static DeckIds getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckIds>(create);
  static DeckIds? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get dids => $_getList(0);
}

class Deck_Common extends $pb.GeneratedMessage {
  factory Deck_Common({
    $core.bool? studyCollapsed,
    $core.bool? browserCollapsed,
    $core.int? lastDayStudied,
    $core.int? newStudied,
    $core.int? reviewStudied,
    $core.int? learningStudied,
    $core.int? millisecondsStudied,
    $core.List<$core.int>? other,
  }) {
    final $result = create();
    if (studyCollapsed != null) {
      $result.studyCollapsed = studyCollapsed;
    }
    if (browserCollapsed != null) {
      $result.browserCollapsed = browserCollapsed;
    }
    if (lastDayStudied != null) {
      $result.lastDayStudied = lastDayStudied;
    }
    if (newStudied != null) {
      $result.newStudied = newStudied;
    }
    if (reviewStudied != null) {
      $result.reviewStudied = reviewStudied;
    }
    if (learningStudied != null) {
      $result.learningStudied = learningStudied;
    }
    if (millisecondsStudied != null) {
      $result.millisecondsStudied = millisecondsStudied;
    }
    if (other != null) {
      $result.other = other;
    }
    return $result;
  }
  Deck_Common._() : super();
  factory Deck_Common.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck_Common.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck.Common', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'studyCollapsed')
    ..aOB(2, _omitFieldNames ? '' : 'browserCollapsed')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'lastDayStudied', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'newStudied', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'reviewStudied', $pb.PbFieldType.O3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'learningStudied', $pb.PbFieldType.O3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'millisecondsStudied', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(255, _omitFieldNames ? '' : 'other', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck_Common clone() => Deck_Common()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck_Common copyWith(void Function(Deck_Common) updates) => super.copyWith((message) => updates(message as Deck_Common)) as Deck_Common;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck_Common create() => Deck_Common._();
  Deck_Common createEmptyInstance() => create();
  static $pb.PbList<Deck_Common> createRepeated() => $pb.PbList<Deck_Common>();
  @$core.pragma('dart2js:noInline')
  static Deck_Common getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck_Common>(create);
  static Deck_Common? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get studyCollapsed => $_getBF(0);
  @$pb.TagNumber(1)
  set studyCollapsed($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStudyCollapsed() => $_has(0);
  @$pb.TagNumber(1)
  void clearStudyCollapsed() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get browserCollapsed => $_getBF(1);
  @$pb.TagNumber(2)
  set browserCollapsed($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBrowserCollapsed() => $_has(1);
  @$pb.TagNumber(2)
  void clearBrowserCollapsed() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get lastDayStudied => $_getIZ(2);
  @$pb.TagNumber(3)
  set lastDayStudied($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLastDayStudied() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastDayStudied() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get newStudied => $_getIZ(3);
  @$pb.TagNumber(4)
  set newStudied($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNewStudied() => $_has(3);
  @$pb.TagNumber(4)
  void clearNewStudied() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get reviewStudied => $_getIZ(4);
  @$pb.TagNumber(5)
  set reviewStudied($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasReviewStudied() => $_has(4);
  @$pb.TagNumber(5)
  void clearReviewStudied() => clearField(5);

  /// previously set in the v1 scheduler,
  /// but not currently used for anything
  @$pb.TagNumber(6)
  $core.int get learningStudied => $_getIZ(5);
  @$pb.TagNumber(6)
  set learningStudied($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLearningStudied() => $_has(5);
  @$pb.TagNumber(6)
  void clearLearningStudied() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get millisecondsStudied => $_getIZ(6);
  @$pb.TagNumber(7)
  set millisecondsStudied($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMillisecondsStudied() => $_has(6);
  @$pb.TagNumber(7)
  void clearMillisecondsStudied() => clearField(7);

  @$pb.TagNumber(255)
  $core.List<$core.int> get other => $_getN(7);
  @$pb.TagNumber(255)
  set other($core.List<$core.int> v) { $_setBytes(7, v); }
  @$pb.TagNumber(255)
  $core.bool hasOther() => $_has(7);
  @$pb.TagNumber(255)
  void clearOther() => clearField(255);
}

class Deck_Normal_DayLimit extends $pb.GeneratedMessage {
  factory Deck_Normal_DayLimit({
    $core.int? limit,
    $core.int? today,
  }) {
    final $result = create();
    if (limit != null) {
      $result.limit = limit;
    }
    if (today != null) {
      $result.today = today;
    }
    return $result;
  }
  Deck_Normal_DayLimit._() : super();
  factory Deck_Normal_DayLimit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck_Normal_DayLimit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck.Normal.DayLimit', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'today', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck_Normal_DayLimit clone() => Deck_Normal_DayLimit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck_Normal_DayLimit copyWith(void Function(Deck_Normal_DayLimit) updates) => super.copyWith((message) => updates(message as Deck_Normal_DayLimit)) as Deck_Normal_DayLimit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck_Normal_DayLimit create() => Deck_Normal_DayLimit._();
  Deck_Normal_DayLimit createEmptyInstance() => create();
  static $pb.PbList<Deck_Normal_DayLimit> createRepeated() => $pb.PbList<Deck_Normal_DayLimit>();
  @$core.pragma('dart2js:noInline')
  static Deck_Normal_DayLimit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck_Normal_DayLimit>(create);
  static Deck_Normal_DayLimit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get limit => $_getIZ(0);
  @$pb.TagNumber(1)
  set limit($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimit() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get today => $_getIZ(1);
  @$pb.TagNumber(2)
  set today($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasToday() => $_has(1);
  @$pb.TagNumber(2)
  void clearToday() => clearField(2);
}

class Deck_Normal extends $pb.GeneratedMessage {
  factory Deck_Normal({
    $fixnum.Int64? configId,
    $core.int? extendNew,
    $core.int? extendReview,
    $core.String? description,
    $core.bool? markdownDescription,
    $core.int? reviewLimit,
    $core.int? newLimit,
    Deck_Normal_DayLimit? reviewLimitToday,
    Deck_Normal_DayLimit? newLimitToday,
    $core.double? desiredRetention,
  }) {
    final $result = create();
    if (configId != null) {
      $result.configId = configId;
    }
    if (extendNew != null) {
      $result.extendNew = extendNew;
    }
    if (extendReview != null) {
      $result.extendReview = extendReview;
    }
    if (description != null) {
      $result.description = description;
    }
    if (markdownDescription != null) {
      $result.markdownDescription = markdownDescription;
    }
    if (reviewLimit != null) {
      $result.reviewLimit = reviewLimit;
    }
    if (newLimit != null) {
      $result.newLimit = newLimit;
    }
    if (reviewLimitToday != null) {
      $result.reviewLimitToday = reviewLimitToday;
    }
    if (newLimitToday != null) {
      $result.newLimitToday = newLimitToday;
    }
    if (desiredRetention != null) {
      $result.desiredRetention = desiredRetention;
    }
    return $result;
  }
  Deck_Normal._() : super();
  factory Deck_Normal.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck_Normal.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck.Normal', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'configId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'extendNew', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'extendReview', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOB(5, _omitFieldNames ? '' : 'markdownDescription')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'reviewLimit', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'newLimit', $pb.PbFieldType.OU3)
    ..aOM<Deck_Normal_DayLimit>(8, _omitFieldNames ? '' : 'reviewLimitToday', subBuilder: Deck_Normal_DayLimit.create)
    ..aOM<Deck_Normal_DayLimit>(9, _omitFieldNames ? '' : 'newLimitToday', subBuilder: Deck_Normal_DayLimit.create)
    ..a<$core.double>(10, _omitFieldNames ? '' : 'desiredRetention', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck_Normal clone() => Deck_Normal()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck_Normal copyWith(void Function(Deck_Normal) updates) => super.copyWith((message) => updates(message as Deck_Normal)) as Deck_Normal;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck_Normal create() => Deck_Normal._();
  Deck_Normal createEmptyInstance() => create();
  static $pb.PbList<Deck_Normal> createRepeated() => $pb.PbList<Deck_Normal>();
  @$core.pragma('dart2js:noInline')
  static Deck_Normal getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck_Normal>(create);
  static Deck_Normal? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get configId => $_getI64(0);
  @$pb.TagNumber(1)
  set configId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasConfigId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get extendNew => $_getIZ(1);
  @$pb.TagNumber(2)
  set extendNew($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasExtendNew() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtendNew() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get extendReview => $_getIZ(2);
  @$pb.TagNumber(3)
  set extendReview($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasExtendReview() => $_has(2);
  @$pb.TagNumber(3)
  void clearExtendReview() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get markdownDescription => $_getBF(4);
  @$pb.TagNumber(5)
  set markdownDescription($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMarkdownDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearMarkdownDescription() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get reviewLimit => $_getIZ(5);
  @$pb.TagNumber(6)
  set reviewLimit($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasReviewLimit() => $_has(5);
  @$pb.TagNumber(6)
  void clearReviewLimit() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get newLimit => $_getIZ(6);
  @$pb.TagNumber(7)
  set newLimit($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasNewLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearNewLimit() => clearField(7);

  @$pb.TagNumber(8)
  Deck_Normal_DayLimit get reviewLimitToday => $_getN(7);
  @$pb.TagNumber(8)
  set reviewLimitToday(Deck_Normal_DayLimit v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasReviewLimitToday() => $_has(7);
  @$pb.TagNumber(8)
  void clearReviewLimitToday() => clearField(8);
  @$pb.TagNumber(8)
  Deck_Normal_DayLimit ensureReviewLimitToday() => $_ensure(7);

  @$pb.TagNumber(9)
  Deck_Normal_DayLimit get newLimitToday => $_getN(8);
  @$pb.TagNumber(9)
  set newLimitToday(Deck_Normal_DayLimit v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasNewLimitToday() => $_has(8);
  @$pb.TagNumber(9)
  void clearNewLimitToday() => clearField(9);
  @$pb.TagNumber(9)
  Deck_Normal_DayLimit ensureNewLimitToday() => $_ensure(8);

  /// Deck-specific desired retention override
  @$pb.TagNumber(10)
  $core.double get desiredRetention => $_getN(9);
  @$pb.TagNumber(10)
  set desiredRetention($core.double v) { $_setFloat(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasDesiredRetention() => $_has(9);
  @$pb.TagNumber(10)
  void clearDesiredRetention() => clearField(10);
}

class Deck_Filtered_SearchTerm extends $pb.GeneratedMessage {
  factory Deck_Filtered_SearchTerm({
    $core.String? search,
    $core.int? limit,
    Deck_Filtered_SearchTerm_Order? order,
  }) {
    final $result = create();
    if (search != null) {
      $result.search = search;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    if (order != null) {
      $result.order = order;
    }
    return $result;
  }
  Deck_Filtered_SearchTerm._() : super();
  factory Deck_Filtered_SearchTerm.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck_Filtered_SearchTerm.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck.Filtered.SearchTerm', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'search')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU3)
    ..e<Deck_Filtered_SearchTerm_Order>(3, _omitFieldNames ? '' : 'order', $pb.PbFieldType.OE, defaultOrMaker: Deck_Filtered_SearchTerm_Order.OLDEST_REVIEWED_FIRST, valueOf: Deck_Filtered_SearchTerm_Order.valueOf, enumValues: Deck_Filtered_SearchTerm_Order.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck_Filtered_SearchTerm clone() => Deck_Filtered_SearchTerm()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck_Filtered_SearchTerm copyWith(void Function(Deck_Filtered_SearchTerm) updates) => super.copyWith((message) => updates(message as Deck_Filtered_SearchTerm)) as Deck_Filtered_SearchTerm;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck_Filtered_SearchTerm create() => Deck_Filtered_SearchTerm._();
  Deck_Filtered_SearchTerm createEmptyInstance() => create();
  static $pb.PbList<Deck_Filtered_SearchTerm> createRepeated() => $pb.PbList<Deck_Filtered_SearchTerm>();
  @$core.pragma('dart2js:noInline')
  static Deck_Filtered_SearchTerm getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck_Filtered_SearchTerm>(create);
  static Deck_Filtered_SearchTerm? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get search => $_getSZ(0);
  @$pb.TagNumber(1)
  set search($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSearch() => $_has(0);
  @$pb.TagNumber(1)
  void clearSearch() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => clearField(2);

  @$pb.TagNumber(3)
  Deck_Filtered_SearchTerm_Order get order => $_getN(2);
  @$pb.TagNumber(3)
  set order(Deck_Filtered_SearchTerm_Order v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrder() => clearField(3);
}

class Deck_Filtered extends $pb.GeneratedMessage {
  factory Deck_Filtered({
    $core.bool? reschedule,
    $core.Iterable<Deck_Filtered_SearchTerm>? searchTerms,
    $core.Iterable<$core.double>? delays,
    $core.int? previewDelay,
    $core.int? previewHardSecs,
    $core.int? previewGoodSecs,
    $core.int? previewAgainSecs,
  }) {
    final $result = create();
    if (reschedule != null) {
      $result.reschedule = reschedule;
    }
    if (searchTerms != null) {
      $result.searchTerms.addAll(searchTerms);
    }
    if (delays != null) {
      $result.delays.addAll(delays);
    }
    if (previewDelay != null) {
      $result.previewDelay = previewDelay;
    }
    if (previewHardSecs != null) {
      $result.previewHardSecs = previewHardSecs;
    }
    if (previewGoodSecs != null) {
      $result.previewGoodSecs = previewGoodSecs;
    }
    if (previewAgainSecs != null) {
      $result.previewAgainSecs = previewAgainSecs;
    }
    return $result;
  }
  Deck_Filtered._() : super();
  factory Deck_Filtered.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck_Filtered.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck.Filtered', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'reschedule')
    ..pc<Deck_Filtered_SearchTerm>(2, _omitFieldNames ? '' : 'searchTerms', $pb.PbFieldType.PM, subBuilder: Deck_Filtered_SearchTerm.create)
    ..p<$core.double>(3, _omitFieldNames ? '' : 'delays', $pb.PbFieldType.KF)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'previewDelay', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'previewHardSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'previewGoodSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'previewAgainSecs', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck_Filtered clone() => Deck_Filtered()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck_Filtered copyWith(void Function(Deck_Filtered) updates) => super.copyWith((message) => updates(message as Deck_Filtered)) as Deck_Filtered;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck_Filtered create() => Deck_Filtered._();
  Deck_Filtered createEmptyInstance() => create();
  static $pb.PbList<Deck_Filtered> createRepeated() => $pb.PbList<Deck_Filtered>();
  @$core.pragma('dart2js:noInline')
  static Deck_Filtered getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck_Filtered>(create);
  static Deck_Filtered? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get reschedule => $_getBF(0);
  @$pb.TagNumber(1)
  set reschedule($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReschedule() => $_has(0);
  @$pb.TagNumber(1)
  void clearReschedule() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Deck_Filtered_SearchTerm> get searchTerms => $_getList(1);

  /// v1 scheduler only
  @$pb.TagNumber(3)
  $core.List<$core.double> get delays => $_getList(2);

  /// v2 and old v3 scheduler only
  @$pb.TagNumber(4)
  $core.int get previewDelay => $_getIZ(3);
  @$pb.TagNumber(4)
  set previewDelay($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPreviewDelay() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreviewDelay() => clearField(4);

  /// recent v3 scheduler only; 0 means card will be returned
  @$pb.TagNumber(5)
  $core.int get previewHardSecs => $_getIZ(4);
  @$pb.TagNumber(5)
  set previewHardSecs($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPreviewHardSecs() => $_has(4);
  @$pb.TagNumber(5)
  void clearPreviewHardSecs() => clearField(5);

  /// recent v3 scheduler only; 0 means card will be returned
  @$pb.TagNumber(6)
  $core.int get previewGoodSecs => $_getIZ(5);
  @$pb.TagNumber(6)
  set previewGoodSecs($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPreviewGoodSecs() => $_has(5);
  @$pb.TagNumber(6)
  void clearPreviewGoodSecs() => clearField(6);

  /// recent v3 scheduler only; 0 means card will be returned
  @$pb.TagNumber(7)
  $core.int get previewAgainSecs => $_getIZ(6);
  @$pb.TagNumber(7)
  set previewAgainSecs($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPreviewAgainSecs() => $_has(6);
  @$pb.TagNumber(7)
  void clearPreviewAgainSecs() => clearField(7);
}

enum Deck_KindContainer_Kind {
  normal,
  filtered,
  notSet
}

/// a container to store the deck specifics in the DB
/// as a tagged enum
class Deck_KindContainer extends $pb.GeneratedMessage {
  factory Deck_KindContainer({
    Deck_Normal? normal,
    Deck_Filtered? filtered,
  }) {
    final $result = create();
    if (normal != null) {
      $result.normal = normal;
    }
    if (filtered != null) {
      $result.filtered = filtered;
    }
    return $result;
  }
  Deck_KindContainer._() : super();
  factory Deck_KindContainer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck_KindContainer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Deck_KindContainer_Kind> _Deck_KindContainer_KindByTag = {
    1 : Deck_KindContainer_Kind.normal,
    2 : Deck_KindContainer_Kind.filtered,
    0 : Deck_KindContainer_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck.KindContainer', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Deck_Normal>(1, _omitFieldNames ? '' : 'normal', subBuilder: Deck_Normal.create)
    ..aOM<Deck_Filtered>(2, _omitFieldNames ? '' : 'filtered', subBuilder: Deck_Filtered.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck_KindContainer clone() => Deck_KindContainer()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck_KindContainer copyWith(void Function(Deck_KindContainer) updates) => super.copyWith((message) => updates(message as Deck_KindContainer)) as Deck_KindContainer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck_KindContainer create() => Deck_KindContainer._();
  Deck_KindContainer createEmptyInstance() => create();
  static $pb.PbList<Deck_KindContainer> createRepeated() => $pb.PbList<Deck_KindContainer>();
  @$core.pragma('dart2js:noInline')
  static Deck_KindContainer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck_KindContainer>(create);
  static Deck_KindContainer? _defaultInstance;

  Deck_KindContainer_Kind whichKind() => _Deck_KindContainer_KindByTag[$_whichOneof(0)]!;
  void clearKind() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Deck_Normal get normal => $_getN(0);
  @$pb.TagNumber(1)
  set normal(Deck_Normal v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNormal() => $_has(0);
  @$pb.TagNumber(1)
  void clearNormal() => clearField(1);
  @$pb.TagNumber(1)
  Deck_Normal ensureNormal() => $_ensure(0);

  @$pb.TagNumber(2)
  Deck_Filtered get filtered => $_getN(1);
  @$pb.TagNumber(2)
  set filtered(Deck_Filtered v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFiltered() => $_has(1);
  @$pb.TagNumber(2)
  void clearFiltered() => clearField(2);
  @$pb.TagNumber(2)
  Deck_Filtered ensureFiltered() => $_ensure(1);
}

enum Deck_Kind {
  normal,
  filtered,
  notSet
}

class Deck extends $pb.GeneratedMessage {
  factory Deck({
    $fixnum.Int64? id,
    $core.String? name,
    $fixnum.Int64? mtimeSecs,
    $core.int? usn,
    Deck_Common? common,
    Deck_Normal? normal,
    Deck_Filtered? filtered,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (mtimeSecs != null) {
      $result.mtimeSecs = mtimeSecs;
    }
    if (usn != null) {
      $result.usn = usn;
    }
    if (common != null) {
      $result.common = common;
    }
    if (normal != null) {
      $result.normal = normal;
    }
    if (filtered != null) {
      $result.filtered = filtered;
    }
    return $result;
  }
  Deck._() : super();
  factory Deck.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Deck.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Deck_Kind> _Deck_KindByTag = {
    6 : Deck_Kind.normal,
    7 : Deck_Kind.filtered,
    0 : Deck_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Deck', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..oo(0, [6, 7])
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'mtimeSecs')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'usn', $pb.PbFieldType.O3)
    ..aOM<Deck_Common>(5, _omitFieldNames ? '' : 'common', subBuilder: Deck_Common.create)
    ..aOM<Deck_Normal>(6, _omitFieldNames ? '' : 'normal', subBuilder: Deck_Normal.create)
    ..aOM<Deck_Filtered>(7, _omitFieldNames ? '' : 'filtered', subBuilder: Deck_Filtered.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Deck clone() => Deck()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Deck copyWith(void Function(Deck) updates) => super.copyWith((message) => updates(message as Deck)) as Deck;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deck create() => Deck._();
  Deck createEmptyInstance() => create();
  static $pb.PbList<Deck> createRepeated() => $pb.PbList<Deck>();
  @$core.pragma('dart2js:noInline')
  static Deck getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Deck>(create);
  static Deck? _defaultInstance;

  Deck_Kind whichKind() => _Deck_KindByTag[$_whichOneof(0)]!;
  void clearKind() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get mtimeSecs => $_getI64(2);
  @$pb.TagNumber(3)
  set mtimeSecs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMtimeSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearMtimeSecs() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get usn => $_getIZ(3);
  @$pb.TagNumber(4)
  set usn($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUsn() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsn() => clearField(4);

  @$pb.TagNumber(5)
  Deck_Common get common => $_getN(4);
  @$pb.TagNumber(5)
  set common(Deck_Common v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasCommon() => $_has(4);
  @$pb.TagNumber(5)
  void clearCommon() => clearField(5);
  @$pb.TagNumber(5)
  Deck_Common ensureCommon() => $_ensure(4);

  @$pb.TagNumber(6)
  Deck_Normal get normal => $_getN(5);
  @$pb.TagNumber(6)
  set normal(Deck_Normal v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasNormal() => $_has(5);
  @$pb.TagNumber(6)
  void clearNormal() => clearField(6);
  @$pb.TagNumber(6)
  Deck_Normal ensureNormal() => $_ensure(5);

  @$pb.TagNumber(7)
  Deck_Filtered get filtered => $_getN(6);
  @$pb.TagNumber(7)
  set filtered(Deck_Filtered v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasFiltered() => $_has(6);
  @$pb.TagNumber(7)
  void clearFiltered() => clearField(7);
  @$pb.TagNumber(7)
  Deck_Filtered ensureFiltered() => $_ensure(6);
}

class AddOrUpdateDeckLegacyRequest extends $pb.GeneratedMessage {
  factory AddOrUpdateDeckLegacyRequest({
    $core.List<$core.int>? deck,
    $core.bool? preserveUsnAndMtime,
  }) {
    final $result = create();
    if (deck != null) {
      $result.deck = deck;
    }
    if (preserveUsnAndMtime != null) {
      $result.preserveUsnAndMtime = preserveUsnAndMtime;
    }
    return $result;
  }
  AddOrUpdateDeckLegacyRequest._() : super();
  factory AddOrUpdateDeckLegacyRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddOrUpdateDeckLegacyRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddOrUpdateDeckLegacyRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'deck', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'preserveUsnAndMtime')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddOrUpdateDeckLegacyRequest clone() => AddOrUpdateDeckLegacyRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddOrUpdateDeckLegacyRequest copyWith(void Function(AddOrUpdateDeckLegacyRequest) updates) => super.copyWith((message) => updates(message as AddOrUpdateDeckLegacyRequest)) as AddOrUpdateDeckLegacyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddOrUpdateDeckLegacyRequest create() => AddOrUpdateDeckLegacyRequest._();
  AddOrUpdateDeckLegacyRequest createEmptyInstance() => create();
  static $pb.PbList<AddOrUpdateDeckLegacyRequest> createRepeated() => $pb.PbList<AddOrUpdateDeckLegacyRequest>();
  @$core.pragma('dart2js:noInline')
  static AddOrUpdateDeckLegacyRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddOrUpdateDeckLegacyRequest>(create);
  static AddOrUpdateDeckLegacyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get deck => $_getN(0);
  @$pb.TagNumber(1)
  set deck($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeck() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeck() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get preserveUsnAndMtime => $_getBF(1);
  @$pb.TagNumber(2)
  set preserveUsnAndMtime($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPreserveUsnAndMtime() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreserveUsnAndMtime() => clearField(2);
}

class DeckTreeRequest extends $pb.GeneratedMessage {
  factory DeckTreeRequest({
    $fixnum.Int64? now,
  }) {
    final $result = create();
    if (now != null) {
      $result.now = now;
    }
    return $result;
  }
  DeckTreeRequest._() : super();
  factory DeckTreeRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckTreeRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckTreeRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'now')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckTreeRequest clone() => DeckTreeRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckTreeRequest copyWith(void Function(DeckTreeRequest) updates) => super.copyWith((message) => updates(message as DeckTreeRequest)) as DeckTreeRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckTreeRequest create() => DeckTreeRequest._();
  DeckTreeRequest createEmptyInstance() => create();
  static $pb.PbList<DeckTreeRequest> createRepeated() => $pb.PbList<DeckTreeRequest>();
  @$core.pragma('dart2js:noInline')
  static DeckTreeRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckTreeRequest>(create);
  static DeckTreeRequest? _defaultInstance;

  /// if non-zero, counts for the provided timestamp will be included
  @$pb.TagNumber(1)
  $fixnum.Int64 get now => $_getI64(0);
  @$pb.TagNumber(1)
  set now($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNow() => $_has(0);
  @$pb.TagNumber(1)
  void clearNow() => clearField(1);
}

class DeckTreeNode extends $pb.GeneratedMessage {
  factory DeckTreeNode({
    $fixnum.Int64? deckId,
    $core.String? name,
    $core.Iterable<DeckTreeNode>? children,
    $core.int? level,
    $core.bool? collapsed,
    $core.int? reviewCount,
    $core.int? learnCount,
    $core.int? newCount,
    $core.int? intradayLearning,
    $core.int? interdayLearningUncapped,
    $core.int? newUncapped,
    $core.int? reviewUncapped,
    $core.int? totalInDeck,
    $core.int? totalIncludingChildren,
    $core.bool? filtered,
  }) {
    final $result = create();
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (name != null) {
      $result.name = name;
    }
    if (children != null) {
      $result.children.addAll(children);
    }
    if (level != null) {
      $result.level = level;
    }
    if (collapsed != null) {
      $result.collapsed = collapsed;
    }
    if (reviewCount != null) {
      $result.reviewCount = reviewCount;
    }
    if (learnCount != null) {
      $result.learnCount = learnCount;
    }
    if (newCount != null) {
      $result.newCount = newCount;
    }
    if (intradayLearning != null) {
      $result.intradayLearning = intradayLearning;
    }
    if (interdayLearningUncapped != null) {
      $result.interdayLearningUncapped = interdayLearningUncapped;
    }
    if (newUncapped != null) {
      $result.newUncapped = newUncapped;
    }
    if (reviewUncapped != null) {
      $result.reviewUncapped = reviewUncapped;
    }
    if (totalInDeck != null) {
      $result.totalInDeck = totalInDeck;
    }
    if (totalIncludingChildren != null) {
      $result.totalIncludingChildren = totalIncludingChildren;
    }
    if (filtered != null) {
      $result.filtered = filtered;
    }
    return $result;
  }
  DeckTreeNode._() : super();
  factory DeckTreeNode.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckTreeNode.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckTreeNode', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'deckId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pc<DeckTreeNode>(3, _omitFieldNames ? '' : 'children', $pb.PbFieldType.PM, subBuilder: DeckTreeNode.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OU3)
    ..aOB(5, _omitFieldNames ? '' : 'collapsed')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'reviewCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'learnCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'newCount', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'intradayLearning', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'interdayLearningUncapped', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'newUncapped', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'reviewUncapped', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'totalInDeck', $pb.PbFieldType.OU3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'totalIncludingChildren', $pb.PbFieldType.OU3)
    ..aOB(16, _omitFieldNames ? '' : 'filtered')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckTreeNode clone() => DeckTreeNode()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckTreeNode copyWith(void Function(DeckTreeNode) updates) => super.copyWith((message) => updates(message as DeckTreeNode)) as DeckTreeNode;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckTreeNode create() => DeckTreeNode._();
  DeckTreeNode createEmptyInstance() => create();
  static $pb.PbList<DeckTreeNode> createRepeated() => $pb.PbList<DeckTreeNode>();
  @$core.pragma('dart2js:noInline')
  static DeckTreeNode getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckTreeNode>(create);
  static DeckTreeNode? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deckId => $_getI64(0);
  @$pb.TagNumber(1)
  set deckId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeckId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeckId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  /// low index so key can be packed into a byte, but at bottom
  /// to make debug output easier to read
  @$pb.TagNumber(3)
  $core.List<DeckTreeNode> get children => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get level => $_getIZ(3);
  @$pb.TagNumber(4)
  set level($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLevel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLevel() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get collapsed => $_getBF(4);
  @$pb.TagNumber(5)
  set collapsed($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasCollapsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearCollapsed() => clearField(5);

  /// counts after adding children+applying limits
  @$pb.TagNumber(6)
  $core.int get reviewCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set reviewCount($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasReviewCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearReviewCount() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get learnCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set learnCount($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasLearnCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearLearnCount() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get newCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set newCount($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasNewCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearNewCount() => clearField(8);

  /// card counts without children or limits applied
  @$pb.TagNumber(9)
  $core.int get intradayLearning => $_getIZ(8);
  @$pb.TagNumber(9)
  set intradayLearning($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasIntradayLearning() => $_has(8);
  @$pb.TagNumber(9)
  void clearIntradayLearning() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get interdayLearningUncapped => $_getIZ(9);
  @$pb.TagNumber(10)
  set interdayLearningUncapped($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasInterdayLearningUncapped() => $_has(9);
  @$pb.TagNumber(10)
  void clearInterdayLearningUncapped() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get newUncapped => $_getIZ(10);
  @$pb.TagNumber(11)
  set newUncapped($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasNewUncapped() => $_has(10);
  @$pb.TagNumber(11)
  void clearNewUncapped() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get reviewUncapped => $_getIZ(11);
  @$pb.TagNumber(12)
  set reviewUncapped($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasReviewUncapped() => $_has(11);
  @$pb.TagNumber(12)
  void clearReviewUncapped() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get totalInDeck => $_getIZ(12);
  @$pb.TagNumber(13)
  set totalInDeck($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasTotalInDeck() => $_has(12);
  @$pb.TagNumber(13)
  void clearTotalInDeck() => clearField(13);

  /// with children, without any limits
  @$pb.TagNumber(14)
  $core.int get totalIncludingChildren => $_getIZ(13);
  @$pb.TagNumber(14)
  set totalIncludingChildren($core.int v) { $_setUnsignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasTotalIncludingChildren() => $_has(13);
  @$pb.TagNumber(14)
  void clearTotalIncludingChildren() => clearField(14);

  @$pb.TagNumber(16)
  $core.bool get filtered => $_getBF(14);
  @$pb.TagNumber(16)
  set filtered($core.bool v) { $_setBool(14, v); }
  @$pb.TagNumber(16)
  $core.bool hasFiltered() => $_has(14);
  @$pb.TagNumber(16)
  void clearFiltered() => clearField(16);
}

class SetDeckCollapsedRequest extends $pb.GeneratedMessage {
  factory SetDeckCollapsedRequest({
    $fixnum.Int64? deckId,
    $core.bool? collapsed,
    SetDeckCollapsedRequest_Scope? scope,
  }) {
    final $result = create();
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (collapsed != null) {
      $result.collapsed = collapsed;
    }
    if (scope != null) {
      $result.scope = scope;
    }
    return $result;
  }
  SetDeckCollapsedRequest._() : super();
  factory SetDeckCollapsedRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetDeckCollapsedRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetDeckCollapsedRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'deckId')
    ..aOB(2, _omitFieldNames ? '' : 'collapsed')
    ..e<SetDeckCollapsedRequest_Scope>(3, _omitFieldNames ? '' : 'scope', $pb.PbFieldType.OE, defaultOrMaker: SetDeckCollapsedRequest_Scope.REVIEWER, valueOf: SetDeckCollapsedRequest_Scope.valueOf, enumValues: SetDeckCollapsedRequest_Scope.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetDeckCollapsedRequest clone() => SetDeckCollapsedRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetDeckCollapsedRequest copyWith(void Function(SetDeckCollapsedRequest) updates) => super.copyWith((message) => updates(message as SetDeckCollapsedRequest)) as SetDeckCollapsedRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDeckCollapsedRequest create() => SetDeckCollapsedRequest._();
  SetDeckCollapsedRequest createEmptyInstance() => create();
  static $pb.PbList<SetDeckCollapsedRequest> createRepeated() => $pb.PbList<SetDeckCollapsedRequest>();
  @$core.pragma('dart2js:noInline')
  static SetDeckCollapsedRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetDeckCollapsedRequest>(create);
  static SetDeckCollapsedRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deckId => $_getI64(0);
  @$pb.TagNumber(1)
  set deckId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeckId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeckId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get collapsed => $_getBF(1);
  @$pb.TagNumber(2)
  set collapsed($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCollapsed() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollapsed() => clearField(2);

  @$pb.TagNumber(3)
  SetDeckCollapsedRequest_Scope get scope => $_getN(2);
  @$pb.TagNumber(3)
  set scope(SetDeckCollapsedRequest_Scope v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasScope() => $_has(2);
  @$pb.TagNumber(3)
  void clearScope() => clearField(3);
}

class GetDeckNamesRequest extends $pb.GeneratedMessage {
  factory GetDeckNamesRequest({
    $core.bool? skipEmptyDefault,
    $core.bool? includeFiltered,
  }) {
    final $result = create();
    if (skipEmptyDefault != null) {
      $result.skipEmptyDefault = skipEmptyDefault;
    }
    if (includeFiltered != null) {
      $result.includeFiltered = includeFiltered;
    }
    return $result;
  }
  GetDeckNamesRequest._() : super();
  factory GetDeckNamesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetDeckNamesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetDeckNamesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'skipEmptyDefault')
    ..aOB(2, _omitFieldNames ? '' : 'includeFiltered')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetDeckNamesRequest clone() => GetDeckNamesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetDeckNamesRequest copyWith(void Function(GetDeckNamesRequest) updates) => super.copyWith((message) => updates(message as GetDeckNamesRequest)) as GetDeckNamesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDeckNamesRequest create() => GetDeckNamesRequest._();
  GetDeckNamesRequest createEmptyInstance() => create();
  static $pb.PbList<GetDeckNamesRequest> createRepeated() => $pb.PbList<GetDeckNamesRequest>();
  @$core.pragma('dart2js:noInline')
  static GetDeckNamesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetDeckNamesRequest>(create);
  static GetDeckNamesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get skipEmptyDefault => $_getBF(0);
  @$pb.TagNumber(1)
  set skipEmptyDefault($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSkipEmptyDefault() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkipEmptyDefault() => clearField(1);

  /// if unset, implies skip_empty_default
  @$pb.TagNumber(2)
  $core.bool get includeFiltered => $_getBF(1);
  @$pb.TagNumber(2)
  set includeFiltered($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIncludeFiltered() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeFiltered() => clearField(2);
}

class DeckNames extends $pb.GeneratedMessage {
  factory DeckNames({
    $core.Iterable<DeckNameId>? entries,
  }) {
    final $result = create();
    if (entries != null) {
      $result.entries.addAll(entries);
    }
    return $result;
  }
  DeckNames._() : super();
  factory DeckNames.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckNames.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckNames', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..pc<DeckNameId>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM, subBuilder: DeckNameId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckNames clone() => DeckNames()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckNames copyWith(void Function(DeckNames) updates) => super.copyWith((message) => updates(message as DeckNames)) as DeckNames;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckNames create() => DeckNames._();
  DeckNames createEmptyInstance() => create();
  static $pb.PbList<DeckNames> createRepeated() => $pb.PbList<DeckNames>();
  @$core.pragma('dart2js:noInline')
  static DeckNames getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckNames>(create);
  static DeckNames? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<DeckNameId> get entries => $_getList(0);
}

class DeckNameId extends $pb.GeneratedMessage {
  factory DeckNameId({
    $fixnum.Int64? id,
    $core.String? name,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  DeckNameId._() : super();
  factory DeckNameId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckNameId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckNameId', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckNameId clone() => DeckNameId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckNameId copyWith(void Function(DeckNameId) updates) => super.copyWith((message) => updates(message as DeckNameId)) as DeckNameId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckNameId create() => DeckNameId._();
  DeckNameId createEmptyInstance() => create();
  static $pb.PbList<DeckNameId> createRepeated() => $pb.PbList<DeckNameId>();
  @$core.pragma('dart2js:noInline')
  static DeckNameId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckNameId>(create);
  static DeckNameId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

class ReparentDecksRequest extends $pb.GeneratedMessage {
  factory ReparentDecksRequest({
    $core.Iterable<$fixnum.Int64>? deckIds,
    $fixnum.Int64? newParent,
  }) {
    final $result = create();
    if (deckIds != null) {
      $result.deckIds.addAll(deckIds);
    }
    if (newParent != null) {
      $result.newParent = newParent;
    }
    return $result;
  }
  ReparentDecksRequest._() : super();
  factory ReparentDecksRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReparentDecksRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReparentDecksRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'deckIds', $pb.PbFieldType.K6)
    ..aInt64(2, _omitFieldNames ? '' : 'newParent')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReparentDecksRequest clone() => ReparentDecksRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReparentDecksRequest copyWith(void Function(ReparentDecksRequest) updates) => super.copyWith((message) => updates(message as ReparentDecksRequest)) as ReparentDecksRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReparentDecksRequest create() => ReparentDecksRequest._();
  ReparentDecksRequest createEmptyInstance() => create();
  static $pb.PbList<ReparentDecksRequest> createRepeated() => $pb.PbList<ReparentDecksRequest>();
  @$core.pragma('dart2js:noInline')
  static ReparentDecksRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReparentDecksRequest>(create);
  static ReparentDecksRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get deckIds => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get newParent => $_getI64(1);
  @$pb.TagNumber(2)
  set newParent($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNewParent() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewParent() => clearField(2);
}

class RenameDeckRequest extends $pb.GeneratedMessage {
  factory RenameDeckRequest({
    $fixnum.Int64? deckId,
    $core.String? newName,
  }) {
    final $result = create();
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (newName != null) {
      $result.newName = newName;
    }
    return $result;
  }
  RenameDeckRequest._() : super();
  factory RenameDeckRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenameDeckRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenameDeckRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'deckId')
    ..aOS(2, _omitFieldNames ? '' : 'newName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenameDeckRequest clone() => RenameDeckRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenameDeckRequest copyWith(void Function(RenameDeckRequest) updates) => super.copyWith((message) => updates(message as RenameDeckRequest)) as RenameDeckRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameDeckRequest create() => RenameDeckRequest._();
  RenameDeckRequest createEmptyInstance() => create();
  static $pb.PbList<RenameDeckRequest> createRepeated() => $pb.PbList<RenameDeckRequest>();
  @$core.pragma('dart2js:noInline')
  static RenameDeckRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenameDeckRequest>(create);
  static RenameDeckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deckId => $_getI64(0);
  @$pb.TagNumber(1)
  set deckId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeckId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeckId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get newName => $_getSZ(1);
  @$pb.TagNumber(2)
  set newName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNewName() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewName() => clearField(2);
}

class FilteredDeckForUpdate extends $pb.GeneratedMessage {
  factory FilteredDeckForUpdate({
    $fixnum.Int64? id,
    $core.String? name,
    Deck_Filtered? config,
    $core.bool? allowEmpty,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (config != null) {
      $result.config = config;
    }
    if (allowEmpty != null) {
      $result.allowEmpty = allowEmpty;
    }
    return $result;
  }
  FilteredDeckForUpdate._() : super();
  factory FilteredDeckForUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FilteredDeckForUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FilteredDeckForUpdate', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.decks'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<Deck_Filtered>(3, _omitFieldNames ? '' : 'config', subBuilder: Deck_Filtered.create)
    ..aOB(4, _omitFieldNames ? '' : 'allowEmpty')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FilteredDeckForUpdate clone() => FilteredDeckForUpdate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FilteredDeckForUpdate copyWith(void Function(FilteredDeckForUpdate) updates) => super.copyWith((message) => updates(message as FilteredDeckForUpdate)) as FilteredDeckForUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilteredDeckForUpdate create() => FilteredDeckForUpdate._();
  FilteredDeckForUpdate createEmptyInstance() => create();
  static $pb.PbList<FilteredDeckForUpdate> createRepeated() => $pb.PbList<FilteredDeckForUpdate>();
  @$core.pragma('dart2js:noInline')
  static FilteredDeckForUpdate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FilteredDeckForUpdate>(create);
  static FilteredDeckForUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  Deck_Filtered get config => $_getN(2);
  @$pb.TagNumber(3)
  set config(Deck_Filtered v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasConfig() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfig() => clearField(3);
  @$pb.TagNumber(3)
  Deck_Filtered ensureConfig() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get allowEmpty => $_getBF(3);
  @$pb.TagNumber(4)
  set allowEmpty($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAllowEmpty() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowEmpty() => clearField(4);
}

class DecksServiceApi {
  $pb.RpcClient _client;
  DecksServiceApi(this._client);

  $async.Future<Deck> newDeck($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<Deck>(ctx, 'DecksService', 'NewDeck', request, Deck())
  ;
  $async.Future<$2.OpChangesWithId> addDeck($pb.ClientContext? ctx, Deck request) =>
    _client.invoke<$2.OpChangesWithId>(ctx, 'DecksService', 'AddDeck', request, $2.OpChangesWithId())
  ;
  $async.Future<$2.OpChangesWithId> addDeckLegacy($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<$2.OpChangesWithId>(ctx, 'DecksService', 'AddDeckLegacy', request, $2.OpChangesWithId())
  ;
  $async.Future<DeckId> addOrUpdateDeckLegacy($pb.ClientContext? ctx, AddOrUpdateDeckLegacyRequest request) =>
    _client.invoke<DeckId>(ctx, 'DecksService', 'AddOrUpdateDeckLegacy', request, DeckId())
  ;
  $async.Future<DeckTreeNode> deckTree($pb.ClientContext? ctx, DeckTreeRequest request) =>
    _client.invoke<DeckTreeNode>(ctx, 'DecksService', 'DeckTree', request, DeckTreeNode())
  ;
  $async.Future<$0.Json> deckTreeLegacy($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Json>(ctx, 'DecksService', 'DeckTreeLegacy', request, $0.Json())
  ;
  $async.Future<$0.Json> getAllDecksLegacy($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Json>(ctx, 'DecksService', 'GetAllDecksLegacy', request, $0.Json())
  ;
  $async.Future<DeckId> getDeckIdByName($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<DeckId>(ctx, 'DecksService', 'GetDeckIdByName', request, DeckId())
  ;
  $async.Future<Deck> getDeck($pb.ClientContext? ctx, DeckId request) =>
    _client.invoke<Deck>(ctx, 'DecksService', 'GetDeck', request, Deck())
  ;
  $async.Future<$2.OpChanges> updateDeck($pb.ClientContext? ctx, Deck request) =>
    _client.invoke<$2.OpChanges>(ctx, 'DecksService', 'UpdateDeck', request, $2.OpChanges())
  ;
  $async.Future<$2.OpChanges> updateDeckLegacy($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<$2.OpChanges>(ctx, 'DecksService', 'UpdateDeckLegacy', request, $2.OpChanges())
  ;
  $async.Future<$2.OpChanges> setDeckCollapsed($pb.ClientContext? ctx, SetDeckCollapsedRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'DecksService', 'SetDeckCollapsed', request, $2.OpChanges())
  ;
  $async.Future<$0.Json> getDeckLegacy($pb.ClientContext? ctx, DeckId request) =>
    _client.invoke<$0.Json>(ctx, 'DecksService', 'GetDeckLegacy', request, $0.Json())
  ;
  $async.Future<DeckNames> getDeckNames($pb.ClientContext? ctx, GetDeckNamesRequest request) =>
    _client.invoke<DeckNames>(ctx, 'DecksService', 'GetDeckNames', request, DeckNames())
  ;
  $async.Future<DeckNames> getDeckAndChildNames($pb.ClientContext? ctx, DeckId request) =>
    _client.invoke<DeckNames>(ctx, 'DecksService', 'GetDeckAndChildNames', request, DeckNames())
  ;
  $async.Future<$0.Json> newDeckLegacy($pb.ClientContext? ctx, $0.Bool request) =>
    _client.invoke<$0.Json>(ctx, 'DecksService', 'NewDeckLegacy', request, $0.Json())
  ;
  $async.Future<$2.OpChangesWithCount> removeDecks($pb.ClientContext? ctx, DeckIds request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'DecksService', 'RemoveDecks', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> reparentDecks($pb.ClientContext? ctx, ReparentDecksRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'DecksService', 'ReparentDecks', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChanges> renameDeck($pb.ClientContext? ctx, RenameDeckRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'DecksService', 'RenameDeck', request, $2.OpChanges())
  ;
  $async.Future<FilteredDeckForUpdate> getOrCreateFilteredDeck($pb.ClientContext? ctx, DeckId request) =>
    _client.invoke<FilteredDeckForUpdate>(ctx, 'DecksService', 'GetOrCreateFilteredDeck', request, FilteredDeckForUpdate())
  ;
  $async.Future<$2.OpChangesWithId> addOrUpdateFilteredDeck($pb.ClientContext? ctx, FilteredDeckForUpdate request) =>
    _client.invoke<$2.OpChangesWithId>(ctx, 'DecksService', 'AddOrUpdateFilteredDeck', request, $2.OpChangesWithId())
  ;
  $async.Future<$0.StringList> filteredDeckOrderLabels($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.StringList>(ctx, 'DecksService', 'FilteredDeckOrderLabels', request, $0.StringList())
  ;
  $async.Future<$2.OpChanges> setCurrentDeck($pb.ClientContext? ctx, DeckId request) =>
    _client.invoke<$2.OpChanges>(ctx, 'DecksService', 'SetCurrentDeck', request, $2.OpChanges())
  ;
  $async.Future<Deck> getCurrentDeck($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<Deck>(ctx, 'DecksService', 'GetCurrentDeck', request, Deck())
  ;
}

class BackendDecksServiceApi {
  $pb.RpcClient _client;
  BackendDecksServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
