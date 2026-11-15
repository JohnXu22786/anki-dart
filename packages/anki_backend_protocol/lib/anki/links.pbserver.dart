// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/links.proto
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

import 'generic.pb.dart' as $0;
import 'links.pb.dart' as $11;
import 'links.pbjson.dart';

export 'links.pb.dart';

abstract class LinksServiceBase extends $pb.GeneratedService {
  $async.Future<$0.String> helpPageLink($pb.ServerContext ctx, $11.HelpPageLinkRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'HelpPageLink': return $11.HelpPageLinkRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'HelpPageLink': return this.helpPageLink(ctx, request as $11.HelpPageLinkRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => LinksServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => LinksServiceBase$messageJson;
}

abstract class BackendLinksServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendLinksServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendLinksServiceBase$messageJson;
}
