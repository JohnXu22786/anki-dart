// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/tags.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'collection.pb.dart' as $2;
import 'generic.pb.dart' as $0;
import 'tags.pb.dart' as $23;
import 'tags.pbjson.dart';

export 'tags.pb.dart';

abstract class TagsServiceBase extends $pb.GeneratedService {
  $async.Future<$2.OpChangesWithCount> clearUnusedTags($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.StringList> allTags($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChangesWithCount> removeTags($pb.ServerContext ctx, $0.String request);
  $async.Future<$2.OpChanges> setTagCollapsed($pb.ServerContext ctx, $23.SetTagCollapsedRequest request);
  $async.Future<$23.TagTreeNode> tagTree($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChangesWithCount> reparentTags($pb.ServerContext ctx, $23.ReparentTagsRequest request);
  $async.Future<$2.OpChangesWithCount> renameTags($pb.ServerContext ctx, $23.RenameTagsRequest request);
  $async.Future<$2.OpChangesWithCount> addNoteTags($pb.ServerContext ctx, $23.NoteIdsAndTagsRequest request);
  $async.Future<$2.OpChangesWithCount> removeNoteTags($pb.ServerContext ctx, $23.NoteIdsAndTagsRequest request);
  $async.Future<$2.OpChangesWithCount> findAndReplaceTag($pb.ServerContext ctx, $23.FindAndReplaceTagRequest request);
  $async.Future<$23.CompleteTagResponse> completeTag($pb.ServerContext ctx, $23.CompleteTagRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ClearUnusedTags': return $0.Empty();
      case 'AllTags': return $0.Empty();
      case 'RemoveTags': return $0.String();
      case 'SetTagCollapsed': return $23.SetTagCollapsedRequest();
      case 'TagTree': return $0.Empty();
      case 'ReparentTags': return $23.ReparentTagsRequest();
      case 'RenameTags': return $23.RenameTagsRequest();
      case 'AddNoteTags': return $23.NoteIdsAndTagsRequest();
      case 'RemoveNoteTags': return $23.NoteIdsAndTagsRequest();
      case 'FindAndReplaceTag': return $23.FindAndReplaceTagRequest();
      case 'CompleteTag': return $23.CompleteTagRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ClearUnusedTags': return this.clearUnusedTags(ctx, request as $0.Empty);
      case 'AllTags': return this.allTags(ctx, request as $0.Empty);
      case 'RemoveTags': return this.removeTags(ctx, request as $0.String);
      case 'SetTagCollapsed': return this.setTagCollapsed(ctx, request as $23.SetTagCollapsedRequest);
      case 'TagTree': return this.tagTree(ctx, request as $0.Empty);
      case 'ReparentTags': return this.reparentTags(ctx, request as $23.ReparentTagsRequest);
      case 'RenameTags': return this.renameTags(ctx, request as $23.RenameTagsRequest);
      case 'AddNoteTags': return this.addNoteTags(ctx, request as $23.NoteIdsAndTagsRequest);
      case 'RemoveNoteTags': return this.removeNoteTags(ctx, request as $23.NoteIdsAndTagsRequest);
      case 'FindAndReplaceTag': return this.findAndReplaceTag(ctx, request as $23.FindAndReplaceTagRequest);
      case 'CompleteTag': return this.completeTag(ctx, request as $23.CompleteTagRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => TagsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => TagsServiceBase$messageJson;
}

abstract class BackendTagsServiceBase extends $pb.GeneratedService {

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendTagsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendTagsServiceBase$messageJson;
}
