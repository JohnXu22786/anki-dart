//
//  Generated code. Do not modify.
//  source: anki/frontend.proto
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

import 'frontend.pb.dart' as $16;
import 'frontend.pbjson.dart';
import 'generic.pb.dart' as $0;
import 'search.pb.dart' as $15;

export 'frontend.pb.dart';

abstract class FrontendServiceBase extends $pb.GeneratedService {
  $async.Future<$16.SchedulingStatesWithContext> getSchedulingStatesWithContext($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> setSchedulingStates($pb.ServerContext ctx, $16.SetSchedulingStatesRequest request);
  $async.Future<$0.Empty> importDone($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> searchInBrowser($pb.ServerContext ctx, $15.SearchNode request);
  $async.Future<$0.Empty> deckOptionsRequireClose($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> deckOptionsReady($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> saveCustomColours($pb.ServerContext ctx, $0.Empty request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetSchedulingStatesWithContext': return $0.Empty();
      case 'SetSchedulingStates': return $16.SetSchedulingStatesRequest();
      case 'ImportDone': return $0.Empty();
      case 'SearchInBrowser': return $15.SearchNode();
      case 'deckOptionsRequireClose': return $0.Empty();
      case 'deckOptionsReady': return $0.Empty();
      case 'SaveCustomColours': return $0.Empty();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetSchedulingStatesWithContext': return this.getSchedulingStatesWithContext(ctx, request as $0.Empty);
      case 'SetSchedulingStates': return this.setSchedulingStates(ctx, request as $16.SetSchedulingStatesRequest);
      case 'ImportDone': return this.importDone(ctx, request as $0.Empty);
      case 'SearchInBrowser': return this.searchInBrowser(ctx, request as $15.SearchNode);
      case 'deckOptionsRequireClose': return this.deckOptionsRequireClose(ctx, request as $0.Empty);
      case 'deckOptionsReady': return this.deckOptionsReady(ctx, request as $0.Empty);
      case 'SaveCustomColours': return this.saveCustomColours(ctx, request as $0.Empty);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => FrontendServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => FrontendServiceBase$messageJson;
}

abstract class BackendFrontendServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendFrontendServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendFrontendServiceBase$messageJson;
}
