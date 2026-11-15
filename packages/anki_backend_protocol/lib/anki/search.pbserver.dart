//
//  Generated code. Do not modify.
//  source: anki/search.proto
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
import 'search.pb.dart' as $15;
import 'search.pbjson.dart';

export 'search.pb.dart';

abstract class SearchServiceBase extends $pb.GeneratedService {
  $async.Future<$0.String> buildSearchString($pb.ServerContext ctx, $15.SearchNode request);
  $async.Future<$15.SearchResponse> searchCards($pb.ServerContext ctx, $15.SearchRequest request);
  $async.Future<$15.SearchResponse> searchNotes($pb.ServerContext ctx, $15.SearchRequest request);
  $async.Future<$0.String> joinSearchNodes($pb.ServerContext ctx, $15.JoinSearchNodesRequest request);
  $async.Future<$0.String> replaceSearchNode($pb.ServerContext ctx, $15.ReplaceSearchNodeRequest request);
  $async.Future<$2.OpChangesWithCount> findAndReplace($pb.ServerContext ctx, $15.FindAndReplaceRequest request);
  $async.Future<$15.BrowserColumns> allBrowserColumns($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$15.BrowserRow> browserRowForId($pb.ServerContext ctx, $0.Int64 request);
  $async.Future<$0.Empty> setActiveBrowserColumns($pb.ServerContext ctx, $0.StringList request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'BuildSearchString': return $15.SearchNode();
      case 'SearchCards': return $15.SearchRequest();
      case 'SearchNotes': return $15.SearchRequest();
      case 'JoinSearchNodes': return $15.JoinSearchNodesRequest();
      case 'ReplaceSearchNode': return $15.ReplaceSearchNodeRequest();
      case 'FindAndReplace': return $15.FindAndReplaceRequest();
      case 'AllBrowserColumns': return $0.Empty();
      case 'BrowserRowForId': return $0.Int64();
      case 'SetActiveBrowserColumns': return $0.StringList();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'BuildSearchString': return this.buildSearchString(ctx, request as $15.SearchNode);
      case 'SearchCards': return this.searchCards(ctx, request as $15.SearchRequest);
      case 'SearchNotes': return this.searchNotes(ctx, request as $15.SearchRequest);
      case 'JoinSearchNodes': return this.joinSearchNodes(ctx, request as $15.JoinSearchNodesRequest);
      case 'ReplaceSearchNode': return this.replaceSearchNode(ctx, request as $15.ReplaceSearchNodeRequest);
      case 'FindAndReplace': return this.findAndReplace(ctx, request as $15.FindAndReplaceRequest);
      case 'AllBrowserColumns': return this.allBrowserColumns(ctx, request as $0.Empty);
      case 'BrowserRowForId': return this.browserRowForId(ctx, request as $0.Int64);
      case 'SetActiveBrowserColumns': return this.setActiveBrowserColumns(ctx, request as $0.StringList);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SearchServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => SearchServiceBase$messageJson;
}

abstract class BackendSearchServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendSearchServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendSearchServiceBase$messageJson;
}
