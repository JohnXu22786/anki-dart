//
//  Generated code. Do not modify.
//  source: anki/ankidroid.proto
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

import 'ankidroid.pb.dart' as $8;
import 'ankidroid.pbjson.dart';
import 'generic.pb.dart' as $0;
import 'scheduler.pb.dart' as $7;

export 'ankidroid.pb.dart';

abstract class AnkidroidServiceBase extends $pb.GeneratedService {
  $async.Future<$0.Json> runDbCommand($pb.ServerContext ctx, $0.Json request);
  $async.Future<$8.DbResponse> runDbCommandProto($pb.ServerContext ctx, $0.Json request);
  $async.Future<$0.Int64> insertForId($pb.ServerContext ctx, $0.Json request);
  $async.Future<$0.Int64> runDbCommandForRowCount($pb.ServerContext ctx, $0.Json request);
  $async.Future<$0.Empty> flushAllQueries($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> flushQuery($pb.ServerContext ctx, $0.Int32 request);
  $async.Future<$8.DbResponse> getNextResultPage($pb.ServerContext ctx, $8.GetNextResultPageRequest request);
  $async.Future<$0.StringList> getColumnNamesFromQuery($pb.ServerContext ctx, $0.String request);
  $async.Future<$8.GetActiveSequenceNumbersResponse> getActiveSequenceNumbers($pb.ServerContext ctx, $0.Empty request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'RunDbCommand': return $0.Json();
      case 'RunDbCommandProto': return $0.Json();
      case 'InsertForId': return $0.Json();
      case 'RunDbCommandForRowCount': return $0.Json();
      case 'FlushAllQueries': return $0.Empty();
      case 'FlushQuery': return $0.Int32();
      case 'GetNextResultPage': return $8.GetNextResultPageRequest();
      case 'GetColumnNamesFromQuery': return $0.String();
      case 'GetActiveSequenceNumbers': return $0.Empty();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'RunDbCommand': return this.runDbCommand(ctx, request as $0.Json);
      case 'RunDbCommandProto': return this.runDbCommandProto(ctx, request as $0.Json);
      case 'InsertForId': return this.insertForId(ctx, request as $0.Json);
      case 'RunDbCommandForRowCount': return this.runDbCommandForRowCount(ctx, request as $0.Json);
      case 'FlushAllQueries': return this.flushAllQueries(ctx, request as $0.Empty);
      case 'FlushQuery': return this.flushQuery(ctx, request as $0.Int32);
      case 'GetNextResultPage': return this.getNextResultPage(ctx, request as $8.GetNextResultPageRequest);
      case 'GetColumnNamesFromQuery': return this.getColumnNamesFromQuery(ctx, request as $0.String);
      case 'GetActiveSequenceNumbers': return this.getActiveSequenceNumbers(ctx, request as $0.Empty);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => AnkidroidServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => AnkidroidServiceBase$messageJson;
}

abstract class BackendAnkidroidServiceBase extends $pb.GeneratedService {
  $async.Future<$7.SchedTimingTodayResponse> schedTimingTodayLegacy($pb.ServerContext ctx, $8.SchedTimingTodayLegacyRequest request);
  $async.Future<$0.Int32> localMinutesWestLegacy($pb.ServerContext ctx, $0.Int64 request);
  $async.Future<$0.Empty> setPageSize($pb.ServerContext ctx, $0.Int64 request);
  $async.Future<$0.Empty> debugProduceError($pb.ServerContext ctx, $0.String request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'SchedTimingTodayLegacy': return $8.SchedTimingTodayLegacyRequest();
      case 'LocalMinutesWestLegacy': return $0.Int64();
      case 'SetPageSize': return $0.Int64();
      case 'DebugProduceError': return $0.String();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'SchedTimingTodayLegacy': return this.schedTimingTodayLegacy(ctx, request as $8.SchedTimingTodayLegacyRequest);
      case 'LocalMinutesWestLegacy': return this.localMinutesWestLegacy(ctx, request as $0.Int64);
      case 'SetPageSize': return this.setPageSize(ctx, request as $0.Int64);
      case 'DebugProduceError': return this.debugProduceError(ctx, request as $0.String);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendAnkidroidServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendAnkidroidServiceBase$messageJson;
}
