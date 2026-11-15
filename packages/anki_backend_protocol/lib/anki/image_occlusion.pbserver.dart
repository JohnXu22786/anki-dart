//
//  Generated code. Do not modify.
//  source: anki/image_occlusion.proto
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
import 'image_occlusion.pb.dart' as $19;
import 'image_occlusion.pbjson.dart';

export 'image_occlusion.pb.dart';

abstract class ImageOcclusionServiceBase extends $pb.GeneratedService {
  $async.Future<$19.GetImageForOcclusionResponse> getImageForOcclusion($pb.ServerContext ctx, $19.GetImageForOcclusionRequest request);
  $async.Future<$19.GetImageOcclusionNoteResponse> getImageOcclusionNote($pb.ServerContext ctx, $19.GetImageOcclusionNoteRequest request);
  $async.Future<$19.GetImageOcclusionFieldsResponse> getImageOcclusionFields($pb.ServerContext ctx, $19.GetImageOcclusionFieldsRequest request);
  $async.Future<$2.OpChanges> addImageOcclusionNotetype($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChanges> addImageOcclusionNote($pb.ServerContext ctx, $19.AddImageOcclusionNoteRequest request);
  $async.Future<$2.OpChanges> updateImageOcclusionNote($pb.ServerContext ctx, $19.UpdateImageOcclusionNoteRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetImageForOcclusion': return $19.GetImageForOcclusionRequest();
      case 'GetImageOcclusionNote': return $19.GetImageOcclusionNoteRequest();
      case 'GetImageOcclusionFields': return $19.GetImageOcclusionFieldsRequest();
      case 'AddImageOcclusionNotetype': return $0.Empty();
      case 'AddImageOcclusionNote': return $19.AddImageOcclusionNoteRequest();
      case 'UpdateImageOcclusionNote': return $19.UpdateImageOcclusionNoteRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetImageForOcclusion': return this.getImageForOcclusion(ctx, request as $19.GetImageForOcclusionRequest);
      case 'GetImageOcclusionNote': return this.getImageOcclusionNote(ctx, request as $19.GetImageOcclusionNoteRequest);
      case 'GetImageOcclusionFields': return this.getImageOcclusionFields(ctx, request as $19.GetImageOcclusionFieldsRequest);
      case 'AddImageOcclusionNotetype': return this.addImageOcclusionNotetype(ctx, request as $0.Empty);
      case 'AddImageOcclusionNote': return this.addImageOcclusionNote(ctx, request as $19.AddImageOcclusionNoteRequest);
      case 'UpdateImageOcclusionNote': return this.updateImageOcclusionNote(ctx, request as $19.UpdateImageOcclusionNoteRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ImageOcclusionServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => ImageOcclusionServiceBase$messageJson;
}

abstract class BackendImageOcclusionServiceBase extends $pb.GeneratedService {

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

  $core.Map<$core.String, $core.dynamic> get $json => BackendImageOcclusionServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendImageOcclusionServiceBase$messageJson;
}
