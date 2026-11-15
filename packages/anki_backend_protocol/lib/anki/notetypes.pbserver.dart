// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/notetypes.proto
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
import 'notetypes.pb.dart' as $12;
import 'notetypes.pbjson.dart';

export 'notetypes.pb.dart';

abstract class NotetypesServiceBase extends $pb.GeneratedService {
  $async.Future<$2.OpChangesWithId> addNotetype($pb.ServerContext ctx, $12.Notetype request);
  $async.Future<$2.OpChanges> updateNotetype($pb.ServerContext ctx, $12.Notetype request);
  $async.Future<$2.OpChangesWithId> addNotetypeLegacy($pb.ServerContext ctx, $0.Json request);
  $async.Future<$2.OpChanges> updateNotetypeLegacy($pb.ServerContext ctx, $12.UpdateNotetypeLegacyRequest request);
  $async.Future<$12.NotetypeId> addOrUpdateNotetype($pb.ServerContext ctx, $12.AddOrUpdateNotetypeRequest request);
  $async.Future<$0.Json> getStockNotetypeLegacy($pb.ServerContext ctx, $12.StockNotetype request);
  $async.Future<$12.Notetype> getNotetype($pb.ServerContext ctx, $12.NotetypeId request);
  $async.Future<$0.Json> getNotetypeLegacy($pb.ServerContext ctx, $12.NotetypeId request);
  $async.Future<$12.NotetypeNames> getNotetypeNames($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$12.NotetypeUseCounts> getNotetypeNamesAndCounts($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$12.NotetypeId> getNotetypeIdByName($pb.ServerContext ctx, $0.String request);
  $async.Future<$2.OpChanges> removeNotetype($pb.ServerContext ctx, $12.NotetypeId request);
  $async.Future<$0.String> getAuxNotetypeConfigKey($pb.ServerContext ctx, $12.GetAuxConfigKeyRequest request);
  $async.Future<$0.String> getAuxTemplateConfigKey($pb.ServerContext ctx, $12.GetAuxTemplateConfigKeyRequest request);
  $async.Future<$12.ChangeNotetypeInfo> getChangeNotetypeInfo($pb.ServerContext ctx, $12.GetChangeNotetypeInfoRequest request);
  $async.Future<$2.OpChanges> changeNotetype($pb.ServerContext ctx, $12.ChangeNotetypeRequest request);
  $async.Future<$0.StringList> getFieldNames($pb.ServerContext ctx, $12.NotetypeId request);
  $async.Future<$2.OpChanges> restoreNotetypeToStock($pb.ServerContext ctx, $12.RestoreNotetypeToStockRequest request);
  $async.Future<$12.GetClozeFieldOrdsResponse> getClozeFieldOrds($pb.ServerContext ctx, $12.NotetypeId request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'AddNotetype': return $12.Notetype();
      case 'UpdateNotetype': return $12.Notetype();
      case 'AddNotetypeLegacy': return $0.Json();
      case 'UpdateNotetypeLegacy': return $12.UpdateNotetypeLegacyRequest();
      case 'AddOrUpdateNotetype': return $12.AddOrUpdateNotetypeRequest();
      case 'GetStockNotetypeLegacy': return $12.StockNotetype();
      case 'GetNotetype': return $12.NotetypeId();
      case 'GetNotetypeLegacy': return $12.NotetypeId();
      case 'GetNotetypeNames': return $0.Empty();
      case 'GetNotetypeNamesAndCounts': return $0.Empty();
      case 'GetNotetypeIdByName': return $0.String();
      case 'RemoveNotetype': return $12.NotetypeId();
      case 'GetAuxNotetypeConfigKey': return $12.GetAuxConfigKeyRequest();
      case 'GetAuxTemplateConfigKey': return $12.GetAuxTemplateConfigKeyRequest();
      case 'GetChangeNotetypeInfo': return $12.GetChangeNotetypeInfoRequest();
      case 'ChangeNotetype': return $12.ChangeNotetypeRequest();
      case 'GetFieldNames': return $12.NotetypeId();
      case 'RestoreNotetypeToStock': return $12.RestoreNotetypeToStockRequest();
      case 'GetClozeFieldOrds': return $12.NotetypeId();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'AddNotetype': return this.addNotetype(ctx, request as $12.Notetype);
      case 'UpdateNotetype': return this.updateNotetype(ctx, request as $12.Notetype);
      case 'AddNotetypeLegacy': return this.addNotetypeLegacy(ctx, request as $0.Json);
      case 'UpdateNotetypeLegacy': return this.updateNotetypeLegacy(ctx, request as $12.UpdateNotetypeLegacyRequest);
      case 'AddOrUpdateNotetype': return this.addOrUpdateNotetype(ctx, request as $12.AddOrUpdateNotetypeRequest);
      case 'GetStockNotetypeLegacy': return this.getStockNotetypeLegacy(ctx, request as $12.StockNotetype);
      case 'GetNotetype': return this.getNotetype(ctx, request as $12.NotetypeId);
      case 'GetNotetypeLegacy': return this.getNotetypeLegacy(ctx, request as $12.NotetypeId);
      case 'GetNotetypeNames': return this.getNotetypeNames(ctx, request as $0.Empty);
      case 'GetNotetypeNamesAndCounts': return this.getNotetypeNamesAndCounts(ctx, request as $0.Empty);
      case 'GetNotetypeIdByName': return this.getNotetypeIdByName(ctx, request as $0.String);
      case 'RemoveNotetype': return this.removeNotetype(ctx, request as $12.NotetypeId);
      case 'GetAuxNotetypeConfigKey': return this.getAuxNotetypeConfigKey(ctx, request as $12.GetAuxConfigKeyRequest);
      case 'GetAuxTemplateConfigKey': return this.getAuxTemplateConfigKey(ctx, request as $12.GetAuxTemplateConfigKeyRequest);
      case 'GetChangeNotetypeInfo': return this.getChangeNotetypeInfo(ctx, request as $12.GetChangeNotetypeInfoRequest);
      case 'ChangeNotetype': return this.changeNotetype(ctx, request as $12.ChangeNotetypeRequest);
      case 'GetFieldNames': return this.getFieldNames(ctx, request as $12.NotetypeId);
      case 'RestoreNotetypeToStock': return this.restoreNotetypeToStock(ctx, request as $12.RestoreNotetypeToStockRequest);
      case 'GetClozeFieldOrds': return this.getClozeFieldOrds(ctx, request as $12.NotetypeId);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => NotetypesServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => NotetypesServiceBase$messageJson;
}

abstract class BackendNotetypesServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendNotetypesServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendNotetypesServiceBase$messageJson;
}
