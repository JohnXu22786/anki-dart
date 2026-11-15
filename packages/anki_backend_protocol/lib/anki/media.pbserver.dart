// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/media.proto
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
import 'media.pb.dart' as $21;
import 'media.pbjson.dart';
import 'notetypes.pb.dart' as $12;

export 'media.pb.dart';

abstract class MediaServiceBase extends $pb.GeneratedService {
  $async.Future<$21.CheckMediaResponse> checkMedia($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.String> addMediaFile($pb.ServerContext ctx, $21.AddMediaFileRequest request);
  $async.Future<$0.Empty> trashMediaFiles($pb.ServerContext ctx, $21.TrashMediaFilesRequest request);
  $async.Future<$0.Empty> emptyTrash($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.Empty> restoreTrash($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.StringList> extractStaticMediaFiles($pb.ServerContext ctx, $12.NotetypeId request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'CheckMedia': return $0.Empty();
      case 'AddMediaFile': return $21.AddMediaFileRequest();
      case 'TrashMediaFiles': return $21.TrashMediaFilesRequest();
      case 'EmptyTrash': return $0.Empty();
      case 'RestoreTrash': return $0.Empty();
      case 'ExtractStaticMediaFiles': return $12.NotetypeId();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'CheckMedia': return this.checkMedia(ctx, request as $0.Empty);
      case 'AddMediaFile': return this.addMediaFile(ctx, request as $21.AddMediaFileRequest);
      case 'TrashMediaFiles': return this.trashMediaFiles(ctx, request as $21.TrashMediaFilesRequest);
      case 'EmptyTrash': return this.emptyTrash(ctx, request as $0.Empty);
      case 'RestoreTrash': return this.restoreTrash(ctx, request as $0.Empty);
      case 'ExtractStaticMediaFiles': return this.extractStaticMediaFiles(ctx, request as $12.NotetypeId);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => MediaServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => MediaServiceBase$messageJson;
}

abstract class BackendMediaServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendMediaServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendMediaServiceBase$messageJson;
}
