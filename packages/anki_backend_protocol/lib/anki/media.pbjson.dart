// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/media.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'generic.pbjson.dart' as $0;
import 'notetypes.pbjson.dart' as $12;

@$core.Deprecated('Use checkMediaResponseDescriptor instead')
const CheckMediaResponse$json = {
  '1': 'CheckMediaResponse',
  '2': [
    {'1': 'unused', '3': 1, '4': 3, '5': 9, '10': 'unused'},
    {'1': 'missing', '3': 2, '4': 3, '5': 9, '10': 'missing'},
    {'1': 'missing_media_notes', '3': 3, '4': 3, '5': 3, '10': 'missingMediaNotes'},
    {'1': 'report', '3': 4, '4': 1, '5': 9, '10': 'report'},
    {'1': 'have_trash', '3': 5, '4': 1, '5': 8, '10': 'haveTrash'},
  ],
};

/// Descriptor for `CheckMediaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkMediaResponseDescriptor = $convert.base64Decode(
    'ChJDaGVja01lZGlhUmVzcG9uc2USFgoGdW51c2VkGAEgAygJUgZ1bnVzZWQSGAoHbWlzc2luZx'
    'gCIAMoCVIHbWlzc2luZxIuChNtaXNzaW5nX21lZGlhX25vdGVzGAMgAygDUhFtaXNzaW5nTWVk'
    'aWFOb3RlcxIWCgZyZXBvcnQYBCABKAlSBnJlcG9ydBIdCgpoYXZlX3RyYXNoGAUgASgIUgloYX'
    'ZlVHJhc2g=');

@$core.Deprecated('Use trashMediaFilesRequestDescriptor instead')
const TrashMediaFilesRequest$json = {
  '1': 'TrashMediaFilesRequest',
  '2': [
    {'1': 'fnames', '3': 1, '4': 3, '5': 9, '10': 'fnames'},
  ],
};

/// Descriptor for `TrashMediaFilesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trashMediaFilesRequestDescriptor = $convert.base64Decode(
    'ChZUcmFzaE1lZGlhRmlsZXNSZXF1ZXN0EhYKBmZuYW1lcxgBIAMoCVIGZm5hbWVz');

@$core.Deprecated('Use addMediaFileRequestDescriptor instead')
const AddMediaFileRequest$json = {
  '1': 'AddMediaFileRequest',
  '2': [
    {'1': 'desired_name', '3': 1, '4': 1, '5': 9, '10': 'desiredName'},
    {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `AddMediaFileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addMediaFileRequestDescriptor = $convert.base64Decode(
    'ChNBZGRNZWRpYUZpbGVSZXF1ZXN0EiEKDGRlc2lyZWRfbmFtZRgBIAEoCVILZGVzaXJlZE5hbW'
    'USEgoEZGF0YRgCIAEoDFIEZGF0YQ==');

const $core.Map<$core.String, $core.dynamic> MediaServiceBase$json = {
  '1': 'MediaService',
  '2': [
    {'1': 'CheckMedia', '2': '.anki.generic.Empty', '3': '.anki.media.CheckMediaResponse'},
    {'1': 'AddMediaFile', '2': '.anki.media.AddMediaFileRequest', '3': '.anki.generic.String'},
    {'1': 'TrashMediaFiles', '2': '.anki.media.TrashMediaFilesRequest', '3': '.anki.generic.Empty'},
    {'1': 'EmptyTrash', '2': '.anki.generic.Empty', '3': '.anki.generic.Empty'},
    {'1': 'RestoreTrash', '2': '.anki.generic.Empty', '3': '.anki.generic.Empty'},
    {'1': 'ExtractStaticMediaFiles', '2': '.anki.notetypes.NotetypeId', '3': '.anki.generic.StringList'},
  ],
};

@$core.Deprecated('Use mediaServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> MediaServiceBase$messageJson = {
  '.anki.generic.Empty': $0.Empty$json,
  '.anki.media.CheckMediaResponse': CheckMediaResponse$json,
  '.anki.media.AddMediaFileRequest': AddMediaFileRequest$json,
  '.anki.generic.String': $0.String$json,
  '.anki.media.TrashMediaFilesRequest': TrashMediaFilesRequest$json,
  '.anki.notetypes.NotetypeId': $12.NotetypeId$json,
  '.anki.generic.StringList': $0.StringList$json,
};

/// Descriptor for `MediaService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List mediaServiceDescriptor = $convert.base64Decode(
    'CgxNZWRpYVNlcnZpY2USQQoKQ2hlY2tNZWRpYRITLmFua2kuZ2VuZXJpYy5FbXB0eRoeLmFua2'
    'kubWVkaWEuQ2hlY2tNZWRpYVJlc3BvbnNlEkUKDEFkZE1lZGlhRmlsZRIfLmFua2kubWVkaWEu'
    'QWRkTWVkaWFGaWxlUmVxdWVzdBoULmFua2kuZ2VuZXJpYy5TdHJpbmcSSgoPVHJhc2hNZWRpYU'
    'ZpbGVzEiIuYW5raS5tZWRpYS5UcmFzaE1lZGlhRmlsZXNSZXF1ZXN0GhMuYW5raS5nZW5lcmlj'
    'LkVtcHR5EjYKCkVtcHR5VHJhc2gSEy5hbmtpLmdlbmVyaWMuRW1wdHkaEy5hbmtpLmdlbmVyaW'
    'MuRW1wdHkSOAoMUmVzdG9yZVRyYXNoEhMuYW5raS5nZW5lcmljLkVtcHR5GhMuYW5raS5nZW5l'
    'cmljLkVtcHR5Ek8KF0V4dHJhY3RTdGF0aWNNZWRpYUZpbGVzEhouYW5raS5ub3RldHlwZXMuTm'
    '90ZXR5cGVJZBoYLmFua2kuZ2VuZXJpYy5TdHJpbmdMaXN0');

const $core.Map<$core.String, $core.dynamic> BackendMediaServiceBase$json = {'1': 'BackendMediaService'};

@$core.Deprecated('Use backendMediaServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> BackendMediaServiceBase$messageJson = {
};

/// Descriptor for `BackendMediaService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List backendMediaServiceDescriptor = $convert.base64Decode(
    'ChNCYWNrZW5kTWVkaWFTZXJ2aWNl');
