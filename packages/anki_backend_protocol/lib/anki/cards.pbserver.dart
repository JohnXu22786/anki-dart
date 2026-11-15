//
//  Generated code. Do not modify.
//  source: anki/cards.proto
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
import 'cards.pbjson.dart';
import 'collection.pb.dart' as $2;

export 'cards.pb.dart';

abstract class CardsServiceBase extends $pb.GeneratedService {
  $async.Future<$3.Card> getCard($pb.ServerContext ctx, $3.CardId request);
  $async.Future<$2.OpChanges> updateCards($pb.ServerContext ctx, $3.UpdateCardsRequest request);
  $async.Future<$2.OpChangesWithCount> removeCards($pb.ServerContext ctx, $3.RemoveCardsRequest request);
  $async.Future<$2.OpChangesWithCount> setDeck($pb.ServerContext ctx, $3.SetDeckRequest request);
  $async.Future<$2.OpChangesWithCount> setFlag($pb.ServerContext ctx, $3.SetFlagRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetCard': return $3.CardId();
      case 'UpdateCards': return $3.UpdateCardsRequest();
      case 'RemoveCards': return $3.RemoveCardsRequest();
      case 'SetDeck': return $3.SetDeckRequest();
      case 'SetFlag': return $3.SetFlagRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetCard': return this.getCard(ctx, request as $3.CardId);
      case 'UpdateCards': return this.updateCards(ctx, request as $3.UpdateCardsRequest);
      case 'RemoveCards': return this.removeCards(ctx, request as $3.RemoveCardsRequest);
      case 'SetDeck': return this.setDeck(ctx, request as $3.SetDeckRequest);
      case 'SetFlag': return this.setFlag(ctx, request as $3.SetFlagRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => CardsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => CardsServiceBase$messageJson;
}

abstract class BackendCardsServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendCardsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendCardsServiceBase$messageJson;
}
