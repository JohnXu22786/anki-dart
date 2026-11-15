// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/card_rendering.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class StripHtmlRequest_Mode extends $pb.ProtobufEnum {
  static const StripHtmlRequest_Mode NORMAL = StripHtmlRequest_Mode._(0, _omitEnumNames ? '' : 'NORMAL');
  static const StripHtmlRequest_Mode PRESERVE_MEDIA_FILENAMES = StripHtmlRequest_Mode._(1, _omitEnumNames ? '' : 'PRESERVE_MEDIA_FILENAMES');

  static const $core.List<StripHtmlRequest_Mode> values = <StripHtmlRequest_Mode> [
    NORMAL,
    PRESERVE_MEDIA_FILENAMES,
  ];

  static final $core.Map<$core.int, StripHtmlRequest_Mode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static StripHtmlRequest_Mode? valueOf($core.int value) => _byValue[value];

  const StripHtmlRequest_Mode._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
