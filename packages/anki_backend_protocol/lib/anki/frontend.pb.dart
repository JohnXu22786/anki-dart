//
//  Generated code. Do not modify.
//  source: anki/frontend.proto
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
import 'scheduler.pb.dart' as $7;
import 'search.pb.dart' as $15;

class SchedulingStatesWithContext extends $pb.GeneratedMessage {
  factory SchedulingStatesWithContext({
    $7.SchedulingStates? states,
    $7.SchedulingContext? context,
  }) {
    final $result = create();
    if (states != null) {
      $result.states = states;
    }
    if (context != null) {
      $result.context = context;
    }
    return $result;
  }
  SchedulingStatesWithContext._() : super();
  factory SchedulingStatesWithContext.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SchedulingStatesWithContext.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SchedulingStatesWithContext', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.frontend'), createEmptyInstance: create)
    ..aOM<$7.SchedulingStates>(1, _omitFieldNames ? '' : 'states', subBuilder: $7.SchedulingStates.create)
    ..aOM<$7.SchedulingContext>(2, _omitFieldNames ? '' : 'context', subBuilder: $7.SchedulingContext.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SchedulingStatesWithContext clone() => SchedulingStatesWithContext()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SchedulingStatesWithContext copyWith(void Function(SchedulingStatesWithContext) updates) => super.copyWith((message) => updates(message as SchedulingStatesWithContext)) as SchedulingStatesWithContext;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchedulingStatesWithContext create() => SchedulingStatesWithContext._();
  SchedulingStatesWithContext createEmptyInstance() => create();
  static $pb.PbList<SchedulingStatesWithContext> createRepeated() => $pb.PbList<SchedulingStatesWithContext>();
  @$core.pragma('dart2js:noInline')
  static SchedulingStatesWithContext getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SchedulingStatesWithContext>(create);
  static SchedulingStatesWithContext? _defaultInstance;

  @$pb.TagNumber(1)
  $7.SchedulingStates get states => $_getN(0);
  @$pb.TagNumber(1)
  set states($7.SchedulingStates v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStates() => $_has(0);
  @$pb.TagNumber(1)
  void clearStates() => clearField(1);
  @$pb.TagNumber(1)
  $7.SchedulingStates ensureStates() => $_ensure(0);

  @$pb.TagNumber(2)
  $7.SchedulingContext get context => $_getN(1);
  @$pb.TagNumber(2)
  set context($7.SchedulingContext v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasContext() => $_has(1);
  @$pb.TagNumber(2)
  void clearContext() => clearField(2);
  @$pb.TagNumber(2)
  $7.SchedulingContext ensureContext() => $_ensure(1);
}

class SetSchedulingStatesRequest extends $pb.GeneratedMessage {
  factory SetSchedulingStatesRequest({
    $core.String? key,
    $7.SchedulingStates? states,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (states != null) {
      $result.states = states;
    }
    return $result;
  }
  SetSchedulingStatesRequest._() : super();
  factory SetSchedulingStatesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetSchedulingStatesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetSchedulingStatesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.frontend'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOM<$7.SchedulingStates>(2, _omitFieldNames ? '' : 'states', subBuilder: $7.SchedulingStates.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetSchedulingStatesRequest clone() => SetSchedulingStatesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetSchedulingStatesRequest copyWith(void Function(SetSchedulingStatesRequest) updates) => super.copyWith((message) => updates(message as SetSchedulingStatesRequest)) as SetSchedulingStatesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSchedulingStatesRequest create() => SetSchedulingStatesRequest._();
  SetSchedulingStatesRequest createEmptyInstance() => create();
  static $pb.PbList<SetSchedulingStatesRequest> createRepeated() => $pb.PbList<SetSchedulingStatesRequest>();
  @$core.pragma('dart2js:noInline')
  static SetSchedulingStatesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetSchedulingStatesRequest>(create);
  static SetSchedulingStatesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $7.SchedulingStates get states => $_getN(1);
  @$pb.TagNumber(2)
  set states($7.SchedulingStates v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasStates() => $_has(1);
  @$pb.TagNumber(2)
  void clearStates() => clearField(2);
  @$pb.TagNumber(2)
  $7.SchedulingStates ensureStates() => $_ensure(1);
}

class FrontendServiceApi {
  $pb.RpcClient _client;
  FrontendServiceApi(this._client);

  $async.Future<SchedulingStatesWithContext> getSchedulingStatesWithContext($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<SchedulingStatesWithContext>(ctx, 'FrontendService', 'GetSchedulingStatesWithContext', request, SchedulingStatesWithContext())
  ;
  $async.Future<$0.Empty> setSchedulingStates($pb.ClientContext? ctx, SetSchedulingStatesRequest request) =>
    _client.invoke<$0.Empty>(ctx, 'FrontendService', 'SetSchedulingStates', request, $0.Empty())
  ;
  $async.Future<$0.Empty> importDone($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'FrontendService', 'ImportDone', request, $0.Empty())
  ;
  $async.Future<$0.Empty> searchInBrowser($pb.ClientContext? ctx, $15.SearchNode request) =>
    _client.invoke<$0.Empty>(ctx, 'FrontendService', 'SearchInBrowser', request, $0.Empty())
  ;
  $async.Future<$0.Empty> deckOptionsRequireClose($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'FrontendService', 'deckOptionsRequireClose', request, $0.Empty())
  ;
  $async.Future<$0.Empty> deckOptionsReady($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'FrontendService', 'deckOptionsReady', request, $0.Empty())
  ;
  $async.Future<$0.Empty> saveCustomColours($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'FrontendService', 'SaveCustomColours', request, $0.Empty())
  ;
}

class BackendFrontendServiceApi {
  $pb.RpcClient _client;
  BackendFrontendServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
