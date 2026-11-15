// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/config.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'collection.pb.dart' as $2;
import 'config.pbenum.dart';
import 'generic.pb.dart' as $0;

export 'config.pbenum.dart';

class ConfigKey extends $pb.GeneratedMessage {
  factory ConfigKey() => create();
  ConfigKey._() : super();
  factory ConfigKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConfigKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConfigKey', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConfigKey clone() => ConfigKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConfigKey copyWith(void Function(ConfigKey) updates) => super.copyWith((message) => updates(message as ConfigKey)) as ConfigKey;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfigKey create() => ConfigKey._();
  ConfigKey createEmptyInstance() => create();
  static $pb.PbList<ConfigKey> createRepeated() => $pb.PbList<ConfigKey>();
  @$core.pragma('dart2js:noInline')
  static ConfigKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConfigKey>(create);
  static ConfigKey? _defaultInstance;
}

class GetConfigBoolRequest extends $pb.GeneratedMessage {
  factory GetConfigBoolRequest({
    ConfigKey_Bool? key,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    return $result;
  }
  GetConfigBoolRequest._() : super();
  factory GetConfigBoolRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConfigBoolRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConfigBoolRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..e<ConfigKey_Bool>(1, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OE, defaultOrMaker: ConfigKey_Bool.BROWSER_TABLE_SHOW_NOTES_MODE, valueOf: ConfigKey_Bool.valueOf, enumValues: ConfigKey_Bool.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConfigBoolRequest clone() => GetConfigBoolRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConfigBoolRequest copyWith(void Function(GetConfigBoolRequest) updates) => super.copyWith((message) => updates(message as GetConfigBoolRequest)) as GetConfigBoolRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConfigBoolRequest create() => GetConfigBoolRequest._();
  GetConfigBoolRequest createEmptyInstance() => create();
  static $pb.PbList<GetConfigBoolRequest> createRepeated() => $pb.PbList<GetConfigBoolRequest>();
  @$core.pragma('dart2js:noInline')
  static GetConfigBoolRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConfigBoolRequest>(create);
  static GetConfigBoolRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConfigKey_Bool get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(ConfigKey_Bool v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
}

class SetConfigBoolRequest extends $pb.GeneratedMessage {
  factory SetConfigBoolRequest({
    ConfigKey_Bool? key,
    $core.bool? value,
    $core.bool? undoable,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (value != null) {
      $result.value = value;
    }
    if (undoable != null) {
      $result.undoable = undoable;
    }
    return $result;
  }
  SetConfigBoolRequest._() : super();
  factory SetConfigBoolRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetConfigBoolRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetConfigBoolRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..e<ConfigKey_Bool>(1, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OE, defaultOrMaker: ConfigKey_Bool.BROWSER_TABLE_SHOW_NOTES_MODE, valueOf: ConfigKey_Bool.valueOf, enumValues: ConfigKey_Bool.values)
    ..aOB(2, _omitFieldNames ? '' : 'value')
    ..aOB(3, _omitFieldNames ? '' : 'undoable')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetConfigBoolRequest clone() => SetConfigBoolRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetConfigBoolRequest copyWith(void Function(SetConfigBoolRequest) updates) => super.copyWith((message) => updates(message as SetConfigBoolRequest)) as SetConfigBoolRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetConfigBoolRequest create() => SetConfigBoolRequest._();
  SetConfigBoolRequest createEmptyInstance() => create();
  static $pb.PbList<SetConfigBoolRequest> createRepeated() => $pb.PbList<SetConfigBoolRequest>();
  @$core.pragma('dart2js:noInline')
  static SetConfigBoolRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetConfigBoolRequest>(create);
  static SetConfigBoolRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConfigKey_Bool get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(ConfigKey_Bool v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get value => $_getBF(1);
  @$pb.TagNumber(2)
  set value($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get undoable => $_getBF(2);
  @$pb.TagNumber(3)
  set undoable($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUndoable() => $_has(2);
  @$pb.TagNumber(3)
  void clearUndoable() => clearField(3);
}

class GetConfigStringRequest extends $pb.GeneratedMessage {
  factory GetConfigStringRequest({
    ConfigKey_String? key,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    return $result;
  }
  GetConfigStringRequest._() : super();
  factory GetConfigStringRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetConfigStringRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConfigStringRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..e<ConfigKey_String>(1, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OE, defaultOrMaker: ConfigKey_String.SET_DUE_BROWSER, valueOf: ConfigKey_String.valueOf, enumValues: ConfigKey_String.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetConfigStringRequest clone() => GetConfigStringRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetConfigStringRequest copyWith(void Function(GetConfigStringRequest) updates) => super.copyWith((message) => updates(message as GetConfigStringRequest)) as GetConfigStringRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConfigStringRequest create() => GetConfigStringRequest._();
  GetConfigStringRequest createEmptyInstance() => create();
  static $pb.PbList<GetConfigStringRequest> createRepeated() => $pb.PbList<GetConfigStringRequest>();
  @$core.pragma('dart2js:noInline')
  static GetConfigStringRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConfigStringRequest>(create);
  static GetConfigStringRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConfigKey_String get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(ConfigKey_String v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
}

class SetConfigStringRequest extends $pb.GeneratedMessage {
  factory SetConfigStringRequest({
    ConfigKey_String? key,
    $core.String? value,
    $core.bool? undoable,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (value != null) {
      $result.value = value;
    }
    if (undoable != null) {
      $result.undoable = undoable;
    }
    return $result;
  }
  SetConfigStringRequest._() : super();
  factory SetConfigStringRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetConfigStringRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetConfigStringRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..e<ConfigKey_String>(1, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OE, defaultOrMaker: ConfigKey_String.SET_DUE_BROWSER, valueOf: ConfigKey_String.valueOf, enumValues: ConfigKey_String.values)
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aOB(3, _omitFieldNames ? '' : 'undoable')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetConfigStringRequest clone() => SetConfigStringRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetConfigStringRequest copyWith(void Function(SetConfigStringRequest) updates) => super.copyWith((message) => updates(message as SetConfigStringRequest)) as SetConfigStringRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetConfigStringRequest create() => SetConfigStringRequest._();
  SetConfigStringRequest createEmptyInstance() => create();
  static $pb.PbList<SetConfigStringRequest> createRepeated() => $pb.PbList<SetConfigStringRequest>();
  @$core.pragma('dart2js:noInline')
  static SetConfigStringRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetConfigStringRequest>(create);
  static SetConfigStringRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConfigKey_String get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(ConfigKey_String v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get undoable => $_getBF(2);
  @$pb.TagNumber(3)
  set undoable($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUndoable() => $_has(2);
  @$pb.TagNumber(3)
  void clearUndoable() => clearField(3);
}

class OptionalStringConfigKey extends $pb.GeneratedMessage {
  factory OptionalStringConfigKey({
    ConfigKey_String? key,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    return $result;
  }
  OptionalStringConfigKey._() : super();
  factory OptionalStringConfigKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OptionalStringConfigKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OptionalStringConfigKey', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..e<ConfigKey_String>(1, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OE, defaultOrMaker: ConfigKey_String.SET_DUE_BROWSER, valueOf: ConfigKey_String.valueOf, enumValues: ConfigKey_String.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OptionalStringConfigKey clone() => OptionalStringConfigKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OptionalStringConfigKey copyWith(void Function(OptionalStringConfigKey) updates) => super.copyWith((message) => updates(message as OptionalStringConfigKey)) as OptionalStringConfigKey;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OptionalStringConfigKey create() => OptionalStringConfigKey._();
  OptionalStringConfigKey createEmptyInstance() => create();
  static $pb.PbList<OptionalStringConfigKey> createRepeated() => $pb.PbList<OptionalStringConfigKey>();
  @$core.pragma('dart2js:noInline')
  static OptionalStringConfigKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OptionalStringConfigKey>(create);
  static OptionalStringConfigKey? _defaultInstance;

  @$pb.TagNumber(1)
  ConfigKey_String get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(ConfigKey_String v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
}

class SetConfigJsonRequest extends $pb.GeneratedMessage {
  factory SetConfigJsonRequest({
    $core.String? key,
    $core.List<$core.int>? valueJson,
    $core.bool? undoable,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (valueJson != null) {
      $result.valueJson = valueJson;
    }
    if (undoable != null) {
      $result.undoable = undoable;
    }
    return $result;
  }
  SetConfigJsonRequest._() : super();
  factory SetConfigJsonRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetConfigJsonRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetConfigJsonRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'valueJson', $pb.PbFieldType.OY)
    ..aOB(3, _omitFieldNames ? '' : 'undoable')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetConfigJsonRequest clone() => SetConfigJsonRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetConfigJsonRequest copyWith(void Function(SetConfigJsonRequest) updates) => super.copyWith((message) => updates(message as SetConfigJsonRequest)) as SetConfigJsonRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetConfigJsonRequest create() => SetConfigJsonRequest._();
  SetConfigJsonRequest createEmptyInstance() => create();
  static $pb.PbList<SetConfigJsonRequest> createRepeated() => $pb.PbList<SetConfigJsonRequest>();
  @$core.pragma('dart2js:noInline')
  static SetConfigJsonRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetConfigJsonRequest>(create);
  static SetConfigJsonRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get valueJson => $_getN(1);
  @$pb.TagNumber(2)
  set valueJson($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValueJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearValueJson() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get undoable => $_getBF(2);
  @$pb.TagNumber(3)
  set undoable($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUndoable() => $_has(2);
  @$pb.TagNumber(3)
  void clearUndoable() => clearField(3);
}

class Preferences_Scheduling extends $pb.GeneratedMessage {
  factory Preferences_Scheduling({
    $core.int? rollover,
    $core.int? learnAheadSecs,
    Preferences_Scheduling_NewReviewMix? newReviewMix,
    $core.bool? newTimezone,
    $core.bool? dayLearnFirst,
  }) {
    final $result = create();
    if (rollover != null) {
      $result.rollover = rollover;
    }
    if (learnAheadSecs != null) {
      $result.learnAheadSecs = learnAheadSecs;
    }
    if (newReviewMix != null) {
      $result.newReviewMix = newReviewMix;
    }
    if (newTimezone != null) {
      $result.newTimezone = newTimezone;
    }
    if (dayLearnFirst != null) {
      $result.dayLearnFirst = dayLearnFirst;
    }
    return $result;
  }
  Preferences_Scheduling._() : super();
  factory Preferences_Scheduling.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Preferences_Scheduling.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Preferences.Scheduling', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'rollover', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'learnAheadSecs', $pb.PbFieldType.OU3)
    ..e<Preferences_Scheduling_NewReviewMix>(4, _omitFieldNames ? '' : 'newReviewMix', $pb.PbFieldType.OE, defaultOrMaker: Preferences_Scheduling_NewReviewMix.DISTRIBUTE, valueOf: Preferences_Scheduling_NewReviewMix.valueOf, enumValues: Preferences_Scheduling_NewReviewMix.values)
    ..aOB(5, _omitFieldNames ? '' : 'newTimezone')
    ..aOB(6, _omitFieldNames ? '' : 'dayLearnFirst')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Preferences_Scheduling clone() => Preferences_Scheduling()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Preferences_Scheduling copyWith(void Function(Preferences_Scheduling) updates) => super.copyWith((message) => updates(message as Preferences_Scheduling)) as Preferences_Scheduling;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Preferences_Scheduling create() => Preferences_Scheduling._();
  Preferences_Scheduling createEmptyInstance() => create();
  static $pb.PbList<Preferences_Scheduling> createRepeated() => $pb.PbList<Preferences_Scheduling>();
  @$core.pragma('dart2js:noInline')
  static Preferences_Scheduling getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Preferences_Scheduling>(create);
  static Preferences_Scheduling? _defaultInstance;

  @$pb.TagNumber(2)
  $core.int get rollover => $_getIZ(0);
  @$pb.TagNumber(2)
  set rollover($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(2)
  $core.bool hasRollover() => $_has(0);
  @$pb.TagNumber(2)
  void clearRollover() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get learnAheadSecs => $_getIZ(1);
  @$pb.TagNumber(3)
  set learnAheadSecs($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasLearnAheadSecs() => $_has(1);
  @$pb.TagNumber(3)
  void clearLearnAheadSecs() => clearField(3);

  @$pb.TagNumber(4)
  Preferences_Scheduling_NewReviewMix get newReviewMix => $_getN(2);
  @$pb.TagNumber(4)
  set newReviewMix(Preferences_Scheduling_NewReviewMix v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasNewReviewMix() => $_has(2);
  @$pb.TagNumber(4)
  void clearNewReviewMix() => clearField(4);

  /// v2 only
  @$pb.TagNumber(5)
  $core.bool get newTimezone => $_getBF(3);
  @$pb.TagNumber(5)
  set newTimezone($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasNewTimezone() => $_has(3);
  @$pb.TagNumber(5)
  void clearNewTimezone() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get dayLearnFirst => $_getBF(4);
  @$pb.TagNumber(6)
  set dayLearnFirst($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasDayLearnFirst() => $_has(4);
  @$pb.TagNumber(6)
  void clearDayLearnFirst() => clearField(6);
}

class Preferences_Reviewing extends $pb.GeneratedMessage {
  factory Preferences_Reviewing({
    $core.bool? hideAudioPlayButtons,
    $core.bool? interruptAudioWhenAnswering,
    $core.bool? showRemainingDueCounts,
    $core.bool? showIntervalsOnButtons,
    $core.int? timeLimitSecs,
    $core.bool? loadBalancerEnabled,
    $core.bool? fsrsShortTermWithStepsEnabled,
  }) {
    final $result = create();
    if (hideAudioPlayButtons != null) {
      $result.hideAudioPlayButtons = hideAudioPlayButtons;
    }
    if (interruptAudioWhenAnswering != null) {
      $result.interruptAudioWhenAnswering = interruptAudioWhenAnswering;
    }
    if (showRemainingDueCounts != null) {
      $result.showRemainingDueCounts = showRemainingDueCounts;
    }
    if (showIntervalsOnButtons != null) {
      $result.showIntervalsOnButtons = showIntervalsOnButtons;
    }
    if (timeLimitSecs != null) {
      $result.timeLimitSecs = timeLimitSecs;
    }
    if (loadBalancerEnabled != null) {
      $result.loadBalancerEnabled = loadBalancerEnabled;
    }
    if (fsrsShortTermWithStepsEnabled != null) {
      $result.fsrsShortTermWithStepsEnabled = fsrsShortTermWithStepsEnabled;
    }
    return $result;
  }
  Preferences_Reviewing._() : super();
  factory Preferences_Reviewing.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Preferences_Reviewing.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Preferences.Reviewing', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'hideAudioPlayButtons')
    ..aOB(2, _omitFieldNames ? '' : 'interruptAudioWhenAnswering')
    ..aOB(3, _omitFieldNames ? '' : 'showRemainingDueCounts')
    ..aOB(4, _omitFieldNames ? '' : 'showIntervalsOnButtons')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'timeLimitSecs', $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'loadBalancerEnabled')
    ..aOB(7, _omitFieldNames ? '' : 'fsrsShortTermWithStepsEnabled')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Preferences_Reviewing clone() => Preferences_Reviewing()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Preferences_Reviewing copyWith(void Function(Preferences_Reviewing) updates) => super.copyWith((message) => updates(message as Preferences_Reviewing)) as Preferences_Reviewing;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Preferences_Reviewing create() => Preferences_Reviewing._();
  Preferences_Reviewing createEmptyInstance() => create();
  static $pb.PbList<Preferences_Reviewing> createRepeated() => $pb.PbList<Preferences_Reviewing>();
  @$core.pragma('dart2js:noInline')
  static Preferences_Reviewing getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Preferences_Reviewing>(create);
  static Preferences_Reviewing? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hideAudioPlayButtons => $_getBF(0);
  @$pb.TagNumber(1)
  set hideAudioPlayButtons($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHideAudioPlayButtons() => $_has(0);
  @$pb.TagNumber(1)
  void clearHideAudioPlayButtons() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get interruptAudioWhenAnswering => $_getBF(1);
  @$pb.TagNumber(2)
  set interruptAudioWhenAnswering($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInterruptAudioWhenAnswering() => $_has(1);
  @$pb.TagNumber(2)
  void clearInterruptAudioWhenAnswering() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get showRemainingDueCounts => $_getBF(2);
  @$pb.TagNumber(3)
  set showRemainingDueCounts($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasShowRemainingDueCounts() => $_has(2);
  @$pb.TagNumber(3)
  void clearShowRemainingDueCounts() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get showIntervalsOnButtons => $_getBF(3);
  @$pb.TagNumber(4)
  set showIntervalsOnButtons($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasShowIntervalsOnButtons() => $_has(3);
  @$pb.TagNumber(4)
  void clearShowIntervalsOnButtons() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get timeLimitSecs => $_getIZ(4);
  @$pb.TagNumber(5)
  set timeLimitSecs($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTimeLimitSecs() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimeLimitSecs() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get loadBalancerEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set loadBalancerEnabled($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLoadBalancerEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearLoadBalancerEnabled() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get fsrsShortTermWithStepsEnabled => $_getBF(6);
  @$pb.TagNumber(7)
  set fsrsShortTermWithStepsEnabled($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasFsrsShortTermWithStepsEnabled() => $_has(6);
  @$pb.TagNumber(7)
  void clearFsrsShortTermWithStepsEnabled() => clearField(7);
}

class Preferences_Editing extends $pb.GeneratedMessage {
  factory Preferences_Editing({
    $core.bool? addingDefaultsToCurrentDeck,
    $core.bool? pasteImagesAsPng,
    $core.bool? pasteStripsFormatting,
    $core.String? defaultSearchText,
    $core.bool? ignoreAccentsInSearch,
    $core.bool? renderLatex,
  }) {
    final $result = create();
    if (addingDefaultsToCurrentDeck != null) {
      $result.addingDefaultsToCurrentDeck = addingDefaultsToCurrentDeck;
    }
    if (pasteImagesAsPng != null) {
      $result.pasteImagesAsPng = pasteImagesAsPng;
    }
    if (pasteStripsFormatting != null) {
      $result.pasteStripsFormatting = pasteStripsFormatting;
    }
    if (defaultSearchText != null) {
      $result.defaultSearchText = defaultSearchText;
    }
    if (ignoreAccentsInSearch != null) {
      $result.ignoreAccentsInSearch = ignoreAccentsInSearch;
    }
    if (renderLatex != null) {
      $result.renderLatex = renderLatex;
    }
    return $result;
  }
  Preferences_Editing._() : super();
  factory Preferences_Editing.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Preferences_Editing.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Preferences.Editing', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'addingDefaultsToCurrentDeck')
    ..aOB(2, _omitFieldNames ? '' : 'pasteImagesAsPng')
    ..aOB(3, _omitFieldNames ? '' : 'pasteStripsFormatting')
    ..aOS(4, _omitFieldNames ? '' : 'defaultSearchText')
    ..aOB(5, _omitFieldNames ? '' : 'ignoreAccentsInSearch')
    ..aOB(6, _omitFieldNames ? '' : 'renderLatex')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Preferences_Editing clone() => Preferences_Editing()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Preferences_Editing copyWith(void Function(Preferences_Editing) updates) => super.copyWith((message) => updates(message as Preferences_Editing)) as Preferences_Editing;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Preferences_Editing create() => Preferences_Editing._();
  Preferences_Editing createEmptyInstance() => create();
  static $pb.PbList<Preferences_Editing> createRepeated() => $pb.PbList<Preferences_Editing>();
  @$core.pragma('dart2js:noInline')
  static Preferences_Editing getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Preferences_Editing>(create);
  static Preferences_Editing? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get addingDefaultsToCurrentDeck => $_getBF(0);
  @$pb.TagNumber(1)
  set addingDefaultsToCurrentDeck($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAddingDefaultsToCurrentDeck() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddingDefaultsToCurrentDeck() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pasteImagesAsPng => $_getBF(1);
  @$pb.TagNumber(2)
  set pasteImagesAsPng($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPasteImagesAsPng() => $_has(1);
  @$pb.TagNumber(2)
  void clearPasteImagesAsPng() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get pasteStripsFormatting => $_getBF(2);
  @$pb.TagNumber(3)
  set pasteStripsFormatting($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPasteStripsFormatting() => $_has(2);
  @$pb.TagNumber(3)
  void clearPasteStripsFormatting() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get defaultSearchText => $_getSZ(3);
  @$pb.TagNumber(4)
  set defaultSearchText($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDefaultSearchText() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultSearchText() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get ignoreAccentsInSearch => $_getBF(4);
  @$pb.TagNumber(5)
  set ignoreAccentsInSearch($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIgnoreAccentsInSearch() => $_has(4);
  @$pb.TagNumber(5)
  void clearIgnoreAccentsInSearch() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get renderLatex => $_getBF(5);
  @$pb.TagNumber(6)
  set renderLatex($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasRenderLatex() => $_has(5);
  @$pb.TagNumber(6)
  void clearRenderLatex() => clearField(6);
}

class Preferences_BackupLimits extends $pb.GeneratedMessage {
  factory Preferences_BackupLimits({
    $core.int? daily,
    $core.int? weekly,
    $core.int? monthly,
    $core.int? minimumIntervalMins,
  }) {
    final $result = create();
    if (daily != null) {
      $result.daily = daily;
    }
    if (weekly != null) {
      $result.weekly = weekly;
    }
    if (monthly != null) {
      $result.monthly = monthly;
    }
    if (minimumIntervalMins != null) {
      $result.minimumIntervalMins = minimumIntervalMins;
    }
    return $result;
  }
  Preferences_BackupLimits._() : super();
  factory Preferences_BackupLimits.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Preferences_BackupLimits.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Preferences.BackupLimits', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'daily', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'weekly', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'monthly', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'minimumIntervalMins', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Preferences_BackupLimits clone() => Preferences_BackupLimits()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Preferences_BackupLimits copyWith(void Function(Preferences_BackupLimits) updates) => super.copyWith((message) => updates(message as Preferences_BackupLimits)) as Preferences_BackupLimits;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Preferences_BackupLimits create() => Preferences_BackupLimits._();
  Preferences_BackupLimits createEmptyInstance() => create();
  static $pb.PbList<Preferences_BackupLimits> createRepeated() => $pb.PbList<Preferences_BackupLimits>();
  @$core.pragma('dart2js:noInline')
  static Preferences_BackupLimits getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Preferences_BackupLimits>(create);
  static Preferences_BackupLimits? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get daily => $_getIZ(0);
  @$pb.TagNumber(1)
  set daily($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDaily() => $_has(0);
  @$pb.TagNumber(1)
  void clearDaily() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get weekly => $_getIZ(1);
  @$pb.TagNumber(2)
  set weekly($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWeekly() => $_has(1);
  @$pb.TagNumber(2)
  void clearWeekly() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get monthly => $_getIZ(2);
  @$pb.TagNumber(3)
  set monthly($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMonthly() => $_has(2);
  @$pb.TagNumber(3)
  void clearMonthly() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get minimumIntervalMins => $_getIZ(3);
  @$pb.TagNumber(4)
  set minimumIntervalMins($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMinimumIntervalMins() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinimumIntervalMins() => clearField(4);
}

class Preferences extends $pb.GeneratedMessage {
  factory Preferences({
    Preferences_Scheduling? scheduling,
    Preferences_Reviewing? reviewing,
    Preferences_Editing? editing,
    Preferences_BackupLimits? backups,
  }) {
    final $result = create();
    if (scheduling != null) {
      $result.scheduling = scheduling;
    }
    if (reviewing != null) {
      $result.reviewing = reviewing;
    }
    if (editing != null) {
      $result.editing = editing;
    }
    if (backups != null) {
      $result.backups = backups;
    }
    return $result;
  }
  Preferences._() : super();
  factory Preferences.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Preferences.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Preferences', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.config'), createEmptyInstance: create)
    ..aOM<Preferences_Scheduling>(1, _omitFieldNames ? '' : 'scheduling', subBuilder: Preferences_Scheduling.create)
    ..aOM<Preferences_Reviewing>(2, _omitFieldNames ? '' : 'reviewing', subBuilder: Preferences_Reviewing.create)
    ..aOM<Preferences_Editing>(3, _omitFieldNames ? '' : 'editing', subBuilder: Preferences_Editing.create)
    ..aOM<Preferences_BackupLimits>(4, _omitFieldNames ? '' : 'backups', subBuilder: Preferences_BackupLimits.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Preferences clone() => Preferences()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Preferences copyWith(void Function(Preferences) updates) => super.copyWith((message) => updates(message as Preferences)) as Preferences;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Preferences create() => Preferences._();
  Preferences createEmptyInstance() => create();
  static $pb.PbList<Preferences> createRepeated() => $pb.PbList<Preferences>();
  @$core.pragma('dart2js:noInline')
  static Preferences getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Preferences>(create);
  static Preferences? _defaultInstance;

  @$pb.TagNumber(1)
  Preferences_Scheduling get scheduling => $_getN(0);
  @$pb.TagNumber(1)
  set scheduling(Preferences_Scheduling v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasScheduling() => $_has(0);
  @$pb.TagNumber(1)
  void clearScheduling() => clearField(1);
  @$pb.TagNumber(1)
  Preferences_Scheduling ensureScheduling() => $_ensure(0);

  @$pb.TagNumber(2)
  Preferences_Reviewing get reviewing => $_getN(1);
  @$pb.TagNumber(2)
  set reviewing(Preferences_Reviewing v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasReviewing() => $_has(1);
  @$pb.TagNumber(2)
  void clearReviewing() => clearField(2);
  @$pb.TagNumber(2)
  Preferences_Reviewing ensureReviewing() => $_ensure(1);

  @$pb.TagNumber(3)
  Preferences_Editing get editing => $_getN(2);
  @$pb.TagNumber(3)
  set editing(Preferences_Editing v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEditing() => $_has(2);
  @$pb.TagNumber(3)
  void clearEditing() => clearField(3);
  @$pb.TagNumber(3)
  Preferences_Editing ensureEditing() => $_ensure(2);

  @$pb.TagNumber(4)
  Preferences_BackupLimits get backups => $_getN(3);
  @$pb.TagNumber(4)
  set backups(Preferences_BackupLimits v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasBackups() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackups() => clearField(4);
  @$pb.TagNumber(4)
  Preferences_BackupLimits ensureBackups() => $_ensure(3);
}

class ConfigServiceApi {
  $pb.RpcClient _client;
  ConfigServiceApi(this._client);

  $async.Future<$0.Json> getConfigJson($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$0.Json>(ctx, 'ConfigService', 'GetConfigJson', request, $0.Json())
  ;
  $async.Future<$2.OpChanges> setConfigJson($pb.ClientContext? ctx, SetConfigJsonRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ConfigService', 'SetConfigJson', request, $2.OpChanges())
  ;
  $async.Future<$0.Empty> setConfigJsonNoUndo($pb.ClientContext? ctx, SetConfigJsonRequest request) =>
    _client.invoke<$0.Empty>(ctx, 'ConfigService', 'SetConfigJsonNoUndo', request, $0.Empty())
  ;
  $async.Future<$2.OpChanges> removeConfig($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ConfigService', 'RemoveConfig', request, $2.OpChanges())
  ;
  $async.Future<$0.Json> getAllConfig($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Json>(ctx, 'ConfigService', 'GetAllConfig', request, $0.Json())
  ;
  $async.Future<$0.Bool> getConfigBool($pb.ClientContext? ctx, GetConfigBoolRequest request) =>
    _client.invoke<$0.Bool>(ctx, 'ConfigService', 'GetConfigBool', request, $0.Bool())
  ;
  $async.Future<$2.OpChanges> setConfigBool($pb.ClientContext? ctx, SetConfigBoolRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ConfigService', 'SetConfigBool', request, $2.OpChanges())
  ;
  $async.Future<$0.String> getConfigString($pb.ClientContext? ctx, GetConfigStringRequest request) =>
    _client.invoke<$0.String>(ctx, 'ConfigService', 'GetConfigString', request, $0.String())
  ;
  $async.Future<$2.OpChanges> setConfigString($pb.ClientContext? ctx, SetConfigStringRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ConfigService', 'SetConfigString', request, $2.OpChanges())
  ;
  $async.Future<Preferences> getPreferences($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<Preferences>(ctx, 'ConfigService', 'GetPreferences', request, Preferences())
  ;
  $async.Future<$2.OpChanges> setPreferences($pb.ClientContext? ctx, Preferences request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ConfigService', 'SetPreferences', request, $2.OpChanges())
  ;
}

class BackendConfigServiceApi {
  $pb.RpcClient _client;
  BackendConfigServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
