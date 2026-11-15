// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/ankiweb.proto
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

import 'ankiweb.pb.dart' as $10;
import 'ankiweb.pbjson.dart';

export 'ankiweb.pb.dart';

abstract class AnkiwebServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => AnkiwebServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => AnkiwebServiceBase$messageJson;
}

abstract class BackendAnkiwebServiceBase extends $pb.GeneratedService {
  $async.Future<$10.GetAddonInfoResponse> getAddonInfo($pb.ServerContext ctx, $10.GetAddonInfoRequest request);
  $async.Future<$10.CheckForUpdateResponse> checkForUpdate($pb.ServerContext ctx, $10.CheckForUpdateRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetAddonInfo': return $10.GetAddonInfoRequest();
      case 'CheckForUpdate': return $10.CheckForUpdateRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetAddonInfo': return this.getAddonInfo(ctx, request as $10.GetAddonInfoRequest);
      case 'CheckForUpdate': return this.checkForUpdate(ctx, request as $10.CheckForUpdateRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendAnkiwebServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendAnkiwebServiceBase$messageJson;
}
