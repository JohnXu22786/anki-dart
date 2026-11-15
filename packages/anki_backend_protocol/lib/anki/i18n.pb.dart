// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/i18n.proto
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
import 'i18n.pbenum.dart';

export 'i18n.pbenum.dart';

class TranslateStringRequest extends $pb.GeneratedMessage {
  factory TranslateStringRequest({
    $core.int? moduleIndex,
    $core.int? messageIndex,
    $core.Map<$core.String, TranslateArgValue>? args,
  }) {
    final $result = create();
    if (moduleIndex != null) {
      $result.moduleIndex = moduleIndex;
    }
    if (messageIndex != null) {
      $result.messageIndex = messageIndex;
    }
    if (args != null) {
      $result.args.addAll(args);
    }
    return $result;
  }
  TranslateStringRequest._() : super();
  factory TranslateStringRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TranslateStringRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TranslateStringRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.i18n'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'moduleIndex', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'messageIndex', $pb.PbFieldType.OU3)
    ..m<$core.String, TranslateArgValue>(3, _omitFieldNames ? '' : 'args', entryClassName: 'TranslateStringRequest.ArgsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: TranslateArgValue.create, valueDefaultOrMaker: TranslateArgValue.getDefault, packageName: const $pb.PackageName('anki.i18n'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TranslateStringRequest clone() => TranslateStringRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TranslateStringRequest copyWith(void Function(TranslateStringRequest) updates) => super.copyWith((message) => updates(message as TranslateStringRequest)) as TranslateStringRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranslateStringRequest create() => TranslateStringRequest._();
  TranslateStringRequest createEmptyInstance() => create();
  static $pb.PbList<TranslateStringRequest> createRepeated() => $pb.PbList<TranslateStringRequest>();
  @$core.pragma('dart2js:noInline')
  static TranslateStringRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TranslateStringRequest>(create);
  static TranslateStringRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get moduleIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set moduleIndex($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasModuleIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearModuleIndex() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get messageIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set messageIndex($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessageIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageIndex() => clearField(2);

  @$pb.TagNumber(3)
  $core.Map<$core.String, TranslateArgValue> get args => $_getMap(2);
}

enum TranslateArgValue_Value {
  str,
  number,
  notSet
}

class TranslateArgValue extends $pb.GeneratedMessage {
  factory TranslateArgValue({
    $core.String? str,
    $core.double? number,
  }) {
    final $result = create();
    if (str != null) {
      $result.str = str;
    }
    if (number != null) {
      $result.number = number;
    }
    return $result;
  }
  TranslateArgValue._() : super();
  factory TranslateArgValue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TranslateArgValue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, TranslateArgValue_Value> _TranslateArgValue_ValueByTag = {
    1 : TranslateArgValue_Value.str,
    2 : TranslateArgValue_Value.number,
    0 : TranslateArgValue_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TranslateArgValue', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.i18n'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'str')
    ..a<$core.double>(2, _omitFieldNames ? '' : 'number', $pb.PbFieldType.OD)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TranslateArgValue clone() => TranslateArgValue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TranslateArgValue copyWith(void Function(TranslateArgValue) updates) => super.copyWith((message) => updates(message as TranslateArgValue)) as TranslateArgValue;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranslateArgValue create() => TranslateArgValue._();
  TranslateArgValue createEmptyInstance() => create();
  static $pb.PbList<TranslateArgValue> createRepeated() => $pb.PbList<TranslateArgValue>();
  @$core.pragma('dart2js:noInline')
  static TranslateArgValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TranslateArgValue>(create);
  static TranslateArgValue? _defaultInstance;

  TranslateArgValue_Value whichValue() => _TranslateArgValue_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get str => $_getSZ(0);
  @$pb.TagNumber(1)
  set str($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStr() => $_has(0);
  @$pb.TagNumber(1)
  void clearStr() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get number => $_getN(1);
  @$pb.TagNumber(2)
  set number($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => clearField(2);
}

class FormatTimespanRequest extends $pb.GeneratedMessage {
  factory FormatTimespanRequest({
    $core.double? seconds,
    FormatTimespanRequest_Context? context,
  }) {
    final $result = create();
    if (seconds != null) {
      $result.seconds = seconds;
    }
    if (context != null) {
      $result.context = context;
    }
    return $result;
  }
  FormatTimespanRequest._() : super();
  factory FormatTimespanRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormatTimespanRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormatTimespanRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.i18n'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'seconds', $pb.PbFieldType.OF)
    ..e<FormatTimespanRequest_Context>(2, _omitFieldNames ? '' : 'context', $pb.PbFieldType.OE, defaultOrMaker: FormatTimespanRequest_Context.PRECISE, valueOf: FormatTimespanRequest_Context.valueOf, enumValues: FormatTimespanRequest_Context.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormatTimespanRequest clone() => FormatTimespanRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormatTimespanRequest copyWith(void Function(FormatTimespanRequest) updates) => super.copyWith((message) => updates(message as FormatTimespanRequest)) as FormatTimespanRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormatTimespanRequest create() => FormatTimespanRequest._();
  FormatTimespanRequest createEmptyInstance() => create();
  static $pb.PbList<FormatTimespanRequest> createRepeated() => $pb.PbList<FormatTimespanRequest>();
  @$core.pragma('dart2js:noInline')
  static FormatTimespanRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormatTimespanRequest>(create);
  static FormatTimespanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get seconds => $_getN(0);
  @$pb.TagNumber(1)
  set seconds($core.double v) { $_setFloat(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeconds() => clearField(1);

  @$pb.TagNumber(2)
  FormatTimespanRequest_Context get context => $_getN(1);
  @$pb.TagNumber(2)
  set context(FormatTimespanRequest_Context v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasContext() => $_has(1);
  @$pb.TagNumber(2)
  void clearContext() => clearField(2);
}

class I18nResourcesRequest extends $pb.GeneratedMessage {
  factory I18nResourcesRequest({
    $core.Iterable<$core.String>? modules,
  }) {
    final $result = create();
    if (modules != null) {
      $result.modules.addAll(modules);
    }
    return $result;
  }
  I18nResourcesRequest._() : super();
  factory I18nResourcesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory I18nResourcesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'I18nResourcesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.i18n'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'modules')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  I18nResourcesRequest clone() => I18nResourcesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  I18nResourcesRequest copyWith(void Function(I18nResourcesRequest) updates) => super.copyWith((message) => updates(message as I18nResourcesRequest)) as I18nResourcesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static I18nResourcesRequest create() => I18nResourcesRequest._();
  I18nResourcesRequest createEmptyInstance() => create();
  static $pb.PbList<I18nResourcesRequest> createRepeated() => $pb.PbList<I18nResourcesRequest>();
  @$core.pragma('dart2js:noInline')
  static I18nResourcesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<I18nResourcesRequest>(create);
  static I18nResourcesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get modules => $_getList(0);
}

class I18nServiceApi {
  $pb.RpcClient _client;
  I18nServiceApi(this._client);

  $async.Future<$0.String> translateString($pb.ClientContext? ctx, TranslateStringRequest request) =>
    _client.invoke<$0.String>(ctx, 'I18nService', 'TranslateString', request, $0.String())
  ;
  $async.Future<$0.String> formatTimespan($pb.ClientContext? ctx, FormatTimespanRequest request) =>
    _client.invoke<$0.String>(ctx, 'I18nService', 'FormatTimespan', request, $0.String())
  ;
  $async.Future<$0.Json> i18nResources($pb.ClientContext? ctx, I18nResourcesRequest request) =>
    _client.invoke<$0.Json>(ctx, 'I18nService', 'I18nResources', request, $0.Json())
  ;
}

class BackendI18nServiceApi {
  $pb.RpcClient _client;
  BackendI18nServiceApi(this._client);

  $async.Future<$0.String> translateString($pb.ClientContext? ctx, TranslateStringRequest request) =>
    _client.invoke<$0.String>(ctx, 'BackendI18nService', 'TranslateString', request, $0.String())
  ;
  $async.Future<$0.String> formatTimespan($pb.ClientContext? ctx, FormatTimespanRequest request) =>
    _client.invoke<$0.String>(ctx, 'BackendI18nService', 'FormatTimespan', request, $0.String())
  ;
  $async.Future<$0.Json> i18nResources($pb.ClientContext? ctx, I18nResourcesRequest request) =>
    _client.invoke<$0.Json>(ctx, 'BackendI18nService', 'I18nResources', request, $0.Json())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
