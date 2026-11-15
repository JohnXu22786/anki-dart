// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/i18n.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FormatTimespanRequest_Context extends $pb.ProtobufEnum {
  static const FormatTimespanRequest_Context PRECISE = FormatTimespanRequest_Context._(0, _omitEnumNames ? '' : 'PRECISE');
  static const FormatTimespanRequest_Context ANSWER_BUTTONS = FormatTimespanRequest_Context._(1, _omitEnumNames ? '' : 'ANSWER_BUTTONS');
  static const FormatTimespanRequest_Context INTERVALS = FormatTimespanRequest_Context._(2, _omitEnumNames ? '' : 'INTERVALS');

  static const $core.List<FormatTimespanRequest_Context> values = <FormatTimespanRequest_Context> [
    PRECISE,
    ANSWER_BUTTONS,
    INTERVALS,
  ];

  static final $core.Map<$core.int, FormatTimespanRequest_Context> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FormatTimespanRequest_Context? valueOf($core.int value) => _byValue[value];

  const FormatTimespanRequest_Context._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
