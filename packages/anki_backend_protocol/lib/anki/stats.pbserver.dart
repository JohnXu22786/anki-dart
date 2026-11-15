// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/stats.proto
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

import 'cards.pb.dart' as $3;
import 'generic.pb.dart' as $0;
import 'stats.pb.dart' as $22;
import 'stats.pbjson.dart';

export 'stats.pb.dart';

abstract class StatsServiceBase extends $pb.GeneratedService {
  $async.Future<$22.CardStatsResponse> cardStats($pb.ServerContext ctx, $3.CardId request);
  $async.Future<$22.ReviewLogs> getReviewLogs($pb.ServerContext ctx, $3.CardId request);
  $async.Future<$22.GraphsResponse> graphs($pb.ServerContext ctx, $22.GraphsRequest request);
  $async.Future<$22.GraphPreferences> getGraphPreferences($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> setGraphPreferences($pb.ServerContext ctx, $22.GraphPreferences request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'CardStats': return $3.CardId();
      case 'GetReviewLogs': return $3.CardId();
      case 'Graphs': return $22.GraphsRequest();
      case 'GetGraphPreferences': return $0.Empty();
      case 'SetGraphPreferences': return $22.GraphPreferences();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'CardStats': return this.cardStats(ctx, request as $3.CardId);
      case 'GetReviewLogs': return this.getReviewLogs(ctx, request as $3.CardId);
      case 'Graphs': return this.graphs(ctx, request as $22.GraphsRequest);
      case 'GetGraphPreferences': return this.getGraphPreferences(ctx, request as $0.Empty);
      case 'SetGraphPreferences': return this.setGraphPreferences(ctx, request as $22.GraphPreferences);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => StatsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => StatsServiceBase$messageJson;
}

abstract class BackendStatsServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendStatsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendStatsServiceBase$messageJson;
}
