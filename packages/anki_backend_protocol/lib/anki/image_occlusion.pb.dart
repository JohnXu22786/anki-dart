// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/image_occlusion.proto
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
import 'generic.pb.dart' as $0;

class GetImageForOcclusionRequest extends $pb.GeneratedMessage {
  factory GetImageForOcclusionRequest({
    $core.String? path,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    return $result;
  }
  GetImageForOcclusionRequest._() : super();
  factory GetImageForOcclusionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageForOcclusionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageForOcclusionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageForOcclusionRequest clone() => GetImageForOcclusionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageForOcclusionRequest copyWith(void Function(GetImageForOcclusionRequest) updates) => super.copyWith((message) => updates(message as GetImageForOcclusionRequest)) as GetImageForOcclusionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageForOcclusionRequest create() => GetImageForOcclusionRequest._();
  GetImageForOcclusionRequest createEmptyInstance() => create();
  static $pb.PbList<GetImageForOcclusionRequest> createRepeated() => $pb.PbList<GetImageForOcclusionRequest>();
  @$core.pragma('dart2js:noInline')
  static GetImageForOcclusionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageForOcclusionRequest>(create);
  static GetImageForOcclusionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);
}

class GetImageForOcclusionResponse extends $pb.GeneratedMessage {
  factory GetImageForOcclusionResponse({
    $core.List<$core.int>? data,
    $core.String? name,
  }) {
    final $result = create();
    if (data != null) {
      $result.data = data;
    }
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  GetImageForOcclusionResponse._() : super();
  factory GetImageForOcclusionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageForOcclusionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageForOcclusionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageForOcclusionResponse clone() => GetImageForOcclusionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageForOcclusionResponse copyWith(void Function(GetImageForOcclusionResponse) updates) => super.copyWith((message) => updates(message as GetImageForOcclusionResponse)) as GetImageForOcclusionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageForOcclusionResponse create() => GetImageForOcclusionResponse._();
  GetImageForOcclusionResponse createEmptyInstance() => create();
  static $pb.PbList<GetImageForOcclusionResponse> createRepeated() => $pb.PbList<GetImageForOcclusionResponse>();
  @$core.pragma('dart2js:noInline')
  static GetImageForOcclusionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageForOcclusionResponse>(create);
  static GetImageForOcclusionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

class AddImageOcclusionNoteRequest extends $pb.GeneratedMessage {
  factory AddImageOcclusionNoteRequest({
    $core.String? imagePath,
    $core.String? occlusions,
    $core.String? header,
    $core.String? backExtra,
    $core.Iterable<$core.String>? tags,
    $fixnum.Int64? notetypeId,
  }) {
    final $result = create();
    if (imagePath != null) {
      $result.imagePath = imagePath;
    }
    if (occlusions != null) {
      $result.occlusions = occlusions;
    }
    if (header != null) {
      $result.header = header;
    }
    if (backExtra != null) {
      $result.backExtra = backExtra;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    return $result;
  }
  AddImageOcclusionNoteRequest._() : super();
  factory AddImageOcclusionNoteRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddImageOcclusionNoteRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddImageOcclusionNoteRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'imagePath')
    ..aOS(2, _omitFieldNames ? '' : 'occlusions')
    ..aOS(3, _omitFieldNames ? '' : 'header')
    ..aOS(4, _omitFieldNames ? '' : 'backExtra')
    ..pPS(5, _omitFieldNames ? '' : 'tags')
    ..aInt64(6, _omitFieldNames ? '' : 'notetypeId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddImageOcclusionNoteRequest clone() => AddImageOcclusionNoteRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddImageOcclusionNoteRequest copyWith(void Function(AddImageOcclusionNoteRequest) updates) => super.copyWith((message) => updates(message as AddImageOcclusionNoteRequest)) as AddImageOcclusionNoteRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddImageOcclusionNoteRequest create() => AddImageOcclusionNoteRequest._();
  AddImageOcclusionNoteRequest createEmptyInstance() => create();
  static $pb.PbList<AddImageOcclusionNoteRequest> createRepeated() => $pb.PbList<AddImageOcclusionNoteRequest>();
  @$core.pragma('dart2js:noInline')
  static AddImageOcclusionNoteRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddImageOcclusionNoteRequest>(create);
  static AddImageOcclusionNoteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get imagePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set imagePath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasImagePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearImagePath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get occlusions => $_getSZ(1);
  @$pb.TagNumber(2)
  set occlusions($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOcclusions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOcclusions() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get header => $_getSZ(2);
  @$pb.TagNumber(3)
  set header($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeader() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeader() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get backExtra => $_getSZ(3);
  @$pb.TagNumber(4)
  set backExtra($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBackExtra() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackExtra() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.String> get tags => $_getList(4);

  @$pb.TagNumber(6)
  $fixnum.Int64 get notetypeId => $_getI64(5);
  @$pb.TagNumber(6)
  set notetypeId($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasNotetypeId() => $_has(5);
  @$pb.TagNumber(6)
  void clearNotetypeId() => clearField(6);
}

class GetImageOcclusionNoteRequest extends $pb.GeneratedMessage {
  factory GetImageOcclusionNoteRequest({
    $fixnum.Int64? noteId,
  }) {
    final $result = create();
    if (noteId != null) {
      $result.noteId = noteId;
    }
    return $result;
  }
  GetImageOcclusionNoteRequest._() : super();
  factory GetImageOcclusionNoteRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionNoteRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionNoteRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'noteId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteRequest clone() => GetImageOcclusionNoteRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteRequest copyWith(void Function(GetImageOcclusionNoteRequest) updates) => super.copyWith((message) => updates(message as GetImageOcclusionNoteRequest)) as GetImageOcclusionNoteRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteRequest create() => GetImageOcclusionNoteRequest._();
  GetImageOcclusionNoteRequest createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionNoteRequest> createRepeated() => $pb.PbList<GetImageOcclusionNoteRequest>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionNoteRequest>(create);
  static GetImageOcclusionNoteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get noteId => $_getI64(0);
  @$pb.TagNumber(1)
  set noteId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNoteId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNoteId() => clearField(1);
}

class GetImageOcclusionNoteResponse_ImageOcclusionProperty extends $pb.GeneratedMessage {
  factory GetImageOcclusionNoteResponse_ImageOcclusionProperty({
    $core.String? name,
    $core.String? value,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  GetImageOcclusionNoteResponse_ImageOcclusionProperty._() : super();
  factory GetImageOcclusionNoteResponse_ImageOcclusionProperty.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionNoteResponse_ImageOcclusionProperty.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionNoteResponse.ImageOcclusionProperty', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusionProperty clone() => GetImageOcclusionNoteResponse_ImageOcclusionProperty()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusionProperty copyWith(void Function(GetImageOcclusionNoteResponse_ImageOcclusionProperty) updates) => super.copyWith((message) => updates(message as GetImageOcclusionNoteResponse_ImageOcclusionProperty)) as GetImageOcclusionNoteResponse_ImageOcclusionProperty;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusionProperty create() => GetImageOcclusionNoteResponse_ImageOcclusionProperty._();
  GetImageOcclusionNoteResponse_ImageOcclusionProperty createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusionProperty> createRepeated() => $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusionProperty>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusionProperty getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionNoteResponse_ImageOcclusionProperty>(create);
  static GetImageOcclusionNoteResponse_ImageOcclusionProperty? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

class GetImageOcclusionNoteResponse_ImageOcclusionShape extends $pb.GeneratedMessage {
  factory GetImageOcclusionNoteResponse_ImageOcclusionShape({
    $core.String? shape,
    $core.Iterable<GetImageOcclusionNoteResponse_ImageOcclusionProperty>? properties,
  }) {
    final $result = create();
    if (shape != null) {
      $result.shape = shape;
    }
    if (properties != null) {
      $result.properties.addAll(properties);
    }
    return $result;
  }
  GetImageOcclusionNoteResponse_ImageOcclusionShape._() : super();
  factory GetImageOcclusionNoteResponse_ImageOcclusionShape.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionNoteResponse_ImageOcclusionShape.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionNoteResponse.ImageOcclusionShape', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shape')
    ..pc<GetImageOcclusionNoteResponse_ImageOcclusionProperty>(2, _omitFieldNames ? '' : 'properties', $pb.PbFieldType.PM, subBuilder: GetImageOcclusionNoteResponse_ImageOcclusionProperty.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusionShape clone() => GetImageOcclusionNoteResponse_ImageOcclusionShape()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusionShape copyWith(void Function(GetImageOcclusionNoteResponse_ImageOcclusionShape) updates) => super.copyWith((message) => updates(message as GetImageOcclusionNoteResponse_ImageOcclusionShape)) as GetImageOcclusionNoteResponse_ImageOcclusionShape;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusionShape create() => GetImageOcclusionNoteResponse_ImageOcclusionShape._();
  GetImageOcclusionNoteResponse_ImageOcclusionShape createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusionShape> createRepeated() => $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusionShape>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusionShape getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionNoteResponse_ImageOcclusionShape>(create);
  static GetImageOcclusionNoteResponse_ImageOcclusionShape? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get shape => $_getSZ(0);
  @$pb.TagNumber(1)
  set shape($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasShape() => $_has(0);
  @$pb.TagNumber(1)
  void clearShape() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<GetImageOcclusionNoteResponse_ImageOcclusionProperty> get properties => $_getList(1);
}

class GetImageOcclusionNoteResponse_ImageOcclusion extends $pb.GeneratedMessage {
  factory GetImageOcclusionNoteResponse_ImageOcclusion({
    $core.Iterable<GetImageOcclusionNoteResponse_ImageOcclusionShape>? shapes,
    $core.int? ordinal,
  }) {
    final $result = create();
    if (shapes != null) {
      $result.shapes.addAll(shapes);
    }
    if (ordinal != null) {
      $result.ordinal = ordinal;
    }
    return $result;
  }
  GetImageOcclusionNoteResponse_ImageOcclusion._() : super();
  factory GetImageOcclusionNoteResponse_ImageOcclusion.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionNoteResponse_ImageOcclusion.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionNoteResponse.ImageOcclusion', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..pc<GetImageOcclusionNoteResponse_ImageOcclusionShape>(1, _omitFieldNames ? '' : 'shapes', $pb.PbFieldType.PM, subBuilder: GetImageOcclusionNoteResponse_ImageOcclusionShape.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ordinal', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusion clone() => GetImageOcclusionNoteResponse_ImageOcclusion()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusion copyWith(void Function(GetImageOcclusionNoteResponse_ImageOcclusion) updates) => super.copyWith((message) => updates(message as GetImageOcclusionNoteResponse_ImageOcclusion)) as GetImageOcclusionNoteResponse_ImageOcclusion;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusion create() => GetImageOcclusionNoteResponse_ImageOcclusion._();
  GetImageOcclusionNoteResponse_ImageOcclusion createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusion> createRepeated() => $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusion>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusion getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionNoteResponse_ImageOcclusion>(create);
  static GetImageOcclusionNoteResponse_ImageOcclusion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<GetImageOcclusionNoteResponse_ImageOcclusionShape> get shapes => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get ordinal => $_getIZ(1);
  @$pb.TagNumber(2)
  set ordinal($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOrdinal() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrdinal() => clearField(2);
}

class GetImageOcclusionNoteResponse_ImageOcclusionNote extends $pb.GeneratedMessage {
  factory GetImageOcclusionNoteResponse_ImageOcclusionNote({
    $core.List<$core.int>? imageData,
    $core.Iterable<GetImageOcclusionNoteResponse_ImageOcclusion>? occlusions,
    $core.String? header,
    $core.String? backExtra,
    $core.Iterable<$core.String>? tags,
    $core.String? imageFileName,
    $core.bool? occludeInactive,
  }) {
    final $result = create();
    if (imageData != null) {
      $result.imageData = imageData;
    }
    if (occlusions != null) {
      $result.occlusions.addAll(occlusions);
    }
    if (header != null) {
      $result.header = header;
    }
    if (backExtra != null) {
      $result.backExtra = backExtra;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (imageFileName != null) {
      $result.imageFileName = imageFileName;
    }
    if (occludeInactive != null) {
      $result.occludeInactive = occludeInactive;
    }
    return $result;
  }
  GetImageOcclusionNoteResponse_ImageOcclusionNote._() : super();
  factory GetImageOcclusionNoteResponse_ImageOcclusionNote.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionNoteResponse_ImageOcclusionNote.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionNoteResponse.ImageOcclusionNote', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'imageData', $pb.PbFieldType.OY)
    ..pc<GetImageOcclusionNoteResponse_ImageOcclusion>(2, _omitFieldNames ? '' : 'occlusions', $pb.PbFieldType.PM, subBuilder: GetImageOcclusionNoteResponse_ImageOcclusion.create)
    ..aOS(3, _omitFieldNames ? '' : 'header')
    ..aOS(4, _omitFieldNames ? '' : 'backExtra')
    ..pPS(5, _omitFieldNames ? '' : 'tags')
    ..aOS(6, _omitFieldNames ? '' : 'imageFileName')
    ..aOB(7, _omitFieldNames ? '' : 'occludeInactive')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusionNote clone() => GetImageOcclusionNoteResponse_ImageOcclusionNote()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse_ImageOcclusionNote copyWith(void Function(GetImageOcclusionNoteResponse_ImageOcclusionNote) updates) => super.copyWith((message) => updates(message as GetImageOcclusionNoteResponse_ImageOcclusionNote)) as GetImageOcclusionNoteResponse_ImageOcclusionNote;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusionNote create() => GetImageOcclusionNoteResponse_ImageOcclusionNote._();
  GetImageOcclusionNoteResponse_ImageOcclusionNote createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusionNote> createRepeated() => $pb.PbList<GetImageOcclusionNoteResponse_ImageOcclusionNote>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse_ImageOcclusionNote getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionNoteResponse_ImageOcclusionNote>(create);
  static GetImageOcclusionNoteResponse_ImageOcclusionNote? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get imageData => $_getN(0);
  @$pb.TagNumber(1)
  set imageData($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasImageData() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageData() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<GetImageOcclusionNoteResponse_ImageOcclusion> get occlusions => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get header => $_getSZ(2);
  @$pb.TagNumber(3)
  set header($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeader() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeader() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get backExtra => $_getSZ(3);
  @$pb.TagNumber(4)
  set backExtra($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBackExtra() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackExtra() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.String> get tags => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get imageFileName => $_getSZ(5);
  @$pb.TagNumber(6)
  set imageFileName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasImageFileName() => $_has(5);
  @$pb.TagNumber(6)
  void clearImageFileName() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get occludeInactive => $_getBF(6);
  @$pb.TagNumber(7)
  set occludeInactive($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasOccludeInactive() => $_has(6);
  @$pb.TagNumber(7)
  void clearOccludeInactive() => clearField(7);
}

enum GetImageOcclusionNoteResponse_Value {
  note,
  error,
  notSet
}

class GetImageOcclusionNoteResponse extends $pb.GeneratedMessage {
  factory GetImageOcclusionNoteResponse({
    GetImageOcclusionNoteResponse_ImageOcclusionNote? note,
    $core.String? error,
  }) {
    final $result = create();
    if (note != null) {
      $result.note = note;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GetImageOcclusionNoteResponse._() : super();
  factory GetImageOcclusionNoteResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionNoteResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, GetImageOcclusionNoteResponse_Value> _GetImageOcclusionNoteResponse_ValueByTag = {
    1 : GetImageOcclusionNoteResponse_Value.note,
    2 : GetImageOcclusionNoteResponse_Value.error,
    0 : GetImageOcclusionNoteResponse_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionNoteResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<GetImageOcclusionNoteResponse_ImageOcclusionNote>(1, _omitFieldNames ? '' : 'note', subBuilder: GetImageOcclusionNoteResponse_ImageOcclusionNote.create)
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse clone() => GetImageOcclusionNoteResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionNoteResponse copyWith(void Function(GetImageOcclusionNoteResponse) updates) => super.copyWith((message) => updates(message as GetImageOcclusionNoteResponse)) as GetImageOcclusionNoteResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse create() => GetImageOcclusionNoteResponse._();
  GetImageOcclusionNoteResponse createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionNoteResponse> createRepeated() => $pb.PbList<GetImageOcclusionNoteResponse>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionNoteResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionNoteResponse>(create);
  static GetImageOcclusionNoteResponse? _defaultInstance;

  GetImageOcclusionNoteResponse_Value whichValue() => _GetImageOcclusionNoteResponse_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  GetImageOcclusionNoteResponse_ImageOcclusionNote get note => $_getN(0);
  @$pb.TagNumber(1)
  set note(GetImageOcclusionNoteResponse_ImageOcclusionNote v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNote() => $_has(0);
  @$pb.TagNumber(1)
  void clearNote() => clearField(1);
  @$pb.TagNumber(1)
  GetImageOcclusionNoteResponse_ImageOcclusionNote ensureNote() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
}

class UpdateImageOcclusionNoteRequest extends $pb.GeneratedMessage {
  factory UpdateImageOcclusionNoteRequest({
    $fixnum.Int64? noteId,
    $core.String? occlusions,
    $core.String? header,
    $core.String? backExtra,
    $core.Iterable<$core.String>? tags,
  }) {
    final $result = create();
    if (noteId != null) {
      $result.noteId = noteId;
    }
    if (occlusions != null) {
      $result.occlusions = occlusions;
    }
    if (header != null) {
      $result.header = header;
    }
    if (backExtra != null) {
      $result.backExtra = backExtra;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    return $result;
  }
  UpdateImageOcclusionNoteRequest._() : super();
  factory UpdateImageOcclusionNoteRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateImageOcclusionNoteRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateImageOcclusionNoteRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'noteId')
    ..aOS(2, _omitFieldNames ? '' : 'occlusions')
    ..aOS(3, _omitFieldNames ? '' : 'header')
    ..aOS(4, _omitFieldNames ? '' : 'backExtra')
    ..pPS(5, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateImageOcclusionNoteRequest clone() => UpdateImageOcclusionNoteRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateImageOcclusionNoteRequest copyWith(void Function(UpdateImageOcclusionNoteRequest) updates) => super.copyWith((message) => updates(message as UpdateImageOcclusionNoteRequest)) as UpdateImageOcclusionNoteRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateImageOcclusionNoteRequest create() => UpdateImageOcclusionNoteRequest._();
  UpdateImageOcclusionNoteRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateImageOcclusionNoteRequest> createRepeated() => $pb.PbList<UpdateImageOcclusionNoteRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateImageOcclusionNoteRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateImageOcclusionNoteRequest>(create);
  static UpdateImageOcclusionNoteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get noteId => $_getI64(0);
  @$pb.TagNumber(1)
  set noteId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNoteId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNoteId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get occlusions => $_getSZ(1);
  @$pb.TagNumber(2)
  set occlusions($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOcclusions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOcclusions() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get header => $_getSZ(2);
  @$pb.TagNumber(3)
  set header($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeader() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeader() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get backExtra => $_getSZ(3);
  @$pb.TagNumber(4)
  set backExtra($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBackExtra() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackExtra() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.String> get tags => $_getList(4);
}

class GetImageOcclusionFieldsRequest extends $pb.GeneratedMessage {
  factory GetImageOcclusionFieldsRequest({
    $fixnum.Int64? notetypeId,
  }) {
    final $result = create();
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    return $result;
  }
  GetImageOcclusionFieldsRequest._() : super();
  factory GetImageOcclusionFieldsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionFieldsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionFieldsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'notetypeId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionFieldsRequest clone() => GetImageOcclusionFieldsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionFieldsRequest copyWith(void Function(GetImageOcclusionFieldsRequest) updates) => super.copyWith((message) => updates(message as GetImageOcclusionFieldsRequest)) as GetImageOcclusionFieldsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionFieldsRequest create() => GetImageOcclusionFieldsRequest._();
  GetImageOcclusionFieldsRequest createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionFieldsRequest> createRepeated() => $pb.PbList<GetImageOcclusionFieldsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionFieldsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionFieldsRequest>(create);
  static GetImageOcclusionFieldsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get notetypeId => $_getI64(0);
  @$pb.TagNumber(1)
  set notetypeId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNotetypeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNotetypeId() => clearField(1);
}

class GetImageOcclusionFieldsResponse extends $pb.GeneratedMessage {
  factory GetImageOcclusionFieldsResponse({
    ImageOcclusionFieldIndexes? fields,
  }) {
    final $result = create();
    if (fields != null) {
      $result.fields = fields;
    }
    return $result;
  }
  GetImageOcclusionFieldsResponse._() : super();
  factory GetImageOcclusionFieldsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetImageOcclusionFieldsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetImageOcclusionFieldsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..aOM<ImageOcclusionFieldIndexes>(1, _omitFieldNames ? '' : 'fields', subBuilder: ImageOcclusionFieldIndexes.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetImageOcclusionFieldsResponse clone() => GetImageOcclusionFieldsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetImageOcclusionFieldsResponse copyWith(void Function(GetImageOcclusionFieldsResponse) updates) => super.copyWith((message) => updates(message as GetImageOcclusionFieldsResponse)) as GetImageOcclusionFieldsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionFieldsResponse create() => GetImageOcclusionFieldsResponse._();
  GetImageOcclusionFieldsResponse createEmptyInstance() => create();
  static $pb.PbList<GetImageOcclusionFieldsResponse> createRepeated() => $pb.PbList<GetImageOcclusionFieldsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetImageOcclusionFieldsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetImageOcclusionFieldsResponse>(create);
  static GetImageOcclusionFieldsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ImageOcclusionFieldIndexes get fields => $_getN(0);
  @$pb.TagNumber(1)
  set fields(ImageOcclusionFieldIndexes v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFields() => $_has(0);
  @$pb.TagNumber(1)
  void clearFields() => clearField(1);
  @$pb.TagNumber(1)
  ImageOcclusionFieldIndexes ensureFields() => $_ensure(0);
}

class ImageOcclusionFieldIndexes extends $pb.GeneratedMessage {
  factory ImageOcclusionFieldIndexes({
    $core.int? occlusions,
    $core.int? image,
    $core.int? header,
    $core.int? backExtra,
  }) {
    final $result = create();
    if (occlusions != null) {
      $result.occlusions = occlusions;
    }
    if (image != null) {
      $result.image = image;
    }
    if (header != null) {
      $result.header = header;
    }
    if (backExtra != null) {
      $result.backExtra = backExtra;
    }
    return $result;
  }
  ImageOcclusionFieldIndexes._() : super();
  factory ImageOcclusionFieldIndexes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImageOcclusionFieldIndexes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImageOcclusionFieldIndexes', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.image_occlusion'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'occlusions', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'image', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'header', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'backExtra', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImageOcclusionFieldIndexes clone() => ImageOcclusionFieldIndexes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImageOcclusionFieldIndexes copyWith(void Function(ImageOcclusionFieldIndexes) updates) => super.copyWith((message) => updates(message as ImageOcclusionFieldIndexes)) as ImageOcclusionFieldIndexes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImageOcclusionFieldIndexes create() => ImageOcclusionFieldIndexes._();
  ImageOcclusionFieldIndexes createEmptyInstance() => create();
  static $pb.PbList<ImageOcclusionFieldIndexes> createRepeated() => $pb.PbList<ImageOcclusionFieldIndexes>();
  @$core.pragma('dart2js:noInline')
  static ImageOcclusionFieldIndexes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImageOcclusionFieldIndexes>(create);
  static ImageOcclusionFieldIndexes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get occlusions => $_getIZ(0);
  @$pb.TagNumber(1)
  set occlusions($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOcclusions() => $_has(0);
  @$pb.TagNumber(1)
  void clearOcclusions() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get image => $_getIZ(1);
  @$pb.TagNumber(2)
  set image($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasImage() => $_has(1);
  @$pb.TagNumber(2)
  void clearImage() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get header => $_getIZ(2);
  @$pb.TagNumber(3)
  set header($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeader() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeader() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get backExtra => $_getIZ(3);
  @$pb.TagNumber(4)
  set backExtra($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBackExtra() => $_has(3);
  @$pb.TagNumber(4)
  void clearBackExtra() => clearField(4);
}

class ImageOcclusionServiceApi {
  $pb.RpcClient _client;
  ImageOcclusionServiceApi(this._client);

  $async.Future<GetImageForOcclusionResponse> getImageForOcclusion($pb.ClientContext? ctx, GetImageForOcclusionRequest request) =>
    _client.invoke<GetImageForOcclusionResponse>(ctx, 'ImageOcclusionService', 'GetImageForOcclusion', request, GetImageForOcclusionResponse())
  ;
  $async.Future<GetImageOcclusionNoteResponse> getImageOcclusionNote($pb.ClientContext? ctx, GetImageOcclusionNoteRequest request) =>
    _client.invoke<GetImageOcclusionNoteResponse>(ctx, 'ImageOcclusionService', 'GetImageOcclusionNote', request, GetImageOcclusionNoteResponse())
  ;
  $async.Future<GetImageOcclusionFieldsResponse> getImageOcclusionFields($pb.ClientContext? ctx, GetImageOcclusionFieldsRequest request) =>
    _client.invoke<GetImageOcclusionFieldsResponse>(ctx, 'ImageOcclusionService', 'GetImageOcclusionFields', request, GetImageOcclusionFieldsResponse())
  ;
  $async.Future<$2.OpChanges> addImageOcclusionNotetype($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ImageOcclusionService', 'AddImageOcclusionNotetype', request, $2.OpChanges())
  ;
  $async.Future<$2.OpChanges> addImageOcclusionNote($pb.ClientContext? ctx, AddImageOcclusionNoteRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ImageOcclusionService', 'AddImageOcclusionNote', request, $2.OpChanges())
  ;
  $async.Future<$2.OpChanges> updateImageOcclusionNote($pb.ClientContext? ctx, UpdateImageOcclusionNoteRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'ImageOcclusionService', 'UpdateImageOcclusionNote', request, $2.OpChanges())
  ;
}

class BackendImageOcclusionServiceApi {
  $pb.RpcClient _client;
  BackendImageOcclusionServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
