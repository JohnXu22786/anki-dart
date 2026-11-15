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

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'card_rendering.pbenum.dart';
import 'generic.pb.dart' as $0;
import 'notes.pb.dart' as $13;
import 'notetypes.pb.dart' as $12;

export 'card_rendering.pbenum.dart';

class ExtractAvTagsRequest extends $pb.GeneratedMessage {
  factory ExtractAvTagsRequest({
    $core.String? text,
    $core.bool? questionSide,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (questionSide != null) {
      $result.questionSide = questionSide;
    }
    return $result;
  }
  ExtractAvTagsRequest._() : super();
  factory ExtractAvTagsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtractAvTagsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtractAvTagsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'questionSide')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtractAvTagsRequest clone() => ExtractAvTagsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtractAvTagsRequest copyWith(void Function(ExtractAvTagsRequest) updates) => super.copyWith((message) => updates(message as ExtractAvTagsRequest)) as ExtractAvTagsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractAvTagsRequest create() => ExtractAvTagsRequest._();
  ExtractAvTagsRequest createEmptyInstance() => create();
  static $pb.PbList<ExtractAvTagsRequest> createRepeated() => $pb.PbList<ExtractAvTagsRequest>();
  @$core.pragma('dart2js:noInline')
  static ExtractAvTagsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtractAvTagsRequest>(create);
  static ExtractAvTagsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get questionSide => $_getBF(1);
  @$pb.TagNumber(2)
  set questionSide($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasQuestionSide() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuestionSide() => clearField(2);
}

class ExtractAvTagsResponse extends $pb.GeneratedMessage {
  factory ExtractAvTagsResponse({
    $core.String? text,
    $core.Iterable<AVTag>? avTags,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (avTags != null) {
      $result.avTags.addAll(avTags);
    }
    return $result;
  }
  ExtractAvTagsResponse._() : super();
  factory ExtractAvTagsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtractAvTagsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtractAvTagsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..pc<AVTag>(2, _omitFieldNames ? '' : 'avTags', $pb.PbFieldType.PM, subBuilder: AVTag.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtractAvTagsResponse clone() => ExtractAvTagsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtractAvTagsResponse copyWith(void Function(ExtractAvTagsResponse) updates) => super.copyWith((message) => updates(message as ExtractAvTagsResponse)) as ExtractAvTagsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractAvTagsResponse create() => ExtractAvTagsResponse._();
  ExtractAvTagsResponse createEmptyInstance() => create();
  static $pb.PbList<ExtractAvTagsResponse> createRepeated() => $pb.PbList<ExtractAvTagsResponse>();
  @$core.pragma('dart2js:noInline')
  static ExtractAvTagsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtractAvTagsResponse>(create);
  static ExtractAvTagsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<AVTag> get avTags => $_getList(1);
}

enum AVTag_Value {
  soundOrVideo,
  tts,
  notSet
}

class AVTag extends $pb.GeneratedMessage {
  factory AVTag({
    $core.String? soundOrVideo,
    TTSTag? tts,
  }) {
    final $result = create();
    if (soundOrVideo != null) {
      $result.soundOrVideo = soundOrVideo;
    }
    if (tts != null) {
      $result.tts = tts;
    }
    return $result;
  }
  AVTag._() : super();
  factory AVTag.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AVTag.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, AVTag_Value> _AVTag_ValueByTag = {
    1 : AVTag_Value.soundOrVideo,
    2 : AVTag_Value.tts,
    0 : AVTag_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AVTag', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'soundOrVideo')
    ..aOM<TTSTag>(2, _omitFieldNames ? '' : 'tts', subBuilder: TTSTag.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AVTag clone() => AVTag()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AVTag copyWith(void Function(AVTag) updates) => super.copyWith((message) => updates(message as AVTag)) as AVTag;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AVTag create() => AVTag._();
  AVTag createEmptyInstance() => create();
  static $pb.PbList<AVTag> createRepeated() => $pb.PbList<AVTag>();
  @$core.pragma('dart2js:noInline')
  static AVTag getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AVTag>(create);
  static AVTag? _defaultInstance;

  AVTag_Value whichValue() => _AVTag_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get soundOrVideo => $_getSZ(0);
  @$pb.TagNumber(1)
  set soundOrVideo($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSoundOrVideo() => $_has(0);
  @$pb.TagNumber(1)
  void clearSoundOrVideo() => clearField(1);

  @$pb.TagNumber(2)
  TTSTag get tts => $_getN(1);
  @$pb.TagNumber(2)
  set tts(TTSTag v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTts() => $_has(1);
  @$pb.TagNumber(2)
  void clearTts() => clearField(2);
  @$pb.TagNumber(2)
  TTSTag ensureTts() => $_ensure(1);
}

class TTSTag extends $pb.GeneratedMessage {
  factory TTSTag({
    $core.String? fieldText,
    $core.String? lang,
    $core.Iterable<$core.String>? voices,
    $core.double? speed,
    $core.Iterable<$core.String>? otherArgs,
  }) {
    final $result = create();
    if (fieldText != null) {
      $result.fieldText = fieldText;
    }
    if (lang != null) {
      $result.lang = lang;
    }
    if (voices != null) {
      $result.voices.addAll(voices);
    }
    if (speed != null) {
      $result.speed = speed;
    }
    if (otherArgs != null) {
      $result.otherArgs.addAll(otherArgs);
    }
    return $result;
  }
  TTSTag._() : super();
  factory TTSTag.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TTSTag.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TTSTag', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldText')
    ..aOS(2, _omitFieldNames ? '' : 'lang')
    ..pPS(3, _omitFieldNames ? '' : 'voices')
    ..a<$core.double>(4, _omitFieldNames ? '' : 'speed', $pb.PbFieldType.OF)
    ..pPS(5, _omitFieldNames ? '' : 'otherArgs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TTSTag clone() => TTSTag()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TTSTag copyWith(void Function(TTSTag) updates) => super.copyWith((message) => updates(message as TTSTag)) as TTSTag;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TTSTag create() => TTSTag._();
  TTSTag createEmptyInstance() => create();
  static $pb.PbList<TTSTag> createRepeated() => $pb.PbList<TTSTag>();
  @$core.pragma('dart2js:noInline')
  static TTSTag getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TTSTag>(create);
  static TTSTag? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldText => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldText($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldText() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldText() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get lang => $_getSZ(1);
  @$pb.TagNumber(2)
  set lang($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLang() => $_has(1);
  @$pb.TagNumber(2)
  void clearLang() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get voices => $_getList(2);

  @$pb.TagNumber(4)
  $core.double get speed => $_getN(3);
  @$pb.TagNumber(4)
  set speed($core.double v) { $_setFloat(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSpeed() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpeed() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.String> get otherArgs => $_getList(4);
}

class ExtractLatexRequest extends $pb.GeneratedMessage {
  factory ExtractLatexRequest({
    $core.String? text,
    $core.bool? svg,
    $core.bool? expandClozes,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (svg != null) {
      $result.svg = svg;
    }
    if (expandClozes != null) {
      $result.expandClozes = expandClozes;
    }
    return $result;
  }
  ExtractLatexRequest._() : super();
  factory ExtractLatexRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtractLatexRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtractLatexRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'svg')
    ..aOB(3, _omitFieldNames ? '' : 'expandClozes')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtractLatexRequest clone() => ExtractLatexRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtractLatexRequest copyWith(void Function(ExtractLatexRequest) updates) => super.copyWith((message) => updates(message as ExtractLatexRequest)) as ExtractLatexRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractLatexRequest create() => ExtractLatexRequest._();
  ExtractLatexRequest createEmptyInstance() => create();
  static $pb.PbList<ExtractLatexRequest> createRepeated() => $pb.PbList<ExtractLatexRequest>();
  @$core.pragma('dart2js:noInline')
  static ExtractLatexRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtractLatexRequest>(create);
  static ExtractLatexRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get svg => $_getBF(1);
  @$pb.TagNumber(2)
  set svg($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSvg() => $_has(1);
  @$pb.TagNumber(2)
  void clearSvg() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get expandClozes => $_getBF(2);
  @$pb.TagNumber(3)
  set expandClozes($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasExpandClozes() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpandClozes() => clearField(3);
}

class ExtractLatexResponse extends $pb.GeneratedMessage {
  factory ExtractLatexResponse({
    $core.String? text,
    $core.Iterable<ExtractedLatex>? latex,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (latex != null) {
      $result.latex.addAll(latex);
    }
    return $result;
  }
  ExtractLatexResponse._() : super();
  factory ExtractLatexResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtractLatexResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtractLatexResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..pc<ExtractedLatex>(2, _omitFieldNames ? '' : 'latex', $pb.PbFieldType.PM, subBuilder: ExtractedLatex.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtractLatexResponse clone() => ExtractLatexResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtractLatexResponse copyWith(void Function(ExtractLatexResponse) updates) => super.copyWith((message) => updates(message as ExtractLatexResponse)) as ExtractLatexResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractLatexResponse create() => ExtractLatexResponse._();
  ExtractLatexResponse createEmptyInstance() => create();
  static $pb.PbList<ExtractLatexResponse> createRepeated() => $pb.PbList<ExtractLatexResponse>();
  @$core.pragma('dart2js:noInline')
  static ExtractLatexResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtractLatexResponse>(create);
  static ExtractLatexResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<ExtractedLatex> get latex => $_getList(1);
}

class ExtractedLatex extends $pb.GeneratedMessage {
  factory ExtractedLatex({
    $core.String? filename,
    $core.String? latexBody,
  }) {
    final $result = create();
    if (filename != null) {
      $result.filename = filename;
    }
    if (latexBody != null) {
      $result.latexBody = latexBody;
    }
    return $result;
  }
  ExtractedLatex._() : super();
  factory ExtractedLatex.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtractedLatex.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtractedLatex', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..aOS(2, _omitFieldNames ? '' : 'latexBody')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtractedLatex clone() => ExtractedLatex()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtractedLatex copyWith(void Function(ExtractedLatex) updates) => super.copyWith((message) => updates(message as ExtractedLatex)) as ExtractedLatex;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractedLatex create() => ExtractedLatex._();
  ExtractedLatex createEmptyInstance() => create();
  static $pb.PbList<ExtractedLatex> createRepeated() => $pb.PbList<ExtractedLatex>();
  @$core.pragma('dart2js:noInline')
  static ExtractedLatex getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtractedLatex>(create);
  static ExtractedLatex? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get latexBody => $_getSZ(1);
  @$pb.TagNumber(2)
  set latexBody($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatexBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatexBody() => clearField(2);
}

class EmptyCardsReport_NoteWithEmptyCards extends $pb.GeneratedMessage {
  factory EmptyCardsReport_NoteWithEmptyCards({
    $fixnum.Int64? noteId,
    $core.Iterable<$fixnum.Int64>? cardIds,
    $core.bool? willDeleteNote,
  }) {
    final $result = create();
    if (noteId != null) {
      $result.noteId = noteId;
    }
    if (cardIds != null) {
      $result.cardIds.addAll(cardIds);
    }
    if (willDeleteNote != null) {
      $result.willDeleteNote = willDeleteNote;
    }
    return $result;
  }
  EmptyCardsReport_NoteWithEmptyCards._() : super();
  factory EmptyCardsReport_NoteWithEmptyCards.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EmptyCardsReport_NoteWithEmptyCards.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EmptyCardsReport.NoteWithEmptyCards', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'noteId')
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'cardIds', $pb.PbFieldType.K6)
    ..aOB(3, _omitFieldNames ? '' : 'willDeleteNote')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EmptyCardsReport_NoteWithEmptyCards clone() => EmptyCardsReport_NoteWithEmptyCards()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EmptyCardsReport_NoteWithEmptyCards copyWith(void Function(EmptyCardsReport_NoteWithEmptyCards) updates) => super.copyWith((message) => updates(message as EmptyCardsReport_NoteWithEmptyCards)) as EmptyCardsReport_NoteWithEmptyCards;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmptyCardsReport_NoteWithEmptyCards create() => EmptyCardsReport_NoteWithEmptyCards._();
  EmptyCardsReport_NoteWithEmptyCards createEmptyInstance() => create();
  static $pb.PbList<EmptyCardsReport_NoteWithEmptyCards> createRepeated() => $pb.PbList<EmptyCardsReport_NoteWithEmptyCards>();
  @$core.pragma('dart2js:noInline')
  static EmptyCardsReport_NoteWithEmptyCards getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EmptyCardsReport_NoteWithEmptyCards>(create);
  static EmptyCardsReport_NoteWithEmptyCards? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get noteId => $_getI64(0);
  @$pb.TagNumber(1)
  set noteId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNoteId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNoteId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$fixnum.Int64> get cardIds => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get willDeleteNote => $_getBF(2);
  @$pb.TagNumber(3)
  set willDeleteNote($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasWillDeleteNote() => $_has(2);
  @$pb.TagNumber(3)
  void clearWillDeleteNote() => clearField(3);
}

class EmptyCardsReport extends $pb.GeneratedMessage {
  factory EmptyCardsReport({
    $core.String? report,
    $core.Iterable<EmptyCardsReport_NoteWithEmptyCards>? notes,
  }) {
    final $result = create();
    if (report != null) {
      $result.report = report;
    }
    if (notes != null) {
      $result.notes.addAll(notes);
    }
    return $result;
  }
  EmptyCardsReport._() : super();
  factory EmptyCardsReport.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EmptyCardsReport.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EmptyCardsReport', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'report')
    ..pc<EmptyCardsReport_NoteWithEmptyCards>(2, _omitFieldNames ? '' : 'notes', $pb.PbFieldType.PM, subBuilder: EmptyCardsReport_NoteWithEmptyCards.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EmptyCardsReport clone() => EmptyCardsReport()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EmptyCardsReport copyWith(void Function(EmptyCardsReport) updates) => super.copyWith((message) => updates(message as EmptyCardsReport)) as EmptyCardsReport;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmptyCardsReport create() => EmptyCardsReport._();
  EmptyCardsReport createEmptyInstance() => create();
  static $pb.PbList<EmptyCardsReport> createRepeated() => $pb.PbList<EmptyCardsReport>();
  @$core.pragma('dart2js:noInline')
  static EmptyCardsReport getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EmptyCardsReport>(create);
  static EmptyCardsReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get report => $_getSZ(0);
  @$pb.TagNumber(1)
  set report($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReport() => $_has(0);
  @$pb.TagNumber(1)
  void clearReport() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<EmptyCardsReport_NoteWithEmptyCards> get notes => $_getList(1);
}

class RenderExistingCardRequest extends $pb.GeneratedMessage {
  factory RenderExistingCardRequest({
    $fixnum.Int64? cardId,
    $core.bool? browser,
    $core.bool? partialRender,
  }) {
    final $result = create();
    if (cardId != null) {
      $result.cardId = cardId;
    }
    if (browser != null) {
      $result.browser = browser;
    }
    if (partialRender != null) {
      $result.partialRender = partialRender;
    }
    return $result;
  }
  RenderExistingCardRequest._() : super();
  factory RenderExistingCardRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderExistingCardRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderExistingCardRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'cardId')
    ..aOB(2, _omitFieldNames ? '' : 'browser')
    ..aOB(3, _omitFieldNames ? '' : 'partialRender')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderExistingCardRequest clone() => RenderExistingCardRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderExistingCardRequest copyWith(void Function(RenderExistingCardRequest) updates) => super.copyWith((message) => updates(message as RenderExistingCardRequest)) as RenderExistingCardRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderExistingCardRequest create() => RenderExistingCardRequest._();
  RenderExistingCardRequest createEmptyInstance() => create();
  static $pb.PbList<RenderExistingCardRequest> createRepeated() => $pb.PbList<RenderExistingCardRequest>();
  @$core.pragma('dart2js:noInline')
  static RenderExistingCardRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderExistingCardRequest>(create);
  static RenderExistingCardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get cardId => $_getI64(0);
  @$pb.TagNumber(1)
  set cardId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCardId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCardId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get browser => $_getBF(1);
  @$pb.TagNumber(2)
  set browser($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBrowser() => $_has(1);
  @$pb.TagNumber(2)
  void clearBrowser() => clearField(2);

  /// If true, rendering will stop when an unknown filter is encountered,
  /// and caller will need to complete rendering. This is done to allow
  /// Python code to modify the rendering.
  @$pb.TagNumber(3)
  $core.bool get partialRender => $_getBF(2);
  @$pb.TagNumber(3)
  set partialRender($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPartialRender() => $_has(2);
  @$pb.TagNumber(3)
  void clearPartialRender() => clearField(3);
}

class RenderUncommittedCardRequest extends $pb.GeneratedMessage {
  factory RenderUncommittedCardRequest({
    $13.Note? note,
    $core.int? cardOrd,
    $12.Notetype_Template? template,
    $core.bool? fillEmpty,
    $core.bool? partialRender,
  }) {
    final $result = create();
    if (note != null) {
      $result.note = note;
    }
    if (cardOrd != null) {
      $result.cardOrd = cardOrd;
    }
    if (template != null) {
      $result.template = template;
    }
    if (fillEmpty != null) {
      $result.fillEmpty = fillEmpty;
    }
    if (partialRender != null) {
      $result.partialRender = partialRender;
    }
    return $result;
  }
  RenderUncommittedCardRequest._() : super();
  factory RenderUncommittedCardRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderUncommittedCardRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderUncommittedCardRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOM<$13.Note>(1, _omitFieldNames ? '' : 'note', subBuilder: $13.Note.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'cardOrd', $pb.PbFieldType.OU3)
    ..aOM<$12.Notetype_Template>(3, _omitFieldNames ? '' : 'template', subBuilder: $12.Notetype_Template.create)
    ..aOB(4, _omitFieldNames ? '' : 'fillEmpty')
    ..aOB(5, _omitFieldNames ? '' : 'partialRender')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderUncommittedCardRequest clone() => RenderUncommittedCardRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderUncommittedCardRequest copyWith(void Function(RenderUncommittedCardRequest) updates) => super.copyWith((message) => updates(message as RenderUncommittedCardRequest)) as RenderUncommittedCardRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderUncommittedCardRequest create() => RenderUncommittedCardRequest._();
  RenderUncommittedCardRequest createEmptyInstance() => create();
  static $pb.PbList<RenderUncommittedCardRequest> createRepeated() => $pb.PbList<RenderUncommittedCardRequest>();
  @$core.pragma('dart2js:noInline')
  static RenderUncommittedCardRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderUncommittedCardRequest>(create);
  static RenderUncommittedCardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $13.Note get note => $_getN(0);
  @$pb.TagNumber(1)
  set note($13.Note v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNote() => $_has(0);
  @$pb.TagNumber(1)
  void clearNote() => clearField(1);
  @$pb.TagNumber(1)
  $13.Note ensureNote() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get cardOrd => $_getIZ(1);
  @$pb.TagNumber(2)
  set cardOrd($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardOrd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardOrd() => clearField(2);

  @$pb.TagNumber(3)
  $12.Notetype_Template get template => $_getN(2);
  @$pb.TagNumber(3)
  set template($12.Notetype_Template v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasTemplate() => $_has(2);
  @$pb.TagNumber(3)
  void clearTemplate() => clearField(3);
  @$pb.TagNumber(3)
  $12.Notetype_Template ensureTemplate() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get fillEmpty => $_getBF(3);
  @$pb.TagNumber(4)
  set fillEmpty($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFillEmpty() => $_has(3);
  @$pb.TagNumber(4)
  void clearFillEmpty() => clearField(4);

  /// If true, rendering will stop when an unknown filter is encountered,
  /// and caller will need to complete rendering. This is done to allow
  /// Python code to modify the rendering.
  @$pb.TagNumber(5)
  $core.bool get partialRender => $_getBF(4);
  @$pb.TagNumber(5)
  set partialRender($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPartialRender() => $_has(4);
  @$pb.TagNumber(5)
  void clearPartialRender() => clearField(5);
}

class RenderUncommittedCardLegacyRequest extends $pb.GeneratedMessage {
  factory RenderUncommittedCardLegacyRequest({
    $13.Note? note,
    $core.int? cardOrd,
    $core.List<$core.int>? template,
    $core.bool? fillEmpty,
    $core.bool? partialRender,
  }) {
    final $result = create();
    if (note != null) {
      $result.note = note;
    }
    if (cardOrd != null) {
      $result.cardOrd = cardOrd;
    }
    if (template != null) {
      $result.template = template;
    }
    if (fillEmpty != null) {
      $result.fillEmpty = fillEmpty;
    }
    if (partialRender != null) {
      $result.partialRender = partialRender;
    }
    return $result;
  }
  RenderUncommittedCardLegacyRequest._() : super();
  factory RenderUncommittedCardLegacyRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderUncommittedCardLegacyRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderUncommittedCardLegacyRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOM<$13.Note>(1, _omitFieldNames ? '' : 'note', subBuilder: $13.Note.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'cardOrd', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'template', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'fillEmpty')
    ..aOB(5, _omitFieldNames ? '' : 'partialRender')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderUncommittedCardLegacyRequest clone() => RenderUncommittedCardLegacyRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderUncommittedCardLegacyRequest copyWith(void Function(RenderUncommittedCardLegacyRequest) updates) => super.copyWith((message) => updates(message as RenderUncommittedCardLegacyRequest)) as RenderUncommittedCardLegacyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderUncommittedCardLegacyRequest create() => RenderUncommittedCardLegacyRequest._();
  RenderUncommittedCardLegacyRequest createEmptyInstance() => create();
  static $pb.PbList<RenderUncommittedCardLegacyRequest> createRepeated() => $pb.PbList<RenderUncommittedCardLegacyRequest>();
  @$core.pragma('dart2js:noInline')
  static RenderUncommittedCardLegacyRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderUncommittedCardLegacyRequest>(create);
  static RenderUncommittedCardLegacyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $13.Note get note => $_getN(0);
  @$pb.TagNumber(1)
  set note($13.Note v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNote() => $_has(0);
  @$pb.TagNumber(1)
  void clearNote() => clearField(1);
  @$pb.TagNumber(1)
  $13.Note ensureNote() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get cardOrd => $_getIZ(1);
  @$pb.TagNumber(2)
  set cardOrd($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardOrd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardOrd() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get template => $_getN(2);
  @$pb.TagNumber(3)
  set template($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTemplate() => $_has(2);
  @$pb.TagNumber(3)
  void clearTemplate() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get fillEmpty => $_getBF(3);
  @$pb.TagNumber(4)
  set fillEmpty($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFillEmpty() => $_has(3);
  @$pb.TagNumber(4)
  void clearFillEmpty() => clearField(4);

  /// If true, rendering will stop when an unknown filter is encountered,
  /// and caller will need to complete rendering. This is done to allow
  /// Python code to modify the rendering.
  @$pb.TagNumber(5)
  $core.bool get partialRender => $_getBF(4);
  @$pb.TagNumber(5)
  set partialRender($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPartialRender() => $_has(4);
  @$pb.TagNumber(5)
  void clearPartialRender() => clearField(5);
}

class RenderCardResponse extends $pb.GeneratedMessage {
  factory RenderCardResponse({
    $core.Iterable<RenderedTemplateNode>? questionNodes,
    $core.Iterable<RenderedTemplateNode>? answerNodes,
    $core.String? css,
    $core.bool? latexSvg,
    $core.bool? isEmpty,
  }) {
    final $result = create();
    if (questionNodes != null) {
      $result.questionNodes.addAll(questionNodes);
    }
    if (answerNodes != null) {
      $result.answerNodes.addAll(answerNodes);
    }
    if (css != null) {
      $result.css = css;
    }
    if (latexSvg != null) {
      $result.latexSvg = latexSvg;
    }
    if (isEmpty != null) {
      $result.isEmpty = isEmpty;
    }
    return $result;
  }
  RenderCardResponse._() : super();
  factory RenderCardResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderCardResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderCardResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..pc<RenderedTemplateNode>(1, _omitFieldNames ? '' : 'questionNodes', $pb.PbFieldType.PM, subBuilder: RenderedTemplateNode.create)
    ..pc<RenderedTemplateNode>(2, _omitFieldNames ? '' : 'answerNodes', $pb.PbFieldType.PM, subBuilder: RenderedTemplateNode.create)
    ..aOS(3, _omitFieldNames ? '' : 'css')
    ..aOB(4, _omitFieldNames ? '' : 'latexSvg')
    ..aOB(5, _omitFieldNames ? '' : 'isEmpty')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderCardResponse clone() => RenderCardResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderCardResponse copyWith(void Function(RenderCardResponse) updates) => super.copyWith((message) => updates(message as RenderCardResponse)) as RenderCardResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderCardResponse create() => RenderCardResponse._();
  RenderCardResponse createEmptyInstance() => create();
  static $pb.PbList<RenderCardResponse> createRepeated() => $pb.PbList<RenderCardResponse>();
  @$core.pragma('dart2js:noInline')
  static RenderCardResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderCardResponse>(create);
  static RenderCardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<RenderedTemplateNode> get questionNodes => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<RenderedTemplateNode> get answerNodes => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get css => $_getSZ(2);
  @$pb.TagNumber(3)
  set css($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCss() => $_has(2);
  @$pb.TagNumber(3)
  void clearCss() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get latexSvg => $_getBF(3);
  @$pb.TagNumber(4)
  set latexSvg($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLatexSvg() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatexSvg() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isEmpty => $_getBF(4);
  @$pb.TagNumber(5)
  set isEmpty($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsEmpty() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsEmpty() => clearField(5);
}

enum RenderedTemplateNode_Value {
  text,
  replacement,
  notSet
}

class RenderedTemplateNode extends $pb.GeneratedMessage {
  factory RenderedTemplateNode({
    $core.String? text,
    RenderedTemplateReplacement? replacement,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (replacement != null) {
      $result.replacement = replacement;
    }
    return $result;
  }
  RenderedTemplateNode._() : super();
  factory RenderedTemplateNode.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderedTemplateNode.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, RenderedTemplateNode_Value> _RenderedTemplateNode_ValueByTag = {
    1 : RenderedTemplateNode_Value.text,
    2 : RenderedTemplateNode_Value.replacement,
    0 : RenderedTemplateNode_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderedTemplateNode', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOM<RenderedTemplateReplacement>(2, _omitFieldNames ? '' : 'replacement', subBuilder: RenderedTemplateReplacement.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderedTemplateNode clone() => RenderedTemplateNode()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderedTemplateNode copyWith(void Function(RenderedTemplateNode) updates) => super.copyWith((message) => updates(message as RenderedTemplateNode)) as RenderedTemplateNode;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderedTemplateNode create() => RenderedTemplateNode._();
  RenderedTemplateNode createEmptyInstance() => create();
  static $pb.PbList<RenderedTemplateNode> createRepeated() => $pb.PbList<RenderedTemplateNode>();
  @$core.pragma('dart2js:noInline')
  static RenderedTemplateNode getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderedTemplateNode>(create);
  static RenderedTemplateNode? _defaultInstance;

  RenderedTemplateNode_Value whichValue() => _RenderedTemplateNode_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  RenderedTemplateReplacement get replacement => $_getN(1);
  @$pb.TagNumber(2)
  set replacement(RenderedTemplateReplacement v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasReplacement() => $_has(1);
  @$pb.TagNumber(2)
  void clearReplacement() => clearField(2);
  @$pb.TagNumber(2)
  RenderedTemplateReplacement ensureReplacement() => $_ensure(1);
}

class RenderedTemplateReplacement extends $pb.GeneratedMessage {
  factory RenderedTemplateReplacement({
    $core.String? fieldName,
    $core.String? currentText,
    $core.Iterable<$core.String>? filters,
  }) {
    final $result = create();
    if (fieldName != null) {
      $result.fieldName = fieldName;
    }
    if (currentText != null) {
      $result.currentText = currentText;
    }
    if (filters != null) {
      $result.filters.addAll(filters);
    }
    return $result;
  }
  RenderedTemplateReplacement._() : super();
  factory RenderedTemplateReplacement.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderedTemplateReplacement.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderedTemplateReplacement', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldName')
    ..aOS(2, _omitFieldNames ? '' : 'currentText')
    ..pPS(3, _omitFieldNames ? '' : 'filters')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderedTemplateReplacement clone() => RenderedTemplateReplacement()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderedTemplateReplacement copyWith(void Function(RenderedTemplateReplacement) updates) => super.copyWith((message) => updates(message as RenderedTemplateReplacement)) as RenderedTemplateReplacement;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderedTemplateReplacement create() => RenderedTemplateReplacement._();
  RenderedTemplateReplacement createEmptyInstance() => create();
  static $pb.PbList<RenderedTemplateReplacement> createRepeated() => $pb.PbList<RenderedTemplateReplacement>();
  @$core.pragma('dart2js:noInline')
  static RenderedTemplateReplacement getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderedTemplateReplacement>(create);
  static RenderedTemplateReplacement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldName => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get currentText => $_getSZ(1);
  @$pb.TagNumber(2)
  set currentText($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCurrentText() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrentText() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get filters => $_getList(2);
}

class RenderMarkdownRequest extends $pb.GeneratedMessage {
  factory RenderMarkdownRequest({
    $core.String? markdown,
    $core.bool? sanitize,
  }) {
    final $result = create();
    if (markdown != null) {
      $result.markdown = markdown;
    }
    if (sanitize != null) {
      $result.sanitize = sanitize;
    }
    return $result;
  }
  RenderMarkdownRequest._() : super();
  factory RenderMarkdownRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RenderMarkdownRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RenderMarkdownRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'markdown')
    ..aOB(2, _omitFieldNames ? '' : 'sanitize')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RenderMarkdownRequest clone() => RenderMarkdownRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RenderMarkdownRequest copyWith(void Function(RenderMarkdownRequest) updates) => super.copyWith((message) => updates(message as RenderMarkdownRequest)) as RenderMarkdownRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenderMarkdownRequest create() => RenderMarkdownRequest._();
  RenderMarkdownRequest createEmptyInstance() => create();
  static $pb.PbList<RenderMarkdownRequest> createRepeated() => $pb.PbList<RenderMarkdownRequest>();
  @$core.pragma('dart2js:noInline')
  static RenderMarkdownRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenderMarkdownRequest>(create);
  static RenderMarkdownRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get markdown => $_getSZ(0);
  @$pb.TagNumber(1)
  set markdown($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMarkdown() => $_has(0);
  @$pb.TagNumber(1)
  void clearMarkdown() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get sanitize => $_getBF(1);
  @$pb.TagNumber(2)
  set sanitize($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSanitize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSanitize() => clearField(2);
}

class StripHtmlRequest extends $pb.GeneratedMessage {
  factory StripHtmlRequest({
    $core.String? text,
    StripHtmlRequest_Mode? mode,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    return $result;
  }
  StripHtmlRequest._() : super();
  factory StripHtmlRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StripHtmlRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StripHtmlRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..e<StripHtmlRequest_Mode>(2, _omitFieldNames ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: StripHtmlRequest_Mode.NORMAL, valueOf: StripHtmlRequest_Mode.valueOf, enumValues: StripHtmlRequest_Mode.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StripHtmlRequest clone() => StripHtmlRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StripHtmlRequest copyWith(void Function(StripHtmlRequest) updates) => super.copyWith((message) => updates(message as StripHtmlRequest)) as StripHtmlRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StripHtmlRequest create() => StripHtmlRequest._();
  StripHtmlRequest createEmptyInstance() => create();
  static $pb.PbList<StripHtmlRequest> createRepeated() => $pb.PbList<StripHtmlRequest>();
  @$core.pragma('dart2js:noInline')
  static StripHtmlRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StripHtmlRequest>(create);
  static StripHtmlRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  StripHtmlRequest_Mode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(StripHtmlRequest_Mode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => clearField(2);
}

class HtmlToTextLineRequest extends $pb.GeneratedMessage {
  factory HtmlToTextLineRequest({
    $core.String? text,
    $core.bool? preserveMediaFilenames,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (preserveMediaFilenames != null) {
      $result.preserveMediaFilenames = preserveMediaFilenames;
    }
    return $result;
  }
  HtmlToTextLineRequest._() : super();
  factory HtmlToTextLineRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HtmlToTextLineRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HtmlToTextLineRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'preserveMediaFilenames')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HtmlToTextLineRequest clone() => HtmlToTextLineRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HtmlToTextLineRequest copyWith(void Function(HtmlToTextLineRequest) updates) => super.copyWith((message) => updates(message as HtmlToTextLineRequest)) as HtmlToTextLineRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HtmlToTextLineRequest create() => HtmlToTextLineRequest._();
  HtmlToTextLineRequest createEmptyInstance() => create();
  static $pb.PbList<HtmlToTextLineRequest> createRepeated() => $pb.PbList<HtmlToTextLineRequest>();
  @$core.pragma('dart2js:noInline')
  static HtmlToTextLineRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HtmlToTextLineRequest>(create);
  static HtmlToTextLineRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get preserveMediaFilenames => $_getBF(1);
  @$pb.TagNumber(2)
  set preserveMediaFilenames($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPreserveMediaFilenames() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreserveMediaFilenames() => clearField(2);
}

class CompareAnswerRequest extends $pb.GeneratedMessage {
  factory CompareAnswerRequest({
    $core.String? expected,
    $core.String? provided,
    $core.bool? combining,
  }) {
    final $result = create();
    if (expected != null) {
      $result.expected = expected;
    }
    if (provided != null) {
      $result.provided = provided;
    }
    if (combining != null) {
      $result.combining = combining;
    }
    return $result;
  }
  CompareAnswerRequest._() : super();
  factory CompareAnswerRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CompareAnswerRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CompareAnswerRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'expected')
    ..aOS(2, _omitFieldNames ? '' : 'provided')
    ..aOB(3, _omitFieldNames ? '' : 'combining')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CompareAnswerRequest clone() => CompareAnswerRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CompareAnswerRequest copyWith(void Function(CompareAnswerRequest) updates) => super.copyWith((message) => updates(message as CompareAnswerRequest)) as CompareAnswerRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompareAnswerRequest create() => CompareAnswerRequest._();
  CompareAnswerRequest createEmptyInstance() => create();
  static $pb.PbList<CompareAnswerRequest> createRepeated() => $pb.PbList<CompareAnswerRequest>();
  @$core.pragma('dart2js:noInline')
  static CompareAnswerRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompareAnswerRequest>(create);
  static CompareAnswerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get expected => $_getSZ(0);
  @$pb.TagNumber(1)
  set expected($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get provided => $_getSZ(1);
  @$pb.TagNumber(2)
  set provided($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProvided() => $_has(1);
  @$pb.TagNumber(2)
  void clearProvided() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get combining => $_getBF(2);
  @$pb.TagNumber(3)
  set combining($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCombining() => $_has(2);
  @$pb.TagNumber(3)
  void clearCombining() => clearField(3);
}

class ExtractClozeForTypingRequest extends $pb.GeneratedMessage {
  factory ExtractClozeForTypingRequest({
    $core.String? text,
    $core.int? ordinal,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (ordinal != null) {
      $result.ordinal = ordinal;
    }
    return $result;
  }
  ExtractClozeForTypingRequest._() : super();
  factory ExtractClozeForTypingRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExtractClozeForTypingRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtractClozeForTypingRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ordinal', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExtractClozeForTypingRequest clone() => ExtractClozeForTypingRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExtractClozeForTypingRequest copyWith(void Function(ExtractClozeForTypingRequest) updates) => super.copyWith((message) => updates(message as ExtractClozeForTypingRequest)) as ExtractClozeForTypingRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtractClozeForTypingRequest create() => ExtractClozeForTypingRequest._();
  ExtractClozeForTypingRequest createEmptyInstance() => create();
  static $pb.PbList<ExtractClozeForTypingRequest> createRepeated() => $pb.PbList<ExtractClozeForTypingRequest>();
  @$core.pragma('dart2js:noInline')
  static ExtractClozeForTypingRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtractClozeForTypingRequest>(create);
  static ExtractClozeForTypingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get ordinal => $_getIZ(1);
  @$pb.TagNumber(2)
  set ordinal($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOrdinal() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrdinal() => clearField(2);
}

class AllTtsVoicesRequest extends $pb.GeneratedMessage {
  factory AllTtsVoicesRequest({
    $core.bool? validate,
  }) {
    final $result = create();
    if (validate != null) {
      $result.validate = validate;
    }
    return $result;
  }
  AllTtsVoicesRequest._() : super();
  factory AllTtsVoicesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AllTtsVoicesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AllTtsVoicesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'validate')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AllTtsVoicesRequest clone() => AllTtsVoicesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AllTtsVoicesRequest copyWith(void Function(AllTtsVoicesRequest) updates) => super.copyWith((message) => updates(message as AllTtsVoicesRequest)) as AllTtsVoicesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllTtsVoicesRequest create() => AllTtsVoicesRequest._();
  AllTtsVoicesRequest createEmptyInstance() => create();
  static $pb.PbList<AllTtsVoicesRequest> createRepeated() => $pb.PbList<AllTtsVoicesRequest>();
  @$core.pragma('dart2js:noInline')
  static AllTtsVoicesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AllTtsVoicesRequest>(create);
  static AllTtsVoicesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get validate => $_getBF(0);
  @$pb.TagNumber(1)
  set validate($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValidate() => $_has(0);
  @$pb.TagNumber(1)
  void clearValidate() => clearField(1);
}

class AllTtsVoicesResponse_TtsVoice extends $pb.GeneratedMessage {
  factory AllTtsVoicesResponse_TtsVoice({
    $core.String? id,
    $core.String? name,
    $core.String? language,
    $core.bool? available,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (language != null) {
      $result.language = language;
    }
    if (available != null) {
      $result.available = available;
    }
    return $result;
  }
  AllTtsVoicesResponse_TtsVoice._() : super();
  factory AllTtsVoicesResponse_TtsVoice.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AllTtsVoicesResponse_TtsVoice.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AllTtsVoicesResponse.TtsVoice', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'language')
    ..aOB(4, _omitFieldNames ? '' : 'available')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AllTtsVoicesResponse_TtsVoice clone() => AllTtsVoicesResponse_TtsVoice()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AllTtsVoicesResponse_TtsVoice copyWith(void Function(AllTtsVoicesResponse_TtsVoice) updates) => super.copyWith((message) => updates(message as AllTtsVoicesResponse_TtsVoice)) as AllTtsVoicesResponse_TtsVoice;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllTtsVoicesResponse_TtsVoice create() => AllTtsVoicesResponse_TtsVoice._();
  AllTtsVoicesResponse_TtsVoice createEmptyInstance() => create();
  static $pb.PbList<AllTtsVoicesResponse_TtsVoice> createRepeated() => $pb.PbList<AllTtsVoicesResponse_TtsVoice>();
  @$core.pragma('dart2js:noInline')
  static AllTtsVoicesResponse_TtsVoice getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AllTtsVoicesResponse_TtsVoice>(create);
  static AllTtsVoicesResponse_TtsVoice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get language => $_getSZ(2);
  @$pb.TagNumber(3)
  set language($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLanguage() => $_has(2);
  @$pb.TagNumber(3)
  void clearLanguage() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get available => $_getBF(3);
  @$pb.TagNumber(4)
  set available($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAvailable() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvailable() => clearField(4);
}

class AllTtsVoicesResponse extends $pb.GeneratedMessage {
  factory AllTtsVoicesResponse({
    $core.Iterable<AllTtsVoicesResponse_TtsVoice>? voices,
  }) {
    final $result = create();
    if (voices != null) {
      $result.voices.addAll(voices);
    }
    return $result;
  }
  AllTtsVoicesResponse._() : super();
  factory AllTtsVoicesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AllTtsVoicesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AllTtsVoicesResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..pc<AllTtsVoicesResponse_TtsVoice>(1, _omitFieldNames ? '' : 'voices', $pb.PbFieldType.PM, subBuilder: AllTtsVoicesResponse_TtsVoice.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AllTtsVoicesResponse clone() => AllTtsVoicesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AllTtsVoicesResponse copyWith(void Function(AllTtsVoicesResponse) updates) => super.copyWith((message) => updates(message as AllTtsVoicesResponse)) as AllTtsVoicesResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllTtsVoicesResponse create() => AllTtsVoicesResponse._();
  AllTtsVoicesResponse createEmptyInstance() => create();
  static $pb.PbList<AllTtsVoicesResponse> createRepeated() => $pb.PbList<AllTtsVoicesResponse>();
  @$core.pragma('dart2js:noInline')
  static AllTtsVoicesResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AllTtsVoicesResponse>(create);
  static AllTtsVoicesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<AllTtsVoicesResponse_TtsVoice> get voices => $_getList(0);
}

class WriteTtsStreamRequest extends $pb.GeneratedMessage {
  factory WriteTtsStreamRequest({
    $core.String? path,
    $core.String? voiceId,
    $core.double? speed,
    $core.String? text,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (voiceId != null) {
      $result.voiceId = voiceId;
    }
    if (speed != null) {
      $result.speed = speed;
    }
    if (text != null) {
      $result.text = text;
    }
    return $result;
  }
  WriteTtsStreamRequest._() : super();
  factory WriteTtsStreamRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WriteTtsStreamRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WriteTtsStreamRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.card_rendering'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'voiceId')
    ..a<$core.double>(3, _omitFieldNames ? '' : 'speed', $pb.PbFieldType.OF)
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WriteTtsStreamRequest clone() => WriteTtsStreamRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WriteTtsStreamRequest copyWith(void Function(WriteTtsStreamRequest) updates) => super.copyWith((message) => updates(message as WriteTtsStreamRequest)) as WriteTtsStreamRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteTtsStreamRequest create() => WriteTtsStreamRequest._();
  WriteTtsStreamRequest createEmptyInstance() => create();
  static $pb.PbList<WriteTtsStreamRequest> createRepeated() => $pb.PbList<WriteTtsStreamRequest>();
  @$core.pragma('dart2js:noInline')
  static WriteTtsStreamRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WriteTtsStreamRequest>(create);
  static WriteTtsStreamRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get voiceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set voiceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVoiceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVoiceId() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get speed => $_getN(2);
  @$pb.TagNumber(3)
  set speed($core.double v) { $_setFloat(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSpeed() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeed() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => clearField(4);
}

class CardRenderingServiceApi {
  $pb.RpcClient _client;
  CardRenderingServiceApi(this._client);

  $async.Future<ExtractAvTagsResponse> extractAvTags($pb.ClientContext? ctx, ExtractAvTagsRequest request) =>
    _client.invoke<ExtractAvTagsResponse>(ctx, 'CardRenderingService', 'ExtractAvTags', request, ExtractAvTagsResponse())
  ;
  $async.Future<ExtractLatexResponse> extractLatex($pb.ClientContext? ctx, ExtractLatexRequest request) =>
    _client.invoke<ExtractLatexResponse>(ctx, 'CardRenderingService', 'ExtractLatex', request, ExtractLatexResponse())
  ;
  $async.Future<EmptyCardsReport> getEmptyCards($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<EmptyCardsReport>(ctx, 'CardRenderingService', 'GetEmptyCards', request, EmptyCardsReport())
  ;
  $async.Future<RenderCardResponse> renderExistingCard($pb.ClientContext? ctx, RenderExistingCardRequest request) =>
    _client.invoke<RenderCardResponse>(ctx, 'CardRenderingService', 'RenderExistingCard', request, RenderCardResponse())
  ;
  $async.Future<RenderCardResponse> renderUncommittedCard($pb.ClientContext? ctx, RenderUncommittedCardRequest request) =>
    _client.invoke<RenderCardResponse>(ctx, 'CardRenderingService', 'RenderUncommittedCard', request, RenderCardResponse())
  ;
  $async.Future<RenderCardResponse> renderUncommittedCardLegacy($pb.ClientContext? ctx, RenderUncommittedCardLegacyRequest request) =>
    _client.invoke<RenderCardResponse>(ctx, 'CardRenderingService', 'RenderUncommittedCardLegacy', request, RenderCardResponse())
  ;
  $async.Future<$0.String> stripAvTags($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'StripAvTags', request, $0.String())
  ;
  $async.Future<$0.String> renderMarkdown($pb.ClientContext? ctx, RenderMarkdownRequest request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'RenderMarkdown', request, $0.String())
  ;
  $async.Future<$0.String> encodeIriPaths($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'EncodeIriPaths', request, $0.String())
  ;
  $async.Future<$0.String> decodeIriPaths($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'DecodeIriPaths', request, $0.String())
  ;
  $async.Future<$0.String> stripHtml($pb.ClientContext? ctx, StripHtmlRequest request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'StripHtml', request, $0.String())
  ;
  $async.Future<$0.String> htmlToTextLine($pb.ClientContext? ctx, HtmlToTextLineRequest request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'HtmlToTextLine', request, $0.String())
  ;
  $async.Future<$0.String> compareAnswer($pb.ClientContext? ctx, CompareAnswerRequest request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'CompareAnswer', request, $0.String())
  ;
  $async.Future<$0.String> extractClozeForTyping($pb.ClientContext? ctx, ExtractClozeForTypingRequest request) =>
    _client.invoke<$0.String>(ctx, 'CardRenderingService', 'ExtractClozeForTyping', request, $0.String())
  ;
}

class BackendCardRenderingServiceApi {
  $pb.RpcClient _client;
  BackendCardRenderingServiceApi(this._client);

  $async.Future<$0.String> stripHtml($pb.ClientContext? ctx, StripHtmlRequest request) =>
    _client.invoke<$0.String>(ctx, 'BackendCardRenderingService', 'StripHtml', request, $0.String())
  ;
  $async.Future<AllTtsVoicesResponse> allTtsVoices($pb.ClientContext? ctx, AllTtsVoicesRequest request) =>
    _client.invoke<AllTtsVoicesResponse>(ctx, 'BackendCardRenderingService', 'AllTtsVoices', request, AllTtsVoicesResponse())
  ;
  $async.Future<$0.Empty> writeTtsStream($pb.ClientContext? ctx, WriteTtsStreamRequest request) =>
    _client.invoke<$0.Empty>(ctx, 'BackendCardRenderingService', 'WriteTtsStream', request, $0.Empty())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
