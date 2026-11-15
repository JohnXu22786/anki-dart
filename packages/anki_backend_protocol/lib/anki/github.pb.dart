// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/github.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'generic.pb.dart' as $0;

class LatestReleaseRequest extends $pb.GeneratedMessage {
  factory LatestReleaseRequest({
    $core.bool? includePrerelease,
  }) {
    final $result = create();
    if (includePrerelease != null) {
      $result.includePrerelease = includePrerelease;
    }
    return $result;
  }
  LatestReleaseRequest._() : super();
  factory LatestReleaseRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LatestReleaseRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LatestReleaseRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.github'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includePrerelease')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LatestReleaseRequest clone() => LatestReleaseRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LatestReleaseRequest copyWith(void Function(LatestReleaseRequest) updates) => super.copyWith((message) => updates(message as LatestReleaseRequest)) as LatestReleaseRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LatestReleaseRequest create() => LatestReleaseRequest._();
  LatestReleaseRequest createEmptyInstance() => create();
  static $pb.PbList<LatestReleaseRequest> createRepeated() => $pb.PbList<LatestReleaseRequest>();
  @$core.pragma('dart2js:noInline')
  static LatestReleaseRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LatestReleaseRequest>(create);
  static LatestReleaseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get includePrerelease => $_getBF(0);
  @$pb.TagNumber(1)
  set includePrerelease($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIncludePrerelease() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludePrerelease() => clearField(1);
}

class GithubRelease extends $pb.GeneratedMessage {
  factory GithubRelease({
    $core.String? tagName,
    $core.String? filename,
    $core.String? url,
    $core.String? checksum,
  }) {
    final $result = create();
    if (tagName != null) {
      $result.tagName = tagName;
    }
    if (filename != null) {
      $result.filename = filename;
    }
    if (url != null) {
      $result.url = url;
    }
    if (checksum != null) {
      $result.checksum = checksum;
    }
    return $result;
  }
  GithubRelease._() : super();
  factory GithubRelease.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GithubRelease.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GithubRelease', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.github'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tagName')
    ..aOS(2, _omitFieldNames ? '' : 'filename')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..aOS(4, _omitFieldNames ? '' : 'checksum')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GithubRelease clone() => GithubRelease()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GithubRelease copyWith(void Function(GithubRelease) updates) => super.copyWith((message) => updates(message as GithubRelease)) as GithubRelease;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GithubRelease create() => GithubRelease._();
  GithubRelease createEmptyInstance() => create();
  static $pb.PbList<GithubRelease> createRepeated() => $pb.PbList<GithubRelease>();
  @$core.pragma('dart2js:noInline')
  static GithubRelease getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GithubRelease>(create);
  static GithubRelease? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tagName => $_getSZ(0);
  @$pb.TagNumber(1)
  set tagName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTagName() => $_has(0);
  @$pb.TagNumber(1)
  void clearTagName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get filename => $_getSZ(1);
  @$pb.TagNumber(2)
  set filename($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilename() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get checksum => $_getSZ(3);
  @$pb.TagNumber(4)
  set checksum($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasChecksum() => $_has(3);
  @$pb.TagNumber(4)
  void clearChecksum() => clearField(4);
}

class GithubServiceApi {
  $pb.RpcClient _client;
  GithubServiceApi(this._client);

}

class BackendGithubServiceApi {
  $pb.RpcClient _client;
  BackendGithubServiceApi(this._client);

  $async.Future<GithubRelease> getLatestRelease($pb.ClientContext? ctx, LatestReleaseRequest request) =>
    _client.invoke<GithubRelease>(ctx, 'BackendGithubService', 'GetLatestRelease', request, GithubRelease())
  ;
  $async.Future<$0.String> downloadRelease($pb.ClientContext? ctx, GithubRelease request) =>
    _client.invoke<$0.String>(ctx, 'BackendGithubService', 'DownloadRelease', request, $0.String())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
