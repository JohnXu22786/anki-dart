//
//  Generated code. Do not modify.
//  source: anki/tags.proto
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

class SetTagCollapsedRequest extends $pb.GeneratedMessage {
  factory SetTagCollapsedRequest({
    $core.String? name,
    $core.bool? collapsed,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (collapsed != null) {
      $result.collapsed = collapsed;
    }
    return $result;
  }
  SetTagCollapsedRequest._() : super();
  factory SetTagCollapsedRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetTagCollapsedRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetTagCollapsedRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'collapsed')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetTagCollapsedRequest clone() => SetTagCollapsedRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetTagCollapsedRequest copyWith(void Function(SetTagCollapsedRequest) updates) => super.copyWith((message) => updates(message as SetTagCollapsedRequest)) as SetTagCollapsedRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetTagCollapsedRequest create() => SetTagCollapsedRequest._();
  SetTagCollapsedRequest createEmptyInstance() => create();
  static $pb.PbList<SetTagCollapsedRequest> createRepeated() => $pb.PbList<SetTagCollapsedRequest>();
  @$core.pragma('dart2js:noInline')
  static SetTagCollapsedRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetTagCollapsedRequest>(create);
  static SetTagCollapsedRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get collapsed => $_getBF(1);
  @$pb.TagNumber(2)
  set collapsed($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCollapsed() => $_has(1);
  @$pb.TagNumber(2)
  void clearCollapsed() => clearField(2);
}

class TagTreeNode extends $pb.GeneratedMessage {
  factory TagTreeNode({
    $core.String? name,
    $core.Iterable<TagTreeNode>? children,
    $core.int? level,
    $core.bool? collapsed,
  }) {
    final $result = create();
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
    return $result;
  }
  TagTreeNode._() : super();
  factory TagTreeNode.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TagTreeNode.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TagTreeNode', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pc<TagTreeNode>(2, _omitFieldNames ? '' : 'children', $pb.PbFieldType.PM, subBuilder: TagTreeNode.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'collapsed')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TagTreeNode clone() => TagTreeNode()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TagTreeNode copyWith(void Function(TagTreeNode) updates) => super.copyWith((message) => updates(message as TagTreeNode)) as TagTreeNode;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TagTreeNode create() => TagTreeNode._();
  TagTreeNode createEmptyInstance() => create();
  static $pb.PbList<TagTreeNode> createRepeated() => $pb.PbList<TagTreeNode>();
  @$core.pragma('dart2js:noInline')
  static TagTreeNode getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TagTreeNode>(create);
  static TagTreeNode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<TagTreeNode> get children => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get level => $_getIZ(2);
  @$pb.TagNumber(3)
  set level($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get collapsed => $_getBF(3);
  @$pb.TagNumber(4)
  set collapsed($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCollapsed() => $_has(3);
  @$pb.TagNumber(4)
  void clearCollapsed() => clearField(4);
}

class ReparentTagsRequest extends $pb.GeneratedMessage {
  factory ReparentTagsRequest({
    $core.Iterable<$core.String>? tags,
    $core.String? newParent,
  }) {
    final $result = create();
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (newParent != null) {
      $result.newParent = newParent;
    }
    return $result;
  }
  ReparentTagsRequest._() : super();
  factory ReparentTagsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReparentTagsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReparentTagsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'tags')
    ..aOS(2, _omitFieldNames ? '' : 'newParent')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReparentTagsRequest clone() => ReparentTagsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReparentTagsRequest copyWith(void Function(ReparentTagsRequest) updates) => super.copyWith((message) => updates(message as ReparentTagsRequest)) as ReparentTagsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReparentTagsRequest create() => ReparentTagsRequest._();
  ReparentTagsRequest createEmptyInstance() => create();
  static $pb.PbList<ReparentTagsRequest> createRepeated() => $pb.PbList<ReparentTagsRequest>();
  @$core.pragma('dart2js:noInline')
  static ReparentTagsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReparentTagsRequest>(create);
  static ReparentTagsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get tags => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get newParent => $_getSZ(1);
  @$pb.TagNumber(2)
  set newParent($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNewParent() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewParent() => clearField(2);
}

class RenameTagsRequest extends $pb.GeneratedMessage {
  factory RenameTagsRequest({
    $core.String? currentPrefix,
    $core.String? newPrefix,
  }) {
    final $result = create();
    if (currentPrefix != null) {
      $result.currentPrefix = currentPrefix;
    }
    if (newPrefix != null) {
      $result.newPrefix = newPrefix;
    }
    return $result;
  }
  RenameTagsRequest._() : super();
  factory RenameTagsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenameTagsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenameTagsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'currentPrefix')
    ..aOS(2, _omitFieldNames ? '' : 'newPrefix')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenameTagsRequest clone() => RenameTagsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenameTagsRequest copyWith(void Function(RenameTagsRequest) updates) => super.copyWith((message) => updates(message as RenameTagsRequest)) as RenameTagsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameTagsRequest create() => RenameTagsRequest._();
  RenameTagsRequest createEmptyInstance() => create();
  static $pb.PbList<RenameTagsRequest> createRepeated() => $pb.PbList<RenameTagsRequest>();
  @$core.pragma('dart2js:noInline')
  static RenameTagsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenameTagsRequest>(create);
  static RenameTagsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get currentPrefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set currentPrefix($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCurrentPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearCurrentPrefix() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPrefix => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPrefix($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNewPrefix() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPrefix() => clearField(2);
}

class NoteIdsAndTagsRequest extends $pb.GeneratedMessage {
  factory NoteIdsAndTagsRequest({
    $core.Iterable<$fixnum.Int64>? noteIds,
    $core.String? tags,
  }) {
    final $result = create();
    if (noteIds != null) {
      $result.noteIds.addAll(noteIds);
    }
    if (tags != null) {
      $result.tags = tags;
    }
    return $result;
  }
  NoteIdsAndTagsRequest._() : super();
  factory NoteIdsAndTagsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NoteIdsAndTagsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NoteIdsAndTagsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'noteIds', $pb.PbFieldType.K6)
    ..aOS(2, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NoteIdsAndTagsRequest clone() => NoteIdsAndTagsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NoteIdsAndTagsRequest copyWith(void Function(NoteIdsAndTagsRequest) updates) => super.copyWith((message) => updates(message as NoteIdsAndTagsRequest)) as NoteIdsAndTagsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NoteIdsAndTagsRequest create() => NoteIdsAndTagsRequest._();
  NoteIdsAndTagsRequest createEmptyInstance() => create();
  static $pb.PbList<NoteIdsAndTagsRequest> createRepeated() => $pb.PbList<NoteIdsAndTagsRequest>();
  @$core.pragma('dart2js:noInline')
  static NoteIdsAndTagsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NoteIdsAndTagsRequest>(create);
  static NoteIdsAndTagsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get noteIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get tags => $_getSZ(1);
  @$pb.TagNumber(2)
  set tags($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTags() => $_has(1);
  @$pb.TagNumber(2)
  void clearTags() => clearField(2);
}

class FindAndReplaceTagRequest extends $pb.GeneratedMessage {
  factory FindAndReplaceTagRequest({
    $core.Iterable<$fixnum.Int64>? noteIds,
    $core.String? search,
    $core.String? replacement,
    $core.bool? regex,
    $core.bool? matchCase,
  }) {
    final $result = create();
    if (noteIds != null) {
      $result.noteIds.addAll(noteIds);
    }
    if (search != null) {
      $result.search = search;
    }
    if (replacement != null) {
      $result.replacement = replacement;
    }
    if (regex != null) {
      $result.regex = regex;
    }
    if (matchCase != null) {
      $result.matchCase = matchCase;
    }
    return $result;
  }
  FindAndReplaceTagRequest._() : super();
  factory FindAndReplaceTagRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FindAndReplaceTagRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FindAndReplaceTagRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'noteIds', $pb.PbFieldType.K6)
    ..aOS(2, _omitFieldNames ? '' : 'search')
    ..aOS(3, _omitFieldNames ? '' : 'replacement')
    ..aOB(4, _omitFieldNames ? '' : 'regex')
    ..aOB(5, _omitFieldNames ? '' : 'matchCase')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FindAndReplaceTagRequest clone() => FindAndReplaceTagRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FindAndReplaceTagRequest copyWith(void Function(FindAndReplaceTagRequest) updates) => super.copyWith((message) => updates(message as FindAndReplaceTagRequest)) as FindAndReplaceTagRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FindAndReplaceTagRequest create() => FindAndReplaceTagRequest._();
  FindAndReplaceTagRequest createEmptyInstance() => create();
  static $pb.PbList<FindAndReplaceTagRequest> createRepeated() => $pb.PbList<FindAndReplaceTagRequest>();
  @$core.pragma('dart2js:noInline')
  static FindAndReplaceTagRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FindAndReplaceTagRequest>(create);
  static FindAndReplaceTagRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get noteIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get search => $_getSZ(1);
  @$pb.TagNumber(2)
  set search($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSearch() => $_has(1);
  @$pb.TagNumber(2)
  void clearSearch() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get replacement => $_getSZ(2);
  @$pb.TagNumber(3)
  set replacement($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReplacement() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplacement() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get regex => $_getBF(3);
  @$pb.TagNumber(4)
  set regex($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRegex() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegex() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get matchCase => $_getBF(4);
  @$pb.TagNumber(5)
  set matchCase($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMatchCase() => $_has(4);
  @$pb.TagNumber(5)
  void clearMatchCase() => clearField(5);
}

class CompleteTagRequest extends $pb.GeneratedMessage {
  factory CompleteTagRequest({
    $core.String? input,
    $core.int? matchLimit,
  }) {
    final $result = create();
    if (input != null) {
      $result.input = input;
    }
    if (matchLimit != null) {
      $result.matchLimit = matchLimit;
    }
    return $result;
  }
  CompleteTagRequest._() : super();
  factory CompleteTagRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CompleteTagRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CompleteTagRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'input')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'matchLimit', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CompleteTagRequest clone() => CompleteTagRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CompleteTagRequest copyWith(void Function(CompleteTagRequest) updates) => super.copyWith((message) => updates(message as CompleteTagRequest)) as CompleteTagRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompleteTagRequest create() => CompleteTagRequest._();
  CompleteTagRequest createEmptyInstance() => create();
  static $pb.PbList<CompleteTagRequest> createRepeated() => $pb.PbList<CompleteTagRequest>();
  @$core.pragma('dart2js:noInline')
  static CompleteTagRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompleteTagRequest>(create);
  static CompleteTagRequest? _defaultInstance;

  /// a partial tag, optionally delimited with ::
  @$pb.TagNumber(1)
  $core.String get input => $_getSZ(0);
  @$pb.TagNumber(1)
  set input($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasInput() => $_has(0);
  @$pb.TagNumber(1)
  void clearInput() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get matchLimit => $_getIZ(1);
  @$pb.TagNumber(2)
  set matchLimit($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMatchLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearMatchLimit() => clearField(2);
}

class CompleteTagResponse extends $pb.GeneratedMessage {
  factory CompleteTagResponse({
    $core.Iterable<$core.String>? tags,
  }) {
    final $result = create();
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    return $result;
  }
  CompleteTagResponse._() : super();
  factory CompleteTagResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CompleteTagResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CompleteTagResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.tags'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CompleteTagResponse clone() => CompleteTagResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CompleteTagResponse copyWith(void Function(CompleteTagResponse) updates) => super.copyWith((message) => updates(message as CompleteTagResponse)) as CompleteTagResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompleteTagResponse create() => CompleteTagResponse._();
  CompleteTagResponse createEmptyInstance() => create();
  static $pb.PbList<CompleteTagResponse> createRepeated() => $pb.PbList<CompleteTagResponse>();
  @$core.pragma('dart2js:noInline')
  static CompleteTagResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompleteTagResponse>(create);
  static CompleteTagResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get tags => $_getList(0);
}

class TagsServiceApi {
  $pb.RpcClient _client;
  TagsServiceApi(this._client);

  $async.Future<$2.OpChangesWithCount> clearUnusedTags($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'ClearUnusedTags', request, $2.OpChangesWithCount())
  ;
  $async.Future<$0.StringList> allTags($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.StringList>(ctx, 'TagsService', 'AllTags', request, $0.StringList())
  ;
  $async.Future<$2.OpChangesWithCount> removeTags($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'RemoveTags', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChanges> setTagCollapsed($pb.ClientContext? ctx, SetTagCollapsedRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'TagsService', 'SetTagCollapsed', request, $2.OpChanges())
  ;
  $async.Future<TagTreeNode> tagTree($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<TagTreeNode>(ctx, 'TagsService', 'TagTree', request, TagTreeNode())
  ;
  $async.Future<$2.OpChangesWithCount> reparentTags($pb.ClientContext? ctx, ReparentTagsRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'ReparentTags', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> renameTags($pb.ClientContext? ctx, RenameTagsRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'RenameTags', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> addNoteTags($pb.ClientContext? ctx, NoteIdsAndTagsRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'AddNoteTags', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> removeNoteTags($pb.ClientContext? ctx, NoteIdsAndTagsRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'RemoveNoteTags', request, $2.OpChangesWithCount())
  ;
  $async.Future<$2.OpChangesWithCount> findAndReplaceTag($pb.ClientContext? ctx, FindAndReplaceTagRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'TagsService', 'FindAndReplaceTag', request, $2.OpChangesWithCount())
  ;
  $async.Future<CompleteTagResponse> completeTag($pb.ClientContext? ctx, CompleteTagRequest request) =>
    _client.invoke<CompleteTagResponse>(ctx, 'TagsService', 'CompleteTag', request, CompleteTagResponse())
  ;
}

class BackendTagsServiceApi {
  $pb.RpcClient _client;
  BackendTagsServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
