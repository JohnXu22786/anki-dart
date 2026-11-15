// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/backend.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'backend.pbenum.dart';
import 'links.pbenum.dart' as $11;

export 'backend.pbenum.dart';

class BackendInit extends $pb.GeneratedMessage {
  factory BackendInit({
    $core.Iterable<$core.String>? preferredLangs,
    $core.String? localeFolderPath,
    $core.bool? server,
  }) {
    final $result = create();
    if (preferredLangs != null) {
      $result.preferredLangs.addAll(preferredLangs);
    }
    if (localeFolderPath != null) {
      $result.localeFolderPath = localeFolderPath;
    }
    if (server != null) {
      $result.server = server;
    }
    return $result;
  }
  BackendInit._() : super();
  factory BackendInit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BackendInit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BackendInit', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.backend'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'preferredLangs')
    ..aOS(2, _omitFieldNames ? '' : 'localeFolderPath')
    ..aOB(3, _omitFieldNames ? '' : 'server')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BackendInit clone() => BackendInit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BackendInit copyWith(void Function(BackendInit) updates) => super.copyWith((message) => updates(message as BackendInit)) as BackendInit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackendInit create() => BackendInit._();
  BackendInit createEmptyInstance() => create();
  static $pb.PbList<BackendInit> createRepeated() => $pb.PbList<BackendInit>();
  @$core.pragma('dart2js:noInline')
  static BackendInit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BackendInit>(create);
  static BackendInit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get preferredLangs => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get localeFolderPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set localeFolderPath($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLocaleFolderPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocaleFolderPath() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get server => $_getBF(2);
  @$pb.TagNumber(3)
  set server($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);
}

class I18nBackendInit extends $pb.GeneratedMessage {
  factory I18nBackendInit({
    $core.Iterable<$core.String>? preferredLangs,
    $core.String? localeFolderPath,
  }) {
    final $result = create();
    if (preferredLangs != null) {
      $result.preferredLangs.addAll(preferredLangs);
    }
    if (localeFolderPath != null) {
      $result.localeFolderPath = localeFolderPath;
    }
    return $result;
  }
  I18nBackendInit._() : super();
  factory I18nBackendInit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory I18nBackendInit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'I18nBackendInit', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.backend'), createEmptyInstance: create)
    ..pPS(4, _omitFieldNames ? '' : 'preferredLangs')
    ..aOS(5, _omitFieldNames ? '' : 'localeFolderPath')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  I18nBackendInit clone() => I18nBackendInit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  I18nBackendInit copyWith(void Function(I18nBackendInit) updates) => super.copyWith((message) => updates(message as I18nBackendInit)) as I18nBackendInit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static I18nBackendInit create() => I18nBackendInit._();
  I18nBackendInit createEmptyInstance() => create();
  static $pb.PbList<I18nBackendInit> createRepeated() => $pb.PbList<I18nBackendInit>();
  @$core.pragma('dart2js:noInline')
  static I18nBackendInit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<I18nBackendInit>(create);
  static I18nBackendInit? _defaultInstance;

  @$pb.TagNumber(4)
  $core.List<$core.String> get preferredLangs => $_getList(0);

  @$pb.TagNumber(5)
  $core.String get localeFolderPath => $_getSZ(1);
  @$pb.TagNumber(5)
  set localeFolderPath($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(5)
  $core.bool hasLocaleFolderPath() => $_has(1);
  @$pb.TagNumber(5)
  void clearLocaleFolderPath() => clearField(5);
}

class BackendError extends $pb.GeneratedMessage {
  factory BackendError({
    $core.String? message,
    BackendError_Kind? kind,
    $11.HelpPageLinkRequest_HelpPage? helpPage,
    $core.String? context,
    $core.String? backtrace,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (helpPage != null) {
      $result.helpPage = helpPage;
    }
    if (context != null) {
      $result.context = context;
    }
    if (backtrace != null) {
      $result.backtrace = backtrace;
    }
    return $result;
  }
  BackendError._() : super();
  factory BackendError.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BackendError.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BackendError', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.backend'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..e<BackendError_Kind>(2, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE, defaultOrMaker: BackendError_Kind.INVALID_INPUT, valueOf: BackendError_Kind.valueOf, enumValues: BackendError_Kind.values)
    ..e<$11.HelpPageLinkRequest_HelpPage>(3, _omitFieldNames ? '' : 'helpPage', $pb.PbFieldType.OE, defaultOrMaker: $11.HelpPageLinkRequest_HelpPage.NOTE_TYPE, valueOf: $11.HelpPageLinkRequest_HelpPage.valueOf, enumValues: $11.HelpPageLinkRequest_HelpPage.values)
    ..aOS(4, _omitFieldNames ? '' : 'context')
    ..aOS(5, _omitFieldNames ? '' : 'backtrace')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BackendError clone() => BackendError()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BackendError copyWith(void Function(BackendError) updates) => super.copyWith((message) => updates(message as BackendError)) as BackendError;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackendError create() => BackendError._();
  BackendError createEmptyInstance() => create();
  static $pb.PbList<BackendError> createRepeated() => $pb.PbList<BackendError>();
  @$core.pragma('dart2js:noInline')
  static BackendError getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BackendError>(create);
  static BackendError? _defaultInstance;

  /// error description, usually localized, suitable for displaying to the user
  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);

  /// the error subtype
  @$pb.TagNumber(2)
  BackendError_Kind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(BackendError_Kind v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => clearField(2);

  /// optional page in the manual
  @$pb.TagNumber(3)
  $11.HelpPageLinkRequest_HelpPage get helpPage => $_getN(2);
  @$pb.TagNumber(3)
  set helpPage($11.HelpPageLinkRequest_HelpPage v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasHelpPage() => $_has(2);
  @$pb.TagNumber(3)
  void clearHelpPage() => clearField(3);

  /// additional information about the context in which the error occurred
  @$pb.TagNumber(4)
  $core.String get context => $_getSZ(3);
  @$pb.TagNumber(4)
  set context($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasContext() => $_has(3);
  @$pb.TagNumber(4)
  void clearContext() => clearField(4);

  /// a backtrace of the underlying error; requires RUST_BACKTRACE to be set
  @$pb.TagNumber(5)
  $core.String get backtrace => $_getSZ(4);
  @$pb.TagNumber(5)
  set backtrace($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBacktrace() => $_has(4);
  @$pb.TagNumber(5)
  void clearBacktrace() => clearField(5);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
