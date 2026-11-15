// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/deck_config.proto
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
import 'deck_config.pb.dart' as $6;
import 'deck_config.pbjson.dart';
import 'decks.pb.dart' as $4;
import 'generic.pb.dart' as $0;

export 'deck_config.pb.dart';

abstract class DeckConfigServiceBase extends $pb.GeneratedService {
  $async.Future<$6.DeckConfigId> addOrUpdateDeckConfigLegacy($pb.ServerContext ctx, $0.Json request);
  $async.Future<$6.DeckConfig> getDeckConfig($pb.ServerContext ctx, $6.DeckConfigId request);
  $async.Future<$0.Json> allDeckConfigLegacy($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Json> getDeckConfigLegacy($pb.ServerContext ctx, $6.DeckConfigId request);
  $async.Future<$0.Json> newDeckConfigLegacy($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> removeDeckConfig($pb.ServerContext ctx, $6.DeckConfigId request);
  $async.Future<$6.DeckConfigsForUpdate> getDeckConfigsForUpdate($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$2.OpChanges> updateDeckConfigs($pb.ServerContext ctx, $6.UpdateDeckConfigsRequest request);
  $async.Future<$6.GetIgnoredBeforeCountResponse> getIgnoredBeforeCount($pb.ServerContext ctx, $6.GetIgnoredBeforeCountRequest request);
  $async.Future<$6.GetRetentionWorkloadResponse> getRetentionWorkload($pb.ServerContext ctx, $6.GetRetentionWorkloadRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'AddOrUpdateDeckConfigLegacy': return $0.Json();
      case 'GetDeckConfig': return $6.DeckConfigId();
      case 'AllDeckConfigLegacy': return $0.Empty();
      case 'GetDeckConfigLegacy': return $6.DeckConfigId();
      case 'NewDeckConfigLegacy': return $0.Empty();
      case 'RemoveDeckConfig': return $6.DeckConfigId();
      case 'GetDeckConfigsForUpdate': return $4.DeckId();
      case 'UpdateDeckConfigs': return $6.UpdateDeckConfigsRequest();
      case 'GetIgnoredBeforeCount': return $6.GetIgnoredBeforeCountRequest();
      case 'GetRetentionWorkload': return $6.GetRetentionWorkloadRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'AddOrUpdateDeckConfigLegacy': return this.addOrUpdateDeckConfigLegacy(ctx, request as $0.Json);
      case 'GetDeckConfig': return this.getDeckConfig(ctx, request as $6.DeckConfigId);
      case 'AllDeckConfigLegacy': return this.allDeckConfigLegacy(ctx, request as $0.Empty);
      case 'GetDeckConfigLegacy': return this.getDeckConfigLegacy(ctx, request as $6.DeckConfigId);
      case 'NewDeckConfigLegacy': return this.newDeckConfigLegacy(ctx, request as $0.Empty);
      case 'RemoveDeckConfig': return this.removeDeckConfig(ctx, request as $6.DeckConfigId);
      case 'GetDeckConfigsForUpdate': return this.getDeckConfigsForUpdate(ctx, request as $4.DeckId);
      case 'UpdateDeckConfigs': return this.updateDeckConfigs(ctx, request as $6.UpdateDeckConfigsRequest);
      case 'GetIgnoredBeforeCount': return this.getIgnoredBeforeCount(ctx, request as $6.GetIgnoredBeforeCountRequest);
      case 'GetRetentionWorkload': return this.getRetentionWorkload(ctx, request as $6.GetRetentionWorkloadRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => DeckConfigServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => DeckConfigServiceBase$messageJson;
}

abstract class BackendDeckConfigServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendDeckConfigServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendDeckConfigServiceBase$messageJson;
}
