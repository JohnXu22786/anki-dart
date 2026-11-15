//
//  Generated code. Do not modify.
//  source: anki/notetypes.proto
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

import 'collection.pb.dart' as $2;
import 'generic.pb.dart' as $0;
import 'notetypes.pbenum.dart';

export 'notetypes.pbenum.dart';

class NotetypeId extends $pb.GeneratedMessage {
  factory NotetypeId({
    $fixnum.Int64? ntid,
  }) {
    final $result = create();
    if (ntid != null) {
      $result.ntid = ntid;
    }
    return $result;
  }
  NotetypeId._() : super();
  factory NotetypeId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NotetypeId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotetypeId', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'ntid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NotetypeId clone() => NotetypeId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NotetypeId copyWith(void Function(NotetypeId) updates) => super.copyWith((message) => updates(message as NotetypeId)) as NotetypeId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotetypeId create() => NotetypeId._();
  NotetypeId createEmptyInstance() => create();
  static $pb.PbList<NotetypeId> createRepeated() => $pb.PbList<NotetypeId>();
  @$core.pragma('dart2js:noInline')
  static NotetypeId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotetypeId>(create);
  static NotetypeId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ntid => $_getI64(0);
  @$pb.TagNumber(1)
  set ntid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNtid() => $_has(0);
  @$pb.TagNumber(1)
  void clearNtid() => clearField(1);
}

class Notetype_Config_CardRequirement extends $pb.GeneratedMessage {
  factory Notetype_Config_CardRequirement({
    $core.int? cardOrd,
    Notetype_Config_CardRequirement_Kind? kind,
    $core.Iterable<$core.int>? fieldOrds,
  }) {
    final $result = create();
    if (cardOrd != null) {
      $result.cardOrd = cardOrd;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (fieldOrds != null) {
      $result.fieldOrds.addAll(fieldOrds);
    }
    return $result;
  }
  Notetype_Config_CardRequirement._() : super();
  factory Notetype_Config_CardRequirement.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype_Config_CardRequirement.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype.Config.CardRequirement', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'cardOrd', $pb.PbFieldType.OU3)
    ..e<Notetype_Config_CardRequirement_Kind>(2, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE, defaultOrMaker: Notetype_Config_CardRequirement_Kind.KIND_NONE, valueOf: Notetype_Config_CardRequirement_Kind.valueOf, enumValues: Notetype_Config_CardRequirement_Kind.values)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'fieldOrds', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype_Config_CardRequirement clone() => Notetype_Config_CardRequirement()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype_Config_CardRequirement copyWith(void Function(Notetype_Config_CardRequirement) updates) => super.copyWith((message) => updates(message as Notetype_Config_CardRequirement)) as Notetype_Config_CardRequirement;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype_Config_CardRequirement create() => Notetype_Config_CardRequirement._();
  Notetype_Config_CardRequirement createEmptyInstance() => create();
  static $pb.PbList<Notetype_Config_CardRequirement> createRepeated() => $pb.PbList<Notetype_Config_CardRequirement>();
  @$core.pragma('dart2js:noInline')
  static Notetype_Config_CardRequirement getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype_Config_CardRequirement>(create);
  static Notetype_Config_CardRequirement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cardOrd => $_getIZ(0);
  @$pb.TagNumber(1)
  set cardOrd($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCardOrd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCardOrd() => clearField(1);

  @$pb.TagNumber(2)
  Notetype_Config_CardRequirement_Kind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(Notetype_Config_CardRequirement_Kind v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get fieldOrds => $_getList(2);
}

class Notetype_Config extends $pb.GeneratedMessage {
  factory Notetype_Config({
    Notetype_Config_Kind? kind,
    $core.int? sortFieldIdx,
    $core.String? css,
    $fixnum.Int64? targetDeckIdUnused,
    $core.String? latexPre,
    $core.String? latexPost,
    $core.bool? latexSvg,
    $core.Iterable<Notetype_Config_CardRequirement>? reqs,
    StockNotetype_OriginalStockKind? originalStockKind,
    $fixnum.Int64? originalId,
    $core.List<$core.int>? other,
  }) {
    final $result = create();
    if (kind != null) {
      $result.kind = kind;
    }
    if (sortFieldIdx != null) {
      $result.sortFieldIdx = sortFieldIdx;
    }
    if (css != null) {
      $result.css = css;
    }
    if (targetDeckIdUnused != null) {
      $result.targetDeckIdUnused = targetDeckIdUnused;
    }
    if (latexPre != null) {
      $result.latexPre = latexPre;
    }
    if (latexPost != null) {
      $result.latexPost = latexPost;
    }
    if (latexSvg != null) {
      $result.latexSvg = latexSvg;
    }
    if (reqs != null) {
      $result.reqs.addAll(reqs);
    }
    if (originalStockKind != null) {
      $result.originalStockKind = originalStockKind;
    }
    if (originalId != null) {
      $result.originalId = originalId;
    }
    if (other != null) {
      $result.other = other;
    }
    return $result;
  }
  Notetype_Config._() : super();
  factory Notetype_Config.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype_Config.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype.Config', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..e<Notetype_Config_Kind>(1, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE, defaultOrMaker: Notetype_Config_Kind.KIND_NORMAL, valueOf: Notetype_Config_Kind.valueOf, enumValues: Notetype_Config_Kind.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'sortFieldIdx', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'css')
    ..aInt64(4, _omitFieldNames ? '' : 'targetDeckIdUnused')
    ..aOS(5, _omitFieldNames ? '' : 'latexPre')
    ..aOS(6, _omitFieldNames ? '' : 'latexPost')
    ..aOB(7, _omitFieldNames ? '' : 'latexSvg')
    ..pc<Notetype_Config_CardRequirement>(8, _omitFieldNames ? '' : 'reqs', $pb.PbFieldType.PM, subBuilder: Notetype_Config_CardRequirement.create)
    ..e<StockNotetype_OriginalStockKind>(9, _omitFieldNames ? '' : 'originalStockKind', $pb.PbFieldType.OE, defaultOrMaker: StockNotetype_OriginalStockKind.ORIGINAL_STOCK_KIND_UNKNOWN, valueOf: StockNotetype_OriginalStockKind.valueOf, enumValues: StockNotetype_OriginalStockKind.values)
    ..aInt64(10, _omitFieldNames ? '' : 'originalId')
    ..a<$core.List<$core.int>>(255, _omitFieldNames ? '' : 'other', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype_Config clone() => Notetype_Config()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype_Config copyWith(void Function(Notetype_Config) updates) => super.copyWith((message) => updates(message as Notetype_Config)) as Notetype_Config;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype_Config create() => Notetype_Config._();
  Notetype_Config createEmptyInstance() => create();
  static $pb.PbList<Notetype_Config> createRepeated() => $pb.PbList<Notetype_Config>();
  @$core.pragma('dart2js:noInline')
  static Notetype_Config getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype_Config>(create);
  static Notetype_Config? _defaultInstance;

  @$pb.TagNumber(1)
  Notetype_Config_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(Notetype_Config_Kind v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get sortFieldIdx => $_getIZ(1);
  @$pb.TagNumber(2)
  set sortFieldIdx($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSortFieldIdx() => $_has(1);
  @$pb.TagNumber(2)
  void clearSortFieldIdx() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get css => $_getSZ(2);
  @$pb.TagNumber(3)
  set css($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCss() => $_has(2);
  @$pb.TagNumber(3)
  void clearCss() => clearField(3);

  /// This is now stored separately; retrieve with DefaultsForAdding()
  @$pb.TagNumber(4)
  $fixnum.Int64 get targetDeckIdUnused => $_getI64(3);
  @$pb.TagNumber(4)
  set targetDeckIdUnused($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTargetDeckIdUnused() => $_has(3);
  @$pb.TagNumber(4)
  void clearTargetDeckIdUnused() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get latexPre => $_getSZ(4);
  @$pb.TagNumber(5)
  set latexPre($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLatexPre() => $_has(4);
  @$pb.TagNumber(5)
  void clearLatexPre() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get latexPost => $_getSZ(5);
  @$pb.TagNumber(6)
  set latexPost($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLatexPost() => $_has(5);
  @$pb.TagNumber(6)
  void clearLatexPost() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get latexSvg => $_getBF(6);
  @$pb.TagNumber(7)
  set latexSvg($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasLatexSvg() => $_has(6);
  @$pb.TagNumber(7)
  void clearLatexSvg() => clearField(7);

  @$pb.TagNumber(8)
  $core.List<Notetype_Config_CardRequirement> get reqs => $_getList(7);

  /// Only set on notetypes created with Anki 2.1.62+.
  @$pb.TagNumber(9)
  StockNotetype_OriginalStockKind get originalStockKind => $_getN(8);
  @$pb.TagNumber(9)
  set originalStockKind(StockNotetype_OriginalStockKind v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasOriginalStockKind() => $_has(8);
  @$pb.TagNumber(9)
  void clearOriginalStockKind() => clearField(9);

  /// the id in the source collection for imported notetypes (Anki 23.10)
  @$pb.TagNumber(10)
  $fixnum.Int64 get originalId => $_getI64(9);
  @$pb.TagNumber(10)
  set originalId($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasOriginalId() => $_has(9);
  @$pb.TagNumber(10)
  void clearOriginalId() => clearField(10);

  @$pb.TagNumber(255)
  $core.List<$core.int> get other => $_getN(10);
  @$pb.TagNumber(255)
  set other($core.List<$core.int> v) { $_setBytes(10, v); }
  @$pb.TagNumber(255)
  $core.bool hasOther() => $_has(10);
  @$pb.TagNumber(255)
  void clearOther() => clearField(255);
}

class Notetype_Field_Config extends $pb.GeneratedMessage {
  factory Notetype_Field_Config({
    $core.bool? sticky,
    $core.bool? rtl,
    $core.String? fontName,
    $core.int? fontSize,
    $core.String? description,
    $core.bool? plainText,
    $core.bool? collapsed,
    $core.bool? excludeFromSearch,
    $fixnum.Int64? id,
    $core.int? tag,
    $core.bool? preventDeletion,
    $core.List<$core.int>? other,
  }) {
    final $result = create();
    if (sticky != null) {
      $result.sticky = sticky;
    }
    if (rtl != null) {
      $result.rtl = rtl;
    }
    if (fontName != null) {
      $result.fontName = fontName;
    }
    if (fontSize != null) {
      $result.fontSize = fontSize;
    }
    if (description != null) {
      $result.description = description;
    }
    if (plainText != null) {
      $result.plainText = plainText;
    }
    if (collapsed != null) {
      $result.collapsed = collapsed;
    }
    if (excludeFromSearch != null) {
      $result.excludeFromSearch = excludeFromSearch;
    }
    if (id != null) {
      $result.id = id;
    }
    if (tag != null) {
      $result.tag = tag;
    }
    if (preventDeletion != null) {
      $result.preventDeletion = preventDeletion;
    }
    if (other != null) {
      $result.other = other;
    }
    return $result;
  }
  Notetype_Field_Config._() : super();
  factory Notetype_Field_Config.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype_Field_Config.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype.Field.Config', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'sticky')
    ..aOB(2, _omitFieldNames ? '' : 'rtl')
    ..aOS(3, _omitFieldNames ? '' : 'fontName')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'fontSize', $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..aOB(6, _omitFieldNames ? '' : 'plainText')
    ..aOB(7, _omitFieldNames ? '' : 'collapsed')
    ..aOB(8, _omitFieldNames ? '' : 'excludeFromSearch')
    ..aInt64(9, _omitFieldNames ? '' : 'id')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'tag', $pb.PbFieldType.OU3)
    ..aOB(11, _omitFieldNames ? '' : 'preventDeletion')
    ..a<$core.List<$core.int>>(255, _omitFieldNames ? '' : 'other', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype_Field_Config clone() => Notetype_Field_Config()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype_Field_Config copyWith(void Function(Notetype_Field_Config) updates) => super.copyWith((message) => updates(message as Notetype_Field_Config)) as Notetype_Field_Config;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype_Field_Config create() => Notetype_Field_Config._();
  Notetype_Field_Config createEmptyInstance() => create();
  static $pb.PbList<Notetype_Field_Config> createRepeated() => $pb.PbList<Notetype_Field_Config>();
  @$core.pragma('dart2js:noInline')
  static Notetype_Field_Config getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype_Field_Config>(create);
  static Notetype_Field_Config? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get sticky => $_getBF(0);
  @$pb.TagNumber(1)
  set sticky($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSticky() => $_has(0);
  @$pb.TagNumber(1)
  void clearSticky() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get rtl => $_getBF(1);
  @$pb.TagNumber(2)
  set rtl($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRtl() => $_has(1);
  @$pb.TagNumber(2)
  void clearRtl() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get fontName => $_getSZ(2);
  @$pb.TagNumber(3)
  set fontName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFontName() => $_has(2);
  @$pb.TagNumber(3)
  void clearFontName() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get fontSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set fontSize($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFontSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearFontSize() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get plainText => $_getBF(5);
  @$pb.TagNumber(6)
  set plainText($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPlainText() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlainText() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get collapsed => $_getBF(6);
  @$pb.TagNumber(7)
  set collapsed($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasCollapsed() => $_has(6);
  @$pb.TagNumber(7)
  void clearCollapsed() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get excludeFromSearch => $_getBF(7);
  @$pb.TagNumber(8)
  set excludeFromSearch($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasExcludeFromSearch() => $_has(7);
  @$pb.TagNumber(8)
  void clearExcludeFromSearch() => clearField(8);

  /// used for merging notetypes on import (Anki 23.10)
  @$pb.TagNumber(9)
  $fixnum.Int64 get id => $_getI64(8);
  @$pb.TagNumber(9)
  set id($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasId() => $_has(8);
  @$pb.TagNumber(9)
  void clearId() => clearField(9);

  /// Can be used to uniquely identify required fields.
  @$pb.TagNumber(10)
  $core.int get tag => $_getIZ(9);
  @$pb.TagNumber(10)
  set tag($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasTag() => $_has(9);
  @$pb.TagNumber(10)
  void clearTag() => clearField(10);

  @$pb.TagNumber(11)
  $core.bool get preventDeletion => $_getBF(10);
  @$pb.TagNumber(11)
  set preventDeletion($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasPreventDeletion() => $_has(10);
  @$pb.TagNumber(11)
  void clearPreventDeletion() => clearField(11);

  @$pb.TagNumber(255)
  $core.List<$core.int> get other => $_getN(11);
  @$pb.TagNumber(255)
  set other($core.List<$core.int> v) { $_setBytes(11, v); }
  @$pb.TagNumber(255)
  $core.bool hasOther() => $_has(11);
  @$pb.TagNumber(255)
  void clearOther() => clearField(255);
}

class Notetype_Field extends $pb.GeneratedMessage {
  factory Notetype_Field({
    $0.UInt32? ord,
    $core.String? name,
    Notetype_Field_Config? config,
  }) {
    final $result = create();
    if (ord != null) {
      $result.ord = ord;
    }
    if (name != null) {
      $result.name = name;
    }
    if (config != null) {
      $result.config = config;
    }
    return $result;
  }
  Notetype_Field._() : super();
  factory Notetype_Field.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype_Field.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype.Field', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aOM<$0.UInt32>(1, _omitFieldNames ? '' : 'ord', subBuilder: $0.UInt32.create)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<Notetype_Field_Config>(5, _omitFieldNames ? '' : 'config', subBuilder: Notetype_Field_Config.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype_Field clone() => Notetype_Field()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype_Field copyWith(void Function(Notetype_Field) updates) => super.copyWith((message) => updates(message as Notetype_Field)) as Notetype_Field;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype_Field create() => Notetype_Field._();
  Notetype_Field createEmptyInstance() => create();
  static $pb.PbList<Notetype_Field> createRepeated() => $pb.PbList<Notetype_Field>();
  @$core.pragma('dart2js:noInline')
  static Notetype_Field getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype_Field>(create);
  static Notetype_Field? _defaultInstance;

  @$pb.TagNumber(1)
  $0.UInt32 get ord => $_getN(0);
  @$pb.TagNumber(1)
  set ord($0.UInt32 v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasOrd() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrd() => clearField(1);
  @$pb.TagNumber(1)
  $0.UInt32 ensureOrd() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(5)
  Notetype_Field_Config get config => $_getN(2);
  @$pb.TagNumber(5)
  set config(Notetype_Field_Config v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasConfig() => $_has(2);
  @$pb.TagNumber(5)
  void clearConfig() => clearField(5);
  @$pb.TagNumber(5)
  Notetype_Field_Config ensureConfig() => $_ensure(2);
}

class Notetype_Template_Config extends $pb.GeneratedMessage {
  factory Notetype_Template_Config({
    $core.String? qFormat,
    $core.String? aFormat,
    $core.String? qFormatBrowser,
    $core.String? aFormatBrowser,
    $fixnum.Int64? targetDeckId,
    $core.String? browserFontName,
    $core.int? browserFontSize,
    $fixnum.Int64? id,
    $core.List<$core.int>? other,
  }) {
    final $result = create();
    if (qFormat != null) {
      $result.qFormat = qFormat;
    }
    if (aFormat != null) {
      $result.aFormat = aFormat;
    }
    if (qFormatBrowser != null) {
      $result.qFormatBrowser = qFormatBrowser;
    }
    if (aFormatBrowser != null) {
      $result.aFormatBrowser = aFormatBrowser;
    }
    if (targetDeckId != null) {
      $result.targetDeckId = targetDeckId;
    }
    if (browserFontName != null) {
      $result.browserFontName = browserFontName;
    }
    if (browserFontSize != null) {
      $result.browserFontSize = browserFontSize;
    }
    if (id != null) {
      $result.id = id;
    }
    if (other != null) {
      $result.other = other;
    }
    return $result;
  }
  Notetype_Template_Config._() : super();
  factory Notetype_Template_Config.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype_Template_Config.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype.Template.Config', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'qFormat')
    ..aOS(2, _omitFieldNames ? '' : 'aFormat')
    ..aOS(3, _omitFieldNames ? '' : 'qFormatBrowser')
    ..aOS(4, _omitFieldNames ? '' : 'aFormatBrowser')
    ..aInt64(5, _omitFieldNames ? '' : 'targetDeckId')
    ..aOS(6, _omitFieldNames ? '' : 'browserFontName')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'browserFontSize', $pb.PbFieldType.OU3)
    ..aInt64(8, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(255, _omitFieldNames ? '' : 'other', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype_Template_Config clone() => Notetype_Template_Config()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype_Template_Config copyWith(void Function(Notetype_Template_Config) updates) => super.copyWith((message) => updates(message as Notetype_Template_Config)) as Notetype_Template_Config;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype_Template_Config create() => Notetype_Template_Config._();
  Notetype_Template_Config createEmptyInstance() => create();
  static $pb.PbList<Notetype_Template_Config> createRepeated() => $pb.PbList<Notetype_Template_Config>();
  @$core.pragma('dart2js:noInline')
  static Notetype_Template_Config getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype_Template_Config>(create);
  static Notetype_Template_Config? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get qFormat => $_getSZ(0);
  @$pb.TagNumber(1)
  set qFormat($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasQFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearQFormat() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get aFormat => $_getSZ(1);
  @$pb.TagNumber(2)
  set aFormat($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearAFormat() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get qFormatBrowser => $_getSZ(2);
  @$pb.TagNumber(3)
  set qFormatBrowser($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasQFormatBrowser() => $_has(2);
  @$pb.TagNumber(3)
  void clearQFormatBrowser() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get aFormatBrowser => $_getSZ(3);
  @$pb.TagNumber(4)
  set aFormatBrowser($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAFormatBrowser() => $_has(3);
  @$pb.TagNumber(4)
  void clearAFormatBrowser() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get targetDeckId => $_getI64(4);
  @$pb.TagNumber(5)
  set targetDeckId($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTargetDeckId() => $_has(4);
  @$pb.TagNumber(5)
  void clearTargetDeckId() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get browserFontName => $_getSZ(5);
  @$pb.TagNumber(6)
  set browserFontName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasBrowserFontName() => $_has(5);
  @$pb.TagNumber(6)
  void clearBrowserFontName() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get browserFontSize => $_getIZ(6);
  @$pb.TagNumber(7)
  set browserFontSize($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasBrowserFontSize() => $_has(6);
  @$pb.TagNumber(7)
  void clearBrowserFontSize() => clearField(7);

  /// used for merging notetypes on import (Anki 23.10)
  @$pb.TagNumber(8)
  $fixnum.Int64 get id => $_getI64(7);
  @$pb.TagNumber(8)
  set id($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasId() => $_has(7);
  @$pb.TagNumber(8)
  void clearId() => clearField(8);

  @$pb.TagNumber(255)
  $core.List<$core.int> get other => $_getN(8);
  @$pb.TagNumber(255)
  set other($core.List<$core.int> v) { $_setBytes(8, v); }
  @$pb.TagNumber(255)
  $core.bool hasOther() => $_has(8);
  @$pb.TagNumber(255)
  void clearOther() => clearField(255);
}

class Notetype_Template extends $pb.GeneratedMessage {
  factory Notetype_Template({
    $0.UInt32? ord,
    $core.String? name,
    $fixnum.Int64? mtimeSecs,
    $core.int? usn,
    Notetype_Template_Config? config,
  }) {
    final $result = create();
    if (ord != null) {
      $result.ord = ord;
    }
    if (name != null) {
      $result.name = name;
    }
    if (mtimeSecs != null) {
      $result.mtimeSecs = mtimeSecs;
    }
    if (usn != null) {
      $result.usn = usn;
    }
    if (config != null) {
      $result.config = config;
    }
    return $result;
  }
  Notetype_Template._() : super();
  factory Notetype_Template.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype_Template.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype.Template', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aOM<$0.UInt32>(1, _omitFieldNames ? '' : 'ord', subBuilder: $0.UInt32.create)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'mtimeSecs')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'usn', $pb.PbFieldType.OS3)
    ..aOM<Notetype_Template_Config>(5, _omitFieldNames ? '' : 'config', subBuilder: Notetype_Template_Config.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype_Template clone() => Notetype_Template()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype_Template copyWith(void Function(Notetype_Template) updates) => super.copyWith((message) => updates(message as Notetype_Template)) as Notetype_Template;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype_Template create() => Notetype_Template._();
  Notetype_Template createEmptyInstance() => create();
  static $pb.PbList<Notetype_Template> createRepeated() => $pb.PbList<Notetype_Template>();
  @$core.pragma('dart2js:noInline')
  static Notetype_Template getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype_Template>(create);
  static Notetype_Template? _defaultInstance;

  @$pb.TagNumber(1)
  $0.UInt32 get ord => $_getN(0);
  @$pb.TagNumber(1)
  set ord($0.UInt32 v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasOrd() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrd() => clearField(1);
  @$pb.TagNumber(1)
  $0.UInt32 ensureOrd() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get mtimeSecs => $_getI64(2);
  @$pb.TagNumber(3)
  set mtimeSecs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMtimeSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearMtimeSecs() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get usn => $_getIZ(3);
  @$pb.TagNumber(4)
  set usn($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUsn() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsn() => clearField(4);

  @$pb.TagNumber(5)
  Notetype_Template_Config get config => $_getN(4);
  @$pb.TagNumber(5)
  set config(Notetype_Template_Config v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasConfig() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfig() => clearField(5);
  @$pb.TagNumber(5)
  Notetype_Template_Config ensureConfig() => $_ensure(4);
}

class Notetype extends $pb.GeneratedMessage {
  factory Notetype({
    $fixnum.Int64? id,
    $core.String? name,
    $fixnum.Int64? mtimeSecs,
    $core.int? usn,
    Notetype_Config? config,
    $core.Iterable<Notetype_Field>? fields,
    $core.Iterable<Notetype_Template>? templates,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (mtimeSecs != null) {
      $result.mtimeSecs = mtimeSecs;
    }
    if (usn != null) {
      $result.usn = usn;
    }
    if (config != null) {
      $result.config = config;
    }
    if (fields != null) {
      $result.fields.addAll(fields);
    }
    if (templates != null) {
      $result.templates.addAll(templates);
    }
    return $result;
  }
  Notetype._() : super();
  factory Notetype.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notetype.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notetype', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aInt64(3, _omitFieldNames ? '' : 'mtimeSecs')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'usn', $pb.PbFieldType.OS3)
    ..aOM<Notetype_Config>(7, _omitFieldNames ? '' : 'config', subBuilder: Notetype_Config.create)
    ..pc<Notetype_Field>(8, _omitFieldNames ? '' : 'fields', $pb.PbFieldType.PM, subBuilder: Notetype_Field.create)
    ..pc<Notetype_Template>(9, _omitFieldNames ? '' : 'templates', $pb.PbFieldType.PM, subBuilder: Notetype_Template.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Notetype clone() => Notetype()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Notetype copyWith(void Function(Notetype) updates) => super.copyWith((message) => updates(message as Notetype)) as Notetype;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notetype create() => Notetype._();
  Notetype createEmptyInstance() => create();
  static $pb.PbList<Notetype> createRepeated() => $pb.PbList<Notetype>();
  @$core.pragma('dart2js:noInline')
  static Notetype getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notetype>(create);
  static Notetype? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
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
  $fixnum.Int64 get mtimeSecs => $_getI64(2);
  @$pb.TagNumber(3)
  set mtimeSecs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMtimeSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearMtimeSecs() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get usn => $_getIZ(3);
  @$pb.TagNumber(4)
  set usn($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUsn() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsn() => clearField(4);

  @$pb.TagNumber(7)
  Notetype_Config get config => $_getN(4);
  @$pb.TagNumber(7)
  set config(Notetype_Config v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasConfig() => $_has(4);
  @$pb.TagNumber(7)
  void clearConfig() => clearField(7);
  @$pb.TagNumber(7)
  Notetype_Config ensureConfig() => $_ensure(4);

  @$pb.TagNumber(8)
  $core.List<Notetype_Field> get fields => $_getList(5);

  @$pb.TagNumber(9)
  $core.List<Notetype_Template> get templates => $_getList(6);
}

class AddOrUpdateNotetypeRequest extends $pb.GeneratedMessage {
  factory AddOrUpdateNotetypeRequest({
    $core.List<$core.int>? json,
    $core.bool? preserveUsnAndMtime,
    $core.bool? skipChecks,
  }) {
    final $result = create();
    if (json != null) {
      $result.json = json;
    }
    if (preserveUsnAndMtime != null) {
      $result.preserveUsnAndMtime = preserveUsnAndMtime;
    }
    if (skipChecks != null) {
      $result.skipChecks = skipChecks;
    }
    return $result;
  }
  AddOrUpdateNotetypeRequest._() : super();
  factory AddOrUpdateNotetypeRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddOrUpdateNotetypeRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddOrUpdateNotetypeRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'json', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'preserveUsnAndMtime')
    ..aOB(3, _omitFieldNames ? '' : 'skipChecks')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddOrUpdateNotetypeRequest clone() => AddOrUpdateNotetypeRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddOrUpdateNotetypeRequest copyWith(void Function(AddOrUpdateNotetypeRequest) updates) => super.copyWith((message) => updates(message as AddOrUpdateNotetypeRequest)) as AddOrUpdateNotetypeRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddOrUpdateNotetypeRequest create() => AddOrUpdateNotetypeRequest._();
  AddOrUpdateNotetypeRequest createEmptyInstance() => create();
  static $pb.PbList<AddOrUpdateNotetypeRequest> createRepeated() => $pb.PbList<AddOrUpdateNotetypeRequest>();
  @$core.pragma('dart2js:noInline')
  static AddOrUpdateNotetypeRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddOrUpdateNotetypeRequest>(create);
  static AddOrUpdateNotetypeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get json => $_getN(0);
  @$pb.TagNumber(1)
  set json($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearJson() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get preserveUsnAndMtime => $_getBF(1);
  @$pb.TagNumber(2)
  set preserveUsnAndMtime($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPreserveUsnAndMtime() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreserveUsnAndMtime() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get skipChecks => $_getBF(2);
  @$pb.TagNumber(3)
  set skipChecks($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSkipChecks() => $_has(2);
  @$pb.TagNumber(3)
  void clearSkipChecks() => clearField(3);
}

class UpdateNotetypeLegacyRequest extends $pb.GeneratedMessage {
  factory UpdateNotetypeLegacyRequest({
    $core.List<$core.int>? json,
    $core.bool? skipChecks,
  }) {
    final $result = create();
    if (json != null) {
      $result.json = json;
    }
    if (skipChecks != null) {
      $result.skipChecks = skipChecks;
    }
    return $result;
  }
  UpdateNotetypeLegacyRequest._() : super();
  factory UpdateNotetypeLegacyRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateNotetypeLegacyRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateNotetypeLegacyRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'json', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'skipChecks')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateNotetypeLegacyRequest clone() => UpdateNotetypeLegacyRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateNotetypeLegacyRequest copyWith(void Function(UpdateNotetypeLegacyRequest) updates) => super.copyWith((message) => updates(message as UpdateNotetypeLegacyRequest)) as UpdateNotetypeLegacyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNotetypeLegacyRequest create() => UpdateNotetypeLegacyRequest._();
  UpdateNotetypeLegacyRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateNotetypeLegacyRequest> createRepeated() => $pb.PbList<UpdateNotetypeLegacyRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateNotetypeLegacyRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateNotetypeLegacyRequest>(create);
  static UpdateNotetypeLegacyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get json => $_getN(0);
  @$pb.TagNumber(1)
  set json($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearJson() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get skipChecks => $_getBF(1);
  @$pb.TagNumber(2)
  set skipChecks($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSkipChecks() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipChecks() => clearField(2);
}

class StockNotetype extends $pb.GeneratedMessage {
  factory StockNotetype({
    StockNotetype_Kind? kind,
  }) {
    final $result = create();
    if (kind != null) {
      $result.kind = kind;
    }
    return $result;
  }
  StockNotetype._() : super();
  factory StockNotetype.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StockNotetype.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StockNotetype', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..e<StockNotetype_Kind>(1, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE, defaultOrMaker: StockNotetype_Kind.KIND_BASIC, valueOf: StockNotetype_Kind.valueOf, enumValues: StockNotetype_Kind.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StockNotetype clone() => StockNotetype()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StockNotetype copyWith(void Function(StockNotetype) updates) => super.copyWith((message) => updates(message as StockNotetype)) as StockNotetype;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StockNotetype create() => StockNotetype._();
  StockNotetype createEmptyInstance() => create();
  static $pb.PbList<StockNotetype> createRepeated() => $pb.PbList<StockNotetype>();
  @$core.pragma('dart2js:noInline')
  static StockNotetype getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StockNotetype>(create);
  static StockNotetype? _defaultInstance;

  @$pb.TagNumber(1)
  StockNotetype_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(StockNotetype_Kind v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => clearField(1);
}

class NotetypeNames extends $pb.GeneratedMessage {
  factory NotetypeNames({
    $core.Iterable<NotetypeNameId>? entries,
  }) {
    final $result = create();
    if (entries != null) {
      $result.entries.addAll(entries);
    }
    return $result;
  }
  NotetypeNames._() : super();
  factory NotetypeNames.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NotetypeNames.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotetypeNames', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..pc<NotetypeNameId>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM, subBuilder: NotetypeNameId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NotetypeNames clone() => NotetypeNames()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NotetypeNames copyWith(void Function(NotetypeNames) updates) => super.copyWith((message) => updates(message as NotetypeNames)) as NotetypeNames;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotetypeNames create() => NotetypeNames._();
  NotetypeNames createEmptyInstance() => create();
  static $pb.PbList<NotetypeNames> createRepeated() => $pb.PbList<NotetypeNames>();
  @$core.pragma('dart2js:noInline')
  static NotetypeNames getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotetypeNames>(create);
  static NotetypeNames? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<NotetypeNameId> get entries => $_getList(0);
}

class NotetypeUseCounts extends $pb.GeneratedMessage {
  factory NotetypeUseCounts({
    $core.Iterable<NotetypeNameIdUseCount>? entries,
  }) {
    final $result = create();
    if (entries != null) {
      $result.entries.addAll(entries);
    }
    return $result;
  }
  NotetypeUseCounts._() : super();
  factory NotetypeUseCounts.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NotetypeUseCounts.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotetypeUseCounts', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..pc<NotetypeNameIdUseCount>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM, subBuilder: NotetypeNameIdUseCount.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NotetypeUseCounts clone() => NotetypeUseCounts()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NotetypeUseCounts copyWith(void Function(NotetypeUseCounts) updates) => super.copyWith((message) => updates(message as NotetypeUseCounts)) as NotetypeUseCounts;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotetypeUseCounts create() => NotetypeUseCounts._();
  NotetypeUseCounts createEmptyInstance() => create();
  static $pb.PbList<NotetypeUseCounts> createRepeated() => $pb.PbList<NotetypeUseCounts>();
  @$core.pragma('dart2js:noInline')
  static NotetypeUseCounts getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotetypeUseCounts>(create);
  static NotetypeUseCounts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<NotetypeNameIdUseCount> get entries => $_getList(0);
}

class NotetypeNameId extends $pb.GeneratedMessage {
  factory NotetypeNameId({
    $fixnum.Int64? id,
    $core.String? name,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  NotetypeNameId._() : super();
  factory NotetypeNameId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NotetypeNameId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotetypeNameId', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NotetypeNameId clone() => NotetypeNameId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NotetypeNameId copyWith(void Function(NotetypeNameId) updates) => super.copyWith((message) => updates(message as NotetypeNameId)) as NotetypeNameId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotetypeNameId create() => NotetypeNameId._();
  NotetypeNameId createEmptyInstance() => create();
  static $pb.PbList<NotetypeNameId> createRepeated() => $pb.PbList<NotetypeNameId>();
  @$core.pragma('dart2js:noInline')
  static NotetypeNameId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotetypeNameId>(create);
  static NotetypeNameId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
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
}

class NotetypeNameIdUseCount extends $pb.GeneratedMessage {
  factory NotetypeNameIdUseCount({
    $fixnum.Int64? id,
    $core.String? name,
    $core.int? useCount,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (useCount != null) {
      $result.useCount = useCount;
    }
    return $result;
  }
  NotetypeNameIdUseCount._() : super();
  factory NotetypeNameIdUseCount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NotetypeNameIdUseCount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotetypeNameIdUseCount', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'useCount', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NotetypeNameIdUseCount clone() => NotetypeNameIdUseCount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NotetypeNameIdUseCount copyWith(void Function(NotetypeNameIdUseCount) updates) => super.copyWith((message) => updates(message as NotetypeNameIdUseCount)) as NotetypeNameIdUseCount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotetypeNameIdUseCount create() => NotetypeNameIdUseCount._();
  NotetypeNameIdUseCount createEmptyInstance() => create();
  static $pb.PbList<NotetypeNameIdUseCount> createRepeated() => $pb.PbList<NotetypeNameIdUseCount>();
  @$core.pragma('dart2js:noInline')
  static NotetypeNameIdUseCount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotetypeNameIdUseCount>(create);
  static NotetypeNameIdUseCount? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
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
  $core.int get useCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set useCount($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUseCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearUseCount() => clearField(3);
}

class GetAuxConfigKeyRequest extends $pb.GeneratedMessage {
  factory GetAuxConfigKeyRequest({
    $fixnum.Int64? id,
    $core.String? key,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (key != null) {
      $result.key = key;
    }
    return $result;
  }
  GetAuxConfigKeyRequest._() : super();
  factory GetAuxConfigKeyRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAuxConfigKeyRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAuxConfigKeyRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAuxConfigKeyRequest clone() => GetAuxConfigKeyRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAuxConfigKeyRequest copyWith(void Function(GetAuxConfigKeyRequest) updates) => super.copyWith((message) => updates(message as GetAuxConfigKeyRequest)) as GetAuxConfigKeyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAuxConfigKeyRequest create() => GetAuxConfigKeyRequest._();
  GetAuxConfigKeyRequest createEmptyInstance() => create();
  static $pb.PbList<GetAuxConfigKeyRequest> createRepeated() => $pb.PbList<GetAuxConfigKeyRequest>();
  @$core.pragma('dart2js:noInline')
  static GetAuxConfigKeyRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAuxConfigKeyRequest>(create);
  static GetAuxConfigKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => clearField(2);
}

class GetAuxTemplateConfigKeyRequest extends $pb.GeneratedMessage {
  factory GetAuxTemplateConfigKeyRequest({
    $fixnum.Int64? notetypeId,
    $core.int? cardOrdinal,
    $core.String? key,
  }) {
    final $result = create();
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    if (cardOrdinal != null) {
      $result.cardOrdinal = cardOrdinal;
    }
    if (key != null) {
      $result.key = key;
    }
    return $result;
  }
  GetAuxTemplateConfigKeyRequest._() : super();
  factory GetAuxTemplateConfigKeyRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAuxTemplateConfigKeyRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAuxTemplateConfigKeyRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'notetypeId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'cardOrdinal', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'key')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAuxTemplateConfigKeyRequest clone() => GetAuxTemplateConfigKeyRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAuxTemplateConfigKeyRequest copyWith(void Function(GetAuxTemplateConfigKeyRequest) updates) => super.copyWith((message) => updates(message as GetAuxTemplateConfigKeyRequest)) as GetAuxTemplateConfigKeyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAuxTemplateConfigKeyRequest create() => GetAuxTemplateConfigKeyRequest._();
  GetAuxTemplateConfigKeyRequest createEmptyInstance() => create();
  static $pb.PbList<GetAuxTemplateConfigKeyRequest> createRepeated() => $pb.PbList<GetAuxTemplateConfigKeyRequest>();
  @$core.pragma('dart2js:noInline')
  static GetAuxTemplateConfigKeyRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAuxTemplateConfigKeyRequest>(create);
  static GetAuxTemplateConfigKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get notetypeId => $_getI64(0);
  @$pb.TagNumber(1)
  set notetypeId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNotetypeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNotetypeId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get cardOrdinal => $_getIZ(1);
  @$pb.TagNumber(2)
  set cardOrdinal($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardOrdinal() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardOrdinal() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get key => $_getSZ(2);
  @$pb.TagNumber(3)
  set key($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => clearField(3);
}

class GetChangeNotetypeInfoRequest extends $pb.GeneratedMessage {
  factory GetChangeNotetypeInfoRequest({
    $fixnum.Int64? oldNotetypeId,
    $fixnum.Int64? newNotetypeId,
  }) {
    final $result = create();
    if (oldNotetypeId != null) {
      $result.oldNotetypeId = oldNotetypeId;
    }
    if (newNotetypeId != null) {
      $result.newNotetypeId = newNotetypeId;
    }
    return $result;
  }
  GetChangeNotetypeInfoRequest._() : super();
  factory GetChangeNotetypeInfoRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetChangeNotetypeInfoRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetChangeNotetypeInfoRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'oldNotetypeId')
    ..aInt64(2, _omitFieldNames ? '' : 'newNotetypeId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetChangeNotetypeInfoRequest clone() => GetChangeNotetypeInfoRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetChangeNotetypeInfoRequest copyWith(void Function(GetChangeNotetypeInfoRequest) updates) => super.copyWith((message) => updates(message as GetChangeNotetypeInfoRequest)) as GetChangeNotetypeInfoRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetChangeNotetypeInfoRequest create() => GetChangeNotetypeInfoRequest._();
  GetChangeNotetypeInfoRequest createEmptyInstance() => create();
  static $pb.PbList<GetChangeNotetypeInfoRequest> createRepeated() => $pb.PbList<GetChangeNotetypeInfoRequest>();
  @$core.pragma('dart2js:noInline')
  static GetChangeNotetypeInfoRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetChangeNotetypeInfoRequest>(create);
  static GetChangeNotetypeInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get oldNotetypeId => $_getI64(0);
  @$pb.TagNumber(1)
  set oldNotetypeId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOldNotetypeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOldNotetypeId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get newNotetypeId => $_getI64(1);
  @$pb.TagNumber(2)
  set newNotetypeId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNewNotetypeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewNotetypeId() => clearField(2);
}

class ChangeNotetypeRequest extends $pb.GeneratedMessage {
  factory ChangeNotetypeRequest({
    $core.Iterable<$fixnum.Int64>? noteIds,
    $core.Iterable<$core.int>? newFields,
    $core.Iterable<$core.int>? newTemplates,
    $fixnum.Int64? oldNotetypeId,
    $fixnum.Int64? newNotetypeId,
    $fixnum.Int64? currentSchema,
    $core.String? oldNotetypeName,
    $core.bool? isCloze,
  }) {
    final $result = create();
    if (noteIds != null) {
      $result.noteIds.addAll(noteIds);
    }
    if (newFields != null) {
      $result.newFields.addAll(newFields);
    }
    if (newTemplates != null) {
      $result.newTemplates.addAll(newTemplates);
    }
    if (oldNotetypeId != null) {
      $result.oldNotetypeId = oldNotetypeId;
    }
    if (newNotetypeId != null) {
      $result.newNotetypeId = newNotetypeId;
    }
    if (currentSchema != null) {
      $result.currentSchema = currentSchema;
    }
    if (oldNotetypeName != null) {
      $result.oldNotetypeName = oldNotetypeName;
    }
    if (isCloze != null) {
      $result.isCloze = isCloze;
    }
    return $result;
  }
  ChangeNotetypeRequest._() : super();
  factory ChangeNotetypeRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChangeNotetypeRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChangeNotetypeRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'noteIds', $pb.PbFieldType.K6)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'newFields', $pb.PbFieldType.K3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'newTemplates', $pb.PbFieldType.K3)
    ..aInt64(4, _omitFieldNames ? '' : 'oldNotetypeId')
    ..aInt64(5, _omitFieldNames ? '' : 'newNotetypeId')
    ..aInt64(6, _omitFieldNames ? '' : 'currentSchema')
    ..aOS(7, _omitFieldNames ? '' : 'oldNotetypeName')
    ..aOB(8, _omitFieldNames ? '' : 'isCloze')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChangeNotetypeRequest clone() => ChangeNotetypeRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChangeNotetypeRequest copyWith(void Function(ChangeNotetypeRequest) updates) => super.copyWith((message) => updates(message as ChangeNotetypeRequest)) as ChangeNotetypeRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeNotetypeRequest create() => ChangeNotetypeRequest._();
  ChangeNotetypeRequest createEmptyInstance() => create();
  static $pb.PbList<ChangeNotetypeRequest> createRepeated() => $pb.PbList<ChangeNotetypeRequest>();
  @$core.pragma('dart2js:noInline')
  static ChangeNotetypeRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChangeNotetypeRequest>(create);
  static ChangeNotetypeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get noteIds => $_getList(0);

  /// -1 is used to represent null, as nullable repeated fields
  /// are unwieldy in protobuf
  @$pb.TagNumber(2)
  $core.List<$core.int> get newFields => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get newTemplates => $_getList(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get oldNotetypeId => $_getI64(3);
  @$pb.TagNumber(4)
  set oldNotetypeId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasOldNotetypeId() => $_has(3);
  @$pb.TagNumber(4)
  void clearOldNotetypeId() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get newNotetypeId => $_getI64(4);
  @$pb.TagNumber(5)
  set newNotetypeId($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasNewNotetypeId() => $_has(4);
  @$pb.TagNumber(5)
  void clearNewNotetypeId() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get currentSchema => $_getI64(5);
  @$pb.TagNumber(6)
  set currentSchema($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasCurrentSchema() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrentSchema() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get oldNotetypeName => $_getSZ(6);
  @$pb.TagNumber(7)
  set oldNotetypeName($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasOldNotetypeName() => $_has(6);
  @$pb.TagNumber(7)
  void clearOldNotetypeName() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isCloze => $_getBF(7);
  @$pb.TagNumber(8)
  set isCloze($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasIsCloze() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsCloze() => clearField(8);
}

class ChangeNotetypeInfo extends $pb.GeneratedMessage {
  factory ChangeNotetypeInfo({
    $core.Iterable<$core.String>? oldFieldNames,
    $core.Iterable<$core.String>? oldTemplateNames,
    $core.Iterable<$core.String>? newFieldNames,
    $core.Iterable<$core.String>? newTemplateNames,
    ChangeNotetypeRequest? input,
    $core.String? oldNotetypeName,
  }) {
    final $result = create();
    if (oldFieldNames != null) {
      $result.oldFieldNames.addAll(oldFieldNames);
    }
    if (oldTemplateNames != null) {
      $result.oldTemplateNames.addAll(oldTemplateNames);
    }
    if (newFieldNames != null) {
      $result.newFieldNames.addAll(newFieldNames);
    }
    if (newTemplateNames != null) {
      $result.newTemplateNames.addAll(newTemplateNames);
    }
    if (input != null) {
      $result.input = input;
    }
    if (oldNotetypeName != null) {
      $result.oldNotetypeName = oldNotetypeName;
    }
    return $result;
  }
  ChangeNotetypeInfo._() : super();
  factory ChangeNotetypeInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChangeNotetypeInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChangeNotetypeInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'oldFieldNames')
    ..pPS(2, _omitFieldNames ? '' : 'oldTemplateNames')
    ..pPS(3, _omitFieldNames ? '' : 'newFieldNames')
    ..pPS(4, _omitFieldNames ? '' : 'newTemplateNames')
    ..aOM<ChangeNotetypeRequest>(5, _omitFieldNames ? '' : 'input', subBuilder: ChangeNotetypeRequest.create)
    ..aOS(6, _omitFieldNames ? '' : 'oldNotetypeName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChangeNotetypeInfo clone() => ChangeNotetypeInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChangeNotetypeInfo copyWith(void Function(ChangeNotetypeInfo) updates) => super.copyWith((message) => updates(message as ChangeNotetypeInfo)) as ChangeNotetypeInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeNotetypeInfo create() => ChangeNotetypeInfo._();
  ChangeNotetypeInfo createEmptyInstance() => create();
  static $pb.PbList<ChangeNotetypeInfo> createRepeated() => $pb.PbList<ChangeNotetypeInfo>();
  @$core.pragma('dart2js:noInline')
  static ChangeNotetypeInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChangeNotetypeInfo>(create);
  static ChangeNotetypeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get oldFieldNames => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get oldTemplateNames => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get newFieldNames => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.String> get newTemplateNames => $_getList(3);

  @$pb.TagNumber(5)
  ChangeNotetypeRequest get input => $_getN(4);
  @$pb.TagNumber(5)
  set input(ChangeNotetypeRequest v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasInput() => $_has(4);
  @$pb.TagNumber(5)
  void clearInput() => clearField(5);
  @$pb.TagNumber(5)
  ChangeNotetypeRequest ensureInput() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get oldNotetypeName => $_getSZ(5);
  @$pb.TagNumber(6)
  set oldNotetypeName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasOldNotetypeName() => $_has(5);
  @$pb.TagNumber(6)
  void clearOldNotetypeName() => clearField(6);
}

class RestoreNotetypeToStockRequest extends $pb.GeneratedMessage {
  factory RestoreNotetypeToStockRequest({
    NotetypeId? notetypeId,
    StockNotetype_Kind? forceKind,
  }) {
    final $result = create();
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    if (forceKind != null) {
      $result.forceKind = forceKind;
    }
    return $result;
  }
  RestoreNotetypeToStockRequest._() : super();
  factory RestoreNotetypeToStockRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RestoreNotetypeToStockRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RestoreNotetypeToStockRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..aOM<NotetypeId>(1, _omitFieldNames ? '' : 'notetypeId', subBuilder: NotetypeId.create)
    ..e<StockNotetype_Kind>(2, _omitFieldNames ? '' : 'forceKind', $pb.PbFieldType.OE, defaultOrMaker: StockNotetype_Kind.KIND_BASIC, valueOf: StockNotetype_Kind.valueOf, enumValues: StockNotetype_Kind.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RestoreNotetypeToStockRequest clone() => RestoreNotetypeToStockRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RestoreNotetypeToStockRequest copyWith(void Function(RestoreNotetypeToStockRequest) updates) => super.copyWith((message) => updates(message as RestoreNotetypeToStockRequest)) as RestoreNotetypeToStockRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RestoreNotetypeToStockRequest create() => RestoreNotetypeToStockRequest._();
  RestoreNotetypeToStockRequest createEmptyInstance() => create();
  static $pb.PbList<RestoreNotetypeToStockRequest> createRepeated() => $pb.PbList<RestoreNotetypeToStockRequest>();
  @$core.pragma('dart2js:noInline')
  static RestoreNotetypeToStockRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RestoreNotetypeToStockRequest>(create);
  static RestoreNotetypeToStockRequest? _defaultInstance;

  @$pb.TagNumber(1)
  NotetypeId get notetypeId => $_getN(0);
  @$pb.TagNumber(1)
  set notetypeId(NotetypeId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNotetypeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNotetypeId() => clearField(1);
  @$pb.TagNumber(1)
  NotetypeId ensureNotetypeId() => $_ensure(0);

  /// Older notetypes did not store their original stock kind, so we allow the UI
  /// to pass in an override to use when missing, or for tests.
  @$pb.TagNumber(2)
  StockNotetype_Kind get forceKind => $_getN(1);
  @$pb.TagNumber(2)
  set forceKind(StockNotetype_Kind v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasForceKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearForceKind() => clearField(2);
}

class GetClozeFieldOrdsResponse extends $pb.GeneratedMessage {
  factory GetClozeFieldOrdsResponse({
    $core.Iterable<$core.int>? ords,
  }) {
    final $result = create();
    if (ords != null) {
      $result.ords.addAll(ords);
    }
    return $result;
  }
  GetClozeFieldOrdsResponse._() : super();
  factory GetClozeFieldOrdsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetClozeFieldOrdsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetClozeFieldOrdsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notetypes'), createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'ords', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetClozeFieldOrdsResponse clone() => GetClozeFieldOrdsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetClozeFieldOrdsResponse copyWith(void Function(GetClozeFieldOrdsResponse) updates) => super.copyWith((message) => updates(message as GetClozeFieldOrdsResponse)) as GetClozeFieldOrdsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetClozeFieldOrdsResponse create() => GetClozeFieldOrdsResponse._();
  GetClozeFieldOrdsResponse createEmptyInstance() => create();
  static $pb.PbList<GetClozeFieldOrdsResponse> createRepeated() => $pb.PbList<GetClozeFieldOrdsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetClozeFieldOrdsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetClozeFieldOrdsResponse>(create);
  static GetClozeFieldOrdsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get ords => $_getList(0);
}

class NotetypesServiceApi {
  $pb.RpcClient _client;
  NotetypesServiceApi(this._client);

  $async.Future<$2.OpChangesWithId> addNotetype($pb.ClientContext? ctx, Notetype request) =>
    _client.invoke<$2.OpChangesWithId>(ctx, 'NotetypesService', 'AddNotetype', request, $2.OpChangesWithId())
  ;
  $async.Future<$2.OpChanges> updateNotetype($pb.ClientContext? ctx, Notetype request) =>
    _client.invoke<$2.OpChanges>(ctx, 'NotetypesService', 'UpdateNotetype', request, $2.OpChanges())
  ;
  $async.Future<$2.OpChangesWithId> addNotetypeLegacy($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<$2.OpChangesWithId>(ctx, 'NotetypesService', 'AddNotetypeLegacy', request, $2.OpChangesWithId())
  ;
  $async.Future<$2.OpChanges> updateNotetypeLegacy($pb.ClientContext? ctx, UpdateNotetypeLegacyRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'NotetypesService', 'UpdateNotetypeLegacy', request, $2.OpChanges())
  ;
  $async.Future<NotetypeId> addOrUpdateNotetype($pb.ClientContext? ctx, AddOrUpdateNotetypeRequest request) =>
    _client.invoke<NotetypeId>(ctx, 'NotetypesService', 'AddOrUpdateNotetype', request, NotetypeId())
  ;
  $async.Future<$0.Json> getStockNotetypeLegacy($pb.ClientContext? ctx, StockNotetype request) =>
    _client.invoke<$0.Json>(ctx, 'NotetypesService', 'GetStockNotetypeLegacy', request, $0.Json())
  ;
  $async.Future<Notetype> getNotetype($pb.ClientContext? ctx, NotetypeId request) =>
    _client.invoke<Notetype>(ctx, 'NotetypesService', 'GetNotetype', request, Notetype())
  ;
  $async.Future<$0.Json> getNotetypeLegacy($pb.ClientContext? ctx, NotetypeId request) =>
    _client.invoke<$0.Json>(ctx, 'NotetypesService', 'GetNotetypeLegacy', request, $0.Json())
  ;
  $async.Future<NotetypeNames> getNotetypeNames($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<NotetypeNames>(ctx, 'NotetypesService', 'GetNotetypeNames', request, NotetypeNames())
  ;
  $async.Future<NotetypeUseCounts> getNotetypeNamesAndCounts($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<NotetypeUseCounts>(ctx, 'NotetypesService', 'GetNotetypeNamesAndCounts', request, NotetypeUseCounts())
  ;
  $async.Future<NotetypeId> getNotetypeIdByName($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<NotetypeId>(ctx, 'NotetypesService', 'GetNotetypeIdByName', request, NotetypeId())
  ;
  $async.Future<$2.OpChanges> removeNotetype($pb.ClientContext? ctx, NotetypeId request) =>
    _client.invoke<$2.OpChanges>(ctx, 'NotetypesService', 'RemoveNotetype', request, $2.OpChanges())
  ;
  $async.Future<$0.String> getAuxNotetypeConfigKey($pb.ClientContext? ctx, GetAuxConfigKeyRequest request) =>
    _client.invoke<$0.String>(ctx, 'NotetypesService', 'GetAuxNotetypeConfigKey', request, $0.String())
  ;
  $async.Future<$0.String> getAuxTemplateConfigKey($pb.ClientContext? ctx, GetAuxTemplateConfigKeyRequest request) =>
    _client.invoke<$0.String>(ctx, 'NotetypesService', 'GetAuxTemplateConfigKey', request, $0.String())
  ;
  $async.Future<ChangeNotetypeInfo> getChangeNotetypeInfo($pb.ClientContext? ctx, GetChangeNotetypeInfoRequest request) =>
    _client.invoke<ChangeNotetypeInfo>(ctx, 'NotetypesService', 'GetChangeNotetypeInfo', request, ChangeNotetypeInfo())
  ;
  $async.Future<$2.OpChanges> changeNotetype($pb.ClientContext? ctx, ChangeNotetypeRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'NotetypesService', 'ChangeNotetype', request, $2.OpChanges())
  ;
  $async.Future<$0.StringList> getFieldNames($pb.ClientContext? ctx, NotetypeId request) =>
    _client.invoke<$0.StringList>(ctx, 'NotetypesService', 'GetFieldNames', request, $0.StringList())
  ;
  $async.Future<$2.OpChanges> restoreNotetypeToStock($pb.ClientContext? ctx, RestoreNotetypeToStockRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'NotetypesService', 'RestoreNotetypeToStock', request, $2.OpChanges())
  ;
  $async.Future<GetClozeFieldOrdsResponse> getClozeFieldOrds($pb.ClientContext? ctx, NotetypeId request) =>
    _client.invoke<GetClozeFieldOrdsResponse>(ctx, 'NotetypesService', 'GetClozeFieldOrds', request, GetClozeFieldOrdsResponse())
  ;
}

class BackendNotetypesServiceApi {
  $pb.RpcClient _client;
  BackendNotetypesServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
