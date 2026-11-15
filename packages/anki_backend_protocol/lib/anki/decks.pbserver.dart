//
//  Generated code. Do not modify.
//  source: anki/decks.proto
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
import 'decks.pb.dart' as $4;
import 'decks.pbjson.dart';
import 'generic.pb.dart' as $0;

export 'decks.pb.dart';

abstract class DecksServiceBase extends $pb.GeneratedService {
  $async.Future<$4.Deck> newDeck($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChangesWithId> addDeck($pb.ServerContext ctx, $4.Deck request);
  $async.Future<$2.OpChangesWithId> addDeckLegacy($pb.ServerContext ctx, $0.Json request);
  $async.Future<$4.DeckId> addOrUpdateDeckLegacy($pb.ServerContext ctx, $4.AddOrUpdateDeckLegacyRequest request);
  $async.Future<$4.DeckTreeNode> deckTree($pb.ServerContext ctx, $4.DeckTreeRequest request);
  $async.Future<$0.Json> deckTreeLegacy($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Json> getAllDecksLegacy($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$4.DeckId> getDeckIdByName($pb.ServerContext ctx, $0.String request);
  $async.Future<$4.Deck> getDeck($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$2.OpChanges> updateDeck($pb.ServerContext ctx, $4.Deck request);
  $async.Future<$2.OpChanges> updateDeckLegacy($pb.ServerContext ctx, $0.Json request);
  $async.Future<$2.OpChanges> setDeckCollapsed($pb.ServerContext ctx, $4.SetDeckCollapsedRequest request);
  $async.Future<$0.Json> getDeckLegacy($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$4.DeckNames> getDeckNames($pb.ServerContext ctx, $4.GetDeckNamesRequest request);
  $async.Future<$4.DeckNames> getDeckAndChildNames($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$0.Json> newDeckLegacy($pb.ServerContext ctx, $0.Bool request);
  $async.Future<$2.OpChangesWithCount> removeDecks($pb.ServerContext ctx, $4.DeckIds request);
  $async.Future<$2.OpChangesWithCount> reparentDecks($pb.ServerContext ctx, $4.ReparentDecksRequest request);
  $async.Future<$2.OpChanges> renameDeck($pb.ServerContext ctx, $4.RenameDeckRequest request);
  $async.Future<$4.FilteredDeckForUpdate> getOrCreateFilteredDeck($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$2.OpChangesWithId> addOrUpdateFilteredDeck($pb.ServerContext ctx, $4.FilteredDeckForUpdate request);
  $async.Future<$0.StringList> filteredDeckOrderLabels($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChanges> setCurrentDeck($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$4.Deck> getCurrentDeck($pb.ServerContext ctx, $0.Empty request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'NewDeck': return $0.Empty();
      case 'AddDeck': return $4.Deck();
      case 'AddDeckLegacy': return $0.Json();
      case 'AddOrUpdateDeckLegacy': return $4.AddOrUpdateDeckLegacyRequest();
      case 'DeckTree': return $4.DeckTreeRequest();
      case 'DeckTreeLegacy': return $0.Empty();
      case 'GetAllDecksLegacy': return $0.Empty();
      case 'GetDeckIdByName': return $0.String();
      case 'GetDeck': return $4.DeckId();
      case 'UpdateDeck': return $4.Deck();
      case 'UpdateDeckLegacy': return $0.Json();
      case 'SetDeckCollapsed': return $4.SetDeckCollapsedRequest();
      case 'GetDeckLegacy': return $4.DeckId();
      case 'GetDeckNames': return $4.GetDeckNamesRequest();
      case 'GetDeckAndChildNames': return $4.DeckId();
      case 'NewDeckLegacy': return $0.Bool();
      case 'RemoveDecks': return $4.DeckIds();
      case 'ReparentDecks': return $4.ReparentDecksRequest();
      case 'RenameDeck': return $4.RenameDeckRequest();
      case 'GetOrCreateFilteredDeck': return $4.DeckId();
      case 'AddOrUpdateFilteredDeck': return $4.FilteredDeckForUpdate();
      case 'FilteredDeckOrderLabels': return $0.Empty();
      case 'SetCurrentDeck': return $4.DeckId();
      case 'GetCurrentDeck': return $0.Empty();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'NewDeck': return this.newDeck(ctx, request as $0.Empty);
      case 'AddDeck': return this.addDeck(ctx, request as $4.Deck);
      case 'AddDeckLegacy': return this.addDeckLegacy(ctx, request as $0.Json);
      case 'AddOrUpdateDeckLegacy': return this.addOrUpdateDeckLegacy(ctx, request as $4.AddOrUpdateDeckLegacyRequest);
      case 'DeckTree': return this.deckTree(ctx, request as $4.DeckTreeRequest);
      case 'DeckTreeLegacy': return this.deckTreeLegacy(ctx, request as $0.Empty);
      case 'GetAllDecksLegacy': return this.getAllDecksLegacy(ctx, request as $0.Empty);
      case 'GetDeckIdByName': return this.getDeckIdByName(ctx, request as $0.String);
      case 'GetDeck': return this.getDeck(ctx, request as $4.DeckId);
      case 'UpdateDeck': return this.updateDeck(ctx, request as $4.Deck);
      case 'UpdateDeckLegacy': return this.updateDeckLegacy(ctx, request as $0.Json);
      case 'SetDeckCollapsed': return this.setDeckCollapsed(ctx, request as $4.SetDeckCollapsedRequest);
      case 'GetDeckLegacy': return this.getDeckLegacy(ctx, request as $4.DeckId);
      case 'GetDeckNames': return this.getDeckNames(ctx, request as $4.GetDeckNamesRequest);
      case 'GetDeckAndChildNames': return this.getDeckAndChildNames(ctx, request as $4.DeckId);
      case 'NewDeckLegacy': return this.newDeckLegacy(ctx, request as $0.Bool);
      case 'RemoveDecks': return this.removeDecks(ctx, request as $4.DeckIds);
      case 'ReparentDecks': return this.reparentDecks(ctx, request as $4.ReparentDecksRequest);
      case 'RenameDeck': return this.renameDeck(ctx, request as $4.RenameDeckRequest);
      case 'GetOrCreateFilteredDeck': return this.getOrCreateFilteredDeck(ctx, request as $4.DeckId);
      case 'AddOrUpdateFilteredDeck': return this.addOrUpdateFilteredDeck(ctx, request as $4.FilteredDeckForUpdate);
      case 'FilteredDeckOrderLabels': return this.filteredDeckOrderLabels(ctx, request as $0.Empty);
      case 'SetCurrentDeck': return this.setCurrentDeck(ctx, request as $4.DeckId);
      case 'GetCurrentDeck': return this.getCurrentDeck(ctx, request as $0.Empty);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => DecksServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => DecksServiceBase$messageJson;
}

abstract class BackendDecksServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendDecksServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendDecksServiceBase$messageJson;
}
