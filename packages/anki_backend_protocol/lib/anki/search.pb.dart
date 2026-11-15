//
//  Generated code. Do not modify.
//  source: anki/search.proto
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
import 'search.pbenum.dart';

export 'search.pbenum.dart';

class SearchNode_Dupe extends $pb.GeneratedMessage {
  factory SearchNode_Dupe({
    $fixnum.Int64? notetypeId,
    $core.String? firstField,
  }) {
    final $result = create();
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    if (firstField != null) {
      $result.firstField = firstField;
    }
    return $result;
  }
  SearchNode_Dupe._() : super();
  factory SearchNode_Dupe.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchNode_Dupe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchNode.Dupe', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'notetypeId')
    ..aOS(2, _omitFieldNames ? '' : 'firstField')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchNode_Dupe clone() => SearchNode_Dupe()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchNode_Dupe copyWith(void Function(SearchNode_Dupe) updates) => super.copyWith((message) => updates(message as SearchNode_Dupe)) as SearchNode_Dupe;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchNode_Dupe create() => SearchNode_Dupe._();
  SearchNode_Dupe createEmptyInstance() => create();
  static $pb.PbList<SearchNode_Dupe> createRepeated() => $pb.PbList<SearchNode_Dupe>();
  @$core.pragma('dart2js:noInline')
  static SearchNode_Dupe getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchNode_Dupe>(create);
  static SearchNode_Dupe? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get notetypeId => $_getI64(0);
  @$pb.TagNumber(1)
  set notetypeId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNotetypeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNotetypeId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get firstField => $_getSZ(1);
  @$pb.TagNumber(2)
  set firstField($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFirstField() => $_has(1);
  @$pb.TagNumber(2)
  void clearFirstField() => clearField(2);
}

class SearchNode_Rated extends $pb.GeneratedMessage {
  factory SearchNode_Rated({
    $core.int? days,
    SearchNode_Rating? rating,
  }) {
    final $result = create();
    if (days != null) {
      $result.days = days;
    }
    if (rating != null) {
      $result.rating = rating;
    }
    return $result;
  }
  SearchNode_Rated._() : super();
  factory SearchNode_Rated.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchNode_Rated.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchNode.Rated', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'days', $pb.PbFieldType.OU3)
    ..e<SearchNode_Rating>(2, _omitFieldNames ? '' : 'rating', $pb.PbFieldType.OE, defaultOrMaker: SearchNode_Rating.RATING_ANY, valueOf: SearchNode_Rating.valueOf, enumValues: SearchNode_Rating.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchNode_Rated clone() => SearchNode_Rated()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchNode_Rated copyWith(void Function(SearchNode_Rated) updates) => super.copyWith((message) => updates(message as SearchNode_Rated)) as SearchNode_Rated;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchNode_Rated create() => SearchNode_Rated._();
  SearchNode_Rated createEmptyInstance() => create();
  static $pb.PbList<SearchNode_Rated> createRepeated() => $pb.PbList<SearchNode_Rated>();
  @$core.pragma('dart2js:noInline')
  static SearchNode_Rated getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchNode_Rated>(create);
  static SearchNode_Rated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => clearField(1);

  @$pb.TagNumber(2)
  SearchNode_Rating get rating => $_getN(1);
  @$pb.TagNumber(2)
  set rating(SearchNode_Rating v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRating() => $_has(1);
  @$pb.TagNumber(2)
  void clearRating() => clearField(2);
}

class SearchNode_IdList extends $pb.GeneratedMessage {
  factory SearchNode_IdList({
    $core.Iterable<$fixnum.Int64>? ids,
  }) {
    final $result = create();
    if (ids != null) {
      $result.ids.addAll(ids);
    }
    return $result;
  }
  SearchNode_IdList._() : super();
  factory SearchNode_IdList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchNode_IdList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchNode.IdList', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'ids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchNode_IdList clone() => SearchNode_IdList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchNode_IdList copyWith(void Function(SearchNode_IdList) updates) => super.copyWith((message) => updates(message as SearchNode_IdList)) as SearchNode_IdList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchNode_IdList create() => SearchNode_IdList._();
  SearchNode_IdList createEmptyInstance() => create();
  static $pb.PbList<SearchNode_IdList> createRepeated() => $pb.PbList<SearchNode_IdList>();
  @$core.pragma('dart2js:noInline')
  static SearchNode_IdList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchNode_IdList>(create);
  static SearchNode_IdList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get ids => $_getList(0);
}

class SearchNode_Group extends $pb.GeneratedMessage {
  factory SearchNode_Group({
    $core.Iterable<SearchNode>? nodes,
    SearchNode_Group_Joiner? joiner,
  }) {
    final $result = create();
    if (nodes != null) {
      $result.nodes.addAll(nodes);
    }
    if (joiner != null) {
      $result.joiner = joiner;
    }
    return $result;
  }
  SearchNode_Group._() : super();
  factory SearchNode_Group.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchNode_Group.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchNode.Group', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..pc<SearchNode>(1, _omitFieldNames ? '' : 'nodes', $pb.PbFieldType.PM, subBuilder: SearchNode.create)
    ..e<SearchNode_Group_Joiner>(2, _omitFieldNames ? '' : 'joiner', $pb.PbFieldType.OE, defaultOrMaker: SearchNode_Group_Joiner.AND, valueOf: SearchNode_Group_Joiner.valueOf, enumValues: SearchNode_Group_Joiner.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchNode_Group clone() => SearchNode_Group()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchNode_Group copyWith(void Function(SearchNode_Group) updates) => super.copyWith((message) => updates(message as SearchNode_Group)) as SearchNode_Group;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchNode_Group create() => SearchNode_Group._();
  SearchNode_Group createEmptyInstance() => create();
  static $pb.PbList<SearchNode_Group> createRepeated() => $pb.PbList<SearchNode_Group>();
  @$core.pragma('dart2js:noInline')
  static SearchNode_Group getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchNode_Group>(create);
  static SearchNode_Group? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SearchNode> get nodes => $_getList(0);

  @$pb.TagNumber(2)
  SearchNode_Group_Joiner get joiner => $_getN(1);
  @$pb.TagNumber(2)
  set joiner(SearchNode_Group_Joiner v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasJoiner() => $_has(1);
  @$pb.TagNumber(2)
  void clearJoiner() => clearField(2);
}

class SearchNode_Field extends $pb.GeneratedMessage {
  factory SearchNode_Field({
    $core.String? fieldName,
    $core.String? text,
    SearchNode_FieldSearchMode? mode,
  }) {
    final $result = create();
    if (fieldName != null) {
      $result.fieldName = fieldName;
    }
    if (text != null) {
      $result.text = text;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    return $result;
  }
  SearchNode_Field._() : super();
  factory SearchNode_Field.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchNode_Field.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchNode.Field', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldName')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..e<SearchNode_FieldSearchMode>(3, _omitFieldNames ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_NORMAL, valueOf: SearchNode_FieldSearchMode.valueOf, enumValues: SearchNode_FieldSearchMode.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchNode_Field clone() => SearchNode_Field()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchNode_Field copyWith(void Function(SearchNode_Field) updates) => super.copyWith((message) => updates(message as SearchNode_Field)) as SearchNode_Field;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchNode_Field create() => SearchNode_Field._();
  SearchNode_Field createEmptyInstance() => create();
  static $pb.PbList<SearchNode_Field> createRepeated() => $pb.PbList<SearchNode_Field>();
  @$core.pragma('dart2js:noInline')
  static SearchNode_Field getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchNode_Field>(create);
  static SearchNode_Field? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldName => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  SearchNode_FieldSearchMode get mode => $_getN(2);
  @$pb.TagNumber(3)
  set mode(SearchNode_FieldSearchMode v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => clearField(3);
}

enum SearchNode_Filter {
  group,
  negated,
  parsableText,
  template,
  nid,
  dupe,
  fieldName,
  rated,
  addedInDays,
  dueInDays,
  flag,
  cardState,
  nids,
  editedInDays,
  deck,
  dueOnDay,
  tag,
  note,
  introducedInDays,
  field_20,
  literalText,
  notSet
}

class SearchNode extends $pb.GeneratedMessage {
  factory SearchNode({
    SearchNode_Group? group,
    SearchNode? negated,
    $core.String? parsableText,
    $core.int? template,
    $fixnum.Int64? nid,
    SearchNode_Dupe? dupe,
    $core.String? fieldName,
    SearchNode_Rated? rated,
    $core.int? addedInDays,
    $core.int? dueInDays,
    SearchNode_Flag? flag,
    SearchNode_CardState? cardState,
    SearchNode_IdList? nids,
    $core.int? editedInDays,
    $core.String? deck,
    $core.int? dueOnDay,
    $core.String? tag,
    $core.String? note,
    $core.int? introducedInDays,
    SearchNode_Field? field_20,
    $core.String? literalText,
  }) {
    final $result = create();
    if (group != null) {
      $result.group = group;
    }
    if (negated != null) {
      $result.negated = negated;
    }
    if (parsableText != null) {
      $result.parsableText = parsableText;
    }
    if (template != null) {
      $result.template = template;
    }
    if (nid != null) {
      $result.nid = nid;
    }
    if (dupe != null) {
      $result.dupe = dupe;
    }
    if (fieldName != null) {
      $result.fieldName = fieldName;
    }
    if (rated != null) {
      $result.rated = rated;
    }
    if (addedInDays != null) {
      $result.addedInDays = addedInDays;
    }
    if (dueInDays != null) {
      $result.dueInDays = dueInDays;
    }
    if (flag != null) {
      $result.flag = flag;
    }
    if (cardState != null) {
      $result.cardState = cardState;
    }
    if (nids != null) {
      $result.nids = nids;
    }
    if (editedInDays != null) {
      $result.editedInDays = editedInDays;
    }
    if (deck != null) {
      $result.deck = deck;
    }
    if (dueOnDay != null) {
      $result.dueOnDay = dueOnDay;
    }
    if (tag != null) {
      $result.tag = tag;
    }
    if (note != null) {
      $result.note = note;
    }
    if (introducedInDays != null) {
      $result.introducedInDays = introducedInDays;
    }
    if (field_20 != null) {
      $result.field_20 = field_20;
    }
    if (literalText != null) {
      $result.literalText = literalText;
    }
    return $result;
  }
  SearchNode._() : super();
  factory SearchNode.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchNode.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SearchNode_Filter> _SearchNode_FilterByTag = {
    1 : SearchNode_Filter.group,
    2 : SearchNode_Filter.negated,
    3 : SearchNode_Filter.parsableText,
    4 : SearchNode_Filter.template,
    5 : SearchNode_Filter.nid,
    6 : SearchNode_Filter.dupe,
    7 : SearchNode_Filter.fieldName,
    8 : SearchNode_Filter.rated,
    9 : SearchNode_Filter.addedInDays,
    10 : SearchNode_Filter.dueInDays,
    11 : SearchNode_Filter.flag,
    12 : SearchNode_Filter.cardState,
    13 : SearchNode_Filter.nids,
    14 : SearchNode_Filter.editedInDays,
    15 : SearchNode_Filter.deck,
    16 : SearchNode_Filter.dueOnDay,
    17 : SearchNode_Filter.tag,
    18 : SearchNode_Filter.note,
    19 : SearchNode_Filter.introducedInDays,
    20 : SearchNode_Filter.field_20,
    21 : SearchNode_Filter.literalText,
    0 : SearchNode_Filter.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchNode', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21])
    ..aOM<SearchNode_Group>(1, _omitFieldNames ? '' : 'group', subBuilder: SearchNode_Group.create)
    ..aOM<SearchNode>(2, _omitFieldNames ? '' : 'negated', subBuilder: SearchNode.create)
    ..aOS(3, _omitFieldNames ? '' : 'parsableText')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'template', $pb.PbFieldType.OU3)
    ..aInt64(5, _omitFieldNames ? '' : 'nid')
    ..aOM<SearchNode_Dupe>(6, _omitFieldNames ? '' : 'dupe', subBuilder: SearchNode_Dupe.create)
    ..aOS(7, _omitFieldNames ? '' : 'fieldName')
    ..aOM<SearchNode_Rated>(8, _omitFieldNames ? '' : 'rated', subBuilder: SearchNode_Rated.create)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'addedInDays', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'dueInDays', $pb.PbFieldType.O3)
    ..e<SearchNode_Flag>(11, _omitFieldNames ? '' : 'flag', $pb.PbFieldType.OE, defaultOrMaker: SearchNode_Flag.FLAG_NONE, valueOf: SearchNode_Flag.valueOf, enumValues: SearchNode_Flag.values)
    ..e<SearchNode_CardState>(12, _omitFieldNames ? '' : 'cardState', $pb.PbFieldType.OE, defaultOrMaker: SearchNode_CardState.CARD_STATE_NEW, valueOf: SearchNode_CardState.valueOf, enumValues: SearchNode_CardState.values)
    ..aOM<SearchNode_IdList>(13, _omitFieldNames ? '' : 'nids', subBuilder: SearchNode_IdList.create)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'editedInDays', $pb.PbFieldType.OU3)
    ..aOS(15, _omitFieldNames ? '' : 'deck')
    ..a<$core.int>(16, _omitFieldNames ? '' : 'dueOnDay', $pb.PbFieldType.O3)
    ..aOS(17, _omitFieldNames ? '' : 'tag')
    ..aOS(18, _omitFieldNames ? '' : 'note')
    ..a<$core.int>(19, _omitFieldNames ? '' : 'introducedInDays', $pb.PbFieldType.OU3)
    ..aOM<SearchNode_Field>(20, _omitFieldNames ? '' : 'field', subBuilder: SearchNode_Field.create)
    ..aOS(21, _omitFieldNames ? '' : 'literalText')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchNode clone() => SearchNode()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchNode copyWith(void Function(SearchNode) updates) => super.copyWith((message) => updates(message as SearchNode)) as SearchNode;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchNode create() => SearchNode._();
  SearchNode createEmptyInstance() => create();
  static $pb.PbList<SearchNode> createRepeated() => $pb.PbList<SearchNode>();
  @$core.pragma('dart2js:noInline')
  static SearchNode getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchNode>(create);
  static SearchNode? _defaultInstance;

  SearchNode_Filter whichFilter() => _SearchNode_FilterByTag[$_whichOneof(0)]!;
  void clearFilter() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SearchNode_Group get group => $_getN(0);
  @$pb.TagNumber(1)
  set group(SearchNode_Group v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroup() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroup() => clearField(1);
  @$pb.TagNumber(1)
  SearchNode_Group ensureGroup() => $_ensure(0);

  @$pb.TagNumber(2)
  SearchNode get negated => $_getN(1);
  @$pb.TagNumber(2)
  set negated(SearchNode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasNegated() => $_has(1);
  @$pb.TagNumber(2)
  void clearNegated() => clearField(2);
  @$pb.TagNumber(2)
  SearchNode ensureNegated() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get parsableText => $_getSZ(2);
  @$pb.TagNumber(3)
  set parsableText($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasParsableText() => $_has(2);
  @$pb.TagNumber(3)
  void clearParsableText() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get template => $_getIZ(3);
  @$pb.TagNumber(4)
  set template($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTemplate() => $_has(3);
  @$pb.TagNumber(4)
  void clearTemplate() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get nid => $_getI64(4);
  @$pb.TagNumber(5)
  set nid($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasNid() => $_has(4);
  @$pb.TagNumber(5)
  void clearNid() => clearField(5);

  @$pb.TagNumber(6)
  SearchNode_Dupe get dupe => $_getN(5);
  @$pb.TagNumber(6)
  set dupe(SearchNode_Dupe v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasDupe() => $_has(5);
  @$pb.TagNumber(6)
  void clearDupe() => clearField(6);
  @$pb.TagNumber(6)
  SearchNode_Dupe ensureDupe() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get fieldName => $_getSZ(6);
  @$pb.TagNumber(7)
  set fieldName($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasFieldName() => $_has(6);
  @$pb.TagNumber(7)
  void clearFieldName() => clearField(7);

  @$pb.TagNumber(8)
  SearchNode_Rated get rated => $_getN(7);
  @$pb.TagNumber(8)
  set rated(SearchNode_Rated v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasRated() => $_has(7);
  @$pb.TagNumber(8)
  void clearRated() => clearField(8);
  @$pb.TagNumber(8)
  SearchNode_Rated ensureRated() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.int get addedInDays => $_getIZ(8);
  @$pb.TagNumber(9)
  set addedInDays($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasAddedInDays() => $_has(8);
  @$pb.TagNumber(9)
  void clearAddedInDays() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get dueInDays => $_getIZ(9);
  @$pb.TagNumber(10)
  set dueInDays($core.int v) { $_setSignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasDueInDays() => $_has(9);
  @$pb.TagNumber(10)
  void clearDueInDays() => clearField(10);

  @$pb.TagNumber(11)
  SearchNode_Flag get flag => $_getN(10);
  @$pb.TagNumber(11)
  set flag(SearchNode_Flag v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasFlag() => $_has(10);
  @$pb.TagNumber(11)
  void clearFlag() => clearField(11);

  @$pb.TagNumber(12)
  SearchNode_CardState get cardState => $_getN(11);
  @$pb.TagNumber(12)
  set cardState(SearchNode_CardState v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasCardState() => $_has(11);
  @$pb.TagNumber(12)
  void clearCardState() => clearField(12);

  @$pb.TagNumber(13)
  SearchNode_IdList get nids => $_getN(12);
  @$pb.TagNumber(13)
  set nids(SearchNode_IdList v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasNids() => $_has(12);
  @$pb.TagNumber(13)
  void clearNids() => clearField(13);
  @$pb.TagNumber(13)
  SearchNode_IdList ensureNids() => $_ensure(12);

  @$pb.TagNumber(14)
  $core.int get editedInDays => $_getIZ(13);
  @$pb.TagNumber(14)
  set editedInDays($core.int v) { $_setUnsignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasEditedInDays() => $_has(13);
  @$pb.TagNumber(14)
  void clearEditedInDays() => clearField(14);

  @$pb.TagNumber(15)
  $core.String get deck => $_getSZ(14);
  @$pb.TagNumber(15)
  set deck($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasDeck() => $_has(14);
  @$pb.TagNumber(15)
  void clearDeck() => clearField(15);

  @$pb.TagNumber(16)
  $core.int get dueOnDay => $_getIZ(15);
  @$pb.TagNumber(16)
  set dueOnDay($core.int v) { $_setSignedInt32(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasDueOnDay() => $_has(15);
  @$pb.TagNumber(16)
  void clearDueOnDay() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get tag => $_getSZ(16);
  @$pb.TagNumber(17)
  set tag($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasTag() => $_has(16);
  @$pb.TagNumber(17)
  void clearTag() => clearField(17);

  @$pb.TagNumber(18)
  $core.String get note => $_getSZ(17);
  @$pb.TagNumber(18)
  set note($core.String v) { $_setString(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasNote() => $_has(17);
  @$pb.TagNumber(18)
  void clearNote() => clearField(18);

  @$pb.TagNumber(19)
  $core.int get introducedInDays => $_getIZ(18);
  @$pb.TagNumber(19)
  set introducedInDays($core.int v) { $_setUnsignedInt32(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasIntroducedInDays() => $_has(18);
  @$pb.TagNumber(19)
  void clearIntroducedInDays() => clearField(19);

  @$pb.TagNumber(20)
  SearchNode_Field get field_20 => $_getN(19);
  @$pb.TagNumber(20)
  set field_20(SearchNode_Field v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasField_20() => $_has(19);
  @$pb.TagNumber(20)
  void clearField_20() => clearField(20);
  @$pb.TagNumber(20)
  SearchNode_Field ensureField_20() => $_ensure(19);

  @$pb.TagNumber(21)
  $core.String get literalText => $_getSZ(20);
  @$pb.TagNumber(21)
  set literalText($core.String v) { $_setString(20, v); }
  @$pb.TagNumber(21)
  $core.bool hasLiteralText() => $_has(20);
  @$pb.TagNumber(21)
  void clearLiteralText() => clearField(21);
}

class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? search,
    SortOrder? order,
  }) {
    final $result = create();
    if (search != null) {
      $result.search = search;
    }
    if (order != null) {
      $result.order = order;
    }
    return $result;
  }
  SearchRequest._() : super();
  factory SearchRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'search')
    ..aOM<SortOrder>(2, _omitFieldNames ? '' : 'order', subBuilder: SortOrder.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchRequest clone() => SearchRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchRequest copyWith(void Function(SearchRequest) updates) => super.copyWith((message) => updates(message as SearchRequest)) as SearchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  SearchRequest createEmptyInstance() => create();
  static $pb.PbList<SearchRequest> createRepeated() => $pb.PbList<SearchRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get search => $_getSZ(0);
  @$pb.TagNumber(1)
  set search($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSearch() => $_has(0);
  @$pb.TagNumber(1)
  void clearSearch() => clearField(1);

  @$pb.TagNumber(2)
  SortOrder get order => $_getN(1);
  @$pb.TagNumber(2)
  set order(SortOrder v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOrder() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrder() => clearField(2);
  @$pb.TagNumber(2)
  SortOrder ensureOrder() => $_ensure(1);
}

class SearchResponse extends $pb.GeneratedMessage {
  factory SearchResponse({
    $core.Iterable<$fixnum.Int64>? ids,
  }) {
    final $result = create();
    if (ids != null) {
      $result.ids.addAll(ids);
    }
    return $result;
  }
  SearchResponse._() : super();
  factory SearchResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SearchResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'ids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SearchResponse clone() => SearchResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SearchResponse copyWith(void Function(SearchResponse) updates) => super.copyWith((message) => updates(message as SearchResponse)) as SearchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResponse create() => SearchResponse._();
  SearchResponse createEmptyInstance() => create();
  static $pb.PbList<SearchResponse> createRepeated() => $pb.PbList<SearchResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchResponse>(create);
  static SearchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get ids => $_getList(0);
}

class SortOrder_Builtin extends $pb.GeneratedMessage {
  factory SortOrder_Builtin({
    $core.String? column,
    $core.bool? reverse,
  }) {
    final $result = create();
    if (column != null) {
      $result.column = column;
    }
    if (reverse != null) {
      $result.reverse = reverse;
    }
    return $result;
  }
  SortOrder_Builtin._() : super();
  factory SortOrder_Builtin.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SortOrder_Builtin.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SortOrder.Builtin', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'column')
    ..aOB(2, _omitFieldNames ? '' : 'reverse')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SortOrder_Builtin clone() => SortOrder_Builtin()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SortOrder_Builtin copyWith(void Function(SortOrder_Builtin) updates) => super.copyWith((message) => updates(message as SortOrder_Builtin)) as SortOrder_Builtin;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SortOrder_Builtin create() => SortOrder_Builtin._();
  SortOrder_Builtin createEmptyInstance() => create();
  static $pb.PbList<SortOrder_Builtin> createRepeated() => $pb.PbList<SortOrder_Builtin>();
  @$core.pragma('dart2js:noInline')
  static SortOrder_Builtin getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SortOrder_Builtin>(create);
  static SortOrder_Builtin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get column => $_getSZ(0);
  @$pb.TagNumber(1)
  set column($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get reverse => $_getBF(1);
  @$pb.TagNumber(2)
  set reverse($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReverse() => $_has(1);
  @$pb.TagNumber(2)
  void clearReverse() => clearField(2);
}

enum SortOrder_Value {
  none,
  custom,
  builtin,
  notSet
}

class SortOrder extends $pb.GeneratedMessage {
  factory SortOrder({
    $0.Empty? none,
    $core.String? custom,
    SortOrder_Builtin? builtin,
  }) {
    final $result = create();
    if (none != null) {
      $result.none = none;
    }
    if (custom != null) {
      $result.custom = custom;
    }
    if (builtin != null) {
      $result.builtin = builtin;
    }
    return $result;
  }
  SortOrder._() : super();
  factory SortOrder.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SortOrder.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SortOrder_Value> _SortOrder_ValueByTag = {
    1 : SortOrder_Value.none,
    2 : SortOrder_Value.custom,
    3 : SortOrder_Value.builtin,
    0 : SortOrder_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SortOrder', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<$0.Empty>(1, _omitFieldNames ? '' : 'none', subBuilder: $0.Empty.create)
    ..aOS(2, _omitFieldNames ? '' : 'custom')
    ..aOM<SortOrder_Builtin>(3, _omitFieldNames ? '' : 'builtin', subBuilder: SortOrder_Builtin.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SortOrder clone() => SortOrder()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SortOrder copyWith(void Function(SortOrder) updates) => super.copyWith((message) => updates(message as SortOrder)) as SortOrder;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SortOrder create() => SortOrder._();
  SortOrder createEmptyInstance() => create();
  static $pb.PbList<SortOrder> createRepeated() => $pb.PbList<SortOrder>();
  @$core.pragma('dart2js:noInline')
  static SortOrder getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SortOrder>(create);
  static SortOrder? _defaultInstance;

  SortOrder_Value whichValue() => _SortOrder_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Empty get none => $_getN(0);
  @$pb.TagNumber(1)
  set none($0.Empty v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNone() => $_has(0);
  @$pb.TagNumber(1)
  void clearNone() => clearField(1);
  @$pb.TagNumber(1)
  $0.Empty ensureNone() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get custom => $_getSZ(1);
  @$pb.TagNumber(2)
  set custom($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCustom() => $_has(1);
  @$pb.TagNumber(2)
  void clearCustom() => clearField(2);

  @$pb.TagNumber(3)
  SortOrder_Builtin get builtin => $_getN(2);
  @$pb.TagNumber(3)
  set builtin(SortOrder_Builtin v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasBuiltin() => $_has(2);
  @$pb.TagNumber(3)
  void clearBuiltin() => clearField(3);
  @$pb.TagNumber(3)
  SortOrder_Builtin ensureBuiltin() => $_ensure(2);
}

class JoinSearchNodesRequest extends $pb.GeneratedMessage {
  factory JoinSearchNodesRequest({
    SearchNode_Group_Joiner? joiner,
    SearchNode? existingNode,
    SearchNode? additionalNode,
  }) {
    final $result = create();
    if (joiner != null) {
      $result.joiner = joiner;
    }
    if (existingNode != null) {
      $result.existingNode = existingNode;
    }
    if (additionalNode != null) {
      $result.additionalNode = additionalNode;
    }
    return $result;
  }
  JoinSearchNodesRequest._() : super();
  factory JoinSearchNodesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory JoinSearchNodesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'JoinSearchNodesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..e<SearchNode_Group_Joiner>(1, _omitFieldNames ? '' : 'joiner', $pb.PbFieldType.OE, defaultOrMaker: SearchNode_Group_Joiner.AND, valueOf: SearchNode_Group_Joiner.valueOf, enumValues: SearchNode_Group_Joiner.values)
    ..aOM<SearchNode>(2, _omitFieldNames ? '' : 'existingNode', subBuilder: SearchNode.create)
    ..aOM<SearchNode>(3, _omitFieldNames ? '' : 'additionalNode', subBuilder: SearchNode.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  JoinSearchNodesRequest clone() => JoinSearchNodesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  JoinSearchNodesRequest copyWith(void Function(JoinSearchNodesRequest) updates) => super.copyWith((message) => updates(message as JoinSearchNodesRequest)) as JoinSearchNodesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinSearchNodesRequest create() => JoinSearchNodesRequest._();
  JoinSearchNodesRequest createEmptyInstance() => create();
  static $pb.PbList<JoinSearchNodesRequest> createRepeated() => $pb.PbList<JoinSearchNodesRequest>();
  @$core.pragma('dart2js:noInline')
  static JoinSearchNodesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinSearchNodesRequest>(create);
  static JoinSearchNodesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SearchNode_Group_Joiner get joiner => $_getN(0);
  @$pb.TagNumber(1)
  set joiner(SearchNode_Group_Joiner v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasJoiner() => $_has(0);
  @$pb.TagNumber(1)
  void clearJoiner() => clearField(1);

  @$pb.TagNumber(2)
  SearchNode get existingNode => $_getN(1);
  @$pb.TagNumber(2)
  set existingNode(SearchNode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExistingNode() => $_has(1);
  @$pb.TagNumber(2)
  void clearExistingNode() => clearField(2);
  @$pb.TagNumber(2)
  SearchNode ensureExistingNode() => $_ensure(1);

  @$pb.TagNumber(3)
  SearchNode get additionalNode => $_getN(2);
  @$pb.TagNumber(3)
  set additionalNode(SearchNode v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAdditionalNode() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdditionalNode() => clearField(3);
  @$pb.TagNumber(3)
  SearchNode ensureAdditionalNode() => $_ensure(2);
}

class ReplaceSearchNodeRequest extends $pb.GeneratedMessage {
  factory ReplaceSearchNodeRequest({
    SearchNode? existingNode,
    SearchNode? replacementNode,
  }) {
    final $result = create();
    if (existingNode != null) {
      $result.existingNode = existingNode;
    }
    if (replacementNode != null) {
      $result.replacementNode = replacementNode;
    }
    return $result;
  }
  ReplaceSearchNodeRequest._() : super();
  factory ReplaceSearchNodeRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReplaceSearchNodeRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReplaceSearchNodeRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aOM<SearchNode>(1, _omitFieldNames ? '' : 'existingNode', subBuilder: SearchNode.create)
    ..aOM<SearchNode>(2, _omitFieldNames ? '' : 'replacementNode', subBuilder: SearchNode.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReplaceSearchNodeRequest clone() => ReplaceSearchNodeRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReplaceSearchNodeRequest copyWith(void Function(ReplaceSearchNodeRequest) updates) => super.copyWith((message) => updates(message as ReplaceSearchNodeRequest)) as ReplaceSearchNodeRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplaceSearchNodeRequest create() => ReplaceSearchNodeRequest._();
  ReplaceSearchNodeRequest createEmptyInstance() => create();
  static $pb.PbList<ReplaceSearchNodeRequest> createRepeated() => $pb.PbList<ReplaceSearchNodeRequest>();
  @$core.pragma('dart2js:noInline')
  static ReplaceSearchNodeRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReplaceSearchNodeRequest>(create);
  static ReplaceSearchNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SearchNode get existingNode => $_getN(0);
  @$pb.TagNumber(1)
  set existingNode(SearchNode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasExistingNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearExistingNode() => clearField(1);
  @$pb.TagNumber(1)
  SearchNode ensureExistingNode() => $_ensure(0);

  @$pb.TagNumber(2)
  SearchNode get replacementNode => $_getN(1);
  @$pb.TagNumber(2)
  set replacementNode(SearchNode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasReplacementNode() => $_has(1);
  @$pb.TagNumber(2)
  void clearReplacementNode() => clearField(2);
  @$pb.TagNumber(2)
  SearchNode ensureReplacementNode() => $_ensure(1);
}

class FindAndReplaceRequest extends $pb.GeneratedMessage {
  factory FindAndReplaceRequest({
    $core.Iterable<$fixnum.Int64>? nids,
    $core.String? search,
    $core.String? replacement,
    $core.bool? regex,
    $core.bool? matchCase,
    $core.String? fieldName,
  }) {
    final $result = create();
    if (nids != null) {
      $result.nids.addAll(nids);
    }
    if (search != null) {
      $result.search = search;
    }
    if (replacement != null) {
      $result.replacement = replacement;
    }
    if (regex != null) {
      $result.regex = regex;
    }
    if (matchCase != null) {
      $result.matchCase = matchCase;
    }
    if (fieldName != null) {
      $result.fieldName = fieldName;
    }
    return $result;
  }
  FindAndReplaceRequest._() : super();
  factory FindAndReplaceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FindAndReplaceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FindAndReplaceRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'nids', $pb.PbFieldType.K6)
    ..aOS(2, _omitFieldNames ? '' : 'search')
    ..aOS(3, _omitFieldNames ? '' : 'replacement')
    ..aOB(4, _omitFieldNames ? '' : 'regex')
    ..aOB(5, _omitFieldNames ? '' : 'matchCase')
    ..aOS(6, _omitFieldNames ? '' : 'fieldName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FindAndReplaceRequest clone() => FindAndReplaceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FindAndReplaceRequest copyWith(void Function(FindAndReplaceRequest) updates) => super.copyWith((message) => updates(message as FindAndReplaceRequest)) as FindAndReplaceRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FindAndReplaceRequest create() => FindAndReplaceRequest._();
  FindAndReplaceRequest createEmptyInstance() => create();
  static $pb.PbList<FindAndReplaceRequest> createRepeated() => $pb.PbList<FindAndReplaceRequest>();
  @$core.pragma('dart2js:noInline')
  static FindAndReplaceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FindAndReplaceRequest>(create);
  static FindAndReplaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get nids => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get search => $_getSZ(1);
  @$pb.TagNumber(2)
  set search($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSearch() => $_has(1);
  @$pb.TagNumber(2)
  void clearSearch() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get replacement => $_getSZ(2);
  @$pb.TagNumber(3)
  set replacement($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReplacement() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplacement() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get regex => $_getBF(3);
  @$pb.TagNumber(4)
  set regex($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRegex() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegex() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get matchCase => $_getBF(4);
  @$pb.TagNumber(5)
  set matchCase($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMatchCase() => $_has(4);
  @$pb.TagNumber(5)
  void clearMatchCase() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get fieldName => $_getSZ(5);
  @$pb.TagNumber(6)
  set fieldName($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasFieldName() => $_has(5);
  @$pb.TagNumber(6)
  void clearFieldName() => clearField(6);
}

class BrowserColumns_Column extends $pb.GeneratedMessage {
  factory BrowserColumns_Column({
    $core.String? key,
    $core.String? cardsModeLabel,
    $core.String? notesModeLabel,
    BrowserColumns_Sorting? sortingCards,
    $core.bool? usesCellFont,
    BrowserColumns_Alignment? alignment,
    $core.String? cardsModeTooltip,
    $core.String? notesModeTooltip,
    BrowserColumns_Sorting? sortingNotes,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (cardsModeLabel != null) {
      $result.cardsModeLabel = cardsModeLabel;
    }
    if (notesModeLabel != null) {
      $result.notesModeLabel = notesModeLabel;
    }
    if (sortingCards != null) {
      $result.sortingCards = sortingCards;
    }
    if (usesCellFont != null) {
      $result.usesCellFont = usesCellFont;
    }
    if (alignment != null) {
      $result.alignment = alignment;
    }
    if (cardsModeTooltip != null) {
      $result.cardsModeTooltip = cardsModeTooltip;
    }
    if (notesModeTooltip != null) {
      $result.notesModeTooltip = notesModeTooltip;
    }
    if (sortingNotes != null) {
      $result.sortingNotes = sortingNotes;
    }
    return $result;
  }
  BrowserColumns_Column._() : super();
  factory BrowserColumns_Column.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BrowserColumns_Column.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BrowserColumns.Column', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'cardsModeLabel')
    ..aOS(3, _omitFieldNames ? '' : 'notesModeLabel')
    ..e<BrowserColumns_Sorting>(4, _omitFieldNames ? '' : 'sortingCards', $pb.PbFieldType.OE, defaultOrMaker: BrowserColumns_Sorting.SORTING_NONE, valueOf: BrowserColumns_Sorting.valueOf, enumValues: BrowserColumns_Sorting.values)
    ..aOB(5, _omitFieldNames ? '' : 'usesCellFont')
    ..e<BrowserColumns_Alignment>(6, _omitFieldNames ? '' : 'alignment', $pb.PbFieldType.OE, defaultOrMaker: BrowserColumns_Alignment.ALIGNMENT_START, valueOf: BrowserColumns_Alignment.valueOf, enumValues: BrowserColumns_Alignment.values)
    ..aOS(7, _omitFieldNames ? '' : 'cardsModeTooltip')
    ..aOS(8, _omitFieldNames ? '' : 'notesModeTooltip')
    ..e<BrowserColumns_Sorting>(9, _omitFieldNames ? '' : 'sortingNotes', $pb.PbFieldType.OE, defaultOrMaker: BrowserColumns_Sorting.SORTING_NONE, valueOf: BrowserColumns_Sorting.valueOf, enumValues: BrowserColumns_Sorting.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BrowserColumns_Column clone() => BrowserColumns_Column()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BrowserColumns_Column copyWith(void Function(BrowserColumns_Column) updates) => super.copyWith((message) => updates(message as BrowserColumns_Column)) as BrowserColumns_Column;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BrowserColumns_Column create() => BrowserColumns_Column._();
  BrowserColumns_Column createEmptyInstance() => create();
  static $pb.PbList<BrowserColumns_Column> createRepeated() => $pb.PbList<BrowserColumns_Column>();
  @$core.pragma('dart2js:noInline')
  static BrowserColumns_Column getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BrowserColumns_Column>(create);
  static BrowserColumns_Column? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get cardsModeLabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set cardsModeLabel($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCardsModeLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearCardsModeLabel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get notesModeLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set notesModeLabel($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNotesModeLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotesModeLabel() => clearField(3);

  /// The default sort order
  @$pb.TagNumber(4)
  BrowserColumns_Sorting get sortingCards => $_getN(3);
  @$pb.TagNumber(4)
  set sortingCards(BrowserColumns_Sorting v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSortingCards() => $_has(3);
  @$pb.TagNumber(4)
  void clearSortingCards() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get usesCellFont => $_getBF(4);
  @$pb.TagNumber(5)
  set usesCellFont($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUsesCellFont() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsesCellFont() => clearField(5);

  @$pb.TagNumber(6)
  BrowserColumns_Alignment get alignment => $_getN(5);
  @$pb.TagNumber(6)
  set alignment(BrowserColumns_Alignment v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasAlignment() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlignment() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get cardsModeTooltip => $_getSZ(6);
  @$pb.TagNumber(7)
  set cardsModeTooltip($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasCardsModeTooltip() => $_has(6);
  @$pb.TagNumber(7)
  void clearCardsModeTooltip() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get notesModeTooltip => $_getSZ(7);
  @$pb.TagNumber(8)
  set notesModeTooltip($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasNotesModeTooltip() => $_has(7);
  @$pb.TagNumber(8)
  void clearNotesModeTooltip() => clearField(8);

  @$pb.TagNumber(9)
  BrowserColumns_Sorting get sortingNotes => $_getN(8);
  @$pb.TagNumber(9)
  set sortingNotes(BrowserColumns_Sorting v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasSortingNotes() => $_has(8);
  @$pb.TagNumber(9)
  void clearSortingNotes() => clearField(9);
}

class BrowserColumns extends $pb.GeneratedMessage {
  factory BrowserColumns({
    $core.Iterable<BrowserColumns_Column>? columns,
  }) {
    final $result = create();
    if (columns != null) {
      $result.columns.addAll(columns);
    }
    return $result;
  }
  BrowserColumns._() : super();
  factory BrowserColumns.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BrowserColumns.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BrowserColumns', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..pc<BrowserColumns_Column>(1, _omitFieldNames ? '' : 'columns', $pb.PbFieldType.PM, subBuilder: BrowserColumns_Column.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BrowserColumns clone() => BrowserColumns()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BrowserColumns copyWith(void Function(BrowserColumns) updates) => super.copyWith((message) => updates(message as BrowserColumns)) as BrowserColumns;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BrowserColumns create() => BrowserColumns._();
  BrowserColumns createEmptyInstance() => create();
  static $pb.PbList<BrowserColumns> createRepeated() => $pb.PbList<BrowserColumns>();
  @$core.pragma('dart2js:noInline')
  static BrowserColumns getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BrowserColumns>(create);
  static BrowserColumns? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BrowserColumns_Column> get columns => $_getList(0);
}

class BrowserRow_Cell extends $pb.GeneratedMessage {
  factory BrowserRow_Cell({
    $core.String? text,
    $core.bool? isRtl,
    BrowserRow_Cell_TextElideMode? elideMode,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (isRtl != null) {
      $result.isRtl = isRtl;
    }
    if (elideMode != null) {
      $result.elideMode = elideMode;
    }
    return $result;
  }
  BrowserRow_Cell._() : super();
  factory BrowserRow_Cell.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BrowserRow_Cell.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BrowserRow.Cell', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'isRtl')
    ..e<BrowserRow_Cell_TextElideMode>(3, _omitFieldNames ? '' : 'elideMode', $pb.PbFieldType.OE, defaultOrMaker: BrowserRow_Cell_TextElideMode.ElideLeft, valueOf: BrowserRow_Cell_TextElideMode.valueOf, enumValues: BrowserRow_Cell_TextElideMode.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BrowserRow_Cell clone() => BrowserRow_Cell()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BrowserRow_Cell copyWith(void Function(BrowserRow_Cell) updates) => super.copyWith((message) => updates(message as BrowserRow_Cell)) as BrowserRow_Cell;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BrowserRow_Cell create() => BrowserRow_Cell._();
  BrowserRow_Cell createEmptyInstance() => create();
  static $pb.PbList<BrowserRow_Cell> createRepeated() => $pb.PbList<BrowserRow_Cell>();
  @$core.pragma('dart2js:noInline')
  static BrowserRow_Cell getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BrowserRow_Cell>(create);
  static BrowserRow_Cell? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isRtl => $_getBF(1);
  @$pb.TagNumber(2)
  set isRtl($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIsRtl() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsRtl() => clearField(2);

  @$pb.TagNumber(3)
  BrowserRow_Cell_TextElideMode get elideMode => $_getN(2);
  @$pb.TagNumber(3)
  set elideMode(BrowserRow_Cell_TextElideMode v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasElideMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearElideMode() => clearField(3);
}

class BrowserRow extends $pb.GeneratedMessage {
  factory BrowserRow({
    $core.Iterable<BrowserRow_Cell>? cells,
    BrowserRow_Color? color,
    $core.String? fontName,
    $core.int? fontSize,
  }) {
    final $result = create();
    if (cells != null) {
      $result.cells.addAll(cells);
    }
    if (color != null) {
      $result.color = color;
    }
    if (fontName != null) {
      $result.fontName = fontName;
    }
    if (fontSize != null) {
      $result.fontSize = fontSize;
    }
    return $result;
  }
  BrowserRow._() : super();
  factory BrowserRow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BrowserRow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BrowserRow', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.search'), createEmptyInstance: create)
    ..pc<BrowserRow_Cell>(1, _omitFieldNames ? '' : 'cells', $pb.PbFieldType.PM, subBuilder: BrowserRow_Cell.create)
    ..e<BrowserRow_Color>(2, _omitFieldNames ? '' : 'color', $pb.PbFieldType.OE, defaultOrMaker: BrowserRow_Color.COLOR_DEFAULT, valueOf: BrowserRow_Color.valueOf, enumValues: BrowserRow_Color.values)
    ..aOS(3, _omitFieldNames ? '' : 'fontName')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'fontSize', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BrowserRow clone() => BrowserRow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BrowserRow copyWith(void Function(BrowserRow) updates) => super.copyWith((message) => updates(message as BrowserRow)) as BrowserRow;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BrowserRow create() => BrowserRow._();
  BrowserRow createEmptyInstance() => create();
  static $pb.PbList<BrowserRow> createRepeated() => $pb.PbList<BrowserRow>();
  @$core.pragma('dart2js:noInline')
  static BrowserRow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BrowserRow>(create);
  static BrowserRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BrowserRow_Cell> get cells => $_getList(0);

  @$pb.TagNumber(2)
  BrowserRow_Color get color => $_getN(1);
  @$pb.TagNumber(2)
  set color(BrowserRow_Color v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearColor() => clearField(2);

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
}

class SearchServiceApi {
  $pb.RpcClient _client;
  SearchServiceApi(this._client);

  $async.Future<$0.String> buildSearchString($pb.ClientContext? ctx, SearchNode request) =>
    _client.invoke<$0.String>(ctx, 'SearchService', 'BuildSearchString', request, $0.String())
  ;
  $async.Future<SearchResponse> searchCards($pb.ClientContext? ctx, SearchRequest request) =>
    _client.invoke<SearchResponse>(ctx, 'SearchService', 'SearchCards', request, SearchResponse())
  ;
  $async.Future<SearchResponse> searchNotes($pb.ClientContext? ctx, SearchRequest request) =>
    _client.invoke<SearchResponse>(ctx, 'SearchService', 'SearchNotes', request, SearchResponse())
  ;
  $async.Future<$0.String> joinSearchNodes($pb.ClientContext? ctx, JoinSearchNodesRequest request) =>
    _client.invoke<$0.String>(ctx, 'SearchService', 'JoinSearchNodes', request, $0.String())
  ;
  $async.Future<$0.String> replaceSearchNode($pb.ClientContext? ctx, ReplaceSearchNodeRequest request) =>
    _client.invoke<$0.String>(ctx, 'SearchService', 'ReplaceSearchNode', request, $0.String())
  ;
  $async.Future<$2.OpChangesWithCount> findAndReplace($pb.ClientContext? ctx, FindAndReplaceRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'SearchService', 'FindAndReplace', request, $2.OpChangesWithCount())
  ;
  $async.Future<BrowserColumns> allBrowserColumns($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<BrowserColumns>(ctx, 'SearchService', 'AllBrowserColumns', request, BrowserColumns())
  ;
  $async.Future<BrowserRow> browserRowForId($pb.ClientContext? ctx, $0.Int64 request) =>
    _client.invoke<BrowserRow>(ctx, 'SearchService', 'BrowserRowForId', request, BrowserRow())
  ;
  $async.Future<$0.Empty> setActiveBrowserColumns($pb.ClientContext? ctx, $0.StringList request) =>
    _client.invoke<$0.Empty>(ctx, 'SearchService', 'SetActiveBrowserColumns', request, $0.Empty())
  ;
}

class BackendSearchServiceApi {
  $pb.RpcClient _client;
  BackendSearchServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
