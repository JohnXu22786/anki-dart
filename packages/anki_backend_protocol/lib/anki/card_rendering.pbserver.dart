// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/card_rendering.proto
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

import 'card_rendering.pb.dart' as $14;
import 'card_rendering.pbjson.dart';
import 'generic.pb.dart' as $0;

export 'card_rendering.pb.dart';

abstract class CardRenderingServiceBase extends $pb.GeneratedService {
  $async.Future<$14.ExtractAvTagsResponse> extractAvTags($pb.ServerContext ctx, $14.ExtractAvTagsRequest request);
  $async.Future<$14.ExtractLatexResponse> extractLatex($pb.ServerContext ctx, $14.ExtractLatexRequest request);
  $async.Future<$14.EmptyCardsReport> getEmptyCards($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$14.RenderCardResponse> renderExistingCard($pb.ServerContext ctx, $14.RenderExistingCardRequest request);
  $async.Future<$14.RenderCardResponse> renderUncommittedCard($pb.ServerContext ctx, $14.RenderUncommittedCardRequest request);
  $async.Future<$14.RenderCardResponse> renderUncommittedCardLegacy($pb.ServerContext ctx, $14.RenderUncommittedCardLegacyRequest request);
  $async.Future<$0.String> stripAvTags($pb.ServerContext ctx, $0.String request);
  $async.Future<$0.String> renderMarkdown($pb.ServerContext ctx, $14.RenderMarkdownRequest request);
  $async.Future<$0.String> encodeIriPaths($pb.ServerContext ctx, $0.String request);
  $async.Future<$0.String> decodeIriPaths($pb.ServerContext ctx, $0.String request);
  $async.Future<$0.String> stripHtml($pb.ServerContext ctx, $14.StripHtmlRequest request);
  $async.Future<$0.String> htmlToTextLine($pb.ServerContext ctx, $14.HtmlToTextLineRequest request);
  $async.Future<$0.String> compareAnswer($pb.ServerContext ctx, $14.CompareAnswerRequest request);
  $async.Future<$0.String> extractClozeForTyping($pb.ServerContext ctx, $14.ExtractClozeForTypingRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ExtractAvTags': return $14.ExtractAvTagsRequest();
      case 'ExtractLatex': return $14.ExtractLatexRequest();
      case 'GetEmptyCards': return $0.Empty();
      case 'RenderExistingCard': return $14.RenderExistingCardRequest();
      case 'RenderUncommittedCard': return $14.RenderUncommittedCardRequest();
      case 'RenderUncommittedCardLegacy': return $14.RenderUncommittedCardLegacyRequest();
      case 'StripAvTags': return $0.String();
      case 'RenderMarkdown': return $14.RenderMarkdownRequest();
      case 'EncodeIriPaths': return $0.String();
      case 'DecodeIriPaths': return $0.String();
      case 'StripHtml': return $14.StripHtmlRequest();
      case 'HtmlToTextLine': return $14.HtmlToTextLineRequest();
      case 'CompareAnswer': return $14.CompareAnswerRequest();
      case 'ExtractClozeForTyping': return $14.ExtractClozeForTypingRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ExtractAvTags': return this.extractAvTags(ctx, request as $14.ExtractAvTagsRequest);
      case 'ExtractLatex': return this.extractLatex(ctx, request as $14.ExtractLatexRequest);
      case 'GetEmptyCards': return this.getEmptyCards(ctx, request as $0.Empty);
      case 'RenderExistingCard': return this.renderExistingCard(ctx, request as $14.RenderExistingCardRequest);
      case 'RenderUncommittedCard': return this.renderUncommittedCard(ctx, request as $14.RenderUncommittedCardRequest);
      case 'RenderUncommittedCardLegacy': return this.renderUncommittedCardLegacy(ctx, request as $14.RenderUncommittedCardLegacyRequest);
      case 'StripAvTags': return this.stripAvTags(ctx, request as $0.String);
      case 'RenderMarkdown': return this.renderMarkdown(ctx, request as $14.RenderMarkdownRequest);
      case 'EncodeIriPaths': return this.encodeIriPaths(ctx, request as $0.String);
      case 'DecodeIriPaths': return this.decodeIriPaths(ctx, request as $0.String);
      case 'StripHtml': return this.stripHtml(ctx, request as $14.StripHtmlRequest);
      case 'HtmlToTextLine': return this.htmlToTextLine(ctx, request as $14.HtmlToTextLineRequest);
      case 'CompareAnswer': return this.compareAnswer(ctx, request as $14.CompareAnswerRequest);
      case 'ExtractClozeForTyping': return this.extractClozeForTyping(ctx, request as $14.ExtractClozeForTypingRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => CardRenderingServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => CardRenderingServiceBase$messageJson;
}

abstract class BackendCardRenderingServiceBase extends $pb.GeneratedService {
  $async.Future<$0.String> stripHtml($pb.ServerContext ctx, $14.StripHtmlRequest request);
  $async.Future<$14.AllTtsVoicesResponse> allTtsVoices($pb.ServerContext ctx, $14.AllTtsVoicesRequest request);
  $async.Future<$0.Empty> writeTtsStream($pb.ServerContext ctx, $14.WriteTtsStreamRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'StripHtml': return $14.StripHtmlRequest();
      case 'AllTtsVoices': return $14.AllTtsVoicesRequest();
      case 'WriteTtsStream': return $14.WriteTtsStreamRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'StripHtml': return this.stripHtml(ctx, request as $14.StripHtmlRequest);
      case 'AllTtsVoices': return this.allTtsVoices(ctx, request as $14.AllTtsVoicesRequest);
      case 'WriteTtsStream': return this.writeTtsStream(ctx, request as $14.WriteTtsStreamRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendCardRenderingServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendCardRenderingServiceBase$messageJson;
}
