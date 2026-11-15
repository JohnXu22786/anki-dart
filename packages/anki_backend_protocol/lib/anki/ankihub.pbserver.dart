//
//  Generated code. Do not modify.
//  source: anki/ankihub.proto
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

import 'ankihub.pb.dart' as $9;
import 'ankihub.pbjson.dart';
import 'generic.pb.dart' as $0;

export 'ankihub.pb.dart';

abstract class AnkiHubServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => AnkiHubServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => AnkiHubServiceBase$messageJson;
}

abstract class BackendAnkiHubServiceBase extends $pb.GeneratedService {
  $async.Future<$9.LoginResponse> ankihubLogin($pb.ServerContext ctx, $9.LoginRequest request);
  $async.Future<$0.Empty> ankihubLogout($pb.ServerContext ctx, $9.LogoutRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'AnkihubLogin': return $9.LoginRequest();
      case 'AnkihubLogout': return $9.LogoutRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'AnkihubLogin': return this.ankihubLogin(ctx, request as $9.LoginRequest);
      case 'AnkihubLogout': return this.ankihubLogout(ctx, request as $9.LogoutRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendAnkiHubServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendAnkiHubServiceBase$messageJson;
}
