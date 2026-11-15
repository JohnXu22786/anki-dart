//
//  Generated code. Do not modify.
//  source: anki/notes.proto
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

import 'cards.pb.dart' as $3;
import 'collection.pb.dart' as $2;
import 'decks.pb.dart' as $4;
import 'notes.pbenum.dart';
import 'notetypes.pb.dart' as $12;

export 'notes.pbenum.dart';

class NoteId extends $pb.GeneratedMessage {
  factory NoteId({
    $fixnum.Int64? nid,
  }) {
    final $result = create();
    if (nid != null) {
      $result.nid = nid;
    }
    return $result;
  }
  NoteId._() : super();
  factory NoteId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NoteId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NoteId', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'nid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NoteId clone() => NoteId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NoteId copyWith(void Function(NoteId) updates) => super.copyWith((message) => updates(message as NoteId)) as NoteId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NoteId create() => NoteId._();
  NoteId createEmptyInstance() => create();
  static $pb.PbList<NoteId> createRepeated() => $pb.PbList<NoteId>();
  @$core.pragma('dart2js:noInline')
  static NoteId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NoteId>(create);
  static NoteId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get nid => $_getI64(0);
  @$pb.TagNumber(1)
  set nid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNid() => $_has(0);
  @$pb.TagNumber(1)
  void clearNid() => clearField(1);
}

class NoteIds extends $pb.GeneratedMessage {
  factory NoteIds({
    $core.Iterable<$fixnum.Int64>? noteIds,
  }) {
    final $result = create();
    if (noteIds != null) {
      $result.noteIds.addAll(noteIds);
    }
    return $result;
  }
  NoteIds._() : super();
  factory NoteIds.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NoteIds.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NoteIds', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'noteIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NoteIds clone() => NoteIds()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NoteIds copyWith(void Function(NoteIds) updates) => super.copyWith((message) => updates(message as NoteIds)) as NoteIds;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NoteIds create() => NoteIds._();
  NoteIds createEmptyInstance() => create();
  static $pb.PbList<NoteIds> createRepeated() => $pb.PbList<NoteIds>();
  @$core.pragma('dart2js:noInline')
  static NoteIds getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NoteIds>(create);
  static NoteIds? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get noteIds => $_getList(0);
}

class Note extends $pb.GeneratedMessage {
  factory Note({
    $fixnum.Int64? id,
    $core.String? guid,
    $fixnum.Int64? notetypeId,
    $core.int? mtimeSecs,
    $core.int? usn,
    $core.Iterable<$core.String>? tags,
    $core.Iterable<$core.String>? fields,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (guid != null) {
      $result.guid = guid;
    }
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    if (mtimeSecs != null) {
      $result.mtimeSecs = mtimeSecs;
    }
    if (usn != null) {
      $result.usn = usn;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (fields != null) {
      $result.fields.addAll(fields);
    }
    return $result;
  }
  Note._() : super();
  factory Note.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Note.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Note', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'guid')
    ..aInt64(3, _omitFieldNames ? '' : 'notetypeId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'mtimeSecs', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'usn', $pb.PbFieldType.O3)
    ..pPS(6, _omitFieldNames ? '' : 'tags')
    ..pPS(7, _omitFieldNames ? '' : 'fields')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Note clone() => Note()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Note copyWith(void Function(Note) updates) => super.copyWith((message) => updates(message as Note)) as Note;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Note create() => Note._();
  Note createEmptyInstance() => create();
  static $pb.PbList<Note> createRepeated() => $pb.PbList<Note>();
  @$core.pragma('dart2js:noInline')
  static Note getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Note>(create);
  static Note? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get guid => $_getSZ(1);
  @$pb.TagNumber(2)
  set guid($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGuid() => $_has(1);
  @$pb.TagNumber(2)
  void clearGuid() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get notetypeId => $_getI64(2);
  @$pb.TagNumber(3)
  set notetypeId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNotetypeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotetypeId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get mtimeSecs => $_getIZ(3);
  @$pb.TagNumber(4)
  set mtimeSecs($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMtimeSecs() => $_has(3);
  @$pb.TagNumber(4)
  void clearMtimeSecs() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get usn => $_getIZ(4);
  @$pb.TagNumber(5)
  set usn($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUsn() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsn() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.String> get tags => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<$core.String> get fields => $_getList(6);
}

class AddNoteRequest extends $pb.GeneratedMessage {
  factory AddNoteRequest({
    Note? note,
    $fixnum.Int64? deckId,
  }) {
    final $result = create();
    if (note != null) {
      $result.note = note;
    }
    if (deckId != null) {
      $result.deckId = deckId;
    }
    return $result;
  }
  AddNoteRequest._() : super();
  factory AddNoteRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddNoteRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddNoteRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aOM<Note>(1, _omitFieldNames ? '' : 'note', subBuilder: Note.create)
    ..aInt64(2, _omitFieldNames ? '' : 'deckId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddNoteRequest clone() => AddNoteRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddNoteRequest copyWith(void Function(AddNoteRequest) updates) => super.copyWith((message) => updates(message as AddNoteRequest)) as AddNoteRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddNoteRequest create() => AddNoteRequest._();
  AddNoteRequest createEmptyInstance() => create();
  static $pb.PbList<AddNoteRequest> createRepeated() => $pb.PbList<AddNoteRequest>();
  @$core.pragma('dart2js:noInline')
  static AddNoteRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddNoteRequest>(create);
  static AddNoteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Note get note => $_getN(0);
  @$pb.TagNumber(1)
  set note(Note v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNote() => $_has(0);
  @$pb.TagNumber(1)
  void clearNote() => clearField(1);
  @$pb.TagNumber(1)
  Note ensureNote() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deckId => $_getI64(1);
  @$pb.TagNumber(2)
  set deckId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeckId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeckId() => clearField(2);
}

class AddNoteResponse extends $pb.GeneratedMessage {
  factory AddNoteResponse({
    $2.OpChangesWithCount? changes,
    $fixnum.Int64? noteId,
  }) {
    final $result = create();
    if (changes != null) {
      $result.changes = changes;
    }
    if (noteId != null) {
      $result.noteId = noteId;
    }
    return $result;
  }
  AddNoteResponse._() : super();
  factory AddNoteResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddNoteResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddNoteResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aOM<$2.OpChangesWithCount>(1, _omitFieldNames ? '' : 'changes', subBuilder: $2.OpChangesWithCount.create)
    ..aInt64(2, _omitFieldNames ? '' : 'noteId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddNoteResponse clone() => AddNoteResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddNoteResponse copyWith(void Function(AddNoteResponse) updates) => super.copyWith((message) => updates(message as AddNoteResponse)) as AddNoteResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddNoteResponse create() => AddNoteResponse._();
  AddNoteResponse createEmptyInstance() => create();
  static $pb.PbList<AddNoteResponse> createRepeated() => $pb.PbList<AddNoteResponse>();
  @$core.pragma('dart2js:noInline')
  static AddNoteResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddNoteResponse>(create);
  static AddNoteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $2.OpChangesWithCount get changes => $_getN(0);
  @$pb.TagNumber(1)
  set changes($2.OpChangesWithCount v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasChanges() => $_has(0);
  @$pb.TagNumber(1)
  void clearChanges() => clearField(1);
  @$pb.TagNumber(1)
  $2.OpChangesWithCount ensureChanges() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get noteId => $_getI64(1);
  @$pb.TagNumber(2)
  set noteId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNoteId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNoteId() => clearField(2);
}

class AddNotesRequest extends $pb.GeneratedMessage {
  factory AddNotesRequest({
    $core.Iterable<AddNoteRequest>? requests,
  }) {
    final $result = create();
    if (requests != null) {
      $result.requests.addAll(requests);
    }
    return $result;
  }
  AddNotesRequest._() : super();
  factory AddNotesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddNotesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddNotesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..pc<AddNoteRequest>(1, _omitFieldNames ? '' : 'requests', $pb.PbFieldType.PM, subBuilder: AddNoteRequest.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddNotesRequest clone() => AddNotesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddNotesRequest copyWith(void Function(AddNotesRequest) updates) => super.copyWith((message) => updates(message as AddNotesRequest)) as AddNotesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddNotesRequest create() => AddNotesRequest._();
  AddNotesRequest createEmptyInstance() => create();
  static $pb.PbList<AddNotesRequest> createRepeated() => $pb.PbList<AddNotesRequest>();
  @$core.pragma('dart2js:noInline')
  static AddNotesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddNotesRequest>(create);
  static AddNotesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<AddNoteRequest> get requests => $_getList(0);
}

class AddNotesResponse extends $pb.GeneratedMessage {
  factory AddNotesResponse({
    $2.OpChanges? changes,
    $core.Iterable<$fixnum.Int64>? nids,
  }) {
    final $result = create();
    if (changes != null) {
      $result.changes = changes;
    }
    if (nids != null) {
      $result.nids.addAll(nids);
    }
    return $result;
  }
  AddNotesResponse._() : super();
  factory AddNotesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddNotesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AddNotesResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aOM<$2.OpChanges>(1, _omitFieldNames ? '' : 'changes', subBuilder: $2.OpChanges.create)
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'nids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddNotesResponse clone() => AddNotesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddNotesResponse copyWith(void Function(AddNotesResponse) updates) => super.copyWith((message) => updates(message as AddNotesResponse)) as AddNotesResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddNotesResponse create() => AddNotesResponse._();
  AddNotesResponse createEmptyInstance() => create();
  static $pb.PbList<AddNotesResponse> createRepeated() => $pb.PbList<AddNotesResponse>();
  @$core.pragma('dart2js:noInline')
  static AddNotesResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddNotesResponse>(create);
  static AddNotesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $2.OpChanges get changes => $_getN(0);
  @$pb.TagNumber(1)
  set changes($2.OpChanges v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasChanges() => $_has(0);
  @$pb.TagNumber(1)
  void clearChanges() => clearField(1);
  @$pb.TagNumber(1)
  $2.OpChanges ensureChanges() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$fixnum.Int64> get nids => $_getList(1);
}

class UpdateNotesRequest extends $pb.GeneratedMessage {
  factory UpdateNotesRequest({
    $core.Iterable<Note>? notes,
    $core.bool? skipUndoEntry,
  }) {
    final $result = create();
    if (notes != null) {
      $result.notes.addAll(notes);
    }
    if (skipUndoEntry != null) {
      $result.skipUndoEntry = skipUndoEntry;
    }
    return $result;
  }
  UpdateNotesRequest._() : super();
  factory UpdateNotesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateNotesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateNotesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..pc<Note>(1, _omitFieldNames ? '' : 'notes', $pb.PbFieldType.PM, subBuilder: Note.create)
    ..aOB(2, _omitFieldNames ? '' : 'skipUndoEntry')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateNotesRequest clone() => UpdateNotesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateNotesRequest copyWith(void Function(UpdateNotesRequest) updates) => super.copyWith((message) => updates(message as UpdateNotesRequest)) as UpdateNotesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNotesRequest create() => UpdateNotesRequest._();
  UpdateNotesRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateNotesRequest> createRepeated() => $pb.PbList<UpdateNotesRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateNotesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateNotesRequest>(create);
  static UpdateNotesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Note> get notes => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get skipUndoEntry => $_getBF(1);
  @$pb.TagNumber(2)
  set skipUndoEntry($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSkipUndoEntry() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipUndoEntry() => clearField(2);
}

class DefaultsForAddingRequest extends $pb.GeneratedMessage {
  factory DefaultsForAddingRequest({
    $fixnum.Int64? homeDeckOfCurrentReviewCard,
  }) {
    final $result = create();
    if (homeDeckOfCurrentReviewCard != null) {
      $result.homeDeckOfCurrentReviewCard = homeDeckOfCurrentReviewCard;
    }
    return $result;
  }
  DefaultsForAddingRequest._() : super();
  factory DefaultsForAddingRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DefaultsForAddingRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DefaultsForAddingRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'homeDeckOfCurrentReviewCard')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DefaultsForAddingRequest clone() => DefaultsForAddingRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DefaultsForAddingRequest copyWith(void Function(DefaultsForAddingRequest) updates) => super.copyWith((message) => updates(message as DefaultsForAddingRequest)) as DefaultsForAddingRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DefaultsForAddingRequest create() => DefaultsForAddingRequest._();
  DefaultsForAddingRequest createEmptyInstance() => create();
  static $pb.PbList<DefaultsForAddingRequest> createRepeated() => $pb.PbList<DefaultsForAddingRequest>();
  @$core.pragma('dart2js:noInline')
  static DefaultsForAddingRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DefaultsForAddingRequest>(create);
  static DefaultsForAddingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get homeDeckOfCurrentReviewCard => $_getI64(0);
  @$pb.TagNumber(1)
  set homeDeckOfCurrentReviewCard($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHomeDeckOfCurrentReviewCard() => $_has(0);
  @$pb.TagNumber(1)
  void clearHomeDeckOfCurrentReviewCard() => clearField(1);
}

class DeckAndNotetype extends $pb.GeneratedMessage {
  factory DeckAndNotetype({
    $fixnum.Int64? deckId,
    $fixnum.Int64? notetypeId,
  }) {
    final $result = create();
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    return $result;
  }
  DeckAndNotetype._() : super();
  factory DeckAndNotetype.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeckAndNotetype.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeckAndNotetype', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'deckId')
    ..aInt64(2, _omitFieldNames ? '' : 'notetypeId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeckAndNotetype clone() => DeckAndNotetype()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeckAndNotetype copyWith(void Function(DeckAndNotetype) updates) => super.copyWith((message) => updates(message as DeckAndNotetype)) as DeckAndNotetype;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeckAndNotetype create() => DeckAndNotetype._();
  DeckAndNotetype createEmptyInstance() => create();
  static $pb.PbList<DeckAndNotetype> createRepeated() => $pb.PbList<DeckAndNotetype>();
  @$core.pragma('dart2js:noInline')
  static DeckAndNotetype getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeckAndNotetype>(create);
  static DeckAndNotetype? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deckId => $_getI64(0);
  @$pb.TagNumber(1)
  set deckId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeckId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeckId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get notetypeId => $_getI64(1);
  @$pb.TagNumber(2)
  set notetypeId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNotetypeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNotetypeId() => clearField(2);
}

class RemoveNotesRequest extends $pb.GeneratedMessage {
  factory RemoveNotesRequest({
    $core.Iterable<$fixnum.Int64>? noteIds,
    $core.Iterable<$fixnum.Int64>? cardIds,
  }) {
    final $result = create();
    if (noteIds != null) {
      $result.noteIds.addAll(noteIds);
    }
    if (cardIds != null) {
      $result.cardIds.addAll(cardIds);
    }
    return $result;
  }
  RemoveNotesRequest._() : super();
  factory RemoveNotesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RemoveNotesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RemoveNotesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'noteIds', $pb.PbFieldType.K6)
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'cardIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RemoveNotesRequest clone() => RemoveNotesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RemoveNotesRequest copyWith(void Function(RemoveNotesRequest) updates) => super.copyWith((message) => updates(message as RemoveNotesRequest)) as RemoveNotesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveNotesRequest create() => RemoveNotesRequest._();
  RemoveNotesRequest createEmptyInstance() => create();
  static $pb.PbList<RemoveNotesRequest> createRepeated() => $pb.PbList<RemoveNotesRequest>();
  @$core.pragma('dart2js:noInline')
  static RemoveNotesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoveNotesRequest>(create);
  static RemoveNotesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get noteIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$fixnum.Int64> get cardIds => $_getList(1);
}

class ClozeNumbersInNoteResponse extends $pb.GeneratedMessage {
  factory ClozeNumbersInNoteResponse({
    $core.Iterable<$core.int>? numbers,
  }) {
    final $result = create();
    if (numbers != null) {
      $result.numbers.addAll(numbers);
    }
    return $result;
  }
  ClozeNumbersInNoteResponse._() : super();
  factory ClozeNumbersInNoteResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClozeNumbersInNoteResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClozeNumbersInNoteResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'numbers', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClozeNumbersInNoteResponse clone() => ClozeNumbersInNoteResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClozeNumbersInNoteResponse copyWith(void Function(ClozeNumbersInNoteResponse) updates) => super.copyWith((message) => updates(message as ClozeNumbersInNoteResponse)) as ClozeNumbersInNoteResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClozeNumbersInNoteResponse create() => ClozeNumbersInNoteResponse._();
  ClozeNumbersInNoteResponse createEmptyInstance() => create();
  static $pb.PbList<ClozeNumbersInNoteResponse> createRepeated() => $pb.PbList<ClozeNumbersInNoteResponse>();
  @$core.pragma('dart2js:noInline')
  static ClozeNumbersInNoteResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClozeNumbersInNoteResponse>(create);
  static ClozeNumbersInNoteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get numbers => $_getList(0);
}

class AfterNoteUpdatesRequest extends $pb.GeneratedMessage {
  factory AfterNoteUpdatesRequest({
    $core.Iterable<$fixnum.Int64>? nids,
    $core.bool? markNotesModified,
    $core.bool? generateCards,
  }) {
    final $result = create();
    if (nids != null) {
      $result.nids.addAll(nids);
    }
    if (markNotesModified != null) {
      $result.markNotesModified = markNotesModified;
    }
    if (generateCards != null) {
      $result.generateCards = generateCards;
    }
    return $result;
  }
  AfterNoteUpdatesRequest._() : super();
  factory AfterNoteUpdatesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AfterNoteUpdatesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AfterNoteUpdatesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'nids', $pb.PbFieldType.K6)
    ..aOB(2, _omitFieldNames ? '' : 'markNotesModified')
    ..aOB(3, _omitFieldNames ? '' : 'generateCards')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AfterNoteUpdatesRequest clone() => AfterNoteUpdatesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AfterNoteUpdatesRequest copyWith(void Function(AfterNoteUpdatesRequest) updates) => super.copyWith((message) => updates(message as AfterNoteUpdatesRequest)) as AfterNoteUpdatesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AfterNoteUpdatesRequest create() => AfterNoteUpdatesRequest._();
  AfterNoteUpdatesRequest createEmptyInstance() => create();
  static $pb.PbList<AfterNoteUpdatesRequest> createRepeated() => $pb.PbList<AfterNoteUpdatesRequest>();
  @$core.pragma('dart2js:noInline')
  static AfterNoteUpdatesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AfterNoteUpdatesRequest>(create);
  static AfterNoteUpdatesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get nids => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get markNotesModified => $_getBF(1);
  @$pb.TagNumber(2)
  set markNotesModified($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMarkNotesModified() => $_has(1);
  @$pb.TagNumber(2)
  void clearMarkNotesModified() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get generateCards => $_getBF(2);
  @$pb.TagNumber(3)
  set generateCards($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGenerateCards() => $_has(2);
  @$pb.TagNumber(3)
  void clearGenerateCards() => clearField(3);
}

class FieldNamesForNotesRequest extends $pb.GeneratedMessage {
  factory FieldNamesForNotesRequest({
    $core.Iterable<$fixnum.Int64>? nids,
  }) {
    final $result = create();
    if (nids != null) {
      $result.nids.addAll(nids);
    }
    return $result;
  }
  FieldNamesForNotesRequest._() : super();
  factory FieldNamesForNotesRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldNamesForNotesRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FieldNamesForNotesRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'nids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldNamesForNotesRequest clone() => FieldNamesForNotesRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldNamesForNotesRequest copyWith(void Function(FieldNamesForNotesRequest) updates) => super.copyWith((message) => updates(message as FieldNamesForNotesRequest)) as FieldNamesForNotesRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldNamesForNotesRequest create() => FieldNamesForNotesRequest._();
  FieldNamesForNotesRequest createEmptyInstance() => create();
  static $pb.PbList<FieldNamesForNotesRequest> createRepeated() => $pb.PbList<FieldNamesForNotesRequest>();
  @$core.pragma('dart2js:noInline')
  static FieldNamesForNotesRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldNamesForNotesRequest>(create);
  static FieldNamesForNotesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get nids => $_getList(0);
}

class FieldNamesForNotesResponse extends $pb.GeneratedMessage {
  factory FieldNamesForNotesResponse({
    $core.Iterable<$core.String>? fields,
  }) {
    final $result = create();
    if (fields != null) {
      $result.fields.addAll(fields);
    }
    return $result;
  }
  FieldNamesForNotesResponse._() : super();
  factory FieldNamesForNotesResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldNamesForNotesResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FieldNamesForNotesResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'fields')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldNamesForNotesResponse clone() => FieldNamesForNotesResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldNamesForNotesResponse copyWith(void Function(FieldNamesForNotesResponse) updates) => super.copyWith((message) => updates(message as FieldNamesForNotesResponse)) as FieldNamesForNotesResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldNamesForNotesResponse create() => FieldNamesForNotesResponse._();
  FieldNamesForNotesResponse createEmptyInstance() => create();
  static $pb.PbList<FieldNamesForNotesResponse> createRepeated() => $pb.PbList<FieldNamesForNotesResponse>();
  @$core.pragma('dart2js:noInline')
  static FieldNamesForNotesResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldNamesForNotesResponse>(create);
  static FieldNamesForNotesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get fields => $_getList(0);
}

class NoteFieldsCheckResponse extends $pb.GeneratedMessage {
  factory NoteFieldsCheckResponse({
    NoteFieldsCheckResponse_State? state,
  }) {
    final $result = create();
    if (state != null) {
      $result.state = state;
    }
    return $result;
  }
  NoteFieldsCheckResponse._() : super();
  factory NoteFieldsCheckResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NoteFieldsCheckResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NoteFieldsCheckResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.notes'), createEmptyInstance: create)
    ..e<NoteFieldsCheckResponse_State>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: NoteFieldsCheckResponse_State.NORMAL, valueOf: NoteFieldsCheckResponse_State.valueOf, enumValues: NoteFieldsCheckResponse_State.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NoteFieldsCheckResponse clone() => NoteFieldsCheckResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NoteFieldsCheckResponse copyWith(void Function(NoteFieldsCheckResponse) updates) => super.copyWith((message) => updates(message as NoteFieldsCheckResponse)) as NoteFieldsCheckResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NoteFieldsCheckResponse create() => NoteFieldsCheckResponse._();
  NoteFieldsCheckResponse createEmptyInstance() => create();
  static $pb.PbList<NoteFieldsCheckResponse> createRepeated() => $pb.PbList<NoteFieldsCheckResponse>();
  @$core.pragma('dart2js:noInline')
  static NoteFieldsCheckResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NoteFieldsCheckResponse>(create);
  static NoteFieldsCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  NoteFieldsCheckResponse_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(NoteFieldsCheckResponse_State v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => clearField(1);
}

class NotesServiceApi {
  $pb.RpcClient _client;
  NotesServiceApi(this._client);

  $async.Future<Note> newNote($pb.ClientContext? ctx, $12.NotetypeId request) =>
    _client.invoke<Note>(ctx, 'NotesService', 'NewNote', request, Note())
  ;
  $async.Future<AddNoteResponse> addNote($pb.ClientContext? ctx, AddNoteRequest request) =>
    _client.invoke<AddNoteResponse>(ctx, 'NotesService', 'AddNote', request, AddNoteResponse())
  ;
  $async.Future<AddNotesResponse> addNotes($pb.ClientContext? ctx, AddNotesRequest request) =>
    _client.invoke<AddNotesResponse>(ctx, 'NotesService', 'AddNotes', request, AddNotesResponse())
  ;
  $async.Future<DeckAndNotetype> defaultsForAdding($pb.ClientContext? ctx, DefaultsForAddingRequest request) =>
    _client.invoke<DeckAndNotetype>(ctx, 'NotesService', 'DefaultsForAdding', request, DeckAndNotetype())
  ;
  $async.Future<$4.DeckId> defaultDeckForNotetype($pb.ClientContext? ctx, $12.NotetypeId request) =>
    _client.invoke<$4.DeckId>(ctx, 'NotesService', 'DefaultDeckForNotetype', request, $4.DeckId())
  ;
  $async.Future<$2.OpChanges> updateNotes($pb.ClientContext? ctx, UpdateNotesRequest request) =>
    _client.invoke<$2.OpChanges>(ctx, 'NotesService', 'UpdateNotes', request, $2.OpChanges())
  ;
  $async.Future<Note> getNote($pb.ClientContext? ctx, NoteId request) =>
    _client.invoke<Note>(ctx, 'NotesService', 'GetNote', request, Note())
  ;
  $async.Future<$2.OpChangesWithCount> removeNotes($pb.ClientContext? ctx, RemoveNotesRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'NotesService', 'RemoveNotes', request, $2.OpChangesWithCount())
  ;
  $async.Future<ClozeNumbersInNoteResponse> clozeNumbersInNote($pb.ClientContext? ctx, Note request) =>
    _client.invoke<ClozeNumbersInNoteResponse>(ctx, 'NotesService', 'ClozeNumbersInNote', request, ClozeNumbersInNoteResponse())
  ;
  $async.Future<$2.OpChangesWithCount> afterNoteUpdates($pb.ClientContext? ctx, AfterNoteUpdatesRequest request) =>
    _client.invoke<$2.OpChangesWithCount>(ctx, 'NotesService', 'AfterNoteUpdates', request, $2.OpChangesWithCount())
  ;
  $async.Future<FieldNamesForNotesResponse> fieldNamesForNotes($pb.ClientContext? ctx, FieldNamesForNotesRequest request) =>
    _client.invoke<FieldNamesForNotesResponse>(ctx, 'NotesService', 'FieldNamesForNotes', request, FieldNamesForNotesResponse())
  ;
  $async.Future<NoteFieldsCheckResponse> noteFieldsCheck($pb.ClientContext? ctx, Note request) =>
    _client.invoke<NoteFieldsCheckResponse>(ctx, 'NotesService', 'NoteFieldsCheck', request, NoteFieldsCheckResponse())
  ;
  $async.Future<$3.CardIds> cardsOfNote($pb.ClientContext? ctx, NoteId request) =>
    _client.invoke<$3.CardIds>(ctx, 'NotesService', 'CardsOfNote', request, $3.CardIds())
  ;
  $async.Future<$12.NotetypeId> getSingleNotetypeOfNotes($pb.ClientContext? ctx, NoteIds request) =>
    _client.invoke<$12.NotetypeId>(ctx, 'NotesService', 'GetSingleNotetypeOfNotes', request, $12.NotetypeId())
  ;
}

class BackendNotesServiceApi {
  $pb.RpcClient _client;
  BackendNotesServiceApi(this._client);

}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
