//
//  Generated code. Do not modify.
//  source: anki/links.proto
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
import 'links.pbenum.dart';

export 'links.pbenum.dart';

class HelpPageLinkRequest extends $pb.GeneratedMessage {
  factory HelpPageLinkRequest({
    HelpPageLinkRequest_HelpPage? page,
  }) {
    final $result = create();
    if (page != null) {
      $result.page = page;
    }
    return $result;
  }
  HelpPageLinkRequest._() : super();
  factory HelpPageLinkRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HelpPageLinkRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HelpPageLinkRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.links'), createEmptyInstance: create)
    ..e<HelpPageLinkRequest_HelpPage>(1, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OE, defaultOrMaker: HelpPageLinkRequest_HelpPage.NOTE_TYPE, valueOf: HelpPageLinkRequest_HelpPage.valueOf, enumValues: HelpPageLinkRequest_HelpPage.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HelpPageLinkRequest clone() => HelpPageLinkRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HelpPageLinkRequest copyWith(void Function(HelpPageLinkRequest) updates) => super.copyWith((message) => updates(message as HelpPageLinkRequest)) as HelpPageLinkRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HelpPageLinkRequest create() => HelpPageLinkRequest._();
  HelpPageLinkRequest createEmptyInstance() => create();
  static $pb.PbList<HelpPageLinkRequest> createRepeated() => $pb.PbList<HelpPageLinkRequest>();
  @$core.pragma('dart2js:noInline')
  static HelpPageLinkRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HelpPageLinkRequest>(create);
  static HelpPageLinkRequest? _defaultInstance;

  @$pb.TagNumber(1)
  HelpPageLinkRequest_HelpPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(HelpPageLinkRequest_HelpPage v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => clearField(1);
}

class LinksServiceApi {
  $pb.RpcClient _client;
  LinksServiceApi(this._client);

  $async.Future<$0.String> helpPageLink($pb.ClientContext? ctx, HelpPageLinkRequest request) =>
    _client.invoke<$0.String>(ctx, 'LinksService', 'HelpPageLink', request, $0.String())
  ;
}

class BackendLinksServiceApi {
  $pb.RpcClient _client;
  BackendLinksServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
