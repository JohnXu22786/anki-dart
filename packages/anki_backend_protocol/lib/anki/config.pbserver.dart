// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/config.proto
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
import 'config.pb.dart' as $5;
import 'config.pbjson.dart';
import 'generic.pb.dart' as $0;

export 'config.pb.dart';

abstract class ConfigServiceBase extends $pb.GeneratedService {
  $async.Future<$0.Json> getConfigJson($pb.ServerContext ctx, $0.String request);
  $async.Future<$2.OpChanges> setConfigJson($pb.ServerContext ctx, $5.SetConfigJsonRequest request);
  $async.Future<$0.Empty> setConfigJsonNoUndo($pb.ServerContext ctx, $5.SetConfigJsonRequest request);
  $async.Future<$2.OpChanges> removeConfig($pb.ServerContext ctx, $0.String request);
  $async.Future<$0.Json> getAllConfig($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Bool> getConfigBool($pb.ServerContext ctx, $5.GetConfigBoolRequest request);
  $async.Future<$2.OpChanges> setConfigBool($pb.ServerContext ctx, $5.SetConfigBoolRequest request);
  $async.Future<$0.String> getConfigString($pb.ServerContext ctx, $5.GetConfigStringRequest request);
  $async.Future<$2.OpChanges> setConfigString($pb.ServerContext ctx, $5.SetConfigStringRequest request);
  $async.Future<$5.Preferences> getPreferences($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChanges> setPreferences($pb.ServerContext ctx, $5.Preferences request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetConfigJson': return $0.String();
      case 'SetConfigJson': return $5.SetConfigJsonRequest();
      case 'SetConfigJsonNoUndo': return $5.SetConfigJsonRequest();
      case 'RemoveConfig': return $0.String();
      case 'GetAllConfig': return $0.Empty();
      case 'GetConfigBool': return $5.GetConfigBoolRequest();
      case 'SetConfigBool': return $5.SetConfigBoolRequest();
      case 'GetConfigString': return $5.GetConfigStringRequest();
      case 'SetConfigString': return $5.SetConfigStringRequest();
      case 'GetPreferences': return $0.Empty();
      case 'SetPreferences': return $5.Preferences();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetConfigJson': return this.getConfigJson(ctx, request as $0.String);
      case 'SetConfigJson': return this.setConfigJson(ctx, request as $5.SetConfigJsonRequest);
      case 'SetConfigJsonNoUndo': return this.setConfigJsonNoUndo(ctx, request as $5.SetConfigJsonRequest);
      case 'RemoveConfig': return this.removeConfig(ctx, request as $0.String);
      case 'GetAllConfig': return this.getAllConfig(ctx, request as $0.Empty);
      case 'GetConfigBool': return this.getConfigBool(ctx, request as $5.GetConfigBoolRequest);
      case 'SetConfigBool': return this.setConfigBool(ctx, request as $5.SetConfigBoolRequest);
      case 'GetConfigString': return this.getConfigString(ctx, request as $5.GetConfigStringRequest);
      case 'SetConfigString': return this.setConfigString(ctx, request as $5.SetConfigStringRequest);
      case 'GetPreferences': return this.getPreferences(ctx, request as $0.Empty);
      case 'SetPreferences': return this.setPreferences(ctx, request as $5.Preferences);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ConfigServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => ConfigServiceBase$messageJson;
}

abstract class BackendConfigServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendConfigServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendConfigServiceBase$messageJson;
}
