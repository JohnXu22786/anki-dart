// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/media.proto
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

import 'generic.pb.dart' as $0;
import 'notetypes.pb.dart' as $12;

class CheckMediaResponse extends $pb.GeneratedMessage {
  factory CheckMediaResponse({
    $core.Iterable<$core.String>? unused,
    $core.Iterable<$core.String>? missing,
    $core.Iterable<$fixnum.Int64>? missingMediaNotes,
    $core.String? report,
    $core.bool? haveTrash,
  }) {
    final $result = create();
    if (unused != null) {
      $result.unused.addAll(unused);
    }
    if (missing != null) {
      $result.missing.addAll(missing);
    }
    if (missingMediaNotes != null) {
      $result.missingMediaNotes.addAll(missingMediaNotes);
    }
    if (report != null) {
      $result.report = report;
    }
    if (haveTrash != null) {
      $result.haveTrash = haveTrash;
    }
    return $result;
  }
  CheckMediaResponse._() : super();
  factory CheckMediaResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckMediaResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CheckMediaResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.media'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'unused')
    ..pPS(2, _omitFieldNames ? '' : 'missing')
    ..p<$fixnum.Int64>(3, _omitFieldNames ? '' : 'missingMediaNotes', $pb.PbFieldType.K6)
    ..aOS(4, _omitFieldNames ? '' : 'report')
    ..aOB(5, _omitFieldNames ? '' : 'haveTrash')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckMediaResponse clone() => CheckMediaResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckMediaResponse copyWith(void Function(CheckMediaResponse) updates) => super.copyWith((message) => updates(message as CheckMediaResponse)) as CheckMediaResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckMediaResponse create() => CheckMediaResponse._();
  CheckMediaResponse createEmptyInstance() => create();
  static $pb.PbList<CheckMediaResponse> createRepeated() => $pb.PbList<CheckMediaResponse>();
  @$core.pragma('dart2js:noInline')
  static CheckMediaResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckMediaResponse>(create);
  static CheckMediaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get unused => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get missing => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$fixnum.Int64> get missingMediaNotes => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get report => $_getSZ(3);
  @$pb.TagNumber(4)
  set report($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasReport() => $_has(3);
  @$pb.TagNumber(4)
  void clearReport() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get haveTrash => $_getBF(4);
  @$pb.TagNumber(5)
  set haveTrash($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasHaveTrash() => $_has(4);
  @$pb.TagNumber(5)
  void clearHaveTrash() => clearField(5);
}

class TrashMediaFilesRequest extends $pb.GeneratedMessage {
  factory TrashMediaFilesRequest({
    $core.Iterable<$core.String>? fnames,
  }) {
    final $result = create();
    if (fnames != null) {
      $result.fnames.addAll(fnames);
    }
    return $result;
  }
  TrashMediaFilesRequest._() : super();
  factory TrashMediaFilesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TrashMediaFilesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TrashMediaFilesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.media'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'fnames')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TrashMediaFilesRequest clone() => TrashMediaFilesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TrashMediaFilesRequest copyWith(void Function(TrashMediaFilesRequest) updates) => super.copyWith((message) => updates(message as TrashMediaFilesRequest)) as TrashMediaFilesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrashMediaFilesRequest create() => TrashMediaFilesRequest._();
  TrashMediaFilesRequest createEmptyInstance() => create();
  static $pb.PbList<TrashMediaFilesRequest> createRepeated() => $pb.PbList<TrashMediaFilesRequest>();
  @$core.pragma('dart2js:noInline')
  static TrashMediaFilesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrashMediaFilesRequest>(create);
  static TrashMediaFilesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get fnames => $_getList(0);
}

class AddMediaFileRequest extends $pb.GeneratedMessage {
  factory AddMediaFileRequest({
    $core.String? desiredName,
    $core.List<$core.int>? data,
  }) {
    final $result = create();
    if (desiredName != null) {
      $result.desiredName = desiredName;
    }
    if (data != null) {
      $result.data = data;
    }
    return $result;
  }
  AddMediaFileRequest._() : super();
  factory AddMediaFileRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddMediaFileRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddMediaFileRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.media'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'desiredName')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddMediaFileRequest clone() => AddMediaFileRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddMediaFileRequest copyWith(void Function(AddMediaFileRequest) updates) => super.copyWith((message) => updates(message as AddMediaFileRequest)) as AddMediaFileRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddMediaFileRequest create() => AddMediaFileRequest._();
  AddMediaFileRequest createEmptyInstance() => create();
  static $pb.PbList<AddMediaFileRequest> createRepeated() => $pb.PbList<AddMediaFileRequest>();
  @$core.pragma('dart2js:noInline')
  static AddMediaFileRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddMediaFileRequest>(create);
  static AddMediaFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get desiredName => $_getSZ(0);
  @$pb.TagNumber(1)
  set desiredName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDesiredName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDesiredName() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

class MediaServiceApi {
  $pb.RpcClient _client;
  MediaServiceApi(this._client);

  $async.Future<CheckMediaResponse> checkMedia($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<CheckMediaResponse>(ctx, 'MediaService', 'CheckMedia', request, CheckMediaResponse())
  ;
  $async.Future<$0.String> addMediaFile($pb.ClientContext? ctx, AddMediaFileRequest request) =>
    _client.invoke<$0.String>(ctx, 'MediaService', 'AddMediaFile', request, $0.String())
  ;
  $async.Future<$0.Empty> trashMediaFiles($pb.ClientContext? ctx, TrashMediaFilesRequest request) =>
    _client.invoke<$0.Empty>(ctx, 'MediaService', 'TrashMediaFiles', request, $0.Empty())
  ;
  $async.Future<$0.Empty> emptyTrash($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'MediaService', 'EmptyTrash', request, $0.Empty())
  ;
  $async.Future<$0.Empty> restoreTrash($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'MediaService', 'RestoreTrash', request, $0.Empty())
  ;
  $async.Future<$0.StringList> extractStaticMediaFiles($pb.ClientContext? ctx, $12.NotetypeId request) =>
    _client.invoke<$0.StringList>(ctx, 'MediaService', 'ExtractStaticMediaFiles', request, $0.StringList())
  ;
}

class BackendMediaServiceApi {
  $pb.RpcClient _client;
  BackendMediaServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
