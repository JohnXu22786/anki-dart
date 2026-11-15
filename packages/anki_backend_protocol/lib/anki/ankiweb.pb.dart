//
//  Generated code. Do not modify.
//  source: anki/ankiweb.proto
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

class GetAddonInfoRequest extends $pb.GeneratedMessage {
  factory GetAddonInfoRequest({
    $core.int? clientVersion,
    $core.Iterable<$core.int>? addonIds,
  }) {
    final $result = create();
    if (clientVersion != null) {
      $result.clientVersion = clientVersion;
    }
    if (addonIds != null) {
      $result.addonIds.addAll(addonIds);
    }
    return $result;
  }
  GetAddonInfoRequest._() : super();
  factory GetAddonInfoRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAddonInfoRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAddonInfoRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankiweb'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'clientVersion', $pb.PbFieldType.OU3)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'addonIds', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAddonInfoRequest clone() => GetAddonInfoRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAddonInfoRequest copyWith(void Function(GetAddonInfoRequest) updates) => super.copyWith((message) => updates(message as GetAddonInfoRequest)) as GetAddonInfoRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAddonInfoRequest create() => GetAddonInfoRequest._();
  GetAddonInfoRequest createEmptyInstance() => create();
  static $pb.PbList<GetAddonInfoRequest> createRepeated() => $pb.PbList<GetAddonInfoRequest>();
  @$core.pragma('dart2js:noInline')
  static GetAddonInfoRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAddonInfoRequest>(create);
  static GetAddonInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get clientVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set clientVersion($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasClientVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientVersion() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get addonIds => $_getList(1);
}

class GetAddonInfoResponse extends $pb.GeneratedMessage {
  factory GetAddonInfoResponse({
    $core.Iterable<AddonInfo>? info,
  }) {
    final $result = create();
    if (info != null) {
      $result.info.addAll(info);
    }
    return $result;
  }
  GetAddonInfoResponse._() : super();
  factory GetAddonInfoResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAddonInfoResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAddonInfoResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankiweb'), createEmptyInstance: create)
    ..pc<AddonInfo>(1, _omitFieldNames ? '' : 'info', $pb.PbFieldType.PM, subBuilder: AddonInfo.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAddonInfoResponse clone() => GetAddonInfoResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAddonInfoResponse copyWith(void Function(GetAddonInfoResponse) updates) => super.copyWith((message) => updates(message as GetAddonInfoResponse)) as GetAddonInfoResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAddonInfoResponse create() => GetAddonInfoResponse._();
  GetAddonInfoResponse createEmptyInstance() => create();
  static $pb.PbList<GetAddonInfoResponse> createRepeated() => $pb.PbList<GetAddonInfoResponse>();
  @$core.pragma('dart2js:noInline')
  static GetAddonInfoResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAddonInfoResponse>(create);
  static GetAddonInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<AddonInfo> get info => $_getList(0);
}

class AddonInfo extends $pb.GeneratedMessage {
  factory AddonInfo({
    $core.int? id,
    $fixnum.Int64? modified,
    $core.int? minVersion,
    $core.int? maxVersion,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (modified != null) {
      $result.modified = modified;
    }
    if (minVersion != null) {
      $result.minVersion = minVersion;
    }
    if (maxVersion != null) {
      $result.maxVersion = maxVersion;
    }
    return $result;
  }
  AddonInfo._() : super();
  factory AddonInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddonInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddonInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankiweb'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU3)
    ..aInt64(2, _omitFieldNames ? '' : 'modified')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'minVersion', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'maxVersion', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddonInfo clone() => AddonInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddonInfo copyWith(void Function(AddonInfo) updates) => super.copyWith((message) => updates(message as AddonInfo)) as AddonInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddonInfo create() => AddonInfo._();
  AddonInfo createEmptyInstance() => create();
  static $pb.PbList<AddonInfo> createRepeated() => $pb.PbList<AddonInfo>();
  @$core.pragma('dart2js:noInline')
  static AddonInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddonInfo>(create);
  static AddonInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get modified => $_getI64(1);
  @$pb.TagNumber(2)
  set modified($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasModified() => $_has(1);
  @$pb.TagNumber(2)
  void clearModified() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get minVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set minVersion($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMinVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearMinVersion() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxVersion => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxVersion($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMaxVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxVersion() => clearField(4);
}

class CheckForUpdateRequest extends $pb.GeneratedMessage {
  factory CheckForUpdateRequest({
    $core.int? version,
    $core.String? buildhash,
    $core.String? os,
    $fixnum.Int64? installId,
    $core.int? lastMessageId,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    if (buildhash != null) {
      $result.buildhash = buildhash;
    }
    if (os != null) {
      $result.os = os;
    }
    if (installId != null) {
      $result.installId = installId;
    }
    if (lastMessageId != null) {
      $result.lastMessageId = lastMessageId;
    }
    return $result;
  }
  CheckForUpdateRequest._() : super();
  factory CheckForUpdateRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckForUpdateRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CheckForUpdateRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankiweb'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'buildhash')
    ..aOS(3, _omitFieldNames ? '' : 'os')
    ..aInt64(4, _omitFieldNames ? '' : 'installId')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'lastMessageId', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckForUpdateRequest clone() => CheckForUpdateRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckForUpdateRequest copyWith(void Function(CheckForUpdateRequest) updates) => super.copyWith((message) => updates(message as CheckForUpdateRequest)) as CheckForUpdateRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckForUpdateRequest create() => CheckForUpdateRequest._();
  CheckForUpdateRequest createEmptyInstance() => create();
  static $pb.PbList<CheckForUpdateRequest> createRepeated() => $pb.PbList<CheckForUpdateRequest>();
  @$core.pragma('dart2js:noInline')
  static CheckForUpdateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckForUpdateRequest>(create);
  static CheckForUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get buildhash => $_getSZ(1);
  @$pb.TagNumber(2)
  set buildhash($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBuildhash() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuildhash() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get os => $_getSZ(2);
  @$pb.TagNumber(3)
  set os($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOs() => $_has(2);
  @$pb.TagNumber(3)
  void clearOs() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get installId => $_getI64(3);
  @$pb.TagNumber(4)
  set installId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasInstallId() => $_has(3);
  @$pb.TagNumber(4)
  void clearInstallId() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get lastMessageId => $_getIZ(4);
  @$pb.TagNumber(5)
  set lastMessageId($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLastMessageId() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastMessageId() => clearField(5);
}

class CheckForUpdateResponse extends $pb.GeneratedMessage {
  factory CheckForUpdateResponse({
    $core.String? newVersion,
    $fixnum.Int64? currentTime,
    $core.String? message,
    $core.int? lastMessageId,
  }) {
    final $result = create();
    if (newVersion != null) {
      $result.newVersion = newVersion;
    }
    if (currentTime != null) {
      $result.currentTime = currentTime;
    }
    if (message != null) {
      $result.message = message;
    }
    if (lastMessageId != null) {
      $result.lastMessageId = lastMessageId;
    }
    return $result;
  }
  CheckForUpdateResponse._() : super();
  factory CheckForUpdateResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckForUpdateResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CheckForUpdateResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankiweb'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'newVersion')
    ..aInt64(2, _omitFieldNames ? '' : 'currentTime')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'lastMessageId', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckForUpdateResponse clone() => CheckForUpdateResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckForUpdateResponse copyWith(void Function(CheckForUpdateResponse) updates) => super.copyWith((message) => updates(message as CheckForUpdateResponse)) as CheckForUpdateResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckForUpdateResponse create() => CheckForUpdateResponse._();
  CheckForUpdateResponse createEmptyInstance() => create();
  static $pb.PbList<CheckForUpdateResponse> createRepeated() => $pb.PbList<CheckForUpdateResponse>();
  @$core.pragma('dart2js:noInline')
  static CheckForUpdateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckForUpdateResponse>(create);
  static CheckForUpdateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get newVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set newVersion($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNewVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearNewVersion() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get currentTime => $_getI64(1);
  @$pb.TagNumber(2)
  set currentTime($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCurrentTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrentTime() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get lastMessageId => $_getIZ(3);
  @$pb.TagNumber(4)
  set lastMessageId($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLastMessageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastMessageId() => clearField(4);
}

class AnkiwebServiceApi {
  $pb.RpcClient _client;
  AnkiwebServiceApi(this._client);

}

class BackendAnkiwebServiceApi {
  $pb.RpcClient _client;
  BackendAnkiwebServiceApi(this._client);

  $async.Future<GetAddonInfoResponse> getAddonInfo($pb.ClientContext? ctx, GetAddonInfoRequest request) =>
    _client.invoke<GetAddonInfoResponse>(ctx, 'BackendAnkiwebService', 'GetAddonInfo', request, GetAddonInfoResponse())
  ;
  $async.Future<CheckForUpdateResponse> checkForUpdate($pb.ClientContext? ctx, CheckForUpdateRequest request) =>
    _client.invoke<CheckForUpdateResponse>(ctx, 'BackendAnkiwebService', 'CheckForUpdate', request, CheckForUpdateResponse())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
