// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  Generated code. Do not modify.
//  source: anki/notes.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class NoteFieldsCheckResponse_State extends $pb.ProtobufEnum {
  static const NoteFieldsCheckResponse_State NORMAL = NoteFieldsCheckResponse_State._(0, _omitEnumNames ? '' : 'NORMAL');
  static const NoteFieldsCheckResponse_State EMPTY = NoteFieldsCheckResponse_State._(1, _omitEnumNames ? '' : 'EMPTY');
  static const NoteFieldsCheckResponse_State DUPLICATE = NoteFieldsCheckResponse_State._(2, _omitEnumNames ? '' : 'DUPLICATE');
  static const NoteFieldsCheckResponse_State MISSING_CLOZE = NoteFieldsCheckResponse_State._(3, _omitEnumNames ? '' : 'MISSING_CLOZE');
  static const NoteFieldsCheckResponse_State NOTETYPE_NOT_CLOZE = NoteFieldsCheckResponse_State._(4, _omitEnumNames ? '' : 'NOTETYPE_NOT_CLOZE');
  static const NoteFieldsCheckResponse_State FIELD_NOT_CLOZE = NoteFieldsCheckResponse_State._(5, _omitEnumNames ? '' : 'FIELD_NOT_CLOZE');

  static const $core.List<NoteFieldsCheckResponse_State> values = <NoteFieldsCheckResponse_State> [
    NORMAL,
    EMPTY,
    DUPLICATE,
    MISSING_CLOZE,
    NOTETYPE_NOT_CLOZE,
    FIELD_NOT_CLOZE,
  ];

  static final $core.Map<$core.int, NoteFieldsCheckResponse_State> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NoteFieldsCheckResponse_State? valueOf($core.int value) => _byValue[value];

  const NoteFieldsCheckResponse_State._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
